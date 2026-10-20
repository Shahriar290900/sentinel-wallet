// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../SentinelVault.sol";

contract SentinelVaultTest is Test {
    SentinelVault v;
    address owner = address(this);
    address agent = address(0xA11CE);
    address payable friend = payable(address(0xF00D));
    address payable stranger = payable(address(0xBAD));

    function setUp() public {
        v = new SentinelVault(agent, 1 ether, 3 ether);
        vm.deal(address(v), 10 ether);
        v.setAllowed(friend, true);
    }

    function test_AgentSpendsWithinCaps() public {
        vm.prank(agent); v.execute(friend, 0.5 ether);
        assertEq(friend.balance, 0.5 ether);
        assertEq(v.spentInWindow(), 0.5 ether);
    }
    function test_RevertWhen_OverPerTxCap() public {
        vm.prank(agent); vm.expectRevert(SentinelVault.OverPerTxCap.selector);
        v.execute(friend, 2 ether);
    }
    function test_RevertWhen_NotAllowlisted() public {
        vm.prank(agent); vm.expectRevert(SentinelVault.NotAllowlisted.selector);
        v.execute(stranger, 0.1 ether);
    }
    function test_RevertWhen_OverDailyCap() public {
        vm.startPrank(agent);
        v.execute(friend, 1 ether); v.execute(friend, 1 ether); v.execute(friend, 1 ether);
        vm.expectRevert(SentinelVault.OverDailyCap.selector);
        v.execute(friend, 0.1 ether);
        vm.stopPrank();
    }
    function test_DailyWindowRollsOver() public {
        vm.startPrank(agent);
        v.execute(friend, 1 ether); v.execute(friend, 1 ether); v.execute(friend, 1 ether);
        vm.warp(block.timestamp + 1 days);
        v.execute(friend, 1 ether);
        vm.stopPrank();
        assertEq(v.spentInWindow(), 1 ether);
    }
    function test_RevertWhen_Paused() public {
        v.setPaused(true);
        vm.prank(agent); vm.expectRevert(SentinelVault.IsPaused.selector);
        v.execute(friend, 0.1 ether);
    }
    function test_RevertWhen_StrangerCallsExecute() public {
        vm.prank(stranger); vm.expectRevert(SentinelVault.NotAgent.selector);
        v.execute(friend, 0.1 ether);
    }
    function test_RevertWhen_AgentChangesPolicy() public {
        vm.startPrank(agent);
        vm.expectRevert(SentinelVault.NotOwner.selector); v.setCaps(100 ether, 100 ether);
        vm.expectRevert(SentinelVault.NotOwner.selector); v.setAllowed(stranger, true);
        vm.expectRevert(SentinelVault.NotOwner.selector); v.setAgent(stranger);
        vm.expectRevert(SentinelVault.NotOwner.selector); v.setPaused(false);
        vm.stopPrank();
    }
    function test_RevertWhen_AgentUsesOwnerPath() public {
        vm.prank(agent); vm.expectRevert(SentinelVault.NotOwner.selector);
        v.executeWithOwner(stranger, 2 ether);
    }
    function test_OwnerApprovesElevatedAction() public {
        v.executeWithOwner(stranger, 2 ether);
        assertEq(stranger.balance, 2 ether);
    }
    function testFuzz_AgentNeverExceedsPerTxCap(uint256 amt) public {
        vm.assume(amt > 1 ether);
        vm.prank(agent); vm.expectRevert(SentinelVault.OverPerTxCap.selector);
        v.execute(friend, amt);
    }
}
