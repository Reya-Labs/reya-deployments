pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

contract OrderForkTest is ReyaForkTest {
    function setUp() public override { }

    function test_SignedFill_ETH() public {
        check_PerpExecuteFill(1);
    }

    function test_SignedFill_BTC() public {
        check_PerpExecuteFill(2);
    }

    function test_SignedFillMetadataBinding_ETH() public {
        check_PerpFillMetadataBinding(1);
    }

    function test_SignedFillNonceReplay_ETH() public {
        check_PerpFillNonceReplay(1);
    }

    function test_SignedFillBatch_ETH() public {
        check_PerpBatchExecuteFill(1);
    }

    function test_SignedFillClose_ETH() public {
        check_PerpFillClosePosition(1);
    }

    function test_SignedFillFees_ETH() public {
        check_PerpFillFees(1);
    }

    function test_SignedFillInsufficientMargin_ETH() public {
        check_PerpFillInsufficientMargin(1);
    }

    function test_SignedFillReduceOnly_ETH() public {
        check_PerpFillReduceOnly(1);
    }

    function test_SignedFillRejectsStaleMark_ETH() public {
        check_PerpMarkPriceStaleness(1);
    }

    function test_SignedFillMarkImpactsMargin_ETH() public {
        check_PerpMarkPriceImpactsMargin(1);
    }
}
