pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { LeverageForkCheck } from "../../reya_common/trade/Leverage.fork.c.sol";

contract LeverageForkTest is ReyaForkTest, LeverageForkCheck {
    function test_Cronos_trade_rusdCollateral_leverage_eth() public {
        check_trade_rusdCollateral_leverage_eth();
    }

    function test_Cronos_trade_rusdCollateral_leverage_btc() public {
        check_trade_rusdCollateral_leverage_btc();
    }

    function test_Cronos_trade_rusdCollateral_leverage_sol() public {
        check_trade_rusdCollateral_leverage_sol();
    }

    function test_Cronos_trade_rusdCollateral_leverage_arb() public {
        check_trade_rusdCollateral_leverage_arb();
    }

    function test_Cronos_trade_rusdCollateral_leverage_op() public {
        check_trade_rusdCollateral_leverage_op();
    }

    function test_Cronos_trade_rusdCollateral_leverage_avax() public {
        check_trade_rusdCollateral_leverage_avax();
    }

    function test_Cronos_trade_rusdCollateral_leverage_mkr() public {
        check_trade_rusdCollateral_leverage_mkr();
    }

    function test_Cronos_trade_rusdCollateral_leverage_link() public {
        check_trade_rusdCollateral_leverage_link();
    }

    function test_Cronos_trade_rusdCollateral_leverage_aave() public {
        check_trade_rusdCollateral_leverage_aave();
    }

    function test_Cronos_trade_rusdCollateral_leverage_crv() public {
        check_trade_rusdCollateral_leverage_crv();
    }

    function test_Cronos_trade_rusdCollateral_leverage_uni() public {
        check_trade_rusdCollateral_leverage_uni();
    }

    function test_Cronos_trade_rusdCollateral_leverage_sui() public {
        check_trade_rusdCollateral_leverage_sui();
    }

    function test_Cronos_trade_rusdCollateral_leverage_tia() public {
        check_trade_rusdCollateral_leverage_tia();
    }

    function test_Cronos_trade_rusdCollateral_leverage_sei() public {
        check_trade_rusdCollateral_leverage_sei();
    }

    function test_Cronos_trade_rusdCollateral_leverage_zro() public {
        check_trade_rusdCollateral_leverage_zro();
    }

    function test_Cronos_trade_rusdCollateral_leverage_xrp() public {
        check_trade_rusdCollateral_leverage_xrp();
    }

    function test_Cronos_trade_rusdCollateral_leverage_wif() public {
        check_trade_rusdCollateral_leverage_wif();
    }

    function test_Cronos_trade_rusdCollateral_leverage_pepe1k() public {
        check_trade_rusdCollateral_leverage_pepe1k();
    }

    // function test_Cronos_trade_rusdCollateral_leverage_popcat() public {
    //     check_trade_rusdCollateral_leverage_popcat();
    // }

    function test_Cronos_trade_rusdCollateral_leverage_doge() public {
        check_trade_rusdCollateral_leverage_doge();
    }

    function test_Cronos_trade_rusdCollateral_leverage_kshib() public {
        check_trade_rusdCollateral_leverage_kshib();
    }

    function test_Cronos_trade_rusdCollateral_leverage_kbonk() public {
        check_trade_rusdCollateral_leverage_kbonk();
    }

    function test_Cronos_trade_rusdCollateral_leverage_apt() public {
        check_trade_rusdCollateral_leverage_apt();
    }

    function test_Cronos_trade_rusdCollateral_leverage_bnb() public {
        check_trade_rusdCollateral_leverage_bnb();
    }

    function test_Cronos_trade_rusdCollateral_leverage_jto() public {
        check_trade_rusdCollateral_leverage_jto();
    }

    function test_Cronos_trade_wethCollateral_leverage_eth() public {
        check_trade_wethCollateral_leverage_eth();
    }

    function test_Cronos_trade_wethCollateral_leverage_btc() public {
        check_trade_wethCollateral_leverage_btc();
    }

    function test_Cronos_trade_wethCollateral_leverage_sol() public {
        check_trade_wethCollateral_leverage_sol();
    }

    function test_Cronos_trade_wethCollateral_leverage_arb() public {
        check_trade_wethCollateral_leverage_arb();
    }

    function test_Cronos_trade_wethCollateral_leverage_op() public {
        check_trade_wethCollateral_leverage_op();
    }

    function test_Cronos_trade_wethCollateral_leverage_avax() public {
        check_trade_wethCollateral_leverage_avax();
    }

    function test_Cronos_trade_wethCollateral_leverage_mkr() public {
        check_trade_wethCollateral_leverage_mkr();
    }

    function test_Cronos_trade_wethCollateral_leverage_link() public {
        check_trade_wethCollateral_leverage_link();
    }

    function test_Cronos_trade_wethCollateral_leverage_aave() public {
        check_trade_wethCollateral_leverage_aave();
    }

    function test_Cronos_trade_wethCollateral_leverage_crv() public {
        check_trade_wethCollateral_leverage_crv();
    }

    function test_Cronos_trade_wethCollateral_leverage_uni() public {
        check_trade_wethCollateral_leverage_uni();
    }

    function test_Cronos_trade_wethCollateral_leverage_sui() public {
        check_trade_wethCollateral_leverage_sui();
    }

    function test_Cronos_trade_wethCollateral_leverage_tia() public {
        check_trade_wethCollateral_leverage_tia();
    }

    function test_Cronos_trade_wethCollateral_leverage_sei() public {
        check_trade_wethCollateral_leverage_sei();
    }

    function test_Cronos_trade_wethCollateral_leverage_zro() public {
        check_trade_wethCollateral_leverage_zro();
    }

    function test_Cronos_trade_wethCollateral_leverage_xrp() public {
        check_trade_wethCollateral_leverage_xrp();
    }

    function test_Cronos_trade_wethCollateral_leverage_wif() public {
        check_trade_wethCollateral_leverage_wif();
    }

    function test_Cronos_trade_wethCollateral_leverage_pepe1k() public {
        check_trade_wethCollateral_leverage_pepe1k();
    }

    // function test_Cronos_trade_wethCollateral_leverage_popcat() public {
    //     check_trade_wethCollateral_leverage_popcat();
    // }

    function test_Cronos_trade_wethCollateral_leverage_doge() public {
        check_trade_wethCollateral_leverage_doge();
    }

    function test_Cronos_trade_wethCollateral_leverage_kshib() public {
        check_trade_wethCollateral_leverage_kshib();
    }

    function test_Cronos_trade_wethCollateral_leverage_kbonk() public {
        check_trade_wethCollateral_leverage_kbonk();
    }

    function test_Cronos_trade_wethCollateral_leverage_apt() public {
        check_trade_wethCollateral_leverage_apt();
    }

    function test_Cronos_trade_wethCollateral_leverage_bnb() public {
        check_trade_wethCollateral_leverage_bnb();
    }

    function test_Cronos_trade_wethCollateral_leverage_jto() public {
        check_trade_wethCollateral_leverage_jto();
    }

    function test_Cronos_trade_usdeCollateral_leverage_eth() public {
        check_trade_usdeCollateral_leverage_eth();
    }

    function test_Cronos_trade_usdeCollateral_leverage_btc() public {
        check_trade_usdeCollateral_leverage_btc();
    }

    function test_Cronos_trade_usdeCollateral_leverage_sol() public {
        check_trade_usdeCollateral_leverage_sol();
    }

    function test_Cronos_trade_usdeCollateral_leverage_arb() public {
        check_trade_usdeCollateral_leverage_arb();
    }

    function test_Cronos_trade_usdeCollateral_leverage_op() public {
        check_trade_usdeCollateral_leverage_op();
    }

    function test_Cronos_trade_usdeCollateral_leverage_avax() public {
        check_trade_usdeCollateral_leverage_avax();
    }

    function test_Cronos_trade_usdeCollateral_leverage_mkr() public {
        check_trade_usdeCollateral_leverage_mkr();
    }

    function test_Cronos_trade_usdeCollateral_leverage_link() public {
        check_trade_usdeCollateral_leverage_link();
    }

    function test_Cronos_trade_usdeCollateral_leverage_aave() public {
        check_trade_usdeCollateral_leverage_aave();
    }

    function test_Cronos_trade_usdeCollateral_leverage_crv() public {
        check_trade_usdeCollateral_leverage_crv();
    }

    function test_Cronos_trade_usdeCollateral_leverage_uni() public {
        check_trade_usdeCollateral_leverage_uni();
    }

    function test_Cronos_trade_usdeCollateral_leverage_sui() public {
        check_trade_usdeCollateral_leverage_sui();
    }

    function test_Cronos_trade_usdeCollateral_leverage_tia() public {
        check_trade_usdeCollateral_leverage_tia();
    }

    function test_Cronos_trade_usdeCollateral_leverage_sei() public {
        check_trade_usdeCollateral_leverage_sei();
    }

    function test_Cronos_trade_usdeCollateral_leverage_zro() public {
        check_trade_usdeCollateral_leverage_zro();
    }

    function test_Cronos_trade_usdeCollateral_leverage_xrp() public {
        check_trade_usdeCollateral_leverage_xrp();
    }

    function test_Cronos_trade_usdeCollateral_leverage_wif() public {
        check_trade_usdeCollateral_leverage_wif();
    }

    function test_Cronos_trade_usdeCollateral_leverage_pepe1k() public {
        check_trade_usdeCollateral_leverage_pepe1k();
    }

    // function test_Cronos_trade_usdeCollateral_leverage_popcat() public {
    //     check_trade_usdeCollateral_leverage_popcat();
    // }

    function test_Cronos_trade_usdeCollateral_leverage_doge() public {
        check_trade_usdeCollateral_leverage_doge();
    }

    function test_Cronos_trade_usdeCollateral_leverage_kshib() public {
        check_trade_usdeCollateral_leverage_kshib();
    }

    function test_Cronos_trade_usdeCollateral_leverage_kbonk() public {
        check_trade_usdeCollateral_leverage_kbonk();
    }

    function test_Cronos_trade_usdeCollateral_leverage_apt() public {
        check_trade_usdeCollateral_leverage_apt();
    }

    function test_Cronos_trade_usdeCollateral_leverage_bnb() public {
        check_trade_usdeCollateral_leverage_bnb();
    }

    function test_Cronos_trade_usdeCollateral_leverage_jto() public {
        check_trade_usdeCollateral_leverage_jto();
    }

    function test_Cronos_trade_susdeCollateral_leverage_eth() public {
        check_trade_susdeCollateral_leverage_eth();
    }

    function test_Cronos_trade_susdeCollateral_leverage_btc() public {
        check_trade_susdeCollateral_leverage_btc();
    }

    function test_Cronos_trade_susdeCollateral_leverage_sol() public {
        check_trade_susdeCollateral_leverage_sol();
    }

    function test_Cronos_trade_susdeCollateral_leverage_arb() public {
        check_trade_susdeCollateral_leverage_arb();
    }

    function test_Cronos_trade_susdeCollateral_leverage_op() public {
        check_trade_susdeCollateral_leverage_op();
    }

    function test_Cronos_trade_susdeCollateral_leverage_avax() public {
        check_trade_susdeCollateral_leverage_avax();
    }

    function test_Cronos_trade_susdeCollateral_leverage_mkr() public {
        check_trade_susdeCollateral_leverage_mkr();
    }

    function test_Cronos_trade_susdeCollateral_leverage_link() public {
        check_trade_susdeCollateral_leverage_link();
    }

    function test_Cronos_trade_susdeCollateral_leverage_aave() public {
        check_trade_susdeCollateral_leverage_aave();
    }

    function test_Cronos_trade_susdeCollateral_leverage_crv() public {
        check_trade_susdeCollateral_leverage_crv();
    }

    function test_Cronos_trade_susdeCollateral_leverage_uni() public {
        check_trade_susdeCollateral_leverage_uni();
    }

    function test_Cronos_trade_susdeCollateral_leverage_sui() public {
        check_trade_susdeCollateral_leverage_sui();
    }

    function test_Cronos_trade_susdeCollateral_leverage_tia() public {
        check_trade_susdeCollateral_leverage_tia();
    }

    function test_Cronos_trade_susdeCollateral_leverage_sei() public {
        check_trade_susdeCollateral_leverage_sei();
    }

    function test_Cronos_trade_susdeCollateral_leverage_zro() public {
        check_trade_susdeCollateral_leverage_zro();
    }

    function test_Cronos_trade_susdeCollateral_leverage_xrp() public {
        check_trade_susdeCollateral_leverage_xrp();
    }

    function test_Cronos_trade_susdeCollateral_leverage_wif() public {
        check_trade_susdeCollateral_leverage_wif();
    }

    function test_Cronos_trade_susdeCollateral_leverage_pepe1k() public {
        check_trade_susdeCollateral_leverage_pepe1k();
    }

    // function test_Cronos_trade_susdeCollateral_leverage_popcat() public {
    //     check_trade_susdeCollateral_leverage_popcat();
    // }

    function test_Cronos_trade_susdeCollateral_leverage_doge() public {
        check_trade_susdeCollateral_leverage_doge();
    }

    function test_Cronos_trade_susdeCollateral_leverage_kshib() public {
        check_trade_susdeCollateral_leverage_kshib();
    }

    function test_Cronos_trade_susdeCollateral_leverage_kbonk() public {
        check_trade_susdeCollateral_leverage_kbonk();
    }

    function test_Cronos_trade_susdeCollateral_leverage_apt() public {
        check_trade_susdeCollateral_leverage_apt();
    }

    function test_Cronos_trade_susdeCollateral_leverage_bnb() public {
        check_trade_susdeCollateral_leverage_bnb();
    }

    function test_Cronos_trade_susdeCollateral_leverage_jto() public {
        check_trade_susdeCollateral_leverage_jto();
    }

    function test_Cronos_trade_deusdCollateral_leverage_eth() public {
        check_trade_deusdCollateral_leverage_eth();
    }

    function test_Cronos_trade_deusdCollateral_leverage_btc() public {
        check_trade_deusdCollateral_leverage_btc();
    }

    function test_Cronos_trade_deusdCollateral_leverage_sol() public {
        check_trade_deusdCollateral_leverage_sol();
    }

    function test_Cronos_trade_deusdCollateral_leverage_arb() public {
        check_trade_deusdCollateral_leverage_arb();
    }

    function test_Cronos_trade_deusdCollateral_leverage_op() public {
        check_trade_deusdCollateral_leverage_op();
    }

    function test_Cronos_trade_deusdCollateral_leverage_avax() public {
        check_trade_deusdCollateral_leverage_avax();
    }

    function test_Cronos_trade_deusdCollateral_leverage_mkr() public {
        check_trade_deusdCollateral_leverage_mkr();
    }

    function test_Cronos_trade_deusdCollateral_leverage_link() public {
        check_trade_deusdCollateral_leverage_link();
    }

    function test_Cronos_trade_deusdCollateral_leverage_aave() public {
        check_trade_deusdCollateral_leverage_aave();
    }

    function test_Cronos_trade_deusdCollateral_leverage_crv() public {
        check_trade_deusdCollateral_leverage_crv();
    }

    function test_Cronos_trade_deusdCollateral_leverage_uni() public {
        check_trade_deusdCollateral_leverage_uni();
    }

    function test_Cronos_trade_deusdCollateral_leverage_sui() public {
        check_trade_deusdCollateral_leverage_sui();
    }

    function test_Cronos_trade_deusdCollateral_leverage_tia() public {
        check_trade_deusdCollateral_leverage_tia();
    }

    function test_Cronos_trade_deusdCollateral_leverage_sei() public {
        check_trade_deusdCollateral_leverage_sei();
    }

    function test_Cronos_trade_deusdCollateral_leverage_zro() public {
        check_trade_deusdCollateral_leverage_zro();
    }

    function test_Cronos_trade_deusdCollateral_leverage_xrp() public {
        check_trade_deusdCollateral_leverage_xrp();
    }

    function test_Cronos_trade_deusdCollateral_leverage_wif() public {
        check_trade_deusdCollateral_leverage_wif();
    }

    function test_Cronos_trade_deusdCollateral_leverage_pepe1k() public {
        check_trade_deusdCollateral_leverage_pepe1k();
    }

    // function test_Cronos_trade_deusdCollateral_leverage_popcat() public {
    //     check_trade_deusdCollateral_leverage_popcat();
    // }

    function test_Cronos_trade_deusdCollateral_leverage_doge() public {
        check_trade_deusdCollateral_leverage_doge();
    }

    function test_Cronos_trade_deusdCollateral_leverage_kshib() public {
        check_trade_deusdCollateral_leverage_kshib();
    }

    function test_Cronos_trade_deusdCollateral_leverage_kbonk() public {
        check_trade_deusdCollateral_leverage_kbonk();
    }

    function test_Cronos_trade_deusdCollateral_leverage_apt() public {
        check_trade_deusdCollateral_leverage_apt();
    }

    function test_Cronos_trade_deusdCollateral_leverage_bnb() public {
        check_trade_deusdCollateral_leverage_bnb();
    }

    function test_Cronos_trade_deusdCollateral_leverage_jto() public {
        check_trade_deusdCollateral_leverage_jto();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_eth() public {
        check_trade_sdeusdCollateral_leverage_eth();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_btc() public {
        check_trade_sdeusdCollateral_leverage_btc();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_sol() public {
        check_trade_sdeusdCollateral_leverage_sol();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_arb() public {
        check_trade_sdeusdCollateral_leverage_arb();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_op() public {
        check_trade_sdeusdCollateral_leverage_op();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_avax() public {
        check_trade_sdeusdCollateral_leverage_avax();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_mkr() public {
        check_trade_sdeusdCollateral_leverage_mkr();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_link() public {
        check_trade_sdeusdCollateral_leverage_link();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_aave() public {
        check_trade_sdeusdCollateral_leverage_aave();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_crv() public {
        check_trade_sdeusdCollateral_leverage_crv();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_uni() public {
        check_trade_sdeusdCollateral_leverage_uni();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_sui() public {
        check_trade_sdeusdCollateral_leverage_sui();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_tia() public {
        check_trade_sdeusdCollateral_leverage_tia();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_sei() public {
        check_trade_sdeusdCollateral_leverage_sei();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_zro() public {
        check_trade_sdeusdCollateral_leverage_zro();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_xrp() public {
        check_trade_sdeusdCollateral_leverage_xrp();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_wif() public {
        check_trade_sdeusdCollateral_leverage_wif();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_pepe1k() public {
        check_trade_sdeusdCollateral_leverage_pepe1k();
    }

    // function test_Cronos_trade_sdeusdCollateral_leverage_popcat() public {
    //     check_trade_sdeusdCollateral_leverage_popcat();
    // }

    function test_Cronos_trade_sdeusdCollateral_leverage_doge() public {
        check_trade_sdeusdCollateral_leverage_doge();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_kshib() public {
        check_trade_sdeusdCollateral_leverage_kshib();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_kbonk() public {
        check_trade_sdeusdCollateral_leverage_kbonk();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_apt() public {
        check_trade_sdeusdCollateral_leverage_apt();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_bnb() public {
        check_trade_sdeusdCollateral_leverage_bnb();
    }

    function test_Cronos_trade_sdeusdCollateral_leverage_jto() public {
        check_trade_sdeusdCollateral_leverage_jto();
    }
}
