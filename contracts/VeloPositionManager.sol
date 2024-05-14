// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./external/openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./external/openzeppelin/contracts/access/Ownable.sol";
import "./external/openzeppelin/contracts/utils/math/SafeMath.sol";
import "./external/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IVeloVaultPositionManager.sol";
import "./interfaces/IVaultFactory.sol";
import "./interfaces/IVeloVault.sol";

import "./libraries/helpers/Errors.sol";
import "./Payments.sol";

import "./interfaces/IAddressRegistry.sol";
import "./libraries/helpers/AddressId.sol";

import "./libraries/types/VaultTypes.sol";

contract VeloPositionManager is
    ReentrancyGuard,
    IVeloVaultPositionManager,
    Ownable,
    Payments
{
    using SafeMath for uint256;

    /// @notice Contract address of the AddressProvider
    address public immutable addressProvider;
    /// @notice Contract address of the VaultFactory
    address public immutable vaultFactory;

    /// @notice permissionLessLiquidation feature
    /// Only if this feature is true, users can liquidate positions without permissions.
    /// Otherwise only liquidators in the whitelist can liquidate positions.
    bool public permissionLessLiquidationEnabled;
    /// @notice liquidatorWhitelist
    mapping(address => bool) public liquidatorWhitelist;

    /// @notice permissionLessCompoundEnabled feature
    /// Only if this feature is true, users can claim the vaults' rewards and reinvest to liquidity  without permissions.
    /// Otherwise only users in the whitelist can call the reinvest function
    bool public permissionLessCompoundEnabled;
    /// @notice CompounderWhitelist
    mapping(address => bool) public compounderWhitelist;

    /// @notice permissionLessRangeStopEnabled feature
    /// Only if this feature is true, users can close outof-range positions
    bool public permissionLessRangeStopEnabled;
    /// @notice rangeStopCallerWhitelist
    mapping(address => bool) public rangeStopCallerWhitelist;

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, Errors.VL_TRANSACTION_TOO_OLD);
        _;
    }

    modifier liquidatorInWhitelist() {
        require(
            permissionLessLiquidationEnabled || liquidatorWhitelist[msg.sender],
            Errors.VL_LIQUIDATOR_NOT_IN_WHITELIST
        );
        _;
    }

    modifier compounderInWhitelist() {
        require(
            permissionLessCompoundEnabled || compounderWhitelist[msg.sender],
            Errors.VL_LIQUIDATOR_NOT_IN_WHITELIST
        );
        _;
    }

    modifier rangeStopCallerInWhitelist() {
        require(
            permissionLessRangeStopEnabled ||
                rangeStopCallerWhitelist[msg.sender],
            Errors.VL_LIQUIDATOR_NOT_IN_WHITELIST
        );
        _;
    }

    constructor(
        address _addressProvider
    )
        Payments(
            IAddressRegistry(_addressProvider).getAddress(
                AddressId.ADDRESS_ID_WETH9
            )
        )
    {
        require(_addressProvider != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        addressProvider = _addressProvider;
        vaultFactory = IAddressRegistry(addressProvider).getAddress(
            AddressId.ADDRESS_ID_VAULT_FACTORY
        );

        disablePermissionLessLiquidation();
        addPermissionedLiquidator(msg.sender);
        disablePermissionLessCompound();
        addPermissionedCompounder(msg.sender);
        disablePermissonLessRangeStop();
        addPermissionedRangeStopCaller(msg.sender);
    }

    /// @notice Callback functions called by the vault to pay tokens to the vault contract.
    /// The caller to this function must be the vault contract
    function payToVaultCallback(
        PayToVaultCallbackParams calldata params
    ) external {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(
            params.vaultId
        );
        require(vaultAddress != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        require(
            vaultAddress == _msgSender(),
            Errors.VT_VAULT_CALLBACK_INVALID_SENDER
        );

        // transfer token0 and token1 from user's wallet to vault
        if (params.amount0 > 0) {
            pay(
                IVeloVault(vaultAddress).token0(),
                params.payer,
                vaultAddress,
                params.amount0
            );
        }
        if (params.amount1 > 0) {
            pay(
                IVeloVault(vaultAddress).token1(),
                params.payer,
                vaultAddress,
                params.amount1
            );
        }
    }

    /// @notice Callback functions called by the vault to pay protocol fee.
    /// The caller to this function must be the vault contract
    function payFeeToTreasuryCallback(
        uint256 vaultId,
        address asset,
        uint256 amount,
        uint256 feeType
    ) external {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(vaultId);
        require(vaultAddress != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        require(
            vaultAddress == _msgSender(),
            Errors.VT_VAULT_CALLBACK_INVALID_SENDER
        );

        address treasury = IAddressRegistry(addressProvider).getAddress(
            AddressId.ADDRESS_ID_TREASURY
        );
        require(treasury != address(0), "zero-address treasury");

        SafeERC20.safeTransferFrom(
            IERC20(asset),
            vaultAddress,
            treasury,
            amount
        );

        emit FeePaid(vaultId, asset, feeType, amount);
    }

    /// @notice Open a new vaultPosition or invest to a existing vault position
    /// @param params The parameters necessary, encoded as `NewOrInvestToVaultPositionParams` in calldata
    function newOrInvestToVaultPosition(
        NewOrInvestToVaultPositionParams calldata params
    ) external payable nonReentrant checkDeadline(params.deadline) {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(
            params.vaultId
        );
        require(vaultAddress != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);

        (uint256 positionId, uint256 liquidity) = IVeloVault(vaultAddress)
            .newOrInvestToVaultPosition(params, _msgSender());

        if (params.vaultPositionId == 0) {
            emit NewVaultPosition(params.vaultId, positionId, _msgSender());
        }

        // if user use ether, refund unused ether to msg.sender
        if (msg.value > 0) {
            refundETH();
        }

        emit InvestToVaultPosition(
            params.vaultId,
            positionId,
            _msgSender(),
            params.amount0Invest,
            params.amount1Invest,
            params.amount0Borrow,
            params.amount1Borrow,
            liquidity
        );
    }

    /// @notice Close a vaultPosition partially
    /// @param params The parameters necessary, encoded as `CloseVaultPositionPartiallyParams` in calldata
    function closeVaultPositionPartially(
        CloseVaultPositionPartiallyParams calldata params
    ) external override nonReentrant checkDeadline(params.deadline) {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(
            params.vaultId
        );
        require(vaultAddress != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);

        (
            uint256 amount0,
            uint256 amount1,
            uint256 repay0,
            uint256 repay1
        ) = IVeloVault(vaultAddress).closeAndRepayPartially(
                params,
                _msgSender()
            );

        if (
            amount0 > 0 &&
            IVeloVault(vaultAddress).token0() == WETH9 &&
            params.receiveNativeETH
        ) {
            unwrapWETH9(amount0, params.receiver);
        }

        if (
            amount1 > 0 &&
            IVeloVault(vaultAddress).token1() == WETH9 &&
            params.receiveNativeETH
        ) {
            unwrapWETH9(amount1, params.receiver);
        }

        emit CloseVaultPositionPartially(
            params.vaultId,
            params.vaultPositionId,
            _msgSender(),
            params.percent,
            amount0,
            amount1,
            repay0,
            repay1
        );
    }

    /// @notice Close the position which is outof price range.
    /// This function can be called only if the `rangeStop` feature is enabled.
    /// Any permissioned user can call this function, regardless of whether they are the position owner.
    /// @param params The parameters necessary, encoded as `CloseVaultPositionPartiallyParams` in calldata
    function closeOutOfRangePosition(
        CloseVaultPositionPartiallyParams calldata params
    )
        external
        payable
        nonReentrant
        rangeStopCallerInWhitelist
        avoidUsingNativeEther
    {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(
            params.vaultId
        );
        require(vaultAddress != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);

        (
            address positionManager,
            uint256 price,
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 fee1
        ) = IVeloVault(vaultAddress).closeAndRepayOutOfRangePosition(params);

        if (
            fee0 > 0 &&
            IVeloVault(vaultAddress).token0() == WETH9 &&
            params.receiveNativeETH
        ) {
            unwrapWETH9(fee0, params.receiver);
        }

        if (
            fee1 > 0 &&
            IVeloVault(vaultAddress).token1() == WETH9 &&
            params.receiveNativeETH
        ) {
            unwrapWETH9(fee1, params.receiver);
        }

        emit CloseOutOfRangePosition(
            params.vaultId,
            params.vaultPositionId,
            positionManager,
            _msgSender(),
            params.percent,
            uint64(block.timestamp),
            price,
            amount0,
            amount1,
            fee0,
            fee1
        );
    }

    /// @notice Liquidate a vaultPosition partially
    /// @param params The parameters necessary, encoded as `LiquidateVaultPositionPartiallyParams` in calldata
    function liquidateVaultPositionPartially(
        LiquidateVaultPositionPartiallyParams calldata params
    ) external payable nonReentrant liquidatorInWhitelist {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(
            params.vaultId
        );
        require(vaultAddress != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);

        IVeloVault.LiquidateState memory result = IVeloVault(vaultAddress)
            .repayAndLiquidatePositionPartially(params, _msgSender());

        if (
            result.liquidatorReceive0 > 0 &&
            IVeloVault(vaultAddress).token0() == WETH9 &&
            params.receiveNativeETH
        ) {
            unwrapWETH9(result.liquidatorReceive0, params.receiver);
        }

        if (
            result.liquidatorReceive1 > 0 &&
            IVeloVault(vaultAddress).token1() == WETH9 &&
            params.receiveNativeETH
        ) {
            unwrapWETH9(result.liquidatorReceive1, params.receiver);
        }

        // if user use ether, refund unused ether to msg.sender
        if (msg.value > 0) {
            refundETH();
        }

        emit LiquidateVaultPositionPartially(
            params.vaultId,
            params.vaultPositionId,
            result.manager,
            _msgSender(),
            params.percent,
            uint64(block.timestamp),
            result.price,
            result.repaidValue,
            result.removedLiquidityValue,
            result.amount0Left,
            result.amount1Left,
            result.liquidateFee0,
            result.liquidateFee1
        );
    }

    /// @notice Invest the earned fee by the position to liquidity
    function investEarnedFeeToLiquidity(
        InvestEarnedFeeToLiquidityParam calldata params
    ) external nonReentrant compounderInWhitelist {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(
            params.vaultId
        );
        require(vaultAddress != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);

        (
            uint256 liquidity,
            uint256 fee0,
            uint256 fee1,
            uint256[] memory rewards
        ) = IVeloVault(vaultAddress).claimRewardsAndReInvestToLiquidity(params);

        if (
            fee0 > 0 &&
            IVeloVault(vaultAddress).token0() == WETH9 &&
            params.receiveNativeETH
        ) {
            unwrapWETH9(fee0, params.compoundFeeReceiver);
        }

        if (
            fee1 > 0 &&
            IVeloVault(vaultAddress).token1() == WETH9 &&
            params.receiveNativeETH
        ) {
            unwrapWETH9(fee1, params.compoundFeeReceiver);
        }

        emit InvestEarnedFeeToLiquidity(
            params.vaultId,
            _msgSender(),
            liquidity,
            fee0,
            fee1,
            rewards
        );
    }

    /// @notice Repay exact value of debts
    function exactRepay(
        ExactRepayParam calldata params
    )
        external
        payable
        nonReentrant
        returns (uint256 amount0Repaid, uint256 amount1Repaid)
    {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(
            params.vaultId
        );
        require(vaultAddress != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);

        address positionMananegr;

        (positionMananegr, amount0Repaid, amount1Repaid) = IVeloVault(
            vaultAddress
        ).exactRepay(params, _msgSender());

        if (
            params.amount0ToRepay > amount0Repaid &&
            IVeloVault(vaultAddress).token0() == WETH9 &&
            params.receiveNativeETH
        ) {
            unwrapWETH9(params.amount0ToRepay.sub(amount0Repaid), _msgSender());
        }

        if (
            params.amount1ToRepay > amount1Repaid &&
            IVeloVault(vaultAddress).token1() == WETH9 &&
            params.receiveNativeETH
        ) {
            unwrapWETH9(params.amount1ToRepay.sub(amount1Repaid), _msgSender());
        }

        // if there is unused ETH, refund it to msg.sender
        if (msg.value > 0) {
            refundETH();
        }

        emit ExactRepay(
            params.vaultId,
            params.vaultPositionId,
            positionMananegr,
            _msgSender(),
            amount0Repaid,
            amount1Repaid
        );
    }

    function adminSetVault(
        uint256 vaultId,
        bytes calldata params
    ) external nonReentrant onlyOwner {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(vaultId);
        require(vaultAddress != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        IVeloVault(vaultAddress).adminSetVault(params);
    }

    /// @notice Transfer the position's manager to another wallet
    /// Must be called by the current manager of the posistion
    /// @param vaultId The Id of the vault
    /// @param vaultPositionId The Id of the position
    /// @param newManager The new address of the manager
    function transferManagerOfVaultPosition(
        uint256 vaultId,
        uint256 vaultPositionId,
        address newManager
    ) external override nonReentrant {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(vaultId);
        require(vaultAddress != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        IVeloVault(vaultAddress).transferManagerTo(
            _msgSender(),
            vaultPositionId,
            newManager
        );
    }

    /// @notice Set stop-loss price range of the position
    /// Users can set a stop-loss price range for a position only if the position is enabled `RangeStop` feature.
    /// If current price goes out of the stop-loss price range, extraFi's bots will close the position
    /// @param vaultId The Id of the vault
    /// @param vaultPositionId The Id of the position
    /// @param enable Enable or Disable the rangeStop feature
    /// @param minPrice The lower price of the stop-loss price range
    /// @param maxPrice The upper price of the stop-loss price range
    function setRangeStop(
        uint256 vaultId,
        uint256 vaultPositionId,
        bool enable,
        uint256 minPrice,
        uint256 maxPrice
    ) external override nonReentrant {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(vaultId);
        require(vaultAddress != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        IVeloVault(vaultAddress).setRangeStop(
            _msgSender(),
            vaultPositionId,
            enable,
            minPrice,
            maxPrice
        );
    }

    function enablePermissionLessLiquidation() public nonReentrant onlyOwner {
        permissionLessLiquidationEnabled = true;
    }

    function disablePermissionLessLiquidation() public nonReentrant onlyOwner {
        permissionLessLiquidationEnabled = false;
    }

    function addPermissionedLiquidator(
        address addr
    ) public nonReentrant onlyOwner {
        liquidatorWhitelist[addr] = true;
    }

    function removePermissionedLiquidator(
        address addr
    ) public nonReentrant onlyOwner {
        liquidatorWhitelist[addr] = false;
    }

    function enablePermissionLessCompound() public nonReentrant onlyOwner {
        permissionLessCompoundEnabled = true;
    }

    function disablePermissionLessCompound() public nonReentrant onlyOwner {
        permissionLessCompoundEnabled = false;
    }

    function addPermissionedCompounder(
        address addr
    ) public nonReentrant onlyOwner {
        compounderWhitelist[addr] = true;
    }

    function removePermissionedCompounder(
        address addr
    ) public nonReentrant onlyOwner {
        compounderWhitelist[addr] = false;
    }

    function enablePermissonLessRangeStop() public nonReentrant onlyOwner {
        permissionLessRangeStopEnabled = true;
    }

    function disablePermissonLessRangeStop() public nonReentrant onlyOwner {
        permissionLessRangeStopEnabled = false;
    }

    function addPermissionedRangeStopCaller(
        address addr
    ) public nonReentrant onlyOwner {
        rangeStopCallerWhitelist[addr] = true;
    }

    function removePermissionedRangeStopCaller(
        address addr
    ) public nonReentrant onlyOwner {
        rangeStopCallerWhitelist[addr] = false;
    }

    //----------------->>>>>  getters <<<<<-----------------
    function getVault(
        uint256 vaultId
    ) external view override returns (VaultTypes.VeloVaultState memory) {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(vaultId);
        return IVeloVault(vaultAddress).getVaultState();
    }

    function getVaultPosition(
        uint256 vaultId,
        uint256 vaultPositionId
    )
        external
        view
        override
        returns (VaultTypes.VeloPositionValue memory state)
    {
        address vaultAddress = IVaultFactory(vaultFactory).vaults(vaultId);
        return IVeloVault(vaultAddress).getPositionValue(vaultPositionId);
    }
}
