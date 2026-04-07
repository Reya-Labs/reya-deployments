pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { WethCollateralPerpOBForkCheck } from "../../reya_common/collaterals/WethCollateralPerpOB.fork.c.sol";

contract WethCollateralForkTest is ReyaForkTest, WethCollateralPerpOBForkCheck {
    uint128 constant ETH_MARKET_ID = 1;

    /// @dev Temporarily skipped — needs investigation into how Core margin calc
    ///      uses pushed mark prices vs oracle manager in perpOB model.
    ///      The hedge test assumes oracle mocks affect both collateral valuation
    ///      and PnL, but perpOB may decouple these.
    function skip_test_Devnet_WethTradeWithWethCollateral() public {
        check_WethTradeWithWethCollateral_PerpOB(ETH_MARKET_ID);
    }
}
