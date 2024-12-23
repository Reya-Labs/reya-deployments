pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { LeverageForkCheck } from "../../reya_common/trade/Leverage.fork.c.sol";

contract LeverageForkTest is ReyaForkTest, LeverageForkCheck {
    function test_trade_rusdCollateral_leverage_eth() public {
        check_trade_rusdCollateral_leverage_eth();
    }

    function test_trade_rusdCollateral_leverage_btc() public {
        check_trade_rusdCollateral_leverage_btc();
    }

    function test_trade_rusdCollateral_leverage_sol() public {
        check_trade_rusdCollateral_leverage_sol();
    }

    function test_trade_rusdCollateral_leverage_arb() public {
        check_trade_rusdCollateral_leverage_arb();
    }

    function test_trade_rusdCollateral_leverage_op() public {
        check_trade_rusdCollateral_leverage_op();
    }

    function test_trade_rusdCollateral_leverage_avax() public {
        check_trade_rusdCollateral_leverage_avax();
    }

    function test_trade_rusdCollateral_leverage_mkr() public {
        check_trade_rusdCollateral_leverage_mkr();
    }

    function test_trade_rusdCollateral_leverage_link() public {
        check_trade_rusdCollateral_leverage_link();
    }

    function test_trade_rusdCollateral_leverage_aave() public {
        check_trade_rusdCollateral_leverage_aave();
    }

    function test_trade_rusdCollateral_leverage_crv() public {
        check_trade_rusdCollateral_leverage_crv();
    }

    function test_trade_rusdCollateral_leverage_uni() public {
        check_trade_rusdCollateral_leverage_uni();
    }

    function test_trade_rusdCollateral_leverage_sui() public {
        check_trade_rusdCollateral_leverage_sui();
    }

    function test_trade_rusdCollateral_leverage_tia() public {
        check_trade_rusdCollateral_leverage_tia();
    }

    function test_trade_rusdCollateral_leverage_sei() public {
        check_trade_rusdCollateral_leverage_sei();
    }

    function test_trade_rusdCollateral_leverage_zro() public {
        check_trade_rusdCollateral_leverage_zro();
    }

    function test_trade_rusdCollateral_leverage_xrp() public {
        check_trade_rusdCollateral_leverage_xrp();
    }

    function test_trade_rusdCollateral_leverage_wif() public {
        check_trade_rusdCollateral_leverage_wif();
    }

    function test_trade_rusdCollateral_leverage_pepe1k() public {
        check_trade_rusdCollateral_leverage_pepe1k();
    }

    function test_trade_rusdCollateral_leverage_popcat() public {
        check_trade_rusdCollateral_leverage_popcat();
    }

    function test_trade_rusdCollateral_leverage_doge() public {
        check_trade_rusdCollateral_leverage_doge();
    }

    function test_trade_rusdCollateral_leverage_kshib() public {
        check_trade_rusdCollateral_leverage_kshib();
    }

    function test_trade_rusdCollateral_leverage_kbonk() public {
        check_trade_rusdCollateral_leverage_kbonk();
    }

    function test_trade_rusdCollateral_leverage_apt() public {
        check_trade_rusdCollateral_leverage_apt();
    }

    function test_trade_rusdCollateral_leverage_bnb() public {
        check_trade_rusdCollateral_leverage_bnb();
    }

    function test_trade_rusdCollateral_leverage_jto() public {
        check_trade_rusdCollateral_leverage_jto();
    }

    function test_trade_rusdCollateral_leverage_ada() public {
        check_trade_rusdCollateral_leverage_ada();
    }

    function test_trade_rusdCollateral_leverage_ldo() public {
        check_trade_rusdCollateral_leverage_ldo();
    }

    function test_trade_rusdCollateral_leverage_pol() public {
        check_trade_rusdCollateral_leverage_pol();
    }

    function test_trade_rusdCollateral_leverage_near() public {
        check_trade_rusdCollateral_leverage_near();
    }

    function test_trade_rusdCollateral_leverage_ftm() public {
        check_trade_rusdCollateral_leverage_ftm();
    }

    function test_trade_rusdCollateral_leverage_ena() public {
        check_trade_rusdCollateral_leverage_ena();
    }

    function test_trade_rusdCollateral_leverage_eigen() public {
        check_trade_rusdCollateral_leverage_eigen();
    }

    function test_trade_rusdCollateral_leverage_pendle() public {
        check_trade_rusdCollateral_leverage_pendle();
    }

    function test_trade_rusdCollateral_leverage_goat() public {
        check_trade_rusdCollateral_leverage_goat();
    }

    function test_trade_rusdCollateral_leverage_grass() public {
        check_trade_rusdCollateral_leverage_grass();
    }

    function test_trade_rusdCollateral_leverage_kneiro() public {
        check_trade_rusdCollateral_leverage_kneiro();
    }

    function test_trade_wethCollateral_leverage_eth() public {
        check_trade_wethCollateral_leverage_eth();
    }

    function test_trade_wethCollateral_leverage_btc() public {
        check_trade_wethCollateral_leverage_btc();
    }

    function test_trade_wethCollateral_leverage_sol() public {
        check_trade_wethCollateral_leverage_sol();
    }

    function test_trade_wethCollateral_leverage_arb() public {
        check_trade_wethCollateral_leverage_arb();
    }

    function test_trade_wethCollateral_leverage_op() public {
        check_trade_wethCollateral_leverage_op();
    }

    function test_trade_wethCollateral_leverage_avax() public {
        check_trade_wethCollateral_leverage_avax();
    }

    function test_trade_wethCollateral_leverage_mkr() public {
        check_trade_wethCollateral_leverage_mkr();
    }

    function test_trade_wethCollateral_leverage_link() public {
        check_trade_wethCollateral_leverage_link();
    }

    function test_trade_wethCollateral_leverage_aave() public {
        check_trade_wethCollateral_leverage_aave();
    }

    function test_trade_wethCollateral_leverage_crv() public {
        check_trade_wethCollateral_leverage_crv();
    }

    function test_trade_wethCollateral_leverage_uni() public {
        check_trade_wethCollateral_leverage_uni();
    }

    function test_trade_wethCollateral_leverage_sui() public {
        check_trade_wethCollateral_leverage_sui();
    }

    function test_trade_wethCollateral_leverage_tia() public {
        check_trade_wethCollateral_leverage_tia();
    }

    function test_trade_wethCollateral_leverage_sei() public {
        check_trade_wethCollateral_leverage_sei();
    }

    function test_trade_wethCollateral_leverage_zro() public {
        check_trade_wethCollateral_leverage_zro();
    }

    function test_trade_wethCollateral_leverage_xrp() public {
        check_trade_wethCollateral_leverage_xrp();
    }

    function test_trade_wethCollateral_leverage_wif() public {
        check_trade_wethCollateral_leverage_wif();
    }

    function test_trade_wethCollateral_leverage_pepe1k() public {
        check_trade_wethCollateral_leverage_pepe1k();
    }

    function test_trade_wethCollateral_leverage_popcat() public {
        check_trade_wethCollateral_leverage_popcat();
    }

    function test_trade_wethCollateral_leverage_doge() public {
        check_trade_wethCollateral_leverage_doge();
    }

    function test_trade_wethCollateral_leverage_kshib() public {
        check_trade_wethCollateral_leverage_kshib();
    }

    function test_trade_wethCollateral_leverage_kbonk() public {
        check_trade_wethCollateral_leverage_kbonk();
    }

    function test_trade_wethCollateral_leverage_apt() public {
        check_trade_wethCollateral_leverage_apt();
    }

    function test_trade_wethCollateral_leverage_bnb() public {
        check_trade_wethCollateral_leverage_bnb();
    }

    function test_trade_wethCollateral_leverage_jto() public {
        check_trade_wethCollateral_leverage_jto();
    }

    function test_trade_wethCollateral_leverage_ada() public {
        check_trade_wethCollateral_leverage_ada();
    }

    function test_trade_wethCollateral_leverage_ldo() public {
        check_trade_wethCollateral_leverage_ldo();
    }

    function test_trade_wethCollateral_leverage_pol() public {
        check_trade_wethCollateral_leverage_pol();
    }

    function test_trade_wethCollateral_leverage_near() public {
        check_trade_wethCollateral_leverage_near();
    }

    function test_trade_wethCollateral_leverage_ftm() public {
        check_trade_wethCollateral_leverage_ftm();
    }

    function test_trade_wethCollateral_leverage_ena() public {
        check_trade_wethCollateral_leverage_ena();
    }

    function test_trade_wethCollateral_leverage_eigen() public {
        check_trade_wethCollateral_leverage_eigen();
    }

    function test_trade_wethCollateral_leverage_pendle() public {
        check_trade_wethCollateral_leverage_pendle();
    }

    function test_trade_wethCollateral_leverage_goat() public {
        check_trade_wethCollateral_leverage_goat();
    }

    function test_trade_wethCollateral_leverage_grass() public {
        check_trade_wethCollateral_leverage_grass();
    }

    function test_trade_wethCollateral_leverage_kneiro() public {
        check_trade_wethCollateral_leverage_kneiro();
    }

    function test_trade_usdeCollateral_leverage_eth() public {
        check_trade_usdeCollateral_leverage_eth();
    }

    function test_trade_usdeCollateral_leverage_btc() public {
        check_trade_usdeCollateral_leverage_btc();
    }

    function test_trade_usdeCollateral_leverage_sol() public {
        check_trade_usdeCollateral_leverage_sol();
    }

    function test_trade_usdeCollateral_leverage_arb() public {
        check_trade_usdeCollateral_leverage_arb();
    }

    function test_trade_usdeCollateral_leverage_op() public {
        check_trade_usdeCollateral_leverage_op();
    }

    function test_trade_usdeCollateral_leverage_avax() public {
        check_trade_usdeCollateral_leverage_avax();
    }

    function test_trade_usdeCollateral_leverage_mkr() public {
        check_trade_usdeCollateral_leverage_mkr();
    }

    function test_trade_usdeCollateral_leverage_link() public {
        check_trade_usdeCollateral_leverage_link();
    }

    function test_trade_usdeCollateral_leverage_aave() public {
        check_trade_usdeCollateral_leverage_aave();
    }

    function test_trade_usdeCollateral_leverage_crv() public {
        check_trade_usdeCollateral_leverage_crv();
    }

    function test_trade_usdeCollateral_leverage_uni() public {
        check_trade_usdeCollateral_leverage_uni();
    }

    function test_trade_usdeCollateral_leverage_sui() public {
        check_trade_usdeCollateral_leverage_sui();
    }

    function test_trade_usdeCollateral_leverage_tia() public {
        check_trade_usdeCollateral_leverage_tia();
    }

    function test_trade_usdeCollateral_leverage_sei() public {
        check_trade_usdeCollateral_leverage_sei();
    }

    function test_trade_usdeCollateral_leverage_zro() public {
        check_trade_usdeCollateral_leverage_zro();
    }

    function test_trade_usdeCollateral_leverage_xrp() public {
        check_trade_usdeCollateral_leverage_xrp();
    }

    function test_trade_usdeCollateral_leverage_wif() public {
        check_trade_usdeCollateral_leverage_wif();
    }

    function test_trade_usdeCollateral_leverage_pepe1k() public {
        check_trade_usdeCollateral_leverage_pepe1k();
    }

    function test_trade_usdeCollateral_leverage_popcat() public {
        check_trade_usdeCollateral_leverage_popcat();
    }

    function test_trade_usdeCollateral_leverage_doge() public {
        check_trade_usdeCollateral_leverage_doge();
    }

    function test_trade_usdeCollateral_leverage_kshib() public {
        check_trade_usdeCollateral_leverage_kshib();
    }

    function test_trade_usdeCollateral_leverage_kbonk() public {
        check_trade_usdeCollateral_leverage_kbonk();
    }

    function test_trade_usdeCollateral_leverage_apt() public {
        check_trade_usdeCollateral_leverage_apt();
    }

    function test_trade_usdeCollateral_leverage_bnb() public {
        check_trade_usdeCollateral_leverage_bnb();
    }

    function test_trade_usdeCollateral_leverage_jto() public {
        check_trade_usdeCollateral_leverage_jto();
    }

    function test_trade_usdeCollateral_leverage_ada() public {
        check_trade_usdeCollateral_leverage_ada();
    }

    function test_trade_usdeCollateral_leverage_ldo() public {
        check_trade_usdeCollateral_leverage_ldo();
    }

    function test_trade_usdeCollateral_leverage_pol() public {
        check_trade_usdeCollateral_leverage_pol();
    }

    function test_trade_usdeCollateral_leverage_near() public {
        check_trade_usdeCollateral_leverage_near();
    }

    function test_trade_usdeCollateral_leverage_ftm() public {
        check_trade_usdeCollateral_leverage_ftm();
    }

    function test_trade_usdeCollateral_leverage_ena() public {
        check_trade_usdeCollateral_leverage_ena();
    }

    function test_trade_usdeCollateral_leverage_eigen() public {
        check_trade_usdeCollateral_leverage_eigen();
    }

    function test_trade_usdeCollateral_leverage_pendle() public {
        check_trade_usdeCollateral_leverage_pendle();
    }

    function test_trade_usdeCollateral_leverage_goat() public {
        check_trade_usdeCollateral_leverage_goat();
    }

    function test_trade_usdeCollateral_leverage_grass() public {
        check_trade_usdeCollateral_leverage_grass();
    }

    function test_trade_usdeCollateral_leverage_kneiro() public {
        check_trade_usdeCollateral_leverage_kneiro();
    }

    function test_trade_susdeCollateral_leverage_eth() public {
        check_trade_susdeCollateral_leverage_eth();
    }

    function test_trade_susdeCollateral_leverage_btc() public {
        check_trade_susdeCollateral_leverage_btc();
    }

    function test_trade_susdeCollateral_leverage_sol() public {
        check_trade_susdeCollateral_leverage_sol();
    }

    function test_trade_susdeCollateral_leverage_arb() public {
        check_trade_susdeCollateral_leverage_arb();
    }

    function test_trade_susdeCollateral_leverage_op() public {
        check_trade_susdeCollateral_leverage_op();
    }

    function test_trade_susdeCollateral_leverage_avax() public {
        check_trade_susdeCollateral_leverage_avax();
    }

    function test_trade_susdeCollateral_leverage_mkr() public {
        check_trade_susdeCollateral_leverage_mkr();
    }

    function test_trade_susdeCollateral_leverage_link() public {
        check_trade_susdeCollateral_leverage_link();
    }

    function test_trade_susdeCollateral_leverage_aave() public {
        check_trade_susdeCollateral_leverage_aave();
    }

    function test_trade_susdeCollateral_leverage_crv() public {
        check_trade_susdeCollateral_leverage_crv();
    }

    function test_trade_susdeCollateral_leverage_uni() public {
        check_trade_susdeCollateral_leverage_uni();
    }

    function test_trade_susdeCollateral_leverage_sui() public {
        check_trade_susdeCollateral_leverage_sui();
    }

    function test_trade_susdeCollateral_leverage_tia() public {
        check_trade_susdeCollateral_leverage_tia();
    }

    function test_trade_susdeCollateral_leverage_sei() public {
        check_trade_susdeCollateral_leverage_sei();
    }

    function test_trade_susdeCollateral_leverage_zro() public {
        check_trade_susdeCollateral_leverage_zro();
    }

    function test_trade_susdeCollateral_leverage_xrp() public {
        check_trade_susdeCollateral_leverage_xrp();
    }

    function test_trade_susdeCollateral_leverage_wif() public {
        check_trade_susdeCollateral_leverage_wif();
    }

    function test_trade_susdeCollateral_leverage_pepe1k() public {
        check_trade_susdeCollateral_leverage_pepe1k();
    }

    function test_trade_susdeCollateral_leverage_popcat() public {
        check_trade_susdeCollateral_leverage_popcat();
    }

    function test_trade_susdeCollateral_leverage_doge() public {
        check_trade_susdeCollateral_leverage_doge();
    }

    function test_trade_susdeCollateral_leverage_kshib() public {
        check_trade_susdeCollateral_leverage_kshib();
    }

    function test_trade_susdeCollateral_leverage_kbonk() public {
        check_trade_susdeCollateral_leverage_kbonk();
    }

    function test_trade_susdeCollateral_leverage_apt() public {
        check_trade_susdeCollateral_leverage_apt();
    }

    function test_trade_susdeCollateral_leverage_bnb() public {
        check_trade_susdeCollateral_leverage_bnb();
    }

    function test_trade_susdeCollateral_leverage_jto() public {
        check_trade_susdeCollateral_leverage_jto();
    }

    function test_trade_susdeCollateral_leverage_ada() public {
        check_trade_susdeCollateral_leverage_ada();
    }

    function test_trade_susdeCollateral_leverage_ldo() public {
        check_trade_susdeCollateral_leverage_ldo();
    }

    function test_trade_susdeCollateral_leverage_pol() public {
        check_trade_susdeCollateral_leverage_pol();
    }

    function test_trade_susdeCollateral_leverage_near() public {
        check_trade_susdeCollateral_leverage_near();
    }

    function test_trade_susdeCollateral_leverage_ftm() public {
        check_trade_susdeCollateral_leverage_ftm();
    }

    function test_trade_susdeCollateral_leverage_ena() public {
        check_trade_susdeCollateral_leverage_ena();
    }

    function test_trade_susdeCollateral_leverage_eigen() public {
        check_trade_susdeCollateral_leverage_eigen();
    }

    function test_trade_susdeCollateral_leverage_pendle() public {
        check_trade_susdeCollateral_leverage_pendle();
    }

    function test_trade_susdeCollateral_leverage_goat() public {
        check_trade_susdeCollateral_leverage_goat();
    }

    function test_trade_susdeCollateral_leverage_grass() public {
        check_trade_susdeCollateral_leverage_grass();
    }

    function test_trade_susdeCollateral_leverage_kneiro() public {
        check_trade_susdeCollateral_leverage_kneiro();
    }

    function test_trade_deusdCollateral_leverage_eth() public {
        check_trade_deusdCollateral_leverage_eth();
    }

    function test_trade_deusdCollateral_leverage_btc() public {
        check_trade_deusdCollateral_leverage_btc();
    }

    function test_trade_deusdCollateral_leverage_sol() public {
        check_trade_deusdCollateral_leverage_sol();
    }

    function test_trade_deusdCollateral_leverage_arb() public {
        check_trade_deusdCollateral_leverage_arb();
    }

    function test_trade_deusdCollateral_leverage_op() public {
        check_trade_deusdCollateral_leverage_op();
    }

    function test_trade_deusdCollateral_leverage_avax() public {
        check_trade_deusdCollateral_leverage_avax();
    }

    function test_trade_deusdCollateral_leverage_mkr() public {
        check_trade_deusdCollateral_leverage_mkr();
    }

    function test_trade_deusdCollateral_leverage_link() public {
        check_trade_deusdCollateral_leverage_link();
    }

    function test_trade_deusdCollateral_leverage_aave() public {
        check_trade_deusdCollateral_leverage_aave();
    }

    function test_trade_deusdCollateral_leverage_crv() public {
        check_trade_deusdCollateral_leverage_crv();
    }

    function test_trade_deusdCollateral_leverage_uni() public {
        check_trade_deusdCollateral_leverage_uni();
    }

    function test_trade_deusdCollateral_leverage_sui() public {
        check_trade_deusdCollateral_leverage_sui();
    }

    function test_trade_deusdCollateral_leverage_tia() public {
        check_trade_deusdCollateral_leverage_tia();
    }

    function test_trade_deusdCollateral_leverage_sei() public {
        check_trade_deusdCollateral_leverage_sei();
    }

    function test_trade_deusdCollateral_leverage_zro() public {
        check_trade_deusdCollateral_leverage_zro();
    }

    function test_trade_deusdCollateral_leverage_xrp() public {
        check_trade_deusdCollateral_leverage_xrp();
    }

    function test_trade_deusdCollateral_leverage_wif() public {
        check_trade_deusdCollateral_leverage_wif();
    }

    function test_trade_deusdCollateral_leverage_pepe1k() public {
        check_trade_deusdCollateral_leverage_pepe1k();
    }

    function test_trade_deusdCollateral_leverage_popcat() public {
        check_trade_deusdCollateral_leverage_popcat();
    }

    function test_trade_deusdCollateral_leverage_doge() public {
        check_trade_deusdCollateral_leverage_doge();
    }

    function test_trade_deusdCollateral_leverage_kshib() public {
        check_trade_deusdCollateral_leverage_kshib();
    }

    function test_trade_deusdCollateral_leverage_kbonk() public {
        check_trade_deusdCollateral_leverage_kbonk();
    }

    function test_trade_deusdCollateral_leverage_apt() public {
        check_trade_deusdCollateral_leverage_apt();
    }

    function test_trade_deusdCollateral_leverage_bnb() public {
        check_trade_deusdCollateral_leverage_bnb();
    }

    function test_trade_deusdCollateral_leverage_jto() public {
        check_trade_deusdCollateral_leverage_jto();
    }

    function test_trade_deusdCollateral_leverage_ada() public {
        check_trade_deusdCollateral_leverage_ada();
    }

    function test_trade_deusdCollateral_leverage_ldo() public {
        check_trade_deusdCollateral_leverage_ldo();
    }

    function test_trade_deusdCollateral_leverage_pol() public {
        check_trade_deusdCollateral_leverage_pol();
    }

    function test_trade_deusdCollateral_leverage_near() public {
        check_trade_deusdCollateral_leverage_near();
    }

    function test_trade_deusdCollateral_leverage_ftm() public {
        check_trade_deusdCollateral_leverage_ftm();
    }

    function test_trade_deusdCollateral_leverage_ena() public {
        check_trade_deusdCollateral_leverage_ena();
    }

    function test_trade_deusdCollateral_leverage_eigen() public {
        check_trade_deusdCollateral_leverage_eigen();
    }

    function test_trade_deusdCollateral_leverage_pendle() public {
        check_trade_deusdCollateral_leverage_pendle();
    }

    function test_trade_deusdCollateral_leverage_goat() public {
        check_trade_deusdCollateral_leverage_goat();
    }

    function test_trade_deusdCollateral_leverage_grass() public {
        check_trade_deusdCollateral_leverage_grass();
    }

    function test_trade_deusdCollateral_leverage_kneiro() public {
        check_trade_deusdCollateral_leverage_kneiro();
    }

    function test_trade_sdeusdCollateral_leverage_eth() public {
        check_trade_sdeusdCollateral_leverage_eth();
    }

    function test_trade_sdeusdCollateral_leverage_btc() public {
        check_trade_sdeusdCollateral_leverage_btc();
    }

    function test_trade_sdeusdCollateral_leverage_sol() public {
        check_trade_sdeusdCollateral_leverage_sol();
    }

    function test_trade_sdeusdCollateral_leverage_arb() public {
        check_trade_sdeusdCollateral_leverage_arb();
    }

    function test_trade_sdeusdCollateral_leverage_op() public {
        check_trade_sdeusdCollateral_leverage_op();
    }

    function test_trade_sdeusdCollateral_leverage_avax() public {
        check_trade_sdeusdCollateral_leverage_avax();
    }

    function test_trade_sdeusdCollateral_leverage_mkr() public {
        check_trade_sdeusdCollateral_leverage_mkr();
    }

    function test_trade_sdeusdCollateral_leverage_link() public {
        check_trade_sdeusdCollateral_leverage_link();
    }

    function test_trade_sdeusdCollateral_leverage_aave() public {
        check_trade_sdeusdCollateral_leverage_aave();
    }

    function test_trade_sdeusdCollateral_leverage_crv() public {
        check_trade_sdeusdCollateral_leverage_crv();
    }

    function test_trade_sdeusdCollateral_leverage_uni() public {
        check_trade_sdeusdCollateral_leverage_uni();
    }

    function test_trade_sdeusdCollateral_leverage_sui() public {
        check_trade_sdeusdCollateral_leverage_sui();
    }

    function test_trade_sdeusdCollateral_leverage_tia() public {
        check_trade_sdeusdCollateral_leverage_tia();
    }

    function test_trade_sdeusdCollateral_leverage_sei() public {
        check_trade_sdeusdCollateral_leverage_sei();
    }

    function test_trade_sdeusdCollateral_leverage_zro() public {
        check_trade_sdeusdCollateral_leverage_zro();
    }

    function test_trade_sdeusdCollateral_leverage_xrp() public {
        check_trade_sdeusdCollateral_leverage_xrp();
    }

    function test_trade_sdeusdCollateral_leverage_wif() public {
        check_trade_sdeusdCollateral_leverage_wif();
    }

    function test_trade_sdeusdCollateral_leverage_pepe1k() public {
        check_trade_sdeusdCollateral_leverage_pepe1k();
    }

    function test_trade_sdeusdCollateral_leverage_popcat() public {
        check_trade_sdeusdCollateral_leverage_popcat();
    }

    function test_trade_sdeusdCollateral_leverage_doge() public {
        check_trade_sdeusdCollateral_leverage_doge();
    }

    function test_trade_sdeusdCollateral_leverage_kshib() public {
        check_trade_sdeusdCollateral_leverage_kshib();
    }

    function test_trade_sdeusdCollateral_leverage_kbonk() public {
        check_trade_sdeusdCollateral_leverage_kbonk();
    }

    function test_trade_sdeusdCollateral_leverage_apt() public {
        check_trade_sdeusdCollateral_leverage_apt();
    }

    function test_trade_sdeusdCollateral_leverage_bnb() public {
        check_trade_sdeusdCollateral_leverage_bnb();
    }

    function test_trade_sdeusdCollateral_leverage_jto() public {
        check_trade_sdeusdCollateral_leverage_jto();
    }

    function test_trade_sdeusdCollateral_leverage_ada() public {
        check_trade_sdeusdCollateral_leverage_ada();
    }

    function test_trade_sdeusdCollateral_leverage_ldo() public {
        check_trade_sdeusdCollateral_leverage_ldo();
    }

    function test_trade_sdeusdCollateral_leverage_pol() public {
        check_trade_sdeusdCollateral_leverage_pol();
    }

    function test_trade_sdeusdCollateral_leverage_near() public {
        check_trade_sdeusdCollateral_leverage_near();
    }

    function test_trade_sdeusdCollateral_leverage_ftm() public {
        check_trade_sdeusdCollateral_leverage_ftm();
    }

    function test_trade_sdeusdCollateral_leverage_ena() public {
        check_trade_sdeusdCollateral_leverage_ena();
    }

    function test_trade_sdeusdCollateral_leverage_eigen() public {
        check_trade_sdeusdCollateral_leverage_eigen();
    }

    function test_trade_sdeusdCollateral_leverage_pendle() public {
        check_trade_sdeusdCollateral_leverage_pendle();
    }

    function test_trade_sdeusdCollateral_leverage_goat() public {
        check_trade_sdeusdCollateral_leverage_goat();
    }

    function test_trade_sdeusdCollateral_leverage_grass() public {
        check_trade_sdeusdCollateral_leverage_grass();
    }

    function test_trade_sdeusdCollateral_leverage_kneiro() public {
        check_trade_sdeusdCollateral_leverage_kneiro();
    }

    function test_trade_rseliniCollateral_leverage_eth() public {
        check_trade_rseliniCollateral_leverage_eth();
    }

    function test_trade_rseliniCollateral_leverage_btc() public {
        check_trade_rseliniCollateral_leverage_btc();
    }

    function test_trade_rseliniCollateral_leverage_sol() public {
        check_trade_rseliniCollateral_leverage_sol();
    }

    function test_trade_rseliniCollateral_leverage_arb() public {
        check_trade_rseliniCollateral_leverage_arb();
    }

    function test_trade_rseliniCollateral_leverage_op() public {
        check_trade_rseliniCollateral_leverage_op();
    }

    function test_trade_rseliniCollateral_leverage_avax() public {
        check_trade_rseliniCollateral_leverage_avax();
    }

    function test_trade_rseliniCollateral_leverage_mkr() public {
        check_trade_rseliniCollateral_leverage_mkr();
    }

    function test_trade_rseliniCollateral_leverage_link() public {
        check_trade_rseliniCollateral_leverage_link();
    }

    function test_trade_rseliniCollateral_leverage_aave() public {
        check_trade_rseliniCollateral_leverage_aave();
    }

    function test_trade_rseliniCollateral_leverage_crv() public {
        check_trade_rseliniCollateral_leverage_crv();
    }

    function test_trade_rseliniCollateral_leverage_uni() public {
        check_trade_rseliniCollateral_leverage_uni();
    }

    function test_trade_rseliniCollateral_leverage_sui() public {
        check_trade_rseliniCollateral_leverage_sui();
    }

    function test_trade_rseliniCollateral_leverage_tia() public {
        check_trade_rseliniCollateral_leverage_tia();
    }

    function test_trade_rseliniCollateral_leverage_sei() public {
        check_trade_rseliniCollateral_leverage_sei();
    }

    function test_trade_rseliniCollateral_leverage_zro() public {
        check_trade_rseliniCollateral_leverage_zro();
    }

    function test_trade_rseliniCollateral_leverage_xrp() public {
        check_trade_rseliniCollateral_leverage_xrp();
    }

    function test_trade_rseliniCollateral_leverage_wif() public {
        check_trade_rseliniCollateral_leverage_wif();
    }

    function test_trade_rseliniCollateral_leverage_pepe1k() public {
        check_trade_rseliniCollateral_leverage_pepe1k();
    }

    function test_trade_rseliniCollateral_leverage_popcat() public {
        check_trade_rseliniCollateral_leverage_popcat();
    }

    function test_trade_rseliniCollateral_leverage_doge() public {
        check_trade_rseliniCollateral_leverage_doge();
    }

    function test_trade_rseliniCollateral_leverage_kshib() public {
        check_trade_rseliniCollateral_leverage_kshib();
    }

    function test_trade_rseliniCollateral_leverage_kbonk() public {
        check_trade_rseliniCollateral_leverage_kbonk();
    }

    function test_trade_rseliniCollateral_leverage_apt() public {
        check_trade_rseliniCollateral_leverage_apt();
    }

    function test_trade_rseliniCollateral_leverage_bnb() public {
        check_trade_rseliniCollateral_leverage_bnb();
    }

    function test_trade_rseliniCollateral_leverage_jto() public {
        check_trade_rseliniCollateral_leverage_jto();
    }

    function test_trade_rseliniCollateral_leverage_ada() public {
        check_trade_rseliniCollateral_leverage_ada();
    }

    function test_trade_rseliniCollateral_leverage_ldo() public {
        check_trade_rseliniCollateral_leverage_ldo();
    }

    function test_trade_rseliniCollateral_leverage_pol() public {
        check_trade_rseliniCollateral_leverage_pol();
    }

    function test_trade_rseliniCollateral_leverage_near() public {
        check_trade_rseliniCollateral_leverage_near();
    }

    function test_trade_rseliniCollateral_leverage_ftm() public {
        check_trade_rseliniCollateral_leverage_ftm();
    }

    function test_trade_rseliniCollateral_leverage_ena() public {
        check_trade_rseliniCollateral_leverage_ena();
    }

    function test_trade_rseliniCollateral_leverage_eigen() public {
        check_trade_rseliniCollateral_leverage_eigen();
    }

    function test_trade_rseliniCollateral_leverage_pendle() public {
        check_trade_rseliniCollateral_leverage_pendle();
    }

    function test_trade_rseliniCollateral_leverage_goat() public {
        check_trade_rseliniCollateral_leverage_goat();
    }

    function test_trade_rseliniCollateral_leverage_grass() public {
        check_trade_rseliniCollateral_leverage_grass();
    }

    function test_trade_rseliniCollateral_leverage_kneiro() public {
        check_trade_rseliniCollateral_leverage_kneiro();
    }

    function test_trade_ramberCollateral_leverage_eth() public {
        check_trade_ramberCollateral_leverage_eth();
    }

    function test_trade_ramberCollateral_leverage_btc() public {
        check_trade_ramberCollateral_leverage_btc();
    }

    function test_trade_ramberCollateral_leverage_sol() public {
        check_trade_ramberCollateral_leverage_sol();
    }

    function test_trade_ramberCollateral_leverage_arb() public {
        check_trade_ramberCollateral_leverage_arb();
    }

    function test_trade_ramberCollateral_leverage_op() public {
        check_trade_ramberCollateral_leverage_op();
    }

    function test_trade_ramberCollateral_leverage_avax() public {
        check_trade_ramberCollateral_leverage_avax();
    }

    function test_trade_ramberCollateral_leverage_mkr() public {
        check_trade_ramberCollateral_leverage_mkr();
    }

    function test_trade_ramberCollateral_leverage_link() public {
        check_trade_ramberCollateral_leverage_link();
    }

    function test_trade_ramberCollateral_leverage_aave() public {
        check_trade_ramberCollateral_leverage_aave();
    }

    function test_trade_ramberCollateral_leverage_crv() public {
        check_trade_ramberCollateral_leverage_crv();
    }

    function test_trade_ramberCollateral_leverage_uni() public {
        check_trade_ramberCollateral_leverage_uni();
    }

    function test_trade_ramberCollateral_leverage_sui() public {
        check_trade_ramberCollateral_leverage_sui();
    }

    function test_trade_ramberCollateral_leverage_tia() public {
        check_trade_ramberCollateral_leverage_tia();
    }

    function test_trade_ramberCollateral_leverage_sei() public {
        check_trade_ramberCollateral_leverage_sei();
    }

    function test_trade_ramberCollateral_leverage_zro() public {
        check_trade_ramberCollateral_leverage_zro();
    }

    function test_trade_ramberCollateral_leverage_xrp() public {
        check_trade_ramberCollateral_leverage_xrp();
    }

    function test_trade_ramberCollateral_leverage_wif() public {
        check_trade_ramberCollateral_leverage_wif();
    }

    function test_trade_ramberCollateral_leverage_pepe1k() public {
        check_trade_ramberCollateral_leverage_pepe1k();
    }

    function test_trade_ramberCollateral_leverage_popcat() public {
        check_trade_ramberCollateral_leverage_popcat();
    }

    function test_trade_ramberCollateral_leverage_doge() public {
        check_trade_ramberCollateral_leverage_doge();
    }

    function test_trade_ramberCollateral_leverage_kshib() public {
        check_trade_ramberCollateral_leverage_kshib();
    }

    function test_trade_ramberCollateral_leverage_kbonk() public {
        check_trade_ramberCollateral_leverage_kbonk();
    }

    function test_trade_ramberCollateral_leverage_apt() public {
        check_trade_ramberCollateral_leverage_apt();
    }

    function test_trade_ramberCollateral_leverage_bnb() public {
        check_trade_ramberCollateral_leverage_bnb();
    }

    function test_trade_ramberCollateral_leverage_jto() public {
        check_trade_ramberCollateral_leverage_jto();
    }

    function test_trade_ramberCollateral_leverage_ada() public {
        check_trade_ramberCollateral_leverage_ada();
    }

    function test_trade_ramberCollateral_leverage_ldo() public {
        check_trade_ramberCollateral_leverage_ldo();
    }

    function test_trade_ramberCollateral_leverage_pol() public {
        check_trade_ramberCollateral_leverage_pol();
    }

    function test_trade_ramberCollateral_leverage_near() public {
        check_trade_ramberCollateral_leverage_near();
    }

    function test_trade_ramberCollateral_leverage_ftm() public {
        check_trade_ramberCollateral_leverage_ftm();
    }

    function test_trade_ramberCollateral_leverage_ena() public {
        check_trade_ramberCollateral_leverage_ena();
    }

    function test_trade_ramberCollateral_leverage_eigen() public {
        check_trade_ramberCollateral_leverage_eigen();
    }

    function test_trade_ramberCollateral_leverage_pendle() public {
        check_trade_ramberCollateral_leverage_pendle();
    }

    function test_trade_ramberCollateral_leverage_goat() public {
        check_trade_ramberCollateral_leverage_goat();
    }

    function test_trade_ramberCollateral_leverage_grass() public {
        check_trade_ramberCollateral_leverage_grass();
    }

    function test_trade_ramberCollateral_leverage_kneiro() public {
        check_trade_ramberCollateral_leverage_kneiro();
    }
}
