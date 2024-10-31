// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import "../../contracts/address-registry/AddressRegistry.sol";

contract AddressRegistryTest is Test {
  address constant WETH = 0x4200000000000000000000000000000000000006;
  address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;


  AddressRegistry addressReg;


  function setUp() public {
    addressReg = new AddressRegistry(WETH);
  }

  function test_setAddressByOwner() public {
    uint256 id = 1111;
    address targetAddress = 0x1010101010101010100101010101010100010101;

    assertEq(addressReg.getAddress(id), ZERO_ADDRESS);
    addressReg.setAddress(id, targetAddress);
    assertEq(addressReg.getAddress(id), targetAddress);
  }

  function testFail_setAddressByNoOwner() public {
    uint256 id = 1111;
    address notOwner = makeAddr("notOwner");
    address targetAddress = 0x1010101010101010100101010101010100010101;
    
    vm.startPrank(notOwner);
    assertEq(addressReg.getAddress(id), ZERO_ADDRESS);

    vm.expectRevert(bytes("Ownable: caller is not the owner !"));
    addressReg.setAddress(id, targetAddress);
    vm.stopPrank();
  }

  function test_getAddress() public view {
    uint256 WETH_ID = 1;

    assertEq(addressReg.getAddress(WETH_ID), WETH);
  }

}