// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lendingpool/ExtraInterestBearingToken.sol";

library ETokenDeployer {
    function deploy(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address underlyingAsset_,
        uint256 id
    ) external returns (address) {
        address eTokenAddress = address(
            new ExtraInterestBearingToken{
                salt: keccak256(
                    abi.encode(
                        underlyingAsset_,
                        id,
                        "ExtraInterestBearingToken"
                    )
                )
            }(name_, symbol_, decimals_, underlyingAsset_)
        );

        return eTokenAddress;
    }
}
