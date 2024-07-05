pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import {
    IOrdersGatewayProxy,
    ConditionalOrderDetails,
    EIP712Signature
} from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";
import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { mockCalculateDigest, hashConditionalOrder } from "../../../src/utils/ConditionalOrderHashing.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

struct LocalState {
    IOrdersGatewayProxy og;
    address user;
    uint256 userPrivateKey;
    uint128 accountId;
    uint128 orderMarketId1;
    SD59x18 orderBase1;
    UD60x18 orderPriceLimit1;
    bool slOrder1IsLongOrder;
    UD60x18 slOrder1TriggerPrice;
    UD60x18 slOrder1PriceLimit;
}

contract SLOrderForkCheck is BaseReyaForkTest {
    bytes32 internal constant MATCH_ORDER = keccak256(bytes("MATCH_ORDER"));
    UD60x18 MIN_PRICE = ud(0);
    UD60x18 MAX_PRICE = ud(type(uint256).max);

    LocalState internal st;

    function createAccountAndDeposit() internal returns (uint128 accountId) {
        uint256 amount = 1_000_000e6;
        deal(sec.usdc, address(sec.periphery), amount);

        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], amount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: st.user, token: address(sec.usdc) })
        );
    }

    function executeOrderAndTriggerSLOrder() internal {
        st.og = IOrdersGatewayProxy(sec.ordersGateway);
        (st.user, st.userPrivateKey) = makeAddrAndKey("user");

        // create and deposit into new margin account
        st.accountId = createAccountAndDeposit();

        // execute short trade
        executeCoreMatchOrder({
            marketId: st.orderMarketId1,
            sender: st.user,
            base: st.orderBase1,
            priceLimit: st.orderPriceLimit1,
            accountId: st.accountId
        });

        // grant permission to the orders gateway for trades
        vm.prank(st.user);
        ICoreProxy(sec.core).grantAccountPermission(st.accountId, MATCH_ORDER, address(st.og));

        // build the counterparty account ids
        uint128[] memory counterpartyAccountIds = new uint128[](1);
        counterpartyAccountIds[0] = sec.passivePoolAccountId;

        // build the conditional order input
        ConditionalOrderDetails memory co = ConditionalOrderDetails({
            accountId: st.accountId,
            marketId: st.orderMarketId1,
            exchangeId: 0,
            counterpartyAccountIds: counterpartyAccountIds,
            orderType: 0,
            inputs: abi.encode(st.slOrder1IsLongOrder, st.slOrder1TriggerPrice, st.slOrder1PriceLimit),
            signer: st.user,
            nonce: 1
        });

        // generate the EIP712 signature
        EIP712Signature memory sig;
        {
            bytes32 hash = hashConditionalOrder(co, block.timestamp + 1);
            bytes32 digest = mockCalculateDigest(hash, address(st.og));

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(st.userPrivateKey, digest);

            sig = EIP712Signature({ v: v, r: r, s: s, deadline: block.timestamp + 1 });
        }

        // check base before SL order
        assertNotEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base, 0);

        // execute the SL order
        st.og.execute(co, sig);

        // check base after SL order
        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base, 0);
    }

    function check_slOrderOnShortPosition_ETH() public {
        (st.orderMarketId1, st.orderBase1, st.orderPriceLimit1) = (1, sd(-1e18), MIN_PRICE);
        (st.slOrder1IsLongOrder, st.slOrder1TriggerPrice, st.slOrder1PriceLimit) = (true, MIN_PRICE, MAX_PRICE);

        executeOrderAndTriggerSLOrder();
    }

    function check_slOrderOnLongPosition_BTC() public {
        (st.orderMarketId1, st.orderBase1, st.orderPriceLimit1) = (2, sd(1e18), MAX_PRICE);
        (st.slOrder1IsLongOrder, st.slOrder1TriggerPrice, st.slOrder1PriceLimit) = (false, MAX_PRICE, MIN_PRICE);

        executeOrderAndTriggerSLOrder();
    }

    function check_slOrderOnShortPosition_SOL() public {
        (st.orderMarketId1, st.orderBase1, st.orderPriceLimit1) = (3, sd(-1e18), MIN_PRICE);
        (st.slOrder1IsLongOrder, st.slOrder1TriggerPrice, st.slOrder1PriceLimit) = (true, MIN_PRICE, MAX_PRICE);

        executeOrderAndTriggerSLOrder();
    }
}
