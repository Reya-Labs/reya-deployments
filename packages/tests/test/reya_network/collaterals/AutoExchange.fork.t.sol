pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { AutoExchangeForkCheck } from "../../reya_common/collaterals/AutoExchange.fork.c.sol";

contract AutoExchangeForkTest is ReyaForkTest, AutoExchangeForkCheck {
    function test_AutoExchangeWeth_WhenUserHasOnlyWeth() public {
        check_AutoExchangeWeth_WhenUserHasOnlyWeth();
    }

    function test_AutoExchangeWeth_WhenUserHasBothWethAndRusd() public {
        check_AutoExchangeWeth_WhenUserHasBothWethAndRusd();
    }

    function test_AutoExchangeUSDe_WhenUserHasOnlyUsde() public {
        check_AutoExchangeUSDe_WhenUserHasOnlyUsde();
    }

    function test_AutoExchangeUSDe_WhenUserHasBothUsdeAndRusd() public {
        check_AutoExchangeUSDe_WhenUserHasBothUsdeAndRusd();
    }

    function test_AutoExchangeSUSDe_WhenUserHasOnlySusde() public {
        check_AutoExchangeSUSDe_WhenUserHasOnlySusde();
    }

    function test_AutoExchangeSUSDe_WhenUserHasBothSusdeAndRusd() public {
        check_AutoExchangeSUSDe_WhenUserHasBothSusdeAndRusd();
    }

    function test_AutoExchangeDEUSD_WhenUserHasOnlyDeusd() public {
        check_AutoExchangeDeusd_WhenUserHasOnlyDeusd();
    }

    function test_AutoExchangeDEUSD_WhenUserHasBothDeusdAndRusd() public {
        check_AutoExchangeDeusd_WhenUserHasBothDeusdAndRusd();
    }

    function test_AutoExchangeSDEUSD_WhenUserHasOnlySdeusd() public {
        check_AutoExchangeSdeusd_WhenUserHasOnlySdeusd();
    }

    function test_AutoExchangeSDEUSD_WhenUserHasBothSdeusdAndRusd() public {
        check_AutoExchangeSdeusd_WhenUserHasBothSdeusdAndRusd();
    }

    function test_Cronos_AutoExchangeRSELINI_WhenUserHasOnlyRselini() public {
        check_AutoExchangeRselini_WhenUserHasOnlyRselini();
    }

    function test_Cronos_AutoExchangeRSELINI_WhenUserHasBothRseliniAndRusd() public {
        check_AutoExchangeRselini_WhenUserHasBothRseliniAndRusd();
    }

    function test_Cronos_AutoExchangeRAMBER_WhenUserHasOnlyRamber() public {
        check_AutoExchangeRamber_WhenUserHasOnlyRamber();
    }

    function test_Cronos_AutoExchangeRAMBER_WhenUserHasBothRamberAndRusd() public {
        check_AutoExchangeRamber_WhenUserHasBothRamberAndRusd();
    }

    function test_Cronos_AutoExchangeSRUSD_WhenUserHasOnlySrusd() public {
        check_AutoExchangeSrusd_WhenUserHasOnlySrusd();
    }

    function test_Cronos_AutoExchangeSRUSD_WhenUserHasBothSrusdAndRusd() public {
        check_AutoExchangeSrusd_WhenUserHasBothSrusdAndRusd();
    }
}
