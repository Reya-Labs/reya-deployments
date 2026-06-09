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
    // d20052026 rotation wallets — names mirror reya_network.toml keys.
    // Addresses are placeholders (address(0)) until the rotation is funded;
    // tests that reference them will fail with a clear mismatch until then.
    // ---------------------------------------------------------------------

    address constant d20052026_liquidator1 = address(0);
    address constant d20052026_liquidator2 = address(0);
    address constant d20052026_ae_liquidator1 = address(0);
    address constant d20052026_co_execution_bot1 = address(0);
    address constant d20052026_co_execution_bot2 = address(0);
    address constant d20052026_co_execution_bot3 = address(0);
    address constant d20052026_co_execution_bot4 = address(0);
    address constant d20052026_co_execution_bot5 = address(0);
    address constant d20052026_co_execution_bot6 = address(0);
    address constant d20052026_co_execution_bot7 = address(0);
    address constant d20052026_co_execution_bot8 = address(0);
    address constant d20052026_co_execution_bot9 = address(0);
    address constant d20052026_matching_engine_publisher1 = address(0);
    address constant d20052026_setTierIdBot = address(0);
    address constant d20052026_setReferralMappingBot = address(0);
    address constant d20052026_storkExecutor1 = address(0);
    address constant d20052026_storkExecutor2 = address(0);
    address constant d20052026_storkExecutor3 = address(0);

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

    function test_pool_srusd_auto_exchange_permissions() public view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("stakedAssetAutoExchange")), 1));
        address[] memory allowlist = IPassivePoolProxy(sec.pool).getFeatureFlagAllowlist(flagId);

        // post-rotation allowlist: the two external AE bots and the new rotation wallet.
        // ae_liquidator1 (06082025/deprecate.toml) and d06082025_ae_liquidator1 (20082026
        // stage 1) have been revoked, so they must not appear here — assertEq catches both.
        address[] memory expectedAllowlist = new address[](3);
        expectedAllowlist[0] = 0xc656647754e72c2Db056712AC40dc04Ce6681a7D; // ae_liquidator2 (external)
        expectedAllowlist[1] = 0x9Afe15992448b33BDa6D5851383E643CE007cb5A; // ae_liquidator3 (external)
        expectedAllowlist[2] = d20052026_ae_liquidator1;

        assertEq(allowlist, expectedAllowlist);
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

        address[] memory expectedAllowlist = new address[](5);
        expectedAllowlist[0] = 0xc656647754e72c2Db056712AC40dc04Ce6681a7D;
        expectedAllowlist[1] = 0x9Afe15992448b33BDa6D5851383E643CE007cb5A;
        expectedAllowlist[2] = d20052026_liquidator2;
        expectedAllowlist[3] = d20052026_liquidator1;
        expectedAllowlist[4] = d20052026_ae_liquidator1;

        assertEq(allowlist, expectedAllowlist);
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

        // post-rotation: the two new wallets must be present
        address[] memory present = new address[](2);
        present[0] = d20052026_liquidator1;
        present[1] = d20052026_liquidator2;
        for (uint256 i = 0; i < present.length; i++) {
            assertTrue(_containsAddress(allowlist, present[i]));
        }

        // post-rotation: every wallet removed by deprecate.toml (stage 1) and
        // deprecate_stage2.toml must be absent. Sources:
        //   stage 1 - liquidator2..9, d06082025_liquidator1/2, dev wallet,
        //             camelotSwapPublisher
        //   stage 2 - liquidator1, liquidator10
        address[] memory absent = new address[](14);
        absent[0] = 0x7Cef71c72d97Ac8CbE4bB9aB091C3bCDB7c1CB56; // liquidator1
        absent[1] = 0xb7335ad22b33afF74F07cA77b0945A3A242A7956; // liquidator2
        absent[2] = 0x64b8466c45436DCd2Bd7A43c580DEFe33AAB4D6C; // liquidator3
        absent[3] = 0x0328d0806c3e64a86Fe405b1368A631A58E63977; // liquidator4
        absent[4] = 0xD86709CF8ed53FBBD6e844cf5A4CB9b0E7592b71; // liquidator5
        absent[5] = 0xb0aB30aa804595835765c50114e4831b474Bd3Ac; // liquidator6
        absent[6] = 0xd956277f454951F95244b55a47e8ed9159CAed85; // liquidator7
        absent[7] = 0x8DA6DD4675e96F706F45BB9566Be31eB050ED652; // liquidator8
        absent[8] = 0xffA24D284111E58E2142dc74e4FB08a398D97c45; // liquidator9
        absent[9] = 0x4d0AfCA2357F1797CF18c579171b71B427604933; // liquidator10
        absent[10] = 0x84d17e2E153FE902Ac5b5d9c877F18DF3b9C6E56; // d06082025_liquidator1
        absent[11] = 0xb776c97866FAeaBe752A2260ceCe8c19153EEbFc; // d06082025_liquidator2
        absent[12] = 0xaE173a960084903b1d278Ff9E3A81DeD82275556; // dev wallet
        absent[13] = 0xE32519ca0e751C754c8E1378846B5cd95A1CB66a; // camelotSwapPublisher
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

        address[] memory expectedAllowlist = new address[](2);
        expectedAllowlist[0] = d20052026_setTierIdBot;
        expectedAllowlist[1] = d20052026_setReferralMappingBot;

        assertEq(allowlist, expectedAllowlist);
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagDenyAll(flagId));
    }

    function test_perp_configure_spread_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureSpread"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](9);
        expectedAllowlist[0] = d20052026_co_execution_bot1;
        expectedAllowlist[1] = d20052026_co_execution_bot2;
        expectedAllowlist[2] = d20052026_co_execution_bot3;
        expectedAllowlist[3] = d20052026_co_execution_bot4;
        expectedAllowlist[4] = d20052026_co_execution_bot5;
        expectedAllowlist[5] = d20052026_co_execution_bot6;
        // staging bots
        expectedAllowlist[6] = d20052026_co_execution_bot7;
        expectedAllowlist[7] = d20052026_co_execution_bot8;

        assertEq(allowlist, expectedAllowlist);
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

        address[] memory expectedAllowlist = new address[](10);
        expectedAllowlist[0] = 0x93e3AaEe71Dc2f42AD9a5992e4A6776B3406104D;
        expectedAllowlist[1] = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9;
        expectedAllowlist[2] = d20052026_co_execution_bot1;
        expectedAllowlist[3] = d20052026_co_execution_bot2;
        expectedAllowlist[4] = d20052026_co_execution_bot3;
        expectedAllowlist[5] = d20052026_co_execution_bot4;
        expectedAllowlist[6] = d20052026_co_execution_bot5;
        expectedAllowlist[7] = d20052026_co_execution_bot6;
        // staging bots
        expectedAllowlist[8] = d20052026_co_execution_bot7;
        expectedAllowlist[9] = d20052026_co_execution_bot8;
        

        assertEq(allowlist, expectedAllowlist);
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagAllowAll(flagId));
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagDenyAll(flagId));
    }

    // ---------------------------------------------------------------------
    // OrdersGatewayProxy — permissioned flags
    // ---------------------------------------------------------------------

    function test_orders_gateway_conditional_orders_permissions() public view {
        bytes32 flagId = keccak256(bytes("conditional_orders"));
        address[] memory allowlist = IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](9);
        expectedAllowlist[0] = d20052026_co_execution_bot1;
        expectedAllowlist[1] = d20052026_co_execution_bot3;
        expectedAllowlist[2] = d20052026_co_execution_bot4;
        expectedAllowlist[3] = d20052026_co_execution_bot5;
        expectedAllowlist[4] = d20052026_co_execution_bot6;
        expectedAllowlist[5] = d20052026_co_execution_bot7;
        expectedAllowlist[6] = d20052026_co_execution_bot2;
        expectedAllowlist[7] = d20052026_co_execution_bot9;
        expectedAllowlist[8] = d20052026_co_execution_bot8;

        assertEq(allowlist, expectedAllowlist);
        // allowAll is expected to be FALSE — conditional_orders should only be executable by the
        // allowlist above. A `true` value means anyone can drive CO execution, which is a
        // security-critical misconfiguration.
        assertFalse(IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowAll(flagId));
        assertFalse(IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagDenyAll(flagId));
    }

    function test_orders_gateway_matching_engine_publisher_permissions() public view {
        bytes32 flagId = keccak256(bytes("matching_engine_publisher"));
        address[] memory allowlist = IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](1);
        expectedAllowlist[0] = d20052026_matching_engine_publisher1;

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

        address[] memory expectedAllowlist = new address[](3);
        expectedAllowlist[0] = d20052026_storkExecutor1;
        expectedAllowlist[1] = d20052026_storkExecutor2;
        expectedAllowlist[2] = d20052026_storkExecutor3;

        assertEq(allowlist, expectedAllowlist);
        // allowAll is intentionally true for the `executors` flag: the gate is open so any caller
        // can invoke executor entrypoints. The allowlist above is preserved for defense-in-depth
        // and to make a future tightening (flip allowAll → false) a single-line config change.
        assertTrue(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowAll(flagId));
        assertFalse(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagDenyAll(flagId));
    }

    function test_oracle_adapters_subsecond_executors_permissions() public view {
        bytes32 flagId = keccak256(bytes("subSecondExecutors"));
        address[] memory allowlist = IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](12);
        expectedAllowlist[0] = d20052026_co_execution_bot1;
        expectedAllowlist[1] = d20052026_co_execution_bot3;
        expectedAllowlist[2] = d20052026_co_execution_bot4;
        expectedAllowlist[3] = d20052026_co_execution_bot5;
        expectedAllowlist[4] = d20052026_co_execution_bot6;
        expectedAllowlist[5] = d20052026_co_execution_bot7;
        expectedAllowlist[6] = d20052026_co_execution_bot2;
        expectedAllowlist[7] = d20052026_co_execution_bot9;
        expectedAllowlist[8] = d20052026_co_execution_bot8;
        expectedAllowlist[9] = d20052026_storkExecutor1;
        expectedAllowlist[10] = d20052026_storkExecutor2;
        expectedAllowlist[11] = d20052026_storkExecutor3;

        assertEq(allowlist, expectedAllowlist);
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

        // check the addresses that should have the permission
        {
            address[] memory allowlist = new address[](1);
            allowlist[0] = d20052026_ae_liquidator1;

            for (uint256 i = 0; i < allowlist.length; i++) {
                assertEq(ICoreProxy(sec.core).hasAccountPermission(aeMarginAccountId, permission, allowlist[i]), true);
            }
        }

        // check the addresses that should not have the permission
        // — deprecated/rotating AE liquidators from reya_network.toml: ae_liquidator1 was
        //   the original (deprecated) and d06082025_ae_liquidator1 is being rotated to
        //   d20052026_ae_liquidator1, so neither should retain ADMIN on aeMarginAccountId1.
        {
            address[] memory revokelist = new address[](2);
            revokelist[0] = 0x89520d105a125CC6165c6685de262c42113Df9c0; // ae_liquidator1
            revokelist[1] = 0x8836cf32426cb26353698B105ab89fb87f52Fc34; // d06082025_ae_liquidator1

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

        // check the addresses that should have the permission
        {
            address[] memory allowlist = new address[](2);
            allowlist[0] = d20052026_liquidator1;
            allowlist[1] = d20052026_liquidator2;

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

        // check the addresses that should not have the permission
        // — every deprecated/rotating liquidator from reya_network.toml: the prior d06082025_*
        //   rotation wallets and all legacy liquidator1..10 (now rotated to d20052026_liquidator1/2)
        {
            address[] memory revokelist = new address[](12);
            revokelist[0] = 0x84d17e2E153FE902Ac5b5d9c877F18DF3b9C6E56; // d06082025_liquidator1
            revokelist[1] = 0xb776c97866FAeaBe752A2260ceCe8c19153EEbFc; // d06082025_liquidator2
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
