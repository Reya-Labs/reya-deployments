pragma solidity >=0.8.19 <0.9.0;

import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";
import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";
import {
    IOrdersGatewayProxy,
    ConditionalOrderDetails,
    EIP712Signature,
    OrderType
} from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { IOracleAdaptersProxy } from "../../../src/interfaces/IOracleAdaptersProxy.sol";

import { ReyaForkTest } from "../ReyaForkTest.sol";

contract PermissionsForkTest is ReyaForkTest {
    // ---------------------------------------------------------------------
    // d18062026 rotation wallets — names/addresses mirror reya_network.toml keys
    // (rotations/18062026/introduce.toml). This rotation applies stage 1
    // (deprecate.toml) + introduce.toml ONLY; deprecate_stage2.toml is NOT yet
    // run, so wallets it would revoke remain present and are asserted as such.
    // ---------------------------------------------------------------------

    address constant d18062026_liquidator1 = 0xcD43C319d5b0E6E0fBB37ed4F61d75B6C08138aB;
    address constant d18062026_liquidator2 = 0x3F7544AE06909389468205B15792c002738D4565;
    address constant d18062026_ae_liquidator1 = 0x0e0C1E80CC13a309602aE340B8C4DC6b4a84F25b;
    address constant d18062026_co_execution_bot1 = 0xEE98b2522a811c41f6FD370B0900e86905f8E3F4;
    address constant d18062026_co_execution_bot2 = 0x392F4eFB04AD308Ae1C55CBA44c00E2656c158a3;
    address constant d18062026_co_execution_bot3 = 0x83F1a9b75fC0422E95A90a9381295A71b71089b0;
    address constant d18062026_co_execution_bot4 = 0x7798C14b6e620367054ad058BEe54e44ab90B976;
    address constant d18062026_co_execution_bot5 = 0x9c22ea6f9e88547B6E658Bf59C4650BD708FAA51;
    address constant d18062026_co_execution_bot6 = 0xb13e082e6549f897739f1c9F9cBdCAeE0dc3BC8E;
    address constant d18062026_co_execution_bot7 = 0xFaB9A76484Fc463653c84d33B671328a65F0Ee4A;
    address constant d18062026_co_execution_bot8 = 0xB7bba1CC10181674325Dc065aF58cF9ECc8F0606;
    address constant d18062026_co_execution_bot9 = 0xd321b17D7D42a532C78A7858c6167ce3BB5afD79;
    address constant d18062026_co_execution_bot10 = 0x3CE11c890cb38844e772203Cf58771634117C9b5;
    address constant d18062026_matching_engine_publisher1 = 0x76B03658661E1b3247cB08dAa8045293122B89ce;
    address constant d18062026_setTierIdBot = 0x4E5052c9CF7FDbD13fF8C30e1Ee9F52476Da50B8;
    address constant d18062026_setReferralMappingBot = 0xdAB5cc2DC31D69fd96B6633E91E2Aede46385F27;
    address constant d18062026_storkExecutor1 = 0xb367dA961Ae48E16d9907B1365c84B3Bb9ABB175;
    address constant d18062026_storkExecutor2 = 0xda4068B909730aC1f44BE98EE142e25744ecBdcE;
    address constant d18062026_storkExecutor3 = 0x9B75b0dDca961ca98900Ff8c1fE57D08Ce0FE132;

    // ---------------------------------------------------------------------
    // Stage-2 wallets (revoked by deprecate_stage2.toml, NOT run in this step).
    // They MUST still hold their permissions in the intermediate state below.
    // ---------------------------------------------------------------------

    address constant liquidator1 = 0x7Cef71c72d97Ac8CbE4bB9aB091C3bCDB7c1CB56;
    address constant liquidator10 = 0x4d0AfCA2357F1797CF18c579171b71B427604933;
    address constant ae_liquidator1 = 0x89520d105a125CC6165c6685de262c42113Df9c0;
    address constant matching_engine_publisher1 = 0x47b3df006f9856c8a8d1B7c558e273B4C1562296;
    address constant setTierIdBot = 0x6b5E482fCE86F0C95cAe69CAC2788EA8610a84c6;
    address constant setReferralMappingBot = 0xAdA667dCCF02CC78944cE8464fa5d722f2c73594;
    // co_execution_bot2..7 are rotated only in stage 2 → still present now.
    address constant co_execution_bot2 = 0xa7a43DFe3353DFf531bc4faDDE5840B9182C2688;
    address constant co_execution_bot3 = 0x10eE819bc1E25cd2Eb3CE023724209f6f56Ef103;
    address constant co_execution_bot4 = 0xA50Aa11999f86f29badEc3fcD3aBa8AbBe153Ba2;
    address constant co_execution_bot5 = 0x496c1408B34353Cd14067DF45a643b9F6Ea1aaa4;
    address constant co_execution_bot6 = 0xbf59e78614F97fDbA523238AefDbe64E2efb28C3;
    address constant co_execution_bot7 = 0xbAF944384b46eB8609c3A5C7894028cE60c15354;
    address constant co_execution_bot8 = 0x7B6365ECDf114Ec3F3c84285990A22E6DF126403;
    address constant co_execution_bot9 = 0x9bf831e7C8e2584Ab63c860Fa2d9Dc16939E1D33;
    address constant storkExecutor18 = 0xf9E50a2584CFBD3d23468A395114461E5154fD61;
    address constant storkExecutor19 = 0xdC9f85dE54543eddD2Cc61e63D5DD8DFFb0b2cF4;
    address constant storkExecutor20 = 0xf5dD8F0D98138330F6b5927B019E5B94B3C1E919;

    // ---------------------------------------------------------------------
    // PassivePoolProxy — permissioned flags
    // ---------------------------------------------------------------------

    function test_pool_autorebalance_permissions() public view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("autoRebalance")), 1));
        address[] memory allowlist = IPassivePoolProxy(sec.pool).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](3);
        expectedAllowlist[0] = 0xf39e89D97B3EEffbF110Dea3110e1DAF74B9C0Ed;
        expectedAllowlist[1] = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9;
        expectedAllowlist[2] = 0x0C81E390758A4C7AEF67BD2b0727DC6404Ea4883;

        assertEq(allowlist, expectedAllowlist);
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagDenyAll(flagId));
    }

    // Order-independent allowlist comparison. Cannon executes independent invokes (same
    // `depends`) in a non-deterministic order, and EnumerableSet removals use swap-and-pop,
    // so the on-chain allowlist order after a rotation is not reliably predictable by hand.
    // We assert set-equality (length + membership) instead of exact ordering.
    function _assertSameMembers(address[] memory actual, address[] memory expected) internal pure {
        assertEq(actual.length, expected.length, "allowlist length mismatch");
        for (uint256 i = 0; i < expected.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < actual.length; j++) {
                if (actual[j] == expected[i]) {
                    found = true;
                    break;
                }
            }
            assertTrue(found, "expected address missing from allowlist");
        }
    }

    function test_pool_srusd_auto_exchange_permissions() public view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("stakedAssetAutoExchange")), 1));
        address[] memory allowlist = IPassivePoolProxy(sec.pool).getFeatureFlagAllowlist(flagId);

        // Intermediate state: the two external AE bots, the new rotation wallet, AND ae_liquidator1.
        // deprecate.toml (stage 1) revokes d06082025_ae_liquidator1 and introduce.toml adds
        // d18062026_ae_liquidator1. ae_liquidator1 is a current holder and is revoked only in
        // stage 2 (deprecate_stage2.toml), so it is still present here.
        address[] memory expectedAllowlist = new address[](4);
        expectedAllowlist[0] = 0xc656647754e72c2Db056712AC40dc04Ce6681a7D; // ae_liquidator2 (external)
        expectedAllowlist[1] = 0x9Afe15992448b33BDa6D5851383E643CE007cb5A; // ae_liquidator3 (external)
        expectedAllowlist[2] = d18062026_ae_liquidator1;
        expectedAllowlist[3] = ae_liquidator1; // stage 2

        _assertSameMembers(allowlist, expectedAllowlist);
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagDenyAll(flagId));
    }

    function test_pool_action_metadata_overwrite_permissions() public view {
        bytes32 flagId = keccak256(bytes("actionMetadataOverwrite"));
        address[] memory allowlist = IPassivePoolProxy(sec.pool).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](2);
        expectedAllowlist[0] = sec.core;
        expectedAllowlist[1] = sec.periphery;

        assertEq(allowlist, expectedAllowlist);
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagDenyAll(flagId));
    }

    function test_pool_whitelisted_collateral_permissions() public view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("whitelistedCollateral")), 1));
        address[] memory allowlist = IPassivePoolProxy(sec.pool).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](5);
        expectedAllowlist[0] = sec.ramber;
        expectedAllowlist[1] = sec.rhedge;
        expectedAllowlist[2] = sec.rselini;
        expectedAllowlist[3] = sec.rusd;
        expectedAllowlist[4] = sec.susde;

        assertEq(allowlist, expectedAllowlist);
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagDenyAll(flagId));
    }

    function test_pool_deposit_permissions() public view {
        // deposit:pool1 is intentionally open at this time — the `addToFeatureFlagAllowlist`
        // entries in passive_pool/configs/feature_flags.toml are prep for a future restriction
        // (unstaking). Until that flips, this test asserts the current expected state.
        // TODO: when deposits are restricted, flip allowAll expectation and enumerate allowlist.
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("deposit")), 1));
        assertTrue(IPassivePoolProxy(sec.pool).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagDenyAll(flagId));
    }

    function test_pool_withdrawal_permissions() public view {
        // withdrawal:pool1 is intentionally open at this time, same reasoning as deposit.
        // TODO: when withdrawals are restricted, flip allowAll expectation.
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("withdrawal")), 1));
        assertTrue(IPassivePoolProxy(sec.pool).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagDenyAll(flagId));
    }

    // ---------------------------------------------------------------------
    // CoreProxy — permissioned flags
    // ---------------------------------------------------------------------

    function test_core_multicall_permissions() public view {
        bytes32 flagId = keccak256(bytes("multicall"));
        address[] memory allowlist = ICoreProxy(sec.core).getFeatureFlagAllowlist(flagId);

        // Intermediate state (stage 1 + introduce). introduce.toml grants multicall ONLY to
        // d18062026_ae_liquidator1 (NOT to the new liquidators). deprecate.toml (stage 1)
        // revokes liquidator1..10 (the liquidator bot does not use multicall), d06082025_liquidator1/2
        // and d06082025_ae_liquidator1. ae_liquidator1 is revoked only in stage 2, so it remains here.
        address[] memory expectedAllowlist = new address[](4);
        expectedAllowlist[0] = 0xc656647754e72c2Db056712AC40dc04Ce6681a7D; // ae_liquidator2 (external)
        expectedAllowlist[1] = 0x9Afe15992448b33BDa6D5851383E643CE007cb5A; // ae_liquidator3 (external)
        expectedAllowlist[2] = ae_liquidator1; // stage 2
        expectedAllowlist[3] = d18062026_ae_liquidator1;

        _assertSameMembers(allowlist, expectedAllowlist);
        assertFalse(ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId));
        assertFalse(ICoreProxy(sec.core).getFeatureFlagDenyAll(flagId));
    }

    function test_core_owner_main_account_id_permissions() public view {
        bytes32 flagId = keccak256(bytes("ownerMainAccountId"));
        address[] memory allowlist = ICoreProxy(sec.core).getFeatureFlagAllowlist(flagId);

        // Note: nobody with this permission anymore, it was used for migration
        assertEq(allowlist.length, 0);
        assertFalse(ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId));
        assertFalse(ICoreProxy(sec.core).getFeatureFlagDenyAll(flagId));
    }

    function test_core_set_custom_im_multiplier_permissions() public view {
        bytes32 flagId = keccak256(bytes("setCustomImMultiplier"));
        address[] memory allowlist = ICoreProxy(sec.core).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](1);
        expectedAllowlist[0] = sec.pool;

        assertEq(allowlist, expectedAllowlist);
        assertFalse(ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId));
        assertFalse(ICoreProxy(sec.core).getFeatureFlagDenyAll(flagId));
    }

    function test_core_camelot_swap_publisher_permissions() public view {
        // camelotSwapPublisher is deprecated; the allowlist should be empty and the flag
        // must not be globally open (otherwise anyone could publish swaps).
        bytes32 flagId = keccak256(bytes("camelotSwapPublisher"));
        address[] memory allowlist = ICoreProxy(sec.core).getFeatureFlagAllowlist(flagId);

        assertEq(allowlist.length, 0);
        assertFalse(ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId));
        assertFalse(ICoreProxy(sec.core).getFeatureFlagDenyAll(flagId));
    }

    function test_core_match_order_publisher_permissions() public view {
        // matchOrderPublisher is globally open (`setFeatureFlagAllowAll(true)` in
        // core/configs/feature_flags.toml), so any caller can publish match orders.
        // The allowlist is preserved for defense-in-depth and to make a future
        // tightening (flip allowAll → false) a one-line config change.
        bytes32 flagId = keccak256(bytes("matchOrderPublisher"));
        address[] memory allowlist = ICoreProxy(sec.core).getFeatureFlagAllowlist(flagId);

        assertTrue(ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId));
        assertFalse(ICoreProxy(sec.core).getFeatureFlagDenyAll(flagId));

        // Intermediate state: the two new wallets are added by introduce.toml, and
        // liquidator1/liquidator10 are revoked only in stage 2 so they must still be present.
        address[] memory present = new address[](4);
        present[0] = d18062026_liquidator1;
        present[1] = d18062026_liquidator2;
        present[2] = liquidator1; // stage 2
        present[3] = liquidator10; // stage 2
        for (uint256 i = 0; i < present.length; i++) {
            assertTrue(_containsAddress(allowlist, present[i]));
        }

        // Every wallet removed by deprecate.toml (stage 1) must be absent:
        //   liquidator2..9, d06082025_liquidator1/2, dev wallet, camelotSwapPublisher.
        // (liquidator1, liquidator10 are stage 2 — asserted present above, not here.)
        address[] memory absent = new address[](12);
        absent[0] = 0xb7335ad22b33afF74F07cA77b0945A3A242A7956; // liquidator2
        absent[1] = 0x64b8466c45436DCd2Bd7A43c580DEFe33AAB4D6C; // liquidator3
        absent[2] = 0x0328d0806c3e64a86Fe405b1368A631A58E63977; // liquidator4
        absent[3] = 0xD86709CF8ed53FBBD6e844cf5A4CB9b0E7592b71; // liquidator5
        absent[4] = 0xb0aB30aa804595835765c50114e4831b474Bd3Ac; // liquidator6
        absent[5] = 0xd956277f454951F95244b55a47e8ed9159CAed85; // liquidator7
        absent[6] = 0x8DA6DD4675e96F706F45BB9566Be31eB050ED652; // liquidator8
        absent[7] = 0xffA24D284111E58E2142dc74e4FB08a398D97c45; // liquidator9
        absent[8] = 0x84d17e2E153FE902Ac5b5d9c877F18DF3b9C6E56; // d06082025_liquidator1
        absent[9] = 0xb776c97866FAeaBe752A2260ceCe8c19153EEbFc; // d06082025_liquidator2
        absent[10] = 0xaE173a960084903b1d278Ff9E3A81DeD82275556; // dev wallet
        absent[11] = 0xE32519ca0e751C754c8E1378846B5cd95A1CB66a; // camelotSwapPublisher
        for (uint256 i = 0; i < absent.length; i++) {
            assertFalse(_containsAddress(allowlist, absent[i]));
        }
    }

    function test_core_notify_account_transfer_permissions() public view {
        // notifyAccountTransfer is intentionally disabled on mainnet (core_disable_account_transfer):
        // allowAll is false AND no addresses are allowlisted, so nobody can invoke the feature.
        // denyAll stays false — the feature is off by being empty, not by being actively denied.
        bytes32 flagId = keccak256(bytes("notifyAccountTransfer"));
        assertFalse(ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId));
        assertFalse(ICoreProxy(sec.core).getFeatureFlagDenyAll(flagId));
        assertEq(ICoreProxy(sec.core).getFeatureFlagAllowlist(flagId).length, 0);
    }

    // ---------------------------------------------------------------------
    // PassivePerpProxy — permissioned flags
    // ---------------------------------------------------------------------

    function test_perp_configure_fees_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureFees"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        // Intermediate state: introduce.toml adds d18062026_setTierIdBot/setReferralMappingBot.
        // The old setTierIdBot/setReferralMappingBot are revoked only in stage 2 → still present.
        // The owner multisig (0x1Fe5...) holds configureFees and is never rotated → present.
        address[] memory expectedAllowlist = new address[](5);
        expectedAllowlist[0] = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9; // owner multisig
        expectedAllowlist[1] = setTierIdBot; // stage 2
        expectedAllowlist[2] = setReferralMappingBot; // stage 2
        expectedAllowlist[3] = d18062026_setTierIdBot;
        expectedAllowlist[4] = d18062026_setReferralMappingBot;

        _assertSameMembers(allowlist, expectedAllowlist);
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagDenyAll(flagId));
    }

    function test_perp_configure_spread_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureSpread"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        // Intermediate state: introduce.toml adds configureSpread for d18062026 bots 1,3,4,5,6,7
        // (mirrors configureDepth). deprecate.toml (stage 1) revokes only co_execution_bot1;
        // co_execution_bot2..7 are revoked in stage 2, so they remain present for now.
        address[] memory expectedAllowlist = new address[](12);
        expectedAllowlist[0] = co_execution_bot2; // stage 2
        expectedAllowlist[1] = co_execution_bot3; // stage 2
        expectedAllowlist[2] = co_execution_bot4; // stage 2
        expectedAllowlist[3] = co_execution_bot5; // stage 2
        expectedAllowlist[4] = co_execution_bot6; // stage 2
        expectedAllowlist[5] = co_execution_bot7; // stage 2
        expectedAllowlist[6] = d18062026_co_execution_bot1;
        expectedAllowlist[7] = d18062026_co_execution_bot3;
        expectedAllowlist[8] = d18062026_co_execution_bot4;
        expectedAllowlist[9] = d18062026_co_execution_bot5;
        expectedAllowlist[10] = d18062026_co_execution_bot6;
        expectedAllowlist[11] = d18062026_co_execution_bot7;

        _assertSameMembers(allowlist, expectedAllowlist);
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagDenyAll(flagId));
    }

    function test_perp_migration1_permissions() public view {
        // migration1 was a one-off used by 0x0c449715a20aa7Ee9a8255E9fB57317e17A8AD4a;
        // deprecate.toml (stage 1) revokes that address. Post-rotation the flag must be
        // fully closed: no allowlist entries and no global open switch.
        bytes32 flagId = keccak256(bytes("migration1"));
        assertEq(IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId).length, 0);
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagDenyAll(flagId));
    }

    function test_perp_initialize_logf_permissions() public view {
        // initializeLogF was only granted to dynamicPricingSetter1, which is removed in
        // deprecate.toml (stage 1). No replacement is introduced, so the flag must be
        // fully closed afterwards.
        bytes32 flagId = keccak256(bytes("initializeLogF"));
        assertEq(IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId).length, 0);
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagDenyAll(flagId));
    }

    function test_perp_configure_depth_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureDepth"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        // Intermediate state: introduce.toml adds configureDepth for d18062026 bots 1,3,4,5,6,7.
        // deprecate.toml (stage 1) revokes co_execution_bot1 AND dynamicPricingSetter1
        // (0x93e3...). co_execution_bot2..7 are revoked in stage 2, so they remain present.
        // The multisig (0x1Fe5...) is not rotated.
        address[] memory expectedAllowlist = new address[](13);
        expectedAllowlist[0] = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9; // multisig
        expectedAllowlist[1] = co_execution_bot2; // stage 2
        expectedAllowlist[2] = co_execution_bot3; // stage 2
        expectedAllowlist[3] = co_execution_bot4; // stage 2
        expectedAllowlist[4] = co_execution_bot5; // stage 2
        expectedAllowlist[5] = co_execution_bot6; // stage 2
        expectedAllowlist[6] = co_execution_bot7; // stage 2
        expectedAllowlist[7] = d18062026_co_execution_bot1;
        expectedAllowlist[8] = d18062026_co_execution_bot3;
        expectedAllowlist[9] = d18062026_co_execution_bot4;
        expectedAllowlist[10] = d18062026_co_execution_bot5;
        expectedAllowlist[11] = d18062026_co_execution_bot6;
        expectedAllowlist[12] = d18062026_co_execution_bot7;

        _assertSameMembers(allowlist, expectedAllowlist);
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagDenyAll(flagId));
    }

    // ---------------------------------------------------------------------
    // OrdersGatewayProxy — permissioned flags
    // ---------------------------------------------------------------------

    function test_orders_gateway_conditional_orders_permissions() public view {
        bytes32 flagId = keccak256(bytes("conditional_orders"));
        address[] memory allowlist = IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowlist(flagId);

        // Intermediate state: introduce.toml adds all 10 d18062026 bots (bot1..bot10).
        // deprecate.toml (stage 1) revokes co_execution_bot1 and d06082025_co_execution_bot_1/3/4.
        // The remaining old bots (co_execution_bot2..9, d06082025_co_execution_bot_2/_5) are
        // revoked in stage 2 → still present here.
        address[] memory expectedAllowlist = new address[](20);
        expectedAllowlist[0] = co_execution_bot2; // stage 2
        expectedAllowlist[1] = co_execution_bot3; // stage 2
        expectedAllowlist[2] = co_execution_bot4; // stage 2
        expectedAllowlist[3] = co_execution_bot5; // stage 2
        expectedAllowlist[4] = co_execution_bot6; // stage 2
        expectedAllowlist[5] = co_execution_bot7; // stage 2
        expectedAllowlist[6] = co_execution_bot8; // stage 2
        expectedAllowlist[7] = co_execution_bot9; // stage 2
        expectedAllowlist[8] = 0xd0a8780853999Ff5Cd0fe852217467d3de160EEb; // d06082025_co_execution_bot_2 (stage 2)
        expectedAllowlist[9] = 0xdDfD9f70972742bE561eFb89E9CF5BEF848729F8; // d06082025_co_execution_bot_5 (stage 2)
        expectedAllowlist[10] = d18062026_co_execution_bot1;
        expectedAllowlist[11] = d18062026_co_execution_bot2;
        expectedAllowlist[12] = d18062026_co_execution_bot3;
        expectedAllowlist[13] = d18062026_co_execution_bot4;
        expectedAllowlist[14] = d18062026_co_execution_bot5;
        expectedAllowlist[15] = d18062026_co_execution_bot6;
        expectedAllowlist[16] = d18062026_co_execution_bot7;
        expectedAllowlist[17] = d18062026_co_execution_bot8;
        expectedAllowlist[18] = d18062026_co_execution_bot9;
        expectedAllowlist[19] = d18062026_co_execution_bot10;

        _assertSameMembers(allowlist, expectedAllowlist);
        // allowAll is expected to be FALSE — conditional_orders should only be executable by the
        // allowlist above. A `true` value means anyone can drive CO execution, which is a
        // security-critical misconfiguration.
        assertFalse(IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowAll(flagId));
        assertFalse(IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagDenyAll(flagId));
    }

    function test_orders_gateway_matching_engine_publisher_permissions() public view {
        bytes32 flagId = keccak256(bytes("matching_engine_publisher"));
        address[] memory allowlist = IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowlist(flagId);

        // Intermediate state: introduce.toml adds d18062026_matching_engine_publisher1. The old
        // matching_engine_publisher1 is revoked only in stage 2, so it remains present for now.
        // FINALIZE: ordering is best-effort — confirm against the cannon test run output.
        address[] memory expectedAllowlist = new address[](2);
        expectedAllowlist[0] = matching_engine_publisher1; // stage 2
        expectedAllowlist[1] = d18062026_matching_engine_publisher1;

        assertEq(allowlist, expectedAllowlist);
        assertFalse(IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowAll(flagId));
        assertFalse(IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagDenyAll(flagId));
    }

    // ---------------------------------------------------------------------
    // OracleAdaptersProxy — permissioned flags
    // ---------------------------------------------------------------------

    function test_oracle_adapters_executors_permissions() public view {
        bytes32 flagId = keccak256(bytes("executors"));
        address[] memory allowlist = IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowlist(flagId);

        // Intermediate state. NOTE: co_execution_bot* are NOT on the `executors` allowlist on-chain
        // (they hold subSecondExecutors only), and the rotation no longer grants `executors` to the
        // new co-bots (parity with predecessors). deprecate.toml (stage 1) revokes storkExecutor1..17
        // and d06082025_storkExecutor1/2/3; storkExecutor18/19/20 remain (revoked in stage 2). The
        // OrdersGateway proxy holds executors and is never rotated. introduce.toml adds only the
        // d18062026_storkExecutor1/2/3.
        address[] memory expectedAllowlist = new address[](7);
        expectedAllowlist[0] = storkExecutor18; // stage 2
        expectedAllowlist[1] = storkExecutor19; // stage 2
        expectedAllowlist[2] = storkExecutor20; // stage 2
        expectedAllowlist[3] = sec.ordersGateway; // permanent holder, not rotated
        expectedAllowlist[4] = d18062026_storkExecutor1;
        expectedAllowlist[5] = d18062026_storkExecutor2;
        expectedAllowlist[6] = d18062026_storkExecutor3;

        _assertSameMembers(allowlist, expectedAllowlist);
        // allowAll is intentionally true for the `executors` flag: the gate is open so any caller
        // can invoke executor entrypoints. The allowlist above is preserved for defense-in-depth
        // and to make a future tightening (flip allowAll → false) a single-line config change.
        assertTrue(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowAll(flagId));
        assertFalse(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagDenyAll(flagId));
    }

    function test_oracle_adapters_subsecond_executors_permissions() public view {
        bytes32 flagId = keccak256(bytes("subSecondExecutors"));
        address[] memory allowlist = IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowlist(flagId);

        // Intermediate state: introduce.toml adds subSecondExecutors for d18062026 co bots
        // 1,3,4,5,6,7 AND d18062026_storkExecutor1/2/3. deprecate.toml (stage 1) revokes
        // storkExecutor1..17, d06082025_storkExecutor1/2/3 and co_execution_bot1. Old
        // co_execution_bot2..7 and storkExecutor18/19/20 are revoked only in stage 2 → present.
        // The OrdersGateway proxy holds subSecondExecutors and is never rotated → present.
        address[] memory expectedAllowlist = new address[](19);
        expectedAllowlist[0] = co_execution_bot2; // stage 2
        expectedAllowlist[1] = co_execution_bot3; // stage 2
        expectedAllowlist[2] = co_execution_bot4; // stage 2
        expectedAllowlist[3] = co_execution_bot5; // stage 2
        expectedAllowlist[4] = co_execution_bot6; // stage 2
        expectedAllowlist[5] = co_execution_bot7; // stage 2
        expectedAllowlist[6] = storkExecutor18; // stage 2
        expectedAllowlist[7] = storkExecutor19; // stage 2
        expectedAllowlist[8] = storkExecutor20; // stage 2
        expectedAllowlist[9] = sec.ordersGateway; // permanent holder, not rotated
        expectedAllowlist[10] = d18062026_co_execution_bot1;
        expectedAllowlist[11] = d18062026_co_execution_bot3;
        expectedAllowlist[12] = d18062026_co_execution_bot4;
        expectedAllowlist[13] = d18062026_co_execution_bot5;
        expectedAllowlist[14] = d18062026_co_execution_bot6;
        expectedAllowlist[15] = d18062026_co_execution_bot7;
        expectedAllowlist[16] = d18062026_storkExecutor1;
        expectedAllowlist[17] = d18062026_storkExecutor2;
        expectedAllowlist[18] = d18062026_storkExecutor3;

        _assertSameMembers(allowlist, expectedAllowlist);
        assertFalse(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowAll(flagId));
        assertFalse(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagDenyAll(flagId));
    }

    function test_oracle_adapters_lm_token_price_updaters_permissions() public view {
        bytes32 flagId = keccak256(bytes("lmTokenPriceUpdaters"));
        // the allowlist is only the deployment owner; content intentionally unchecked here
        // since the owner address is covered elsewhere in the ownership fuzz test.
        // what we care about is that the flag is not globally open and not paused.
        assertFalse(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowAll(flagId));
        assertFalse(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagDenyAll(flagId));
    }

    // ---------------------------------------------------------------------
    // CoreProxy — configuration/account permissions (no allowAll/denyAll concept)
    // ---------------------------------------------------------------------

    function test_perp_market_volatility_configurator_permissions() public view {
        bytes32 permission = keccak256(bytes("CP_PP_MARKET_VOLATILITY_CONFIGURATOR"));

        // check the addresses that should not have the permission
        {
            address[] memory revokelist = new address[](21);
            revokelist[0] = 0x460709Fc45340055d68f8CECa5e66c99e11BA7A5;
            revokelist[1] = 0x7B2240556Fd593D09C8F3915328629A8fA916613;
            revokelist[2] = 0x9f57C8e4A8Cd5e66A81C7DF7079ff797428a7C92;
            revokelist[3] = 0xBaAEB7483d1D746d8CF942a3A26C7Fec66139967;
            revokelist[4] = 0x029a1c99aC36680e1D2c479f61a966D8734e4fa8;
            revokelist[5] = 0xf6965516e3a326b86510Fa1dAD52aa7EBd1fCB3d;
            revokelist[6] = 0x41528555d19B8002EF5Ba51fc709dFB5c29a2996;
            revokelist[7] = 0x4AF44F22119E3e7bd00058C4eef833708b7F8bf3;
            revokelist[8] = 0xBf345d145eE74EbcF9FE91Eee9887CEf2549F891;
            revokelist[9] = 0xf9E50a2584CFBD3d23468A395114461E5154fD61;
            revokelist[10] = 0xdC9f85dE54543eddD2Cc61e63D5DD8DFFb0b2cF4;
            revokelist[11] = 0x8f6f7BaD792fFBD018B2C71Cec830F9fca8657D0;
            revokelist[12] = 0xf5dD8F0D98138330F6b5927B019E5B94B3C1E919;
            revokelist[13] = 0x58245Bf2efF760dF0E98c28B07bF33C45787ef58;
            revokelist[14] = 0xEb663bF954E99E06eC80c42F6216b5DeAB0F3C8D;
            revokelist[15] = 0x015a04108E5E55325a044c0Ddd768584680FE68f;
            revokelist[16] = 0xb16186082978C651820aAD07A7Ef0327b272878A;
            revokelist[17] = 0x27922Fb56418DF8C366718D86DD1E54E0Fde280F;
            revokelist[18] = 0xC4CCB6bCD9b465D1a3367487587c8C79E2dab443;
            revokelist[19] = 0xe4D82DAfb347C3A6973b86B75053f2513b78072D;
            revokelist[20] = 0xAEFE6157392807bf9d0f7fC239b62172A35B8c5F;

            for (uint256 i = 0; i < revokelist.length; i++) {
                assertEq(ICoreProxy(sec.core).hasConfigurationPermission(1, permission, revokelist[i]), false);
            }
        }
    }

    function test_ae_margin_account_permissions() public view {
        bytes32 permission = keccak256(bytes("ADMIN"));
        uint128 aeMarginAccountId = 109_372;

        // This rotation (stage 1 + introduce) makes NO account-permission changes: introduce.toml
        // does not grant ADMIN to d18062026_ae_liquidator1, and the existing ADMIN holder
        // d06082025_ae_liquidator1 is revoked only by deprecate_stage2.toml (not run yet). So the
        // ADMIN holder is unchanged.
        {
            address[] memory allowlist = new address[](1);
            allowlist[0] = 0x8836cf32426cb26353698B105ab89fb87f52Fc34; // d06082025_ae_liquidator1 (stage 2)

            for (uint256 i = 0; i < allowlist.length; i++) {
                assertEq(ICoreProxy(sec.core).hasAccountPermission(aeMarginAccountId, permission, allowlist[i]), true);
            }
        }

        // The new wallet does not yet hold ADMIN (no grant in introduce.toml), and the legacy
        // ae_liquidator1 never held it.
        {
            address[] memory revokelist = new address[](2);
            revokelist[0] = d18062026_ae_liquidator1; // not granted in this rotation
            revokelist[1] = ae_liquidator1;

            for (uint256 i = 0; i < revokelist.length; i++) {
                assertEq(ICoreProxy(sec.core).hasAccountPermission(aeMarginAccountId, permission, revokelist[i]), false);
            }
        }

        // autoExchange:<token> is open (allowAll=true) for every collateral except sRUSD.
        // sRUSD intentionally restricts auto-exchange to the passive pool (see srusd.toml);
        // every other collateral lets anyone trigger auto-exchange, so allowAll must be true.
        address[] memory openAutoExchangeTokens = new address[](10);
        openAutoExchangeTokens[0] = sec.weth;
        openAutoExchangeTokens[1] = sec.wbtc;
        openAutoExchangeTokens[2] = sec.usde;
        openAutoExchangeTokens[3] = sec.susde;
        openAutoExchangeTokens[4] = sec.deusd;
        openAutoExchangeTokens[5] = sec.sdeusd;
        openAutoExchangeTokens[6] = sec.wsteth;
        openAutoExchangeTokens[7] = sec.rselini;
        openAutoExchangeTokens[8] = sec.ramber;
        openAutoExchangeTokens[9] = sec.rhedge;

        for (uint256 i = 0; i < openAutoExchangeTokens.length; i++) {
            bytes32 flagId = keccak256(abi.encode(keccak256(bytes("autoExchange")), openAutoExchangeTokens[i]));
            assertTrue(ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId));
            assertFalse(ICoreProxy(sec.core).getFeatureFlagDenyAll(flagId));
        }
    }

    // ---------------------------------------------------------------------
    // Behavioural unauthorized-revert checks — defense in depth on top of
    // the static allowAll/denyAll/allowlist assertions above. Each test calls
    // a gated entrypoint from a wallet that is deliberately not in the
    // allowlist and asserts the call reverts with the expected
    // FeatureUnavailable(flag) error. If the allow-all escape hatch is ever
    // flipped on for a permissioned flag, these tests fail loudly because
    // the call proceeds past the feature-flag check and reverts with a
    // different downstream error.
    // ---------------------------------------------------------------------

    function test_orders_gateway_conditional_orders_rejects_non_allowlisted_caller() public {
        address stranger = vm.addr(uint256(keccak256(bytes("not-a-co-executor"))));

        bytes32 flagId = keccak256(bytes("conditional_orders"));
        address[] memory allowlist = IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowlist(flagId);
        for (uint256 i = 0; i < allowlist.length; i++) {
            assertTrue(allowlist[i] != stranger, "stranger unexpectedly in allowlist");
        }

        ConditionalOrderDetails memory order = ConditionalOrderDetails({
            accountId: 0,
            marketId: 0,
            exchangeId: 0,
            counterpartyAccountIds: new uint128[](0),
            orderType: uint8(OrderType.LimitOrder),
            inputs: "",
            signer: address(0),
            nonce: 0
        });
        EIP712Signature memory sig = EIP712Signature({ v: 0, r: bytes32(0), s: bytes32(0), deadline: 0 });

        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(IOrdersGatewayProxy.FeatureUnavailable.selector, flagId));
        IOrdersGatewayProxy(sec.ordersGateway).execute(order, sig);
    }

    function test_liquidator_margin_account_permissions() public view {
        bytes32 permission1 = keccak256(bytes("DUTCH_LIQUIDATION"));
        bytes32 permission2 = keccak256(bytes("MATCH_ORDER"));
        uint128 liquidatorMarginAccountId = 109_371;

        // This rotation (stage 1 + introduce) makes NO account-permission changes: introduce.toml
        // does not grant DUTCH_LIQUIDATION/MATCH_ORDER to the new d18062026 liquidators, and the
        // existing holders d06082025_liquidator1/2 are not revoked (no liquidator account-permission
        // revoke in either deprecate file). So the holders are unchanged.
        {
            address[] memory allowlist = new address[](2);
            allowlist[0] = 0x84d17e2E153FE902Ac5b5d9c877F18DF3b9C6E56; // d06082025_liquidator1
            allowlist[1] = 0xb776c97866FAeaBe752A2260ceCe8c19153EEbFc; // d06082025_liquidator2

            for (uint256 i = 0; i < allowlist.length; i++) {
                assertEq(
                    ICoreProxy(sec.core).hasAccountPermission(liquidatorMarginAccountId, permission1, allowlist[i]),
                    true
                );

                assertEq(
                    ICoreProxy(sec.core).hasAccountPermission(liquidatorMarginAccountId, permission2, allowlist[i]),
                    true
                );
            }
        }

        // The new wallets do not yet hold these permissions (no grant in introduce.toml), and the
        // legacy liquidator1..10 never held them.
        {
            address[] memory revokelist = new address[](12);
            revokelist[0] = d18062026_liquidator1; // not granted in this rotation
            revokelist[1] = d18062026_liquidator2; // not granted in this rotation
            revokelist[2] = 0x7Cef71c72d97Ac8CbE4bB9aB091C3bCDB7c1CB56; // liquidator1
            revokelist[3] = 0xb7335ad22b33afF74F07cA77b0945A3A242A7956; // liquidator2
            revokelist[4] = 0x64b8466c45436DCd2Bd7A43c580DEFe33AAB4D6C; // liquidator3
            revokelist[5] = 0x0328d0806c3e64a86Fe405b1368A631A58E63977; // liquidator4
            revokelist[6] = 0xD86709CF8ed53FBBD6e844cf5A4CB9b0E7592b71; // liquidator5
            revokelist[7] = 0xb0aB30aa804595835765c50114e4831b474Bd3Ac; // liquidator6
            revokelist[8] = 0xd956277f454951F95244b55a47e8ed9159CAed85; // liquidator7
            revokelist[9] = 0x8DA6DD4675e96F706F45BB9566Be31eB050ED652; // liquidator8
            revokelist[10] = 0xffA24D284111E58E2142dc74e4FB08a398D97c45; // liquidator9
            revokelist[11] = 0x4d0AfCA2357F1797CF18c579171b71B427604933; // liquidator10

            for (uint256 i = 0; i < revokelist.length; i++) {
                assertEq(
                    ICoreProxy(sec.core).hasAccountPermission(liquidatorMarginAccountId, permission1, revokelist[i]),
                    false
                );

                assertEq(
                    ICoreProxy(sec.core).hasAccountPermission(liquidatorMarginAccountId, permission2, revokelist[i]),
                    false
                );
            }
        }
    }

    function _containsAddress(address[] memory haystack, address needle) private pure returns (bool) {
        for (uint256 i = 0; i < haystack.length; i++) {
            if (haystack[i] == needle) return true;
        }
        return false;
    }
}
