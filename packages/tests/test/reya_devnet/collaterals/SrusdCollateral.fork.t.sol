pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SrusdCollateralForkCheck } from "../../reya_common/collaterals/SrusdCollateral.fork.c.sol";

/**
 * @title SrusdCollateralForkTest (Devnet)
 * @notice Fork tests for sRUSD as a collateral on devnet.
 * @dev Only `checkFuzz_SRUSDMintBurn` is wired. The other checks in
 *      `SrusdCollateralForkCheck` (`check_srusd_view_functions`,
 *      `check_srusd_cap_exceeded`, `check_srusd_deposit_withdraw`,
 *      `check_transfer_srusdCollateral`, `check_trade_srusdCollateral_*`)
 *      call `IOracleManagerProxy.process(parentCollateralConfig.oracleNodeId)`
 *      and depend on a real Stork sRUSD pricing node — devnet's
 *      `cp1Rusd_srusdParentConfig_oracleNodeId` is `0x0…000` by design
 *      (no orderbook trading planned for SRUSDRUSD on devnet, see
 *      `omnibus/reya_devnet.toml` + `devnet/collateral_pools/tokens/srusd.toml`).
 *      Re-enable the deposit/view tests once a real sRUSD oracle is wired.
 */
contract SrusdCollateralForkTest is ReyaForkTest, SrusdCollateralForkCheck {
    function testFuzz_Devnet_SRUSDMintBurn(address attacker) public {
        vm.assume(attacker != sec.pool);
        checkFuzz_SRUSDMintBurn(attacker);
    }
}
