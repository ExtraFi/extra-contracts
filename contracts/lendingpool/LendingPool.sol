// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../external/openzeppelin/contracts/utils/math/SafeMath.sol";
import "../external/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../external/openzeppelin/contracts/access/Ownable.sol";
import "../external/openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/ILendingPool.sol";
import "../interfaces/IVaultFactory.sol";

import "../libraries/types/DataTypes.sol";
import "../libraries/logic/ReserveLogic.sol";
import "../libraries/logic/ReserveKey.sol";
import "../libraries/logic/ETokenDeployer.sol";
import "../libraries/logic/StakingRewardsDeployer.sol";

import "../AddressRegistry.sol";
import "../Payments.sol";

contract LendingPool is ILendingPool, Ownable, Payments, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ReserveLogic for DataTypes.ReserveData;

    uint256 constant MINIMUM_ETOKEN_AMOUNT = 1000;
    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Reserve map, each reserve represents a pool that users can deposit/withdraw/borrow/repay
    mapping(uint256 => DataTypes.ReserveData) public reserves;
    uint256 public nextReserveId = 1;

    // Credits is the borrowing power of vaults
    // Each vault should own a specific credits so as to borrow tokens from the pool
    // Only the contract that have enough credits can borrow from lending pool
    // Only owners can set this map to grant new credits to a contract
    // Credits, mapping(reserveId => mapping(contract_address => credits))
    mapping(uint256 => mapping(address => uint256)) public credits;

    // Whitelist of vault contracts
    // only vault contracts in the whitelist can borrow from the lending pool
    mapping(address => bool) public borrowingWhiteList;

    address public immutable addressRegistry;

    // Debt positions, mapping(debtId => DebtPosition)
    mapping(uint256 => DataTypes.DebtPositionData) public debtPositions;
    uint256 public nextDebtPositionId = 1;

    bool public paused = false;

    modifier notPaused() {
        require(!paused, Errors.LP_IS_PAUSED);
        _;
    }

    constructor(address _addressRegistry, address _WETH9) Payments(_WETH9) {
        require(_addressRegistry != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        require(_WETH9 != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        addressRegistry = _addressRegistry;
    }

    /// @notice initialize a reserve pool for an asset
    function initReserve(address asset) external onlyOwner notPaused {
        uint256 id = nextReserveId;
        nextReserveId += 1;

        // new a eToken contract
        string memory name = string(
            abi.encodePacked(
                ERC20(asset).name(),
                "(ExtraFi Interest Bearing Token)"
            )
        );
        string memory symbol = string(
            abi.encodePacked("e", ERC20(asset).symbol())
        );
        uint8 decimals = ERC20(asset).decimals();

        address eTokenAddress = ETokenDeployer.deploy(
            name,
            symbol,
            decimals,
            asset,
            id
        );

        DataTypes.ReserveData storage reserveData = reserves[id];
        reserveData.setActive(true);
        reserveData.setBorrowingEnabled(true);

        initReserve(reserveData, asset, eTokenAddress, type(uint256).max, id);

        createStakingPoolForReserve(id);

        emit InitReserve(asset, eTokenAddress, reserveData.stakingAddress, id);
    }

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying eTokens.
     * - E.g. User deposits 100 USDC and gets in return for specific amount of eUSDC
     * the eUSDC amount depends on the exchange rate between USDC and eUSDC
     * @param reserveId The ID of the reserve
     * @param amount The amount of reserve to be deposited
     * @param onBehalfOf The address that will receive the eTokens, same as _msgSender() if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of eTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) public payable notPaused nonReentrant returns (uint256 eTokenAmount) {
        eTokenAmount = _deposit(reserveId, amount, onBehalfOf);

        // if there is unused ETH, refund it to _msgSender()
        if (msg.value > 0) {
            refundETH();
        }

        // emit event
        emit Deposited(
            reserveId,
            _msgSender(),
            onBehalfOf,
            amount,
            eTokenAmount,
            referralCode
        );
    }

    // deposit assets and stake eToken to the staking contract for rewards
    function depositAndStake(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external payable notPaused nonReentrant returns (uint256 eTokenAmount) {
        eTokenAmount = _deposit(reserveId, amount, address(this));

        address stakingPool = reserves[reserveId].stakingAddress;
        require(stakingPool != address(0), "Address=0");
        IERC20(getETokenAddress(reserveId)).approve(stakingPool, eTokenAmount);
        IStakingRewards(stakingPool).stake(eTokenAmount, onBehalfOf);

        // if there is unused ETH, refund it to _msgSender()
        if (msg.value > 0) {
            refundETH();
        }

        // emit event
        emit Deposited(
            reserveId,
            _msgSender(),
            onBehalfOf,
            amount,
            eTokenAmount,
            referralCode
        );
    }

    /**
     * @dev User redeems eTokens in exchange for the underlying asset
     * E.g. User has 100 fUSDC, and the current exchange rate of fUSDC and USDC is 1:1.1
     * he will receive 110 USDC after redeem 100fUSDC
     * @param reserveId The id of the reserve
     * @param eTokenAmount The amount of eTokens to redeem
     *   - If the amount is type(uint256).max, all of user's eTokens will be redeemed
     * @param to Address that will receive the underlying tokens, same as _msgSender() if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @param receiveNativeETH If receive native ETH, set this param to true
     * @return The underlying token amount user finally receive
     **/
    function redeem(
        uint256 reserveId,
        uint256 eTokenAmount,
        address to,
        bool receiveNativeETH
    ) public notPaused nonReentrant returns (uint256) {
        DataTypes.ReserveData storage reserve = getReserve(reserveId);

        if (eTokenAmount == type(uint256).max) {
            eTokenAmount = IExtraInterestBearingToken(reserve.eTokenAddress)
                .balanceOf(_msgSender());
        }
        // transfer eTokens to this contract
        IERC20(reserve.eTokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            eTokenAmount
        );

        // calculate underlying tokens using eTokens
        uint256 underlyingTokenAmount = _redeem(
            reserveId,
            eTokenAmount,
            to,
            receiveNativeETH
        );

        emit Redeemed(
            reserveId,
            _msgSender(),
            to,
            eTokenAmount,
            underlyingTokenAmount
        );

        return (underlyingTokenAmount);
    }

    // unstake stakedEtoken and redeem etokens
    function unStakeAndWithdraw(
        uint256 reserveId,
        uint256 eTokenAmount,
        address to,
        bool receiveNativeETH
    ) external notPaused nonReentrant returns (uint256) {
        address stakingPool = reserves[reserveId].stakingAddress;
        require(stakingPool != address(0), "Address=0");

        IStakingRewards(stakingPool).withdrawByLendingPool(
            eTokenAmount,
            _msgSender(),
            address(this)
        );

        uint256 underlyingTokenAmount = _redeem(
            reserveId,
            eTokenAmount,
            to,
            receiveNativeETH
        );

        emit Redeemed(
            reserveId,
            _msgSender(),
            to,
            eTokenAmount,
            underlyingTokenAmount
        );

        return (underlyingTokenAmount);
    }

    function _deposit(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf
    ) internal returns (uint256 eTokenAmount) {
        DataTypes.ReserveData storage reserve = getReserve(reserveId);
        require(!reserve.getFrozen(), Errors.VL_RESERVE_FROZEN);
        // update states
        reserve.updateState(getTreasury());

        // validate
        reserve.checkCapacity(amount);

        uint256 exchangeRate = reserve.reserveToETokenExchangeRate();

        // Transfer the user's reserve token to eToken contract
        pay(
            reserve.underlyingTokenAddress,
            _msgSender(),
            reserve.eTokenAddress,
            amount
        );

        // Mint eTokens for the user
        eTokenAmount = amount.mul(exchangeRate).div(Precision.FACTOR1E18);

        require(eTokenAmount > MINIMUM_ETOKEN_AMOUNT, Errors.VL_ETOKEN_AMOUNT_TOO_SMALL);
        if (IExtraInterestBearingToken(reserve.eTokenAddress).totalSupply() == 0) {
            // Burn the first 1000 etoken, to defend against lp inflation attacks
            IExtraInterestBearingToken(reserve.eTokenAddress).mint(
                DEAD_ADDRESS,
                MINIMUM_ETOKEN_AMOUNT
            );

            eTokenAmount -= MINIMUM_ETOKEN_AMOUNT;
        }

        IExtraInterestBearingToken(reserve.eTokenAddress).mint(
            onBehalfOf,
            eTokenAmount
        );

        // update the interest rate after the deposit
        reserve.updateInterestRates();
    }

    function _redeem(
        uint256 reserveId,
        uint256 eTokenAmount,
        address to,
        bool receiveNativeETH
    ) internal returns (uint256) {
        DataTypes.ReserveData storage reserve = getReserve(reserveId);
        // update states
        reserve.updateState(getTreasury());

        // calculate underlying tokens using eTokens
        uint256 underlyingTokenAmount = reserve
            .eTokenToReserveExchangeRate()
            .mul(eTokenAmount)
            .div(Precision.FACTOR1E18);

        require(
            underlyingTokenAmount <= reserve.availableLiquidity(),
            Errors.VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH
        );

        if (reserve.underlyingTokenAddress == WETH9 && receiveNativeETH) {
            IExtraInterestBearingToken(reserve.eTokenAddress).burn(
                address(this),
                eTokenAmount,
                underlyingTokenAmount
            );
            unwrapWETH9(underlyingTokenAmount, to);
        } else {
            // burn eTokens and transfer the underlying tokens to receiver
            IExtraInterestBearingToken(reserve.eTokenAddress).burn(
                to,
                eTokenAmount,
                underlyingTokenAmount
            );
        }

        // update the interest rate after the redeem
        reserve.updateInterestRates();

        return (underlyingTokenAmount);
    }

    function newDebtPosition(
        uint256 reserveId
    ) external notPaused nonReentrant returns (uint256 debtId) {
        DataTypes.ReserveData storage reserve = getReserve(reserveId);
        require(!reserve.getFrozen(), Errors.VL_RESERVE_FROZEN);
        require(reserve.getBorrowingEnabled(), Errors.VL_BORROWING_NOT_ENABLED);

        debtId = nextDebtPositionId;
        nextDebtPositionId = nextDebtPositionId + 1;
        DataTypes.DebtPositionData storage newPosition = debtPositions[debtId];
        newPosition.owner = _msgSender();

        reserve.updateState(getTreasury());
        reserve.updateInterestRates();

        newPosition.reserveId = reserveId;
        newPosition.borrowedIndex = reserve.borrowingIndex;
    }

    /**
     * @dev Allows farming users to borrow a specific `amount` of the reserve underlying asset.
     * The user's borrowed tokens is transferred to the vault contract and is recorded in the user's vault position.
     * When debt ratio of user's vault position reach the liquidate limit,
     * the position will be liquidated and repay his debt(borrowed value + accrued interest)
     * @param onBehalfOf The beneficiary of the borrowing, receiving the tokens in his vaultPosition
     * @param debtId The debtPositionId
     * @param amount The amount to be borrowed
     */
    function borrow(
        address onBehalfOf,
        uint256 debtId,
        uint256 amount
    ) external notPaused nonReentrant {
        require(
            borrowingWhiteList[_msgSender()],
            Errors.VL_BORROWING_CALLER_NOT_IN_WHITELIST
        );

        DataTypes.DebtPositionData storage debtPosition = debtPositions[debtId];
        require(
            _msgSender() == debtPosition.owner,
            Errors.VL_INVALID_DEBT_OWNER
        );

        DataTypes.ReserveData storage reserve = getReserve(
            debtPosition.reserveId
        );
        require(!reserve.getFrozen(), Errors.VL_RESERVE_FROZEN);
        require(reserve.getBorrowingEnabled(), Errors.VL_BORROWING_NOT_ENABLED);

        // update states
        reserve.updateState(getTreasury());
        updateDebtPosition(debtPosition, reserve.borrowingIndex);

        // only vault contract has credits to borrow tokens
        // when this function is called from the vault contracts,
        // the _msgSender() is the vault's address
        uint256 credit = credits[debtPosition.reserveId][_msgSender()];
        require(amount <= credit, Errors.VL_OUT_OF_CREDITS);
        credits[debtPosition.reserveId][_msgSender()] = credit.sub(amount);

        require(
            amount <= reserve.availableLiquidity(),
            Errors.LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW
        );
        reserve.totalBorrows += amount;
        debtPosition.borrowed += amount;
        // The receiver of the underlying tokens must be the farming contract (_msgSender())
        IExtraInterestBearingToken(reserve.eTokenAddress).transferUnderlyingTo(
            _msgSender(),
            amount
        );

        reserve.updateInterestRates();

        emit Borrow(debtPosition.reserveId, _msgSender(), onBehalfOf, amount);
    }

    /**
     * @notice Repays borrowed underlying tokens to the reserve pool
     * The user's debt is recorded in the vault position(Vault Contract).
     * After this function successfully executed, user's debt should be reduced in Vault Contract.
     * @param onBehalfOf The user who repay debts in his vaultPosition
     * @param debtId The debtPositionId
     * @param amount The amount to be borrowed
     * @return The final amount repaid
     **/
    function repay(
        address onBehalfOf,
        uint256 debtId,
        uint256 amount
    ) external notPaused nonReentrant returns (uint256) {
        require(
            borrowingWhiteList[_msgSender()],
            Errors.VL_BORROWING_CALLER_NOT_IN_WHITELIST
        );

        DataTypes.DebtPositionData storage debtPosition = debtPositions[debtId];
        require(
            _msgSender() == debtPosition.owner,
            Errors.VL_INVALID_DEBT_OWNER
        );

        DataTypes.ReserveData storage reserve = getReserve(
            debtPosition.reserveId
        );

        // update states
        reserve.updateState(getTreasury());
        updateDebtPosition(debtPosition, reserve.borrowingIndex);

        if (amount > debtPosition.borrowed) {
            amount = debtPosition.borrowed;
        }

        if (amount > reserve.totalBorrows) {
            amount = reserve.totalBorrows;
        }

        reserve.totalBorrows = reserve.totalBorrows.sub(amount);
        debtPosition.borrowed = debtPosition.borrowed.sub(amount);

        // only vaultPositionManager contract has credits to borrow tokens
        // when this function is called from the vaultPositionManager contracts,
        // the _msgSender() is the contract's address
        uint256 credit = credits[debtPosition.reserveId][_msgSender()];
        credits[debtPosition.reserveId][_msgSender()] = credit.add(amount);

        // Transfer the underlying tokens from the vaultPosition to the eToken contract
        IERC20(reserve.underlyingTokenAddress).safeTransferFrom(
            _msgSender(),
            reserve.eTokenAddress,
            amount
        );

        reserve.updateInterestRates();

        emit Repay(debtPosition.reserveId, onBehalfOf, _msgSender(), amount);
        return amount;
    }

    function initReserve(
        DataTypes.ReserveData storage reserveData,
        address underlyingTokenAddress,
        address eTokenAddress,
        uint256 reserveCapacity,
        uint256 id
    ) internal {
        reserveData.underlyingTokenAddress = underlyingTokenAddress;
        reserveData.eTokenAddress = eTokenAddress;
        reserveData.reserveCapacity = reserveCapacity;
        reserveData.id = id;

        reserveData.lastUpdateTimestamp = uint128(block.timestamp);
        reserveData.borrowingIndex = Precision.FACTOR1E18;

        reserveData.reserveFeeRate = 1500; // 15.00%

        // set initial borrowing rate
        // (0%, 0%) -> (80%, 20%) -> (90%, 50%) -> (100%, 150%)
        setBorrowingRateConfig(reserveData, 8000, 2000, 9000, 5000, 15000);
    }

    function createStakingPoolForReserve(uint256 reserveId) internal {
        address eTokenAddress = reserves[reserveId].eTokenAddress;
        require(eTokenAddress != address(0), "Address=0");

        reserves[reserveId].stakingAddress = StakingRewardsDeployer.deploy(
            eTokenAddress
        );

        Ownable(reserves[reserveId].stakingAddress).transferOwnership(owner());
    }

    function updateDebtPosition(
        DataTypes.DebtPositionData storage debtPosition,
        uint256 latestBorrowingIndex
    ) internal {
        debtPosition.borrowed = debtPosition
            .borrowed
            .mul(latestBorrowingIndex)
            .div(debtPosition.borrowedIndex);

        debtPosition.borrowedIndex = latestBorrowingIndex;
    }

    function setBorrowingRateConfig(
        DataTypes.ReserveData storage reserve,
        uint16 utilizationA,
        uint16 borrowingRateA,
        uint16 utilizationB,
        uint16 borrowingRateB,
        uint16 maxBorrowingRate
    ) internal {
        // (0%, 0%) -> (utilizationA, borrowingRateA) -> (utilizationB, borrowingRateB) -> (100%, maxBorrowingRate)
        reserve.borrowingRateConfig.utilizationA = uint128(
            Precision.FACTOR1E18.mul(utilizationA).div(Constants.PERCENT_100)
        );

        reserve.borrowingRateConfig.borrowingRateA = uint128(
            Precision.FACTOR1E18.mul(borrowingRateA).div(Constants.PERCENT_100)
        );
        reserve.borrowingRateConfig.utilizationB = uint128(
            Precision.FACTOR1E18.mul(utilizationB).div(Constants.PERCENT_100)
        );
        reserve.borrowingRateConfig.borrowingRateB = uint128(
            Precision.FACTOR1E18.mul(borrowingRateB).div(Constants.PERCENT_100)
        );
        reserve.borrowingRateConfig.maxBorrowingRate = uint128(
            Precision.FACTOR1E18.mul(maxBorrowingRate).div(
                Constants.PERCENT_100
            )
        );
    }

    function getReserve(
        uint256 reserveId
    ) internal view returns (DataTypes.ReserveData storage reserve) {
        reserve = reserves[reserveId];
        require(reserve.getActive(), Errors.VL_NO_ACTIVE_RESERVE);
    }

    function getTreasury() internal view returns (address treasury) {
        treasury = AddressRegistry(addressRegistry).getAddress(
            AddressId.ADDRESS_ID_TREASURY
        );
        require(treasury != address(0), Errors.VL_TREASURY_ADDRESS_NOT_SET);
    }

    function getVault(
        uint256 vaultId
    ) internal view returns (address vaultAddress) {
        address vaultFactory = AddressRegistry(addressRegistry).getAddress(
            AddressId.ADDRESS_ID_VAULT_FACTORY
        );

        vaultAddress = IVaultFactory(vaultFactory).vaults(vaultId);
        require(vaultAddress != address(0), "Invalid VaultId");
    }

    function getReserveStatus(
        uint256[] calldata reserveIdArr
    ) external view returns (ReserveStatus[] memory statusArr) {
        statusArr = new ReserveStatus[](reserveIdArr.length);

        for (uint256 i = 0; i < reserveIdArr.length; i++) {
            statusArr[i].reserveId = reserveIdArr[i];
            statusArr[i].underlyingTokenAddress = reserves[reserveIdArr[i]]
                .underlyingTokenAddress;
            statusArr[i].eTokenAddress = reserves[reserveIdArr[i]]
                .eTokenAddress;
            statusArr[i].stakingAddress = reserves[reserveIdArr[i]]
                .stakingAddress;
            (statusArr[i].totalLiquidity, statusArr[i].totalBorrows) = reserves[
                reserveIdArr[i]
            ].totalLiquidityAndBorrows();
            statusArr[i].exchangeRate = reserves[reserveIdArr[i]]
                .eTokenToReserveExchangeRate();
            statusArr[i].borrowingRate = reserves[reserveIdArr[i]]
                .borrowingRate();
        }
    }

    function getPositionStatus(
        uint256[] calldata reserveIdArr,
        address user
    ) external view returns (PositionStatus[] memory statusArr) {
        statusArr = new PositionStatus[](reserveIdArr.length);

        for (uint256 i = 0; i < reserveIdArr.length; i++) {
            statusArr[i].reserveId = reserveIdArr[i];
            statusArr[i].user = user;
            statusArr[i].eTokenStaked = IStakingRewards(
                reserves[reserveIdArr[i]].stakingAddress
            ).balanceOf(user);
            statusArr[i].eTokenUnStaked = IERC20(
                reserves[reserveIdArr[i]].eTokenAddress
            ).balanceOf(user);
            statusArr[i].liquidity = statusArr[i]
                .eTokenStaked
                .add(statusArr[i].eTokenUnStaked)
                .mul(reserves[reserveIdArr[i]].eTokenToReserveExchangeRate())
                .div(Precision.FACTOR1E18);
        }
    }

    function getCurrentDebt(
        uint256 debtId
    )
        external
        view
        returns (uint256 currentDebt, uint256 latestBorrowingIndex)
    {
        DataTypes.DebtPositionData storage debtPosition = debtPositions[debtId];
        DataTypes.ReserveData storage reserve = reserves[
            debtPosition.reserveId
        ];

        latestBorrowingIndex = reserve.latestBorrowingIndex();
        currentDebt = debtPosition.borrowed.mul(latestBorrowingIndex).div(
            debtPosition.borrowedIndex
        );
    }

    function getReserveIdOfDebt(uint256 debtId) public view returns (uint256) {
        return debtPositions[debtId].reserveId;
    }

    function getUnderlyingTokenAddress(
        uint256 reserveId
    ) public view returns (address) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return reserve.underlyingTokenAddress;
    }

    function getETokenAddress(uint256 reserveId) public view returns (address) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return reserve.eTokenAddress;
    }

    function getStakingAddress(
        uint256 reserveId
    ) public view returns (address) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return reserve.stakingAddress;
    }

    function exchangeRateOfReserve(
        uint256 reserveId
    ) public view returns (uint256) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return reserve.eTokenToReserveExchangeRate();
    }

    function utilizationRateOfReserve(
        uint256 reserveId
    ) public view returns (uint256) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return reserve.utilizationRate();
    }

    function borrowingRateOfReserve(
        uint256 reserveId
    ) public view returns (uint256) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return uint256(reserve.borrowingRate());
    }

    function totalLiquidityOfReserve(
        uint256 reserveId
    ) public view returns (uint256 totalLiquidity) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        (totalLiquidity, ) = reserve.totalLiquidityAndBorrows();
    }

    function totalBorrowsOfReserve(
        uint256 reserveId
    ) public view returns (uint256 totalBorrows) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        (, totalBorrows) = reserve.totalLiquidityAndBorrows();
    }

    //----------------->>>>>  Set with Admin <<<<<-----------------
    function emergencyPauseAll() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unPauseAll() external onlyOwner {
        paused = false;
        emit UnPaused();
    }

    function enableVaultToBorrow(uint256 vaultId) external onlyOwner notPaused {
        address vaultAddr = getVault(vaultId);

        borrowingWhiteList[vaultAddr] = true;
        emit EnableVaultToBorrow(vaultId, vaultAddr);
    }

    function disableVaultToBorrow(
        uint256 vaultId
    ) external onlyOwner notPaused {
        address vaultAddr = getVault(vaultId);

        borrowingWhiteList[vaultAddr] = false;
        emit DisableVaultToBorrow(vaultId, vaultAddr);
    }

    function setCreditsOfVault(
        uint256 vaultId,
        uint256 reserveId,
        uint256 credit
    ) external onlyOwner notPaused {
        address vaultAddr = getVault(vaultId);
        credits[reserveId][vaultAddr] = credit;
        emit SetCreditsOfVault(vaultId, vaultAddr, reserveId, credit);
    }

    function activateReserve(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setActive(true);

        emit ReserveActivated(reserveId);
    }

    function deActivateReserve(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setActive(false);
        emit ReserveDeActivated(reserveId);
    }

    function freezeReserve(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setFrozen(true);
        emit ReserveFrozen(reserveId);
    }

    function unFreezeReserve(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setFrozen(false);
        emit ReserveUnFreeze(reserveId);
    }

    function enableBorrowing(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setBorrowingEnabled(true);
        emit ReserveBorrowEnabled(reserveId);
    }

    function disableBorrowing(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setBorrowingEnabled(false);
        emit ReserveBorrowDisabled(reserveId);
    }

    function setReserveFeeRate(
        uint256 reserveId,
        uint16 _rate
    ) public onlyOwner notPaused {
        require(_rate <= Constants.PERCENT_100, "invalid percent");
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.reserveFeeRate = _rate;

        emit SetReserveFeeRate(reserveId, _rate);
    }

    function setBorrowingRateConfig(
        uint256 reserveId,
        uint16 utilizationA,
        uint16 borrowingRateA,
        uint16 utilizationB,
        uint16 borrowingRateB,
        uint16 maxBorrowingRate
    ) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        setBorrowingRateConfig(
            reserve,
            utilizationA,
            borrowingRateA,
            utilizationB,
            borrowingRateB,
            maxBorrowingRate
        );

        emit SetInterestRateConfig(
            reserveId,
            utilizationA,
            borrowingRateA,
            utilizationB,
            borrowingRateB,
            maxBorrowingRate
        );
    }

    function setReserveCapacity(
        uint256 reserveId,
        uint256 cap
    ) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];

        reserve.reserveCapacity = cap;
        emit SetReserveCapacity(reserveId, cap);
    }
}
