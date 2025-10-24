pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { FundingRateForkCheck } from "../../reya_common/trade/FundingRate.fork.c.sol";

contract FundingRateForkTest is ReyaForkTest, FundingRateForkCheck {
    function test_FundingVelocity_eth() public {
        check_FundingVelocity(1);
    }

    function test_FundingVelocity_btc() public {
        check_FundingVelocity(2);
    }

    function test_FundingVelocity_sol() public {
        check_FundingVelocity(3);
    }

    function test_FundingVelocity_arb() public {
        check_FundingVelocity(4);
    }

    function test_FundingVelocity_op() public {
        check_FundingVelocity(5);
    }

    function test_FundingVelocity_avax() public {
        check_FundingVelocity(6);
    }

    function test_FundingVelocity_mkr() public {
        check_FundingVelocity(7);
    }

    function test_FundingVelocity_link() public {
        check_FundingVelocity(8);
    }

    function test_FundingVelocity_aave() public {
        check_FundingVelocity(9);
    }

    function test_FundingVelocity_crv() public {
        check_FundingVelocity(10);
    }

    function test_FundingVelocity_uni() public {
        check_FundingVelocity(11);
    }

    function test_FundingVelocity_sui() public {
        check_FundingVelocity(12);
    }

    function test_FundingVelocity_tia() public {
        check_FundingVelocity(13);
    }

    function test_FundingVelocity_sei() public {
        check_FundingVelocity(14);
    }

    function test_FundingVelocity_zro() public {
        check_FundingVelocity(15);
    }

    function test_FundingVelocity_xrp() public {
        check_FundingVelocity(16);
    }

    function test_FundingVelocity_wif() public {
        check_FundingVelocity(17);
    }

    function test_FundingVelocity_pepe1k() public {
        check_FundingVelocity(18);
    }

    function test_FundingVelocity_popcat() public {
        check_FundingVelocity(19);
    }

    function test_FundingVelocity_doge() public {
        check_FundingVelocity(20);
    }

    function test_FundingVelocity_kshib() public {
        check_FundingVelocity(21);
    }

    function test_FundingVelocity_kbonk() public {
        check_FundingVelocity(22);
    }

    function test_FundingVelocity_apt() public {
        check_FundingVelocity(23);
    }

    function test_FundingVelocity_bnb() public {
        check_FundingVelocity(24);
    }

    function test_FundingVelocity_jto() public {
        check_FundingVelocity(25);
    }

    function test_FundingVelocity_ada() public {
        check_FundingVelocity(26);
    }

    function test_FundingVelocity_ldo() public {
        check_FundingVelocity(27);
    }

    // note: market paused
    // function test_FundingVelocity_pol() public {
    //     check_FundingVelocity(28);
    // }

    function test_FundingVelocity_near() public {
        check_FundingVelocity(29);
    }

    function test_FundingVelocity_ftm() public {
        check_FundingVelocity(30);
    }

    function test_FundingVelocity_ena() public {
        check_FundingVelocity(31);
    }

    function test_FundingVelocity_eigen() public {
        check_FundingVelocity(32);
    }

    function test_FundingVelocity_pendle() public {
        check_FundingVelocity(33);
    }

    function test_FundingVelocity_goat() public {
        check_FundingVelocity(34);
    }

    function test_FundingVelocity_grass() public {
        check_FundingVelocity(35);
    }

    function test_FundingVelocity_kneiro() public {
        check_FundingVelocity(36);
    }

    // note: market paused
    // function test_FundingVelocity_dot() public {
    //     check_FundingVelocity(37);
    // }

    function test_FundingVelocity_ltc() public {
        check_FundingVelocity(38);
    }

    function test_FundingVelocity_pyth() public {
        check_FundingVelocity(39);
    }

    function test_FundingVelocity_jup() public {
        check_FundingVelocity(40);
    }

    function test_FundingVelocity_pengu() public {
        check_FundingVelocity(41);
    }

    function test_FundingVelocity_trump() public {
        check_FundingVelocity(42);
    }

    function test_FundingVelocity_hype() public {
        check_FundingVelocity(43);
    }

    function test_FundingVelocity_virtual() public {
        check_FundingVelocity(44);
    }

    function test_FundingVelocity_ai16z() public {
        check_FundingVelocity(45);
    }

    // note: market paused
    // function test_FundingVelocity_aixbt() public {
    //     check_FundingVelocity(46);
    // }

    function test_FundingVelocity_sonic() public {
        check_FundingVelocity(47);
    }

    function test_FundingVelocity_fartcoin() public {
        check_FundingVelocity(48);
    }

    function test_FundingVelocity_griffain() public {
        check_FundingVelocity(49);
    }

    function test_FundingVelocity_wld() public {
        check_FundingVelocity(50);
    }

    function test_FundingVelocity_atom() public {
        check_FundingVelocity(51);
    }

    function test_FundingVelocity_ape() public {
        check_FundingVelocity(52);
    }

    function test_FundingVelocity_ton() public {
        check_FundingVelocity(53);
    }

    function test_FundingVelocity_ondo() public {
        check_FundingVelocity(54);
    }

    function test_FundingVelocity_trx() public {
        check_FundingVelocity(55);
    }

    function test_FundingVelocity_inj() public {
        check_FundingVelocity(56);
    }

    function test_FundingVelocity_move() public {
        check_FundingVelocity(57);
    }

    function test_FundingVelocity_bera() public {
        check_FundingVelocity(58);
    }

    function test_FundingVelocity_layer() public {
        check_FundingVelocity(59);
    }

    function test_FundingVelocity_tao() public {
        check_FundingVelocity(60);
    }

    function test_FundingVelocity_ip() public {
        check_FundingVelocity(61);
    }

    function test_FundingVelocity_me() public {
        check_FundingVelocity(62);
    }

    function test_FundingVelocity_pump() public {
        check_FundingVelocity(63);
    }

    function test_FundingVelocity_morpho() public {
        check_FundingVelocity(64);
    }

    function test_FundingVelocity_syrup() public {
        check_FundingVelocity(65);
    }

    function test_FundingVelocity_aero() public {
        check_FundingVelocity(66);
    }

    function test_FundingVelocity_kaito() public {
        check_FundingVelocity(67);
    }

    function test_FundingVelocity_zora() public {
        check_FundingVelocity(68);
    }

    function test_FundingVelocity_prove() public {
        check_FundingVelocity(69);
    }

    function test_FundingVelocity_paxg() public {
        check_FundingVelocity(70);
    }

    function test_FundingVelocity_yzy() public {
        check_FundingVelocity(71);
    }

    function test_FundingVelocity_xpl() public {
        check_FundingVelocity(72);
    }

    function test_FundingVelocity_wlfi() public {
        check_FundingVelocity(73);
    }

    function test_FundingVelocity_linea() public {
        check_FundingVelocity(74);
    }

    function test_FundingVelocity_mega() public {
        check_FundingVelocity(75);
    }
}
