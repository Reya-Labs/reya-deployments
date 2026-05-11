pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { WethCollateralPerpOBForkCheck } from "../../reya_common/collaterals/WethCollateralPerpOB.fork.c.sol";

contract WethCollateralForkTest is ReyaForkTest, WethCollateralPerpOBForkCheck {
    uint128 constant ETH_MARKET_ID = 1;

    function test_Devnet_WethTradeWithWethCollateral() public {
        check_WethTradeWithWethCollateral_PerpOB(ETH_MARKET_ID);
    }
}
