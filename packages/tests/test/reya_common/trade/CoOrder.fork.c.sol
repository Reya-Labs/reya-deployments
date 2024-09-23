pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import {
    IOrdersGatewayProxy,
    ConditionalOrderDetails,
    EIP712Signature as OG_EIP712Signature
} from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";
import { ICoreProxy, EIP712Signature as Core_EIP712Signature } from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { ConditionalOrderHashing } from "../../../src/utils/ConditionalOrderHashing.sol";
import { GrantAccountPermissionHashing } from "../../../src/utils/GrantAccountPermissionHashing.sol";
import { RevokeAccountPermissionHashing } from "../../../src/utils/RevokeAccountPermissionHashing.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

struct LocalState {
    IOrdersGatewayProxy og;
    address user;
    uint256 userPrivateKey;
    uint256 nonce;
    uint128 accountId;
    uint128 orderMarketId1;
    SD59x18 orderBase1;
    UD60x18 orderPriceLimit1;
    bool coOrder1IsLongOrder; // irrelevant for Limit order
    UD60x18 coOrder1TriggerPrice;
    UD60x18 coOrder1PriceLimit; // irrelevant for Limit order
    uint8 coOrder1Type;
}

contract CoOrderForkCheck is BaseReyaForkTest {
    bytes32 internal constant MATCH_ORDER = keccak256(bytes("MATCH_ORDER"));
    UD60x18 MIN_PRICE = ud(0);
    UD60x18 MAX_PRICE = ud(type(uint256).max);
    LocalState internal st;

    function setUp() public {
        removeMarketsOILimit();
    }

    function createAccountAndDeposit() internal returns (uint128 accountId) {
        uint256 amount = 1_000_000e6;
        deal(sec.usdc, address(sec.periphery), amount);

        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], amount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: st.user, token: address(sec.usdc) })
        );
    }

    function executeOrderAndTriggerCoOrder() internal {
        st.og = IOrdersGatewayProxy(sec.ordersGateway);
        (st.user, st.userPrivateKey) = makeAddrAndKey("user");

        // create and deposit into new margin account
        st.accountId = createAccountAndDeposit();

        // execute trade
        if (st.coOrder1Type == 0 || st.coOrder1Type == 1) {
            executeCoreMatchOrder({
                marketId: st.orderMarketId1,
                sender: st.user,
                base: st.orderBase1,
                priceLimit: st.orderPriceLimit1,
                accountId: st.accountId
            });

            // check base before SL/TP order
            assertEq(
                IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base,
                st.orderBase1.unwrap()
            );
        }

        if (st.coOrder1Type == 2) {
            // check base before Limit order
            assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base, 0);
        }

        // build the conditional order and its signature
        ConditionalOrderDetails memory co;
        OG_EIP712Signature memory coSig;
        {
            // build the counterparty account ids
            uint128[] memory counterpartyAccountIds = new uint128[](1);
            counterpartyAccountIds[0] = sec.passivePoolAccountId;

            bytes memory inputs;
            if (st.coOrder1Type == 0 || st.coOrder1Type == 1) {
                inputs = abi.encode(st.coOrder1IsLongOrder, st.coOrder1TriggerPrice, st.coOrder1PriceLimit);
            }

            if (st.coOrder1Type == 2) {
                inputs = abi.encode(st.orderBase1, st.coOrder1TriggerPrice);
            }

            // build the conditional order input
            co = ConditionalOrderDetails({
                accountId: st.accountId,
                marketId: st.orderMarketId1,
                exchangeId: 0,
                counterpartyAccountIds: counterpartyAccountIds,
                orderType: st.coOrder1Type,
                inputs: inputs,
                signer: st.user,
                nonce: st.nonce
            });

            bytes32 digest = ConditionalOrderHashing.mockCalculateDigest(co, block.timestamp + 1, sec.ordersGateway);

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(st.userPrivateKey, digest);

            coSig = OG_EIP712Signature({ v: v, r: r, s: s, deadline: block.timestamp + 1 });
        }

        // assert that the OG contract does not have the permission
        assertFalse(ICoreProxy(sec.core).isAuthorizedForAccount(st.accountId, MATCH_ORDER, address(st.og)));

        // assert that the SL order is not executable without the permission
        vm.expectRevert();
        st.og.execute(co, coSig);

        // grant permission to the orders gateway for trades
        {
            bytes32 digest = GrantAccountPermissionHashing.mockCalculateDigest(
                st.accountId, MATCH_ORDER, sec.ordersGateway, 2 * st.nonce - 1, block.timestamp + 1, sec.core
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(st.userPrivateKey, digest);

            Core_EIP712Signature memory sig = Core_EIP712Signature({ v: v, r: r, s: s, deadline: block.timestamp + 1 });

            ICoreProxy(sec.core).grantAccountPermissionBySig(st.accountId, MATCH_ORDER, sec.ordersGateway, sig);
        }

        // assert that the OG contract does have the permission after granting it
        assertTrue(ICoreProxy(sec.core).isAuthorizedForAccount(st.accountId, MATCH_ORDER, address(st.og)));

        // generate the EIP712 signature and execute the SL order
        st.og.execute(co, coSig);

        // check base after SL order
        if (st.coOrder1Type == 0 || st.coOrder1Type == 1) {
            assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base, 0);
        }

        if (st.coOrder1Type == 2) {
            assertEq(
                IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base,
                st.orderBase1.unwrap()
            );
        }

        // revoke permission to the orders gateway for trades
        {
            bytes32 digest = RevokeAccountPermissionHashing.mockCalculateDigest(
                st.accountId, MATCH_ORDER, sec.ordersGateway, 2 * st.nonce, block.timestamp + 1, sec.core
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(st.userPrivateKey, digest);

            Core_EIP712Signature memory sig = Core_EIP712Signature({ v: v, r: r, s: s, deadline: block.timestamp + 1 });

            ICoreProxy(sec.core).revokeAccountPermissionBySig(st.accountId, MATCH_ORDER, sec.ordersGateway, sig);
        }

        // assert that the OG contract does not have the permission after revoking it
        assertFalse(ICoreProxy(sec.core).isAuthorizedForAccount(st.accountId, MATCH_ORDER, address(st.og)));
    }

    function check_slOrderOnShortPosition() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;
            st.orderMarketId1 = i;
            st.orderBase1 = sd(-1e18);
            st.orderPriceLimit1 = MIN_PRICE;

            st.coOrder1Type = 0;
            st.coOrder1IsLongOrder = true;
            st.coOrder1TriggerPrice = MIN_PRICE;
            st.coOrder1PriceLimit = MAX_PRICE;

            executeOrderAndTriggerCoOrder();
        }
    }

    function check_slOrderOnLongPosition_BTC() public {
        mockFreshPrices();

        st.orderMarketId1 = 2;
        st.orderBase1 = sd(1e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.coOrder1Type = 0;
        st.coOrder1IsLongOrder = false;
        st.coOrder1TriggerPrice = MAX_PRICE;
        st.coOrder1PriceLimit = MIN_PRICE;

        st.nonce = 1;

        executeOrderAndTriggerCoOrder();
    }

    function check_tpOrderOnShortPosition() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;
            st.orderMarketId1 = i;
            st.orderBase1 = sd(-1e18);
            st.orderPriceLimit1 = MIN_PRICE;

            st.coOrder1Type = 1;
            st.coOrder1IsLongOrder = true;
            st.coOrder1TriggerPrice = MAX_PRICE;
            st.coOrder1PriceLimit = MAX_PRICE;

            executeOrderAndTriggerCoOrder();
        }
    }

    function check_tpOrderOnLongPosition_BTC() public {
        mockFreshPrices();

        st.orderMarketId1 = 2;
        st.orderBase1 = sd(1e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.coOrder1Type = 1;
        st.coOrder1IsLongOrder = false;
        st.coOrder1TriggerPrice = MIN_PRICE;
        st.coOrder1PriceLimit = MIN_PRICE;

        st.nonce = 1;

        executeOrderAndTriggerCoOrder();
    }

    function check_shortLimitOrder() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;
            st.orderMarketId1 = i;
            st.orderBase1 = sd(-1e18);
            st.orderPriceLimit1 = MIN_PRICE; // irrelevant

            st.coOrder1Type = 2;
            st.coOrder1IsLongOrder = false; // irrelevant
            st.coOrder1TriggerPrice = MIN_PRICE;
            st.coOrder1PriceLimit = MIN_PRICE; //irrelevant

            executeOrderAndTriggerCoOrder();
        }
    }

    function check_longLimitOrder_BTC() public {
        mockFreshPrices();

        st.orderMarketId1 = 2;
        st.orderBase1 = sd(1e18);
        st.coOrder1Type = 2;
        st.coOrder1TriggerPrice = MAX_PRICE;

        st.nonce = 1;

        executeOrderAndTriggerCoOrder();
    }
}
