pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { LeverageForkCheck } from "../../reya_common/trade/Leverage.fork.c.sol";

contract LeverageForkTest is ReyaForkTest, LeverageForkCheck {
    function test_Cronos_trade_rusdCollateral_leverage_eth() public {
        check_trade_leverage(1, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_btc() public {
        check_trade_leverage(2, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_sol() public {
        check_trade_leverage(3, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_arb() public {
        check_trade_leverage(4, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_op() public {
        check_trade_leverage(5, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_avax() public {
        check_trade_leverage(6, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_mkr() public {
        check_trade_leverage(7, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_link() public {
        check_trade_leverage(8, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_aave() public {
        check_trade_leverage(9, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_crv() public {
        check_trade_leverage(10, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_uni() public {
        check_trade_leverage(11, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_sui() public {
        check_trade_leverage(12, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_tia() public {
        check_trade_leverage(13, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_sei() public {
        check_trade_leverage(14, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_zro() public {
        check_trade_leverage(15, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_xrp() public {
        check_trade_leverage(16, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_wif() public {
        check_trade_leverage(17, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_pepe1k() public {
        check_trade_leverage(18, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_popcat() public {
        check_trade_leverage(19, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_doge() public {
        check_trade_leverage(20, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_kshib() public {
        check_trade_leverage(21, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_kbonk() public {
        check_trade_leverage(22, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_apt() public {
        check_trade_leverage(23, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_bnb() public {
        check_trade_leverage(24, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_jto() public {
        check_trade_leverage(25, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_ada() public {
        check_trade_leverage(26, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_ldo() public {
        check_trade_leverage(27, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_pol() public {
        check_trade_leverage(28, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_near() public {
        check_trade_leverage(29, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_ftm() public {
        check_trade_leverage(30, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_ena() public {
        check_trade_leverage(31, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_eigen() public {
        check_trade_leverage(32, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_pendle() public {
        check_trade_leverage(33, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_goat() public {
        check_trade_leverage(34, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_grass() public {
        check_trade_leverage(35, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_kneiro() public {
        check_trade_leverage(36, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_dot() public {
        check_trade_leverage(37, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_ltc() public {
        check_trade_leverage(38, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_pyth() public {
        check_trade_leverage(39, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_jup() public {
        check_trade_leverage(40, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_pengu() public {
        check_trade_leverage(41, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_trump() public {
        check_trade_leverage(42, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_hype() public {
        check_trade_leverage(43, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_virtual() public {
        check_trade_leverage(44, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_ai16z() public {
        check_trade_leverage(45, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_aixbt() public {
        check_trade_leverage(46, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_sonic() public {
        check_trade_leverage(47, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_fartcoin() public {
        check_trade_leverage(48, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_griffain() public {
        check_trade_leverage(49, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_wld() public {
        check_trade_leverage(50, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_atom() public {
        check_trade_leverage(51, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_ape() public {
        check_trade_leverage(52, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_ton() public {
        check_trade_leverage(53, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_ondo() public {
        check_trade_leverage(54, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_trx() public {
        check_trade_leverage(55, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_inj() public {
        check_trade_leverage(56, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_move() public {
        check_trade_leverage(57, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_bera() public {
        check_trade_leverage(58, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_layer() public {
        check_trade_leverage(59, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_tao() public {
        check_trade_leverage(60, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_ip() public {
        check_trade_leverage(61, sec.usdc);
    }

    function test_Cronos_trade_rusdCollateral_leverage_me() public {
        check_trade_leverage(62, sec.usdc);
    }

    function test_Cronos_trade_wethCollateral_leverage_eth() public {
        check_trade_leverage(1, sec.weth);
    }

    function test_Cronos_trade_usdeCollateral_leverage_btc() public {
        check_trade_leverage(2, sec.usde);
    }

    function test_Cronos_trade_susdeCollateral_leverage_sol() public {
        check_trade_leverage(3, sec.susde);
    }

    function test_Cronos_trade_deusdCollateral_leverage_arb() public {
        check_trade_leverage(4, sec.deusd);
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_op() public {
        check_trade_leverage(5, sec.sdeusd);
    }

    function test_Cronos_trade_rseliniCollateral_leverage_avax() public {
        check_trade_leverage(6, sec.rselini);
    }

    function test_Cronos_trade_ramberCollateral_leverage_mkr() public {
        check_trade_leverage(7, sec.ramber);
    }

    function test_Cronos_trade_srusdCollateral_leverage_link() public {
        check_trade_leverage(8, sec.srusd);
    }

    function test_Cronos_trade_rhedgeCollateral_leverage_aave() public {
        check_trade_leverage(9, sec.rhedge);
    }

    function test_Cronos_trade_wstethCollateral_leverage_crv() public {
        check_trade_leverage(10, sec.wsteth);
    }
}
