// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../external/velodrome/contracts/interfaces/IRouter.sol";

interface IVeloSwapPathManager {
    function isPermissionedPath(
        IRouter.route[] memory path
    ) external returns (bool);

    function getPath(
        address from,
        address to
    ) external view returns (IRouter.route[] memory);
}
