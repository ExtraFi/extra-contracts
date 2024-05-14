// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../external/openzeppelin/contracts/utils/math/SafeMath.sol";
import "../external/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../external/openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../external/openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IExtraInterestBearingToken.sol";
import "../interfaces/ILendingPool.sol";
import "../libraries/helpers/Errors.sol";

/**
 * @title ExtraInterestBearingToken(EToken)
 * @dev Implementation of the interest bearing token(eToken) for the extraFi Lending Pool
 * @author extraFi Team
 */
contract ExtraInterestBearingToken is
    IExtraInterestBearingToken,
    ReentrancyGuard,
    ERC20
{
    using SafeERC20 for IERC20;

    address public immutable lendingPool;
    address public immutable underlyingAsset;

    uint8 private _decimals;

    modifier onlyLendingPool() {
        require(
            msg.sender == lendingPool,
            Errors.LP_CALLER_MUST_BE_LENDING_POOL
        );
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address underlyingAsset_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;

        require(underlyingAsset_ != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        underlyingAsset = underlyingAsset_;
        lendingPool = msg.sender;
    }

    /**
     * @dev Mints `amount` eTokens to `user`, only the LendingPool Contract can call this function.
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     */
    function mint(
        address user,
        uint256 amount
    ) external onlyLendingPool nonReentrant {
        _mint(user, amount);
        emit Mint(user, amount);
    }

    /**
     * @dev Burns eTokens from `user` and sends the underlying tokens to `receiverOfUnderlying`
     * Can only be called by the lending pool;
     * The `underlyingTokenAmount` should be calculated based on the current exchange rate in lending pool
     * @param receiverOfUnderlying The address that will receive the underlying tokens
     * @param eTokenAmount The amount of eTokens being burned
     * @param underlyingTokenAmount The amount of underlying tokens being transferred to user
     **/
    function burn(
        address receiverOfUnderlying,
        uint256 eTokenAmount,
        uint256 underlyingTokenAmount
    ) external onlyLendingPool nonReentrant {
        _burn(msg.sender, eTokenAmount);

        IERC20(underlyingAsset).safeTransfer(
            receiverOfUnderlying,
            underlyingTokenAmount
        );

        emit Burn(
            msg.sender,
            receiverOfUnderlying,
            eTokenAmount,
            underlyingTokenAmount
        );
    }

    /**
     * @dev Mints eTokens to the reserve's fee receiver
     * @param treasury The address of treasury
     * @param amount The amount of tokens getting minted
     */
    function mintToTreasury(
        address treasury,
        uint256 amount
    ) external onlyLendingPool nonReentrant {
        require(treasury != address(0), "zero address");
        _mint(treasury, amount);
        emit MintToTreasury(treasury, amount);
    }

    /**
     * @dev Transfers the underlying tokens to `target`. Called by the LendingPool to transfer
     * underlying tokens to target in functions like borrow(), withdraw()
     * @param target The recipient of the eTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(
        address target,
        uint256 amount
    ) external onlyLendingPool nonReentrant returns (uint256) {
        IERC20(underlyingAsset).safeTransfer(target, amount);
        return amount;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
