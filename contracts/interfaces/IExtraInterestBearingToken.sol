// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IExtraInterestBearingToken is IERC20 {
    /**
     * @dev Emitted after the mint action
     * @param to The address receive tokens
     * @param value The amount being
     **/
    event Mint(address indexed to, uint256 value);

    /**
     * @dev Mints `amount` eTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     */
    function mint(address user, uint256 amount) external;

    /**
     * @dev Emitted after eTokens are burned
     * @param from The owner of the eTokens, getting them burned
     * @param target The address that will receive the underlying tokens
     * @param eTokenAmount The amount being burned
     * @param underlyingTokenAmount The amount of underlying tokens being transferred to user
     **/
    event Burn(
        address indexed from,
        address indexed target,
        uint256 eTokenAmount,
        uint256 underlyingTokenAmount
    );

    /**
     * @dev Burns eTokens from `user` and sends the underlying tokens to `receiverOfUnderlying`
     * Can only be called by the lending pool;
     * The `underlyingTokenAmount` should be calculated based on the current exchange rate in lending pool
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param eTokenAmount The amount of eTokens being burned
     * @param underlyingTokenAmount The amount of underlying tokens being transferred to user
     **/
    function burn(
        address receiverOfUnderlying,
        uint256 eTokenAmount,
        uint256 underlyingTokenAmount
    ) external;

    /**
     * @dev Emitted after the minted to treasury
     * @param treasury The treasury address
     * @param value The amount being minted
     **/
    event MintToTreasury(address indexed treasury, uint256 value);

    /**
     * @dev Mints eTokens to the treasury of the reserve
     * @param treasury The address of treasury
     * @param amount The amount of ftokens getting minted
     */
    function mintToTreasury(address treasury, uint256 amount) external;

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
    ) external returns (uint256);
}
