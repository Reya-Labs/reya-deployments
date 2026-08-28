pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

contract FundingRateForkTest is ReyaForkTest {
    function setUp() public override { }

    function test_PushAndReadFundingRate_ETH() public {
        check_PushFundingRate(1);
    }

    function test_PushAndReadFundingRate_BTC() public {
        check_PushFundingRate(2);
    }

    function test_RejectsStaleFundingPayload_ETH() public {
        check_FundingRateStaleness(1);
    }

    function test_StaleFundingBlocksTrade_ETH() public {
        check_FundingRateStalenessForTrade(1);
    }

    function test_FundingAccrual_ETH() public {
        check_FundingRateAccrual(1);
    }
}
