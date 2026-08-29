pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SpotAccountForkCheck } from "../../reya_common/accounts/SpotAccount.fork.c.sol";
import { ICoreProxy, CollateralInfo } from "../../../src/interfaces/ICoreProxy.sol";

contract SpotAccountForkTest is ReyaForkTest, SpotAccountForkCheck {
    function test_SpotAccount_DepositWithdrawFlows() public {
        (address user,) = makeAddrAndKey("user");
        uint128 spotAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(user);

        depositMA(spotAccountId, sec.rusd, 10_000e6);
        depositMA(spotAccountId, sec.weth, 1e18);
        withdrawMA(spotAccountId, sec.rusd, 5000e6);

        CollateralInfo memory rusd = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.rusd);
        CollateralInfo memory weth = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.weth);
        assertEq(rusd.netDeposits, 5000e6);
        assertEq(weth.netDeposits, 1e18);
    }

    function test_SpotAccount_CollateralLimits() public {
        check_SpotAccount_CollateralLimits();
    }
}
