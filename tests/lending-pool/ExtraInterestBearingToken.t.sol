pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";

import "../../contracts/tokens/MockedMintableERC20.sol";
import "../../contracts/lendingpool/ExtraInterestBearingToken.sol";


contract ExtraInterestBearingTokenTest is Test {
  ExtraInterestBearingToken eToken;
  MockedMintableERC20 udnerlyingToken;

  address lendingPool;

  function setUp() public {
    lendingPool = makeAddr("LENDING_POOL");
    vm.startPrank(lendingPool);

    udnerlyingToken = new MockedMintableERC20("MOCKED_DAI", "DAI");

    eToken = new ExtraInterestBearingToken("EXTRA_MOCKED_DAI","eDAI", 18, address(udnerlyingToken));


    vm.stopPrank();
  }

  function test_mintByLendingPool() public {
      vm.startPrank(lendingPool);
      
      address alice = makeAddr("ALICE");
      uint256 amount = 1000000000000000000;

      assertEq(eToken.balanceOf(alice), 0);

      eToken.mint(
        alice,
        amount
      );

      assertEq(eToken.balanceOf(alice), amount);

      vm.stopPrank();
  }

  function testFail_mintByOthers() public {
      address alice = makeAddr("ALICE");

      vm.startPrank(alice);
      
      uint256 amount = 1000000000000000000;
      eToken.mint(
        alice,
        amount
      );

      vm.stopPrank();
  }


  function test_BurnByLendingPool() public {
      vm.startPrank(lendingPool);
      
      address alice = makeAddr("ALICE");
      uint256 amount = 1000000000000000000;

      udnerlyingToken.mint(address(eToken), amount);
      assertEq(udnerlyingToken.balanceOf(address(eToken)), amount);

      assertEq(eToken.balanceOf(alice), 0);

      eToken.mint(
        address(lendingPool),
        amount
      );

      eToken.burn(
        alice,
        amount,
        amount
      );

      assertEq(udnerlyingToken.balanceOf(alice), amount);

      vm.stopPrank();
  }

    function testFail_BurnByOthers() public {
      uint256 amount = 1000000000000000000;

      vm.prank( address(lendingPool));
      eToken.mint(
        address(lendingPool),
        amount
      );

      address alice = makeAddr("ALICE");

      vm.startPrank(alice);
      

      udnerlyingToken.mint(address(eToken), amount);
      assertEq(udnerlyingToken.balanceOf(address(eToken)), amount);

      
      eToken.burn(
        alice,
        amount,
        amount
      );

      assertEq(udnerlyingToken.balanceOf(alice), amount);

      vm.stopPrank();
  }



}