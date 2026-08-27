pragma solidity >=0.8.19 <0.9.0;

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { ReyaForkTest } from "../ReyaForkTest.sol";

contract PermissionsForkTest is ReyaForkTest {
    /// perpOB cutover prerequisite, same grant and same reasoning as mainnet's
    /// test_perp_configure_risk_block_permissions -- the shared
    /// passive_perp/configs/feature_flags.toml is included here too, via
    /// passive_perp/testnet.toml. Cronos's deployed router still authorizes
    /// setRiskBlockId with per-collateral-pool RBAC and never reads this flag,
    /// so the grant is inert until cronos moves to the 1.1.x router; this test
    /// is the only thing that says it landed at all.
    function test_perp_configure_risk_block_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureRiskBlock"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](1);
        expectedAllowlist[0] = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;

        assertEq(allowlist, expectedAllowlist);
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagAllowAll(flagId));
    }

    function test_perp_configure_spread_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureSpread"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](7);
        expectedAllowlist[0] = 0x0d171dFaab3440c0C88F3a07d8F3e9ffE56C609a;
        expectedAllowlist[1] = 0xa7a43DFe3353DFf531bc4faDDE5840B9182C2688;
        expectedAllowlist[2] = 0xf9E50a2584CFBD3d23468A395114461E5154fD61;
        expectedAllowlist[3] = 0xdC9f85dE54543eddD2Cc61e63D5DD8DFFb0b2cF4;
        expectedAllowlist[4] = 0xf5dD8F0D98138330F6b5927B019E5B94B3C1E919;
        expectedAllowlist[5] = address(0);
        expectedAllowlist[6] = 0x744b23B8E86Af45b686E9BBf7cF463e6ED79a984;

        assertEq(allowlist, expectedAllowlist);
    }

    function test_perp_configure_depth_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureDepth"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](9);
        expectedAllowlist[0] = 0x0d171dFaab3440c0C88F3a07d8F3e9ffE56C609a;
        expectedAllowlist[1] = 0xa7a43DFe3353DFf531bc4faDDE5840B9182C2688;
        expectedAllowlist[2] = 0xf9E50a2584CFBD3d23468A395114461E5154fD61;
        expectedAllowlist[3] = 0xdC9f85dE54543eddD2Cc61e63D5DD8DFFb0b2cF4;
        expectedAllowlist[4] = 0xf5dD8F0D98138330F6b5927B019E5B94B3C1E919;
        expectedAllowlist[5] = address(0);
        expectedAllowlist[6] = 0x93e3AaEe71Dc2f42AD9a5992e4A6776B3406104D;
        expectedAllowlist[7] = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;
        expectedAllowlist[8] = 0x744b23B8E86Af45b686E9BBf7cF463e6ED79a984;

        assertEq(allowlist, expectedAllowlist);
    }
}
