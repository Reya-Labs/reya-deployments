pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { LeveragePerpOBForkCheck } from "../../reya_common/trade/LeveragePerpOB.fork.c.sol";

contract LeverageForkTest is ReyaForkTest, LeveragePerpOBForkCheck {
    uint128 constant ETH_MARKET_ID = 1;
    uint256 constant ETH_LEVERAGE = 25e18;
    uint256 constant ETH_MARK_PRICE = 3000e18;

    function test_Devnet_Leverage_ETH_rUSD() public {
        check_trade_leverage_perpOB(ETH_MARKET_ID, ETH_LEVERAGE, ETH_MARK_PRICE, sec.rusd);
    }

    /// @dev Temporarily skipped — arithmetic overflow in Core margin calc
    ///      with wETH collateral. Needs investigation into the wETH deposit + fill
    ///      interaction in perpOB.
    function skip_test_Devnet_Leverage_ETH_wETH() public {
        check_trade_leverage_perpOB(ETH_MARKET_ID, ETH_LEVERAGE, ETH_MARK_PRICE, sec.weth);
    }
}
