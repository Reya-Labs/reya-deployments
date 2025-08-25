pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PSlippageForkCheck } from "../../reya_common/trade/PSlippage.fork.c.sol";

contract PSlippageForkTest is ReyaForkTest, PSlippageForkCheck {
// function test_trade_slippage_eth_long() public {
//     check_trade_slippage_eth_long();
// }

// function test_trade_slippage_btc_long() public {
//     check_trade_slippage_btc_long();
// }

// function test_trade_slippage_sol_long() public {
//     check_trade_slippage_sol_long();
// }

// function test_trade_slippage_arb_long() public {
//     check_trade_slippage_arb_long();
// }

// function test_trade_slippage_op_long() public {
//     check_trade_slippage_op_long();
// }

// function test_trade_slippage_avax_long() public {
//     check_trade_slippage_avax_long();
// }

// function test_trade_slippage_mkr_long() public {
//     check_trade_slippage_mkr_long();
// }

// function test_trade_slippage_link_long() public {
//     check_trade_slippage_link_long();
// }

// function test_trade_slippage_aave_long() public {
//     check_trade_slippage_aave_long();
// }

// function test_trade_slippage_crv_long() public {
//     check_trade_slippage_crv_long();
// }

// function test_trade_slippage_uni_long() public {
//     check_trade_slippage_uni_long();
// }

// function test_trade_slippage_sui_long() public {
//     check_trade_slippage_sui_long();
// }

// function test_trade_slippage_tia_long() public {
//     check_trade_slippage_tia_long();
// }

// function test_trade_slippage_sei_long() public {
//     check_trade_slippage_sei_long();
// }

// function test_trade_slippage_zro_long() public {
//     check_trade_slippage_zro_long();
// }

// function test_trade_slippage_xrp_long() public {
//     check_trade_slippage_xrp_long();
// }

// function test_trade_slippage_wif_long() public {
//     check_trade_slippage_wif_long();
// }

// function test_trade_slippage_pepe1k_long() public {
//     check_trade_slippage_pepe1k_long();
// }

// function test_trade_slippage_popcat_long() public {
//     check_trade_slippage_popcat_long();
// }

// function test_trade_slippage_doge_long() public {
//     check_trade_slippage_doge_long();
// }

// function test_trade_slippage_kshib_long() public {
//     check_trade_slippage_kshib_long();
// }

// function test_trade_slippage_kbonk_long() public {
//     check_trade_slippage_kbonk_long();
// }

// function test_trade_slippage_apt_long() public {
//     check_trade_slippage_apt_long();
// }

// function test_trade_slippage_bnb_long() public {
//     check_trade_slippage_bnb_long();
// }

// function test_trade_slippage_jto_long() public {
//     check_trade_slippage_jto_long();
// }

// function test_trade_slippage_ada_long() public {
//     check_trade_slippage_ada_long();
// }

// function test_trade_slippage_ldo_long() public {
//     check_trade_slippage_ldo_long();
// }

// function test_trade_slippage_pol_long() public {
//     check_trade_slippage_pol_long();
// }

// function test_trade_slippage_near_long() public {
//     check_trade_slippage_near_long();
// }

// // function test_trade_slippage_ftm_long() public {
// //     check_trade_slippage_ftm_long();
// // }

// function test_trade_slippage_ena_long() public {
//     check_trade_slippage_ena_long();
// }

// function test_trade_slippage_eigen_long() public {
//     check_trade_slippage_eigen_long();
// }

// function test_trade_slippage_pendle_long() public {
//     check_trade_slippage_pendle_long();
// }

// function test_trade_slippage_goat_long() public {
//     check_trade_slippage_goat_long();
// }

// function test_trade_slippage_grass_long() public {
//     check_trade_slippage_grass_long();
// }

// function test_trade_slippage_kneiro_long() public {
//     check_trade_slippage_kneiro_long();
// }

// function test_trade_slippage_dot_long() public {
//     check_trade_slippage_dot_long();
// }

// function test_trade_slippage_ltc_long() public {
//     check_trade_slippage_ltc_long();
// }

// function test_trade_slippage_pyth_long() public {
//     check_trade_slippage_pyth_long();
// }

// function test_trade_slippage_jup_long() public {
//     check_trade_slippage_jup_long();
// }

// function test_trade_slippage_pengu_long() public {
//     check_trade_slippage_pengu_long();
// }

// function test_trade_slippage_trump_long() public {
//     check_trade_slippage_trump_long();
// }

// function test_trade_slippage_hype_long() public {
//     check_trade_slippage_hype_long();
// }

// function test_trade_slippage_virtual_long() public {
//     check_trade_slippage_virtual_long();
// }

// function test_trade_slippage_ai16z_long() public {
//     check_trade_slippage_ai16z_long();
// }

// function test_trade_slippage_aixbt_long() public {
//     check_trade_slippage_aixbt_long();
// }

// function test_trade_slippage_sonic_long() public {
//     check_trade_slippage_sonic_long();
// }

// function test_trade_slippage_fartcoin_long() public {
//     check_trade_slippage_fartcoin_long();
// }

// function test_trade_slippage_griffain_long() public {
//     check_trade_slippage_griffain_long();
// }

// function test_trade_slippage_wld_long() public {
//     check_trade_slippage_wld_long();
// }

// function test_trade_slippage_atom_long() public {
//     check_trade_slippage_atom_long();
// }

// function test_trade_slippage_ape_long() public {
//     check_trade_slippage_ape_long();
// }

// function test_trade_slippage_ton_long() public {
//     check_trade_slippage_ton_long();
// }

// function test_trade_slippage_ondo_long() public {
//     check_trade_slippage_ondo_long();
// }

// function test_trade_slippage_trx_long() public {
//     check_trade_slippage_trx_long();
// }

// function test_trade_slippage_inj_long() public {
//     check_trade_slippage_inj_long();
// }

// function test_trade_slippage_move_long() public {
//     check_trade_slippage_move_long();
// }

// function test_trade_slippage_bera_long() public {
//     check_trade_slippage_bera_long();
// }

// function test_trade_slippage_layer_long() public {
//     check_trade_slippage_layer_long();
// }

// function test_trade_slippage_tao_long() public {
//     check_trade_slippage_tao_long();
// }

// function test_trade_slippage_ip_long() public {
//     check_trade_slippage_ip_long();
// }

// function test_trade_slippage_me_long() public {
//     check_trade_slippage_me_long();
// }

// function test_trade_slippage_pump_long() public {
//     check_trade_slippage_pump_long();
// }

// function test_trade_slippage_morpho_long() public {
//     check_trade_slippage_morpho_long();
// }

// function test_trade_slippage_syrup_long() public {
//     check_trade_slippage_syrup_long();
// }

// function test_trade_slippage_aero_long() public {
//     check_trade_slippage_aero_long();
// }

// function test_trade_slippage_kaito_long() public {
//     check_trade_slippage_kaito_long();
// }

// function test_trade_slippage_zora_long() public {
//     check_trade_slippage_zora_long();
// }

// function test_trade_slippage_prove_long() public {
//     check_trade_slippage_prove_long();
// }

// function test_trade_slippage_paxg_long() public {
//     check_trade_slippage_paxg_long();
// }

// function test_trade_slippage_yzy_long() public {
//     check_trade_slippage_yzy_long();
// }

// function test_trade_slippage_xpl_long() public {
//     check_trade_slippage_xpl_long();
// }

// function test_trade_slippage_wlfi_long() public {
//     check_trade_slippage_wlfi_long();
// }

// function test_trade_slippage_eth_short() public {
//     check_trade_slippage_eth_short();
// }

// function test_trade_slippage_btc_short() public {
//     check_trade_slippage_btc_short();
// }

// function test_trade_slippage_sol_short() public {
//     check_trade_slippage_sol_short();
// }

// function test_trade_slippage_arb_short() public {
//     check_trade_slippage_arb_short();
// }

// function test_trade_slippage_op_short() public {
//     check_trade_slippage_op_short();
// }

// function test_trade_slippage_avax_short() public {
//     check_trade_slippage_avax_short();
// }

// function test_trade_slippage_mkr_short() public {
//     check_trade_slippage_mkr_short();
// }

// function test_trade_slippage_link_short() public {
//     check_trade_slippage_link_short();
// }

// function test_trade_slippage_aave_short() public {
//     check_trade_slippage_aave_short();
// }

// function test_trade_slippage_crv_short() public {
//     check_trade_slippage_crv_short();
// }

// function test_trade_slippage_uni_short() public {
//     check_trade_slippage_uni_short();
// }

// function test_trade_slippage_sui_short() public {
//     check_trade_slippage_sui_short();
// }

// function test_trade_slippage_tia_short() public {
//     check_trade_slippage_tia_short();
// }

// function test_trade_slippage_sei_short() public {
//     check_trade_slippage_sei_short();
// }

// function test_trade_slippage_zro_short() public {
//     check_trade_slippage_zro_short();
// }

// function test_trade_slippage_xrp_short() public {
//     check_trade_slippage_xrp_short();
// }

// function test_trade_slippage_wif_short() public {
//     check_trade_slippage_wif_short();
// }

// function test_trade_slippage_pepe1k_short() public {
//     check_trade_slippage_pepe1k_short();
// }

// function test_trade_slippage_popcat_short() public {
//     check_trade_slippage_popcat_short();
// }

// function test_trade_slippage_doge_short() public {
//     check_trade_slippage_doge_short();
// }

// function test_trade_slippage_kshib_short() public {
//     check_trade_slippage_kshib_short();
// }

// function test_trade_slippage_kbonk_short() public {
//     check_trade_slippage_kbonk_short();
// }

// function test_trade_slippage_apt_short() public {
//     check_trade_slippage_apt_short();
// }

// function test_trade_slippage_bnb_short() public {
//     check_trade_slippage_bnb_short();
// }

// function test_trade_slippage_jto_short() public {
//     check_trade_slippage_jto_short();
// }

// function test_trade_slippage_ada_short() public {
//     check_trade_slippage_ada_short();
// }

// function test_trade_slippage_ldo_short() public {
//     check_trade_slippage_ldo_short();
// }

// function test_trade_slippage_pol_short() public {
//     check_trade_slippage_pol_short();
// }

// function test_trade_slippage_near_short() public {
//     check_trade_slippage_near_short();
// }

// // function test_trade_slippage_ftm_short() public {
// //     check_trade_slippage_ftm_short();
// // }

// function test_trade_slippage_ena_short() public {
//     check_trade_slippage_ena_short();
// }

// function test_trade_slippage_eigen_short() public {
//     check_trade_slippage_eigen_short();
// }

// function test_trade_slippage_pendle_short() public {
//     check_trade_slippage_pendle_short();
// }

// function test_trade_slippage_goat_short() public {
//     check_trade_slippage_goat_short();
// }

// function test_trade_slippage_grass_short() public {
//     check_trade_slippage_grass_short();
// }

// function test_trade_slippage_kneiro_short() public {
//     check_trade_slippage_kneiro_short();
// }

// function test_trade_slippage_dot_short() public {
//     check_trade_slippage_dot_short();
// }

// function test_trade_slippage_ltc_short() public {
//     check_trade_slippage_ltc_short();
// }

// function test_trade_slippage_pyth_short() public {
//     check_trade_slippage_pyth_short();
// }

// function test_trade_slippage_jup_short() public {
//     check_trade_slippage_jup_short();
// }

// function test_trade_slippage_pengu_short() public {
//     check_trade_slippage_pengu_short();
// }

// function test_trade_slippage_trump_short() public {
//     check_trade_slippage_trump_short();
// }

// function test_trade_slippage_hype_short() public {
//     check_trade_slippage_hype_short();
// }

// function test_trade_slippage_virtual_short() public {
//     check_trade_slippage_virtual_short();
// }

// function test_trade_slippage_ai16z_short() public {
//     check_trade_slippage_ai16z_short();
// }

// function test_trade_slippage_aixbt_short() public {
//     check_trade_slippage_aixbt_short();
// }

// function test_trade_slippage_sonic_short() public {
//     check_trade_slippage_sonic_short();
// }

// function test_trade_slippage_fartcoin_short() public {
//     check_trade_slippage_fartcoin_short();
// }

// function test_trade_slippage_griffain_short() public {
//     check_trade_slippage_griffain_short();
// }

// function test_trade_slippage_wld_short() public {
//     check_trade_slippage_wld_short();
// }

// function test_trade_slippage_atom_short() public {
//     check_trade_slippage_atom_short();
// }

// function test_trade_slippage_ape_short() public {
//     check_trade_slippage_ape_short();
// }

// function test_trade_slippage_ton_short() public {
//     check_trade_slippage_ton_short();
// }

// function test_trade_slippage_ondo_short() public {
//     check_trade_slippage_ondo_short();
// }

// function test_trade_slippage_trx_short() public {
//     check_trade_slippage_trx_short();
// }

// function test_trade_slippage_inj_short() public {
//     check_trade_slippage_inj_short();
// }

// function test_trade_slippage_move_short() public {
//     check_trade_slippage_move_short();
// }

// function test_trade_slippage_bera_short() public {
//     check_trade_slippage_bera_short();
// }

// function test_trade_slippage_layer_short() public {
//     check_trade_slippage_layer_short();
// }

// function test_trade_slippage_tao_short() public {
//     check_trade_slippage_tao_short();
// }

// function test_trade_slippage_ip_short() public {
//     check_trade_slippage_ip_short();
// }

// function test_trade_slippage_me_short() public {
//     check_trade_slippage_me_short();
// }

// function test_trade_slippage_pump_short() public {
//     check_trade_slippage_pump_short();
// }

// function test_trade_slippage_morpho_short() public {
//     check_trade_slippage_morpho_short();
// }

// function test_trade_slippage_syrup_short() public {
//     check_trade_slippage_syrup_short();
// }

// function test_trade_slippage_aero_short() public {
//     check_trade_slippage_aero_short();
// }

// function test_trade_slippage_kaito_short() public {
//     check_trade_slippage_kaito_short();
// }

// function test_trade_slippage_zora_short() public {
//     check_trade_slippage_zora_short();
// }

// function test_trade_slippage_prove_short() public {
//     check_trade_slippage_prove_short();
// }

// function test_trade_slippage_paxg_short() public {
//     check_trade_slippage_paxg_short();
// }

// function test_trade_slippage_yzy_short() public {
//     check_trade_slippage_yzy_short();
// }

// function test_trade_slippage_xpl_short() public {
//     check_trade_slippage_xpl_short();
// }

// function test_trade_slippage_wlfi_short() public {
//     check_trade_slippage_wlfi_short();
// }
}
