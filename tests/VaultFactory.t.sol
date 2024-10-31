// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../contracts/VaultFactory.sol";

// The newVault logic in VaultFactory relies on the contracts of Velodrome and the Lending Pool, 
// so testing these features requires forking the OP mainnet.
contract VaultFacotryTest is Test {
    uint256 optimismFork;
    string OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL");
    address ADDRESS_PROVIDER_ON_CHAIN = 0x85603119C938750Dfb5904f8a501b64F3F3A01D2;
    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    event NewVault(
        address indexed token0,
        address indexed token1,
        bool stable,
        address vaultAddress,
        uint256 indexed vaultId
    );

    VaultFactory vaultFactory;
    
    function setUp() public {
        optimismFork = vm.createSelectFork(OPTIMISM_RPC_URL);

        vaultFactory = new VaultFactory(ADDRESS_PROVIDER_ON_CHAIN);
    }

    function test_getVault() public view {
        assertEq(vaultFactory.nextVaultID(), 1);
        assertEq(vaultFactory.vaults(1), ZERO_ADDRESS);
    }

    function test_newVault() public {

      vm.expectEmit(true, true, false, false);
      // The event we expect
      emit NewVault(
        0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85,
        0x9560e827aF36c94D2Ac33a39bCE1Fe78631088Db,
        false,
        ZERO_ADDRESS,
        1
      );

      bytes memory newVaultParams = buildNewVaultParams();
      vaultFactory.newVault(newVaultParams);

      assertEq(vaultFactory.nextVaultID(), 2);
      
      address vaultAddr = vaultFactory.vaults(1);
      assert(vaultAddr != ZERO_ADDRESS);
      console2.log(vaultAddr);
    }

    function testFail_newVaultByNoOwner() public {
        address notOwner = makeAddr("notOwner");        
        vm.startPrank(notOwner);

        bytes memory newVaultParams = buildNewVaultParams();

        vm.expectRevert(bytes("Ownable: caller is not the owner !"));
        vaultFactory.newVault(newVaultParams);
    }


    struct InitializeParam {
      address tokenA;
      address tokenB;
      bool stable;
      address gauge;
      uint256 lendingReserveIdA;
      uint256 lendingReserveIdB;
      address[] rewardTokens;
    }

    function buildNewVaultParams() internal pure returns(bytes memory) {
      InitializeParam memory initParam;

      // vAmm-USDC/VELO
      initParam.tokenA = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
      initParam.tokenB = 0x9560e827aF36c94D2Ac33a39bCE1Fe78631088Db;
      initParam.stable = false;
      initParam.gauge = 0xFf6b058484517BF58450DfC4a6eb53F1A2171775;
      initParam.lendingReserveIdA = 70;
      initParam.lendingReserveIdB = 35;
      initParam.rewardTokens = new address[](1);
      initParam.rewardTokens[0] = 0x9560e827aF36c94D2Ac33a39bCE1Fe78631088Db;

      bytes memory initialParam = abi.encode(
        initParam
      );

      uint16 vaultVersion = 1;

      bytes memory newVaultParams = abi.encode(vaultVersion, initialParam);

      return newVaultParams;
    }
}