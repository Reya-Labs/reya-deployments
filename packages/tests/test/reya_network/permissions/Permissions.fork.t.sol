pragma solidity >=0.8.19 <0.9.0;

import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";
import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";
import { IOrdersGatewayProxy } from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { IOracleAdaptersProxy } from "../../../src/interfaces/IOracleAdaptersProxy.sol";

import { ReyaForkTest } from "../ReyaForkTest.sol";

contract PermissionsForkTest is ReyaForkTest {
    function test_pool_autorebalance_permissions() public view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("autoRebalance")), 1));
        address[] memory allowlist = IPassivePoolProxy(sec.pool).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](2);
        expectedAllowlist[0] = 0xf39e89D97B3EEffbF110Dea3110e1DAF74B9C0Ed;
        expectedAllowlist[1] = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9;

        assertEq(allowlist, expectedAllowlist);
    }

    function test_pool_srusd_auto_exchange_permissions() public view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("stakedAssetAutoExchange")), 1));
        address[] memory allowlist = IPassivePoolProxy(sec.pool).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](4);
        expectedAllowlist[0] = 0x89520d105a125CC6165c6685de262c42113Df9c0;
        expectedAllowlist[1] = 0xc656647754e72c2Db056712AC40dc04Ce6681a7D;
        expectedAllowlist[2] = 0x9Afe15992448b33BDa6D5851383E643CE007cb5A;
        expectedAllowlist[3] = 0x8836cf32426cb26353698B105ab89fb87f52Fc34;

        assertEq(allowlist, expectedAllowlist);
    }

    function test_core_multicall_permissions() public view {
        bytes32 flagId = keccak256(bytes("multicall"));
        address[] memory allowlist = ICoreProxy(sec.core).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](16);
        expectedAllowlist[0] = 0x4d0AfCA2357F1797CF18c579171b71B427604933;
        expectedAllowlist[1] = 0x7Cef71c72d97Ac8CbE4bB9aB091C3bCDB7c1CB56;
        expectedAllowlist[2] = 0xb7335ad22b33afF74F07cA77b0945A3A242A7956;
        expectedAllowlist[3] = 0x64b8466c45436DCd2Bd7A43c580DEFe33AAB4D6C;
        expectedAllowlist[4] = 0x0328d0806c3e64a86Fe405b1368A631A58E63977;
        expectedAllowlist[5] = 0xD86709CF8ed53FBBD6e844cf5A4CB9b0E7592b71;
        expectedAllowlist[6] = 0xb0aB30aa804595835765c50114e4831b474Bd3Ac;
        expectedAllowlist[7] = 0xd956277f454951F95244b55a47e8ed9159CAed85;
        expectedAllowlist[8] = 0x8DA6DD4675e96F706F45BB9566Be31eB050ED652;
        expectedAllowlist[9] = 0xffA24D284111E58E2142dc74e4FB08a398D97c45;
        expectedAllowlist[10] = 0x89520d105a125CC6165c6685de262c42113Df9c0;
        expectedAllowlist[11] = 0xc656647754e72c2Db056712AC40dc04Ce6681a7D;
        expectedAllowlist[12] = 0x9Afe15992448b33BDa6D5851383E643CE007cb5A;
        expectedAllowlist[13] = 0xb776c97866FAeaBe752A2260ceCe8c19153EEbFc;
        expectedAllowlist[14] = 0x84d17e2E153FE902Ac5b5d9c877F18DF3b9C6E56;
        expectedAllowlist[15] = 0x8836cf32426cb26353698B105ab89fb87f52Fc34;

        assertEq(allowlist, expectedAllowlist);
    }

    function test_core_owner_main_account_id_permissions() public view {
        bytes32 flagId = keccak256(bytes("ownerMainAccountId"));
        address[] memory allowlist = ICoreProxy(sec.core).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](1);
        expectedAllowlist[0] = 0x3964296c2d089160B2833407CBF638a48CEDAcc7;
        assertEq(allowlist, expectedAllowlist);
    }

    function test_perp_configure_fees_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureFees"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](7);
        expectedAllowlist[0] = 0x2598D555b4e92d493416676f36a09d29A19835B9;
        expectedAllowlist[1] = 0x6b5E482fCE86F0C95cAe69CAC2788EA8610a84c6;
        expectedAllowlist[2] = 0xAdA667dCCF02CC78944cE8464fa5d722f2c73594;
        expectedAllowlist[3] = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9;
        expectedAllowlist[4] = 0x23ADf7BA3f9d2a8D9F4b34b65aFC4aDb0fC85c46;
        expectedAllowlist[5] = 0x3964296c2d089160B2833407CBF638a48CEDAcc7;
        expectedAllowlist[6] = 0xc99a112E3dA3AACbaEA357fec8fc64802B4804Af;

        assertEq(allowlist, expectedAllowlist);
    }

    function test_orders_gateway_conditional_orders_permissions() public view {
        bytes32 flagId = keccak256(bytes("conditional_orders"));
        address[] memory allowlist = IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](12);
        expectedAllowlist[0] = 0x0d171dFaab3440c0C88F3a07d8F3e9ffE56C609a;
        expectedAllowlist[1] = 0xa7a43DFe3353DFf531bc4faDDE5840B9182C2688;
        expectedAllowlist[2] = 0x10eE819bc1E25cd2Eb3CE023724209f6f56Ef103;
        expectedAllowlist[3] = 0xA50Aa11999f86f29badEc3fcD3aBa8AbBe153Ba2;
        expectedAllowlist[4] = 0x496c1408B34353Cd14067DF45a643b9F6Ea1aaa4;
        expectedAllowlist[5] = 0xbf59e78614F97fDbA523238AefDbe64E2efb28C3;
        expectedAllowlist[6] = 0xbAF944384b46eB8609c3A5C7894028cE60c15354;
        expectedAllowlist[7] = 0xd933f2FcA9Be1A8Fb0Db05cb63570c62930e8d61;
        expectedAllowlist[8] = 0xd0a8780853999Ff5Cd0fe852217467d3de160EEb;
        expectedAllowlist[9] = 0xb5Cd25E984Daa87a7DcdfaA7fd4c4e97AE0A95B8;
        expectedAllowlist[10] = 0xa4d537B5C310CEF9514e7255Fca1268A2B80d67D;
        expectedAllowlist[11] = 0xdDfD9f70972742bE561eFb89E9CF5BEF848729F8;

        assertEq(allowlist, expectedAllowlist);
    }

    function test_oracle_adapters_executors_permissions() public view {
        bytes32 flagId = keccak256(bytes("executors"));
        address[] memory allowlist = IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](24);
        expectedAllowlist[0] = 0x460709Fc45340055d68f8CECa5e66c99e11BA7A5;
        expectedAllowlist[1] = 0x7B2240556Fd593D09C8F3915328629A8fA916613;
        expectedAllowlist[2] = 0x9f57C8e4A8Cd5e66A81C7DF7079ff797428a7C92;
        expectedAllowlist[3] = 0xBaAEB7483d1D746d8CF942a3A26C7Fec66139967;
        expectedAllowlist[4] = 0x029a1c99aC36680e1D2c479f61a966D8734e4fa8;
        expectedAllowlist[5] = 0xf6965516e3a326b86510Fa1dAD52aa7EBd1fCB3d;
        expectedAllowlist[6] = 0x41528555d19B8002EF5Ba51fc709dFB5c29a2996;
        expectedAllowlist[7] = 0x4AF44F22119E3e7bd00058C4eef833708b7F8bf3;
        expectedAllowlist[8] = 0xBf345d145eE74EbcF9FE91Eee9887CEf2549F891;
        expectedAllowlist[9] = 0xf9E50a2584CFBD3d23468A395114461E5154fD61;
        expectedAllowlist[10] = 0xdC9f85dE54543eddD2Cc61e63D5DD8DFFb0b2cF4;
        expectedAllowlist[11] = 0x8f6f7BaD792fFBD018B2C71Cec830F9fca8657D0;
        expectedAllowlist[12] = 0xf5dD8F0D98138330F6b5927B019E5B94B3C1E919;
        expectedAllowlist[13] = 0x58245Bf2efF760dF0E98c28B07bF33C45787ef58;
        expectedAllowlist[14] = 0xEb663bF954E99E06eC80c42F6216b5DeAB0F3C8D;
        expectedAllowlist[15] = 0x015a04108E5E55325a044c0Ddd768584680FE68f;
        expectedAllowlist[16] = 0xb16186082978C651820aAD07A7Ef0327b272878A;
        expectedAllowlist[17] = 0x27922Fb56418DF8C366718D86DD1E54E0Fde280F;
        expectedAllowlist[18] = 0xC4CCB6bCD9b465D1a3367487587c8C79E2dab443;
        expectedAllowlist[19] = 0xe4D82DAfb347C3A6973b86B75053f2513b78072D;
        expectedAllowlist[20] = 0x942C8b975877D3201BAa385497a1037DAD3f336f;
        expectedAllowlist[21] = 0xe5476044f3F2a601748816f7177A72bf1aa3f2E1;
        expectedAllowlist[22] = 0x53ca123CbE4e7a4dD093302E0EfDab2a28b55a4f;
        expectedAllowlist[23] = 0xfc8c96bE87Da63CeCddBf54abFA7B13ee8044739;

        assertEq(allowlist, expectedAllowlist);
    }

    function test_oracle_adapters_subsecond_executors_permissions() public view {
        bytes32 flagId = keccak256(bytes("subSecondExecutors"));
        address[] memory allowlist = IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](31);
        expectedAllowlist[0] = 0x460709Fc45340055d68f8CECa5e66c99e11BA7A5;
        expectedAllowlist[1] = 0x7B2240556Fd593D09C8F3915328629A8fA916613;
        expectedAllowlist[2] = 0x9f57C8e4A8Cd5e66A81C7DF7079ff797428a7C92;
        expectedAllowlist[3] = 0xBaAEB7483d1D746d8CF942a3A26C7Fec66139967;
        expectedAllowlist[4] = 0x029a1c99aC36680e1D2c479f61a966D8734e4fa8;
        expectedAllowlist[5] = 0xf6965516e3a326b86510Fa1dAD52aa7EBd1fCB3d;
        expectedAllowlist[6] = 0x41528555d19B8002EF5Ba51fc709dFB5c29a2996;
        expectedAllowlist[7] = 0x4AF44F22119E3e7bd00058C4eef833708b7F8bf3;
        expectedAllowlist[8] = 0xBf345d145eE74EbcF9FE91Eee9887CEf2549F891;
        expectedAllowlist[9] = 0xf9E50a2584CFBD3d23468A395114461E5154fD61;
        expectedAllowlist[10] = 0xdC9f85dE54543eddD2Cc61e63D5DD8DFFb0b2cF4;
        expectedAllowlist[11] = 0x8f6f7BaD792fFBD018B2C71Cec830F9fca8657D0;
        expectedAllowlist[12] = 0xf5dD8F0D98138330F6b5927B019E5B94B3C1E919;
        expectedAllowlist[13] = 0x58245Bf2efF760dF0E98c28B07bF33C45787ef58;
        expectedAllowlist[14] = 0xEb663bF954E99E06eC80c42F6216b5DeAB0F3C8D;
        expectedAllowlist[15] = 0x015a04108E5E55325a044c0Ddd768584680FE68f;
        expectedAllowlist[16] = 0xb16186082978C651820aAD07A7Ef0327b272878A;
        expectedAllowlist[17] = 0x27922Fb56418DF8C366718D86DD1E54E0Fde280F;
        expectedAllowlist[18] = 0xC4CCB6bCD9b465D1a3367487587c8C79E2dab443;
        expectedAllowlist[19] = 0xe4D82DAfb347C3A6973b86B75053f2513b78072D;
        expectedAllowlist[20] = 0x942C8b975877D3201BAa385497a1037DAD3f336f;
        expectedAllowlist[21] = 0xe5476044f3F2a601748816f7177A72bf1aa3f2E1;
        expectedAllowlist[22] = 0x53ca123CbE4e7a4dD093302E0EfDab2a28b55a4f;
        expectedAllowlist[23] = 0x0d171dFaab3440c0C88F3a07d8F3e9ffE56C609a;
        expectedAllowlist[24] = 0xa7a43DFe3353DFf531bc4faDDE5840B9182C2688;
        expectedAllowlist[25] = 0x10eE819bc1E25cd2Eb3CE023724209f6f56Ef103;
        expectedAllowlist[26] = 0xA50Aa11999f86f29badEc3fcD3aBa8AbBe153Ba2;
        expectedAllowlist[27] = 0x496c1408B34353Cd14067DF45a643b9F6Ea1aaa4;
        expectedAllowlist[28] = 0xbf59e78614F97fDbA523238AefDbe64E2efb28C3;
        expectedAllowlist[29] = 0xbAF944384b46eB8609c3A5C7894028cE60c15354;
        expectedAllowlist[30] = 0xfc8c96bE87Da63CeCddBf54abFA7B13ee8044739;

        assertEq(allowlist, expectedAllowlist);
    }

    function test_perp_market_volatility_configurator_permissions() public view {
        bytes32 permission = keccak256(bytes("CP_PP_MARKET_VOLATILITY_CONFIGURATOR"));

        // check the addresses that should have the permission
        {
            address[] memory allowlist = new address[](21);
            allowlist[0] = 0x460709Fc45340055d68f8CECa5e66c99e11BA7A5;
            allowlist[1] = 0x7B2240556Fd593D09C8F3915328629A8fA916613;
            allowlist[2] = 0x9f57C8e4A8Cd5e66A81C7DF7079ff797428a7C92;
            allowlist[3] = 0xBaAEB7483d1D746d8CF942a3A26C7Fec66139967;
            allowlist[4] = 0x029a1c99aC36680e1D2c479f61a966D8734e4fa8;
            allowlist[5] = 0xf6965516e3a326b86510Fa1dAD52aa7EBd1fCB3d;
            allowlist[6] = 0x41528555d19B8002EF5Ba51fc709dFB5c29a2996;
            allowlist[7] = 0x4AF44F22119E3e7bd00058C4eef833708b7F8bf3;
            allowlist[8] = 0xBf345d145eE74EbcF9FE91Eee9887CEf2549F891;
            allowlist[9] = 0xf9E50a2584CFBD3d23468A395114461E5154fD61;
            allowlist[10] = 0xdC9f85dE54543eddD2Cc61e63D5DD8DFFb0b2cF4;
            allowlist[11] = 0x8f6f7BaD792fFBD018B2C71Cec830F9fca8657D0;
            allowlist[12] = 0xf5dD8F0D98138330F6b5927B019E5B94B3C1E919;
            allowlist[13] = 0x58245Bf2efF760dF0E98c28B07bF33C45787ef58;
            allowlist[14] = 0xEb663bF954E99E06eC80c42F6216b5DeAB0F3C8D;
            allowlist[15] = 0x015a04108E5E55325a044c0Ddd768584680FE68f;
            allowlist[16] = 0xb16186082978C651820aAD07A7Ef0327b272878A;
            allowlist[17] = 0x27922Fb56418DF8C366718D86DD1E54E0Fde280F;
            allowlist[18] = 0xC4CCB6bCD9b465D1a3367487587c8C79E2dab443;
            allowlist[19] = 0xe4D82DAfb347C3A6973b86B75053f2513b78072D;
            allowlist[20] = 0xAEFE6157392807bf9d0f7fC239b62172A35B8c5F;

            for (uint256 i = 0; i < allowlist.length; i++) {
                assertEq(ICoreProxy(sec.core).hasConfigurationPermission(1, permission, allowlist[i]), true);
            }
        }

        // check the addresses that should not have the permission
        {
            address[] memory revokelist = new address[](0);

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
            allowlist[0] = 0x8836cf32426cb26353698B105ab89fb87f52Fc34;

            for (uint256 i = 0; i < allowlist.length; i++) {
                assertEq(ICoreProxy(sec.core).hasAccountPermission(aeMarginAccountId, permission, allowlist[i]), true);
            }
        }

        // check the addresses that should not have the permission
        {
            address[] memory revokelist = new address[](0);

            for (uint256 i = 0; i < revokelist.length; i++) {
                assertEq(ICoreProxy(sec.core).hasAccountPermission(aeMarginAccountId, permission, revokelist[i]), false);
            }
        }
    }

    function test_liquidator_margin_account_permissions() public view {
        bytes32 permission1 = keccak256(bytes("DUTCH_LIQUIDATION"));
        bytes32 permission2 = keccak256(bytes("MATCH_ORDER"));
        uint128 liquidatorMarginAccountId = 109_371;

        // check the addresses that should have the permission
        {
            address[] memory allowlist = new address[](2);
            allowlist[0] = 0x84d17e2E153FE902Ac5b5d9c877F18DF3b9C6E56;
            allowlist[1] = 0xb776c97866FAeaBe752A2260ceCe8c19153EEbFc;

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
        {
            address[] memory revokelist = new address[](0);

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

    function test_perp_configure_spread_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureSpread"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](7);
        expectedAllowlist[0] = 0x0d171dFaab3440c0C88F3a07d8F3e9ffE56C609a;
        expectedAllowlist[1] = 0xa7a43DFe3353DFf531bc4faDDE5840B9182C2688;
        expectedAllowlist[2] = 0x10eE819bc1E25cd2Eb3CE023724209f6f56Ef103;
        expectedAllowlist[3] = 0xA50Aa11999f86f29badEc3fcD3aBa8AbBe153Ba2;
        expectedAllowlist[4] = 0x496c1408B34353Cd14067DF45a643b9F6Ea1aaa4;
        expectedAllowlist[5] = 0xbf59e78614F97fDbA523238AefDbe64E2efb28C3;
        expectedAllowlist[6] = 0xbAF944384b46eB8609c3A5C7894028cE60c15354;

        assertEq(allowlist, expectedAllowlist);
    }

    function test_perp_configure_depth_permissions() public view {
        bytes32 flagId = keccak256(bytes("configureDepth"));
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flagId);

        address[] memory expectedAllowlist = new address[](9);
        expectedAllowlist[0] = 0x0d171dFaab3440c0C88F3a07d8F3e9ffE56C609a;
        expectedAllowlist[1] = 0xa7a43DFe3353DFf531bc4faDDE5840B9182C2688;
        expectedAllowlist[2] = 0x10eE819bc1E25cd2Eb3CE023724209f6f56Ef103;
        expectedAllowlist[3] = 0xA50Aa11999f86f29badEc3fcD3aBa8AbBe153Ba2;
        expectedAllowlist[4] = 0x496c1408B34353Cd14067DF45a643b9F6Ea1aaa4;
        expectedAllowlist[5] = 0xbf59e78614F97fDbA523238AefDbe64E2efb28C3;
        expectedAllowlist[6] = 0xbAF944384b46eB8609c3A5C7894028cE60c15354;
        expectedAllowlist[7] = 0x93e3AaEe71Dc2f42AD9a5992e4A6776B3406104D;
        expectedAllowlist[8] = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9;

        assertEq(allowlist, expectedAllowlist);
    }
}
