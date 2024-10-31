pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";

import "../../contracts/address-registry/AddressRegistry.sol";
import "../../contracts/tokens/MockedMintableERC20.sol";
import "../../contracts/lendingpool/StakingRewards.sol";
import "../../contracts/lendingpool/LendingPool.sol";
import {ExtraInterestBearingToken as EToken} from "../../contracts/lendingpool/ExtraInterestBearingToken.sol";

contract LendingPoolTest is Test {
    LendingPool lendingPool;
    AddressRegistry addressRegistry;
    address treasury;
    address owner;
    address alice;
    address bob;

    event InitReserve(
        address indexed reserve,
        address indexed eTokenAddress,
        address stakingAddress,
        uint256 id
    );

    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;

    function setUp()public {

      

      alice = makeAddr("Alice");
      bob = makeAddr("Bob");
      treasury = makeAddr("Treasury");

      addressRegistry = new AddressRegistry(WETH_ADDRESS);
      addressRegistry.setAddress(AddressId.ADDRESS_ID_TREASURY, treasury);

      lendingPool = new LendingPool(
          address(addressRegistry),
          WETH_ADDRESS
      );

      owner = lendingPool.owner();
    }

    function test_initReserveByOwner() public {
      MockedMintableERC20 reserve = new MockedMintableERC20("DAI", "DAI");

      assertEq(lendingPool.nextReserveId(), 1);

      vm.expectEmit(true, false, false, false);
      // The event we expect
      emit InitReserve(
        address(reserve),
        ZERO_ADDRESS,
        ZERO_ADDRESS,
        1
      );
      lendingPool.initReserve(address(reserve));

      assertEq(lendingPool.nextReserveId(), 2);
    }

    function testFail_initReserveByAlice() public {
      MockedMintableERC20 reserve = new MockedMintableERC20("DAI", "DAI");
      vm.prank(alice);

      vm.expectRevert(bytes("Ownable: caller is not the owner !"));
      lendingPool.initReserve(address(reserve));
    }

    function test_deposit() public {
      MockedMintableERC20 reserve = new MockedMintableERC20("DAI", "DAI");

      uint256 reserveId = initReserve(address(reserve));

      vm.startPrank(alice);
      uint256 amount = 1e20;
      reserve.mint(alice, amount);
      reserve.approve(address(lendingPool), amount);
      lendingPool.deposit(
        reserveId,
        amount,
        alice,
        0
      );

      address eToken = lendingPool.getETokenAddress(reserveId);
      assertEq(reserve.balanceOf(eToken), amount);
      assertEq(EToken(eToken).totalSupply(), amount);
      assertEq(EToken(eToken).balanceOf(alice), amount - 1000);

      vm.stopPrank();
    }

    function testFail_depositTooSmall() public {
      MockedMintableERC20 reserve = new MockedMintableERC20("DAI", "DAI");

      uint256 reserveId = initReserve(address(reserve));

      vm.startPrank(alice);
      uint256 amount = 1000;
      reserve.mint(alice, amount);
      reserve.approve(address(lendingPool), amount);

      lendingPool.deposit(
        reserveId,
        amount,
        alice,
        0
      );

      vm.stopPrank();
    }

    function test_withdraw() public {
      MockedMintableERC20 reserve = new MockedMintableERC20("DAI", "DAI");

      uint256 reserveId = initReserve(address(reserve));

      reserve.mint(alice, 1e18);

      deposit(reserveId, alice, 1e18);

      address eToken = lendingPool.getETokenAddress(reserveId);

      assertEq(reserve.balanceOf(alice), 0);
      assertEq(reserve.balanceOf(eToken), 1e18);

      uint256 amount = EToken(eToken).balanceOf(alice);

      vm.startPrank(alice);
      EToken(eToken).approve(address(lendingPool), amount);

      lendingPool.redeem(
        reserveId,
        amount,
        alice,
        false
      );

      assertEq(EToken(eToken).balanceOf(alice), 0);
      assertEq(reserve.balanceOf(alice), amount);
      vm.stopPrank();
    }

    function deposit(uint256 reserveId, address user, uint256 amount) internal  {
     
      vm.startPrank(user);
      
      address reserve = lendingPool.getUnderlyingTokenAddress(reserveId);
      
      MockedMintableERC20(reserve).approve(address(lendingPool), amount);

      lendingPool.deposit(
        reserveId,
        amount,
        user,
        0
      );

      vm.stopPrank(); 
    }

    function initReserve(address reserve) internal returns (uint256 reserveId){
      vm.startPrank(owner);

      lendingPool.initReserve(address(reserve));

      reserveId = lendingPool.nextReserveId() - 1;
      vm.stopPrank();
    }
}