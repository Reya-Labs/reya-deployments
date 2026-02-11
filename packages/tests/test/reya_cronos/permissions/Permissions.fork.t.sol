pragma solidity >=0.8.19 <0.9.0;

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { ReyaForkTest } from "../ReyaForkTest.sol";

contract PermissionsForkTest is ReyaForkTest {
    function test_perp_configure_spread_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureSpread"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](5);
        expectedAllowlist[0] = 0x0d171dFaab3440c0C88F3a07d8F3e9ffE56C609a;
        expectedAllowlist[1] = 0xa7a43DFe3353DFf531bc4faDDE5840B9182C2688;
        expectedAllowlist[2] = 0xf9E50a2584CFBD3d23468A395114461E5154fD61;
        expectedAllowlist[3] = 0xdC9f85dE54543eddD2Cc61e63D5DD8DFFb0b2cF4;
        expectedAllowlist[4] = 0xf5dD8F0D98138330F6b5927B019E5B94B3C1E919;

        assertEq(allowlist, expectedAllowlist);
    }

    function test_perp_configure_depth_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureDepth"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](5);
        expectedAllowlist[0] = 0x0d171dFaab3440c0C88F3a07d8F3e9ffE56C609a;
        expectedAllowlist[1] = 0xa7a43DFe3353DFf531bc4faDDE5840B9182C2688;
        expectedAllowlist[2] = 0xf9E50a2584CFBD3d23468A395114461E5154fD61;
        expectedAllowlist[3] = 0xdC9f85dE54543eddD2Cc61e63D5DD8DFFb0b2cF4;
        expectedAllowlist[4] = 0xf5dD8F0D98138330F6b5927B019E5B94B3C1E919;

        assertEq(allowlist, expectedAllowlist);
    }
}
