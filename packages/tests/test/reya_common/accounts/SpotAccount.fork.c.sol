pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ICoreProxy, CollateralInfo, Command } from "../../../src/interfaces/ICoreProxy.sol";
import { sd } from "@prb/math/SD59x18.sol";
import { ud } from "@prb/math/UD60x18.sol";

contract SpotAccountForkCheck is BaseReyaForkTest {
    function check_SpotAccount_Flows() public {
        (address user,) = makeAddrAndKey("user");
        uint128 spotAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(user);

        // deposit 10000 rUSD into spot account
        {
            depositMA(spotAccountId, sec.rusd, 10_000e6);

            CollateralInfo memory collateralInfo = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.rusd);
            assertEq(collateralInfo.netDeposits, 10_000e6);
        }

        // deposit 500 rUSD into spot account
        {
            depositMA(spotAccountId, sec.rusd, 500e6);

            CollateralInfo memory collateralInfo = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.rusd);
            assertEq(collateralInfo.netDeposits, 10_500e6);
        }

        // deposit 1 wETH into spot account
        {
            depositMA(spotAccountId, sec.weth, 1e18);

            CollateralInfo memory collateralInfo = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.weth);
            assertEq(collateralInfo.netDeposits, 1e18);
        }

        // withdraw 5000 rUSD from spot account
        {
            withdrawMA(spotAccountId, sec.rusd, 5000e6);

            CollateralInfo memory collateralInfo = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.rusd);
            assertEq(collateralInfo.netDeposits, 5500e6);
        }

        // transfer between margin accounts
        uint128 mainAccountId = ICoreProxy(sec.core).getOwnerMainAccountId(user);

        // transfer 200 rUSD from spot account to main account
        {
            transferBetweenMAs(spotAccountId, mainAccountId, sec.rusd, 200e6);

            CollateralInfo memory collateralInfo = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.rusd);
            assertEq(collateralInfo.netDeposits, 5300e6);

            collateralInfo = ICoreProxy(sec.core).getCollateralInfo(mainAccountId, sec.rusd);
            assertEq(collateralInfo.netDeposits, 200e6);
        }

        // transfer 1 wETH from spot account to main account
        {
            transferBetweenMAs(spotAccountId, mainAccountId, sec.weth, 1e18);

            CollateralInfo memory collateralInfo = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.weth);
            assertEq(collateralInfo.netDeposits, 0);

            collateralInfo = ICoreProxy(sec.core).getCollateralInfo(mainAccountId, sec.weth);
            assertEq(collateralInfo.netDeposits, 1e18);
        }

        // transfer 0.3 wETH from main account to spot account
        {
            transferBetweenMAs(mainAccountId, spotAccountId, sec.weth, 0.3e18);

            CollateralInfo memory collateralInfo = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.weth);
            assertEq(collateralInfo.netDeposits, 0.3e18);

            collateralInfo = ICoreProxy(sec.core).getCollateralInfo(mainAccountId, sec.weth);
            assertEq(collateralInfo.netDeposits, 0.7e18);
        }
    }

    function check_SpotAccount_CollateralLimits() public {
        (address user,) = makeAddrAndKey("user");
        uint128 spotAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(user);

        depositMA(spotAccountId, sec.weth, 100_000_000e18);
    }

    function check_PerpTradingOnSpotAccount() public {
        mockFreshPrices();

        (address user,) = makeAddrAndKey("user");
        uint128 spotAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(user);
        uint128 mainAccountId = ICoreProxy(sec.core).getOwnerMainAccountId(user);

        Command[] memory commands = new Command[](1);
        commands[0] = getMatchOrderCoreCommand(1, sd(1e18), ud(1_000_000e18));

        // perp trades work on normal accounts
        depositMA(mainAccountId, sec.rusd, 10_000e6);
        vm.prank(user);
        ICoreProxy(sec.core).execute(mainAccountId, commands);

        // perp trades are not allowed on spot accounts
        depositMA(spotAccountId, sec.rusd, 10_000e6);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(ICoreProxy.SpotAccount.selector, spotAccountId));
        ICoreProxy(sec.core).execute(spotAccountId, commands);
    }

    function check_UniqueSpotAccountPerUser() public {
        (address user,) = makeAddrAndKey("user");
        uint128 spotAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(user);
        assertEq(spotAccountId, ICoreProxy(sec.core).createOrGetSpotAccount(user));
    }
}
