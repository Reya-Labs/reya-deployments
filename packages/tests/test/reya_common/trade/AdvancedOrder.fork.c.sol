pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import {
    IOrdersGatewayProxy,
    ConditionalOrderDetails,
    EIP712Signature as OG_EIP712Signature,
    MatchOrderDetails,
    AccountAdvancedOrders,
    AdvancedOrder
} from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";
import { ICoreProxy, EIP712Signature as Core_EIP712Signature } from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

struct LocalState {
    IOrdersGatewayProxy og;
    address user;
    uint256 userPrivateKey;
    uint256 nonce;
    uint128 accountId;
    uint128 orderMarketId1;
    SD59x18 orderBaseBefore1;
    SD59x18 orderBase1;
    UD60x18 orderPriceLimit1;
    bool isReduceOnly;
    // mark true if testing what happens if isReduceOnly is falsely set to true
    bool isNotReduceOnlyImplicit;
}

contract AdvancedOrderForkCheck is BaseReyaForkTest {
    bytes32 internal constant MATCH_ORDER = keccak256(bytes("MATCH_ORDER"));
    bytes32 internal constant _ADVANCED_ORDER_EXECUTION_FEATURE_FLAG = keccak256(bytes("advanced_orders"));
    UD60x18 MIN_PRICE = ud(0);
    UD60x18 MAX_PRICE = ud(type(uint256).max);
    LocalState internal st;

    constructor() {
        vm.prank(sec.multisig);
        IOrdersGatewayProxy(sec.ordersGateway).setFeatureFlagAllowAll(_ADVANCED_ORDER_EXECUTION_FEATURE_FLAG, true);
    }

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

    function executeOrderAndTriggerAdvancedOrder() internal {
        st.og = IOrdersGatewayProxy(sec.ordersGateway);
        (st.user, st.userPrivateKey) = makeAddrAndKey("user");

        // create and deposit into new margin account
        st.accountId = createAccountAndDeposit();

        // execute trade
        executeCoreMatchOrder({
            marketId: st.orderMarketId1,
            sender: st.user,
            base: st.orderBaseBefore1,
            priceLimit: SD59x18.unwrap(st.orderBaseBefore1) > 0 ? MAX_PRICE : MIN_PRICE,
            accountId: st.accountId
        });

        // check base before SL/TP order
        assertEq(
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base,
            st.orderBaseBefore1.unwrap()
        );

        // build the advanced order and its signature
        AccountAdvancedOrders[] memory inputs;
        {
            // build the counterparty account ids
            uint128[] memory counterpartyAccountIds = new uint128[](1);
            counterpartyAccountIds[0] = sec.passivePoolAccountId;

            inputs = new AccountAdvancedOrders[](1);
            AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](1);
            advancedOrders[0] = AdvancedOrder({
                isReduceOnly: st.isReduceOnly,
                matchOrder: MatchOrderDetails({
                    marketId: st.orderMarketId1,
                    exchangeId: 0,
                    counterpartyAccountIds: counterpartyAccountIds,
                    baseDelta: st.orderBase1.unwrap(),
                    priceLimit: st.orderPriceLimit1.unwrap()
                })
            });
            inputs[0] = AccountAdvancedOrders({ accountId: st.accountId, advancedOrders: advancedOrders });
        }

        // assert that the OG contract does not have the permission
        assertFalse(ICoreProxy(sec.core).isAuthorizedForAccount(st.accountId, MATCH_ORDER, address(st.og)));

        // generate the EIP712 signature and execute the SL order
        vm.prank(st.user);
        st.og.executeOrders(st.user, inputs);

        // check base after close order
        if (!st.isReduceOnly || st.isNotReduceOnlyImplicit) {
            // execution skipped
            assertEq(
                IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base,
                st.orderBaseBefore1.unwrap(),
                "check base after close order"
            );
        } else {
            assertEq(
                IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base,
                st.orderBaseBefore1.unwrap() + st.orderBase1.unwrap(),
                "check base after close order"
            );
        }
    }

    function check_fullCloseOrderOnShortPosition() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;

            st.orderMarketId1 = i;
            st.orderBaseBefore1 = sd(-1e18);
            st.orderBase1 = sd(1e18);
            st.isReduceOnly = true;
            st.orderPriceLimit1 = MAX_PRICE;

            executeOrderAndTriggerAdvancedOrder();
        }
    }

    function check_partialCloseOrderOnShortPosition() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;

            st.orderMarketId1 = i;
            st.orderBaseBefore1 = sd(-2e18);
            st.orderBase1 = sd(1e18);
            st.orderPriceLimit1 = MAX_PRICE;
            st.isReduceOnly = true;

            executeOrderAndTriggerAdvancedOrder();
        }
    }

    function check_fullCloseOrderOnLongPosition() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;

            st.orderMarketId1 = i;
            st.orderBaseBefore1 = sd(1e18);
            st.orderBase1 = sd(-1e18);
            st.orderPriceLimit1 = MIN_PRICE;
            st.isReduceOnly = true;

            executeOrderAndTriggerAdvancedOrder();
        }
    }

    function check_partialCloseOrderOnLongPosition() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;

            st.orderMarketId1 = i;
            st.orderBaseBefore1 = sd(2e18);
            st.orderBase1 = sd(-1e18);
            st.orderPriceLimit1 = MIN_PRICE;
            st.isReduceOnly = true;

            executeOrderAndTriggerAdvancedOrder();
        }
    }

    function check_NotReduceOnlyOrderSkipped() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;

            st.orderMarketId1 = i;
            st.orderBaseBefore1 = sd(1e18);
            st.orderBase1 = sd(-0.5e18);
            st.orderPriceLimit1 = MIN_PRICE;
            st.isReduceOnly = false;

            executeOrderAndTriggerAdvancedOrder();
        }
    }

    function check_NotReduceOnlyOrderThatFlipsShortIsSkipped() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;

            st.orderMarketId1 = i;
            st.orderBaseBefore1 = sd(1e18);
            st.orderBase1 = sd(-1.5e18); // flips
            st.orderPriceLimit1 = MIN_PRICE;
            st.isReduceOnly = true;
            st.isNotReduceOnlyImplicit = true;

            executeOrderAndTriggerAdvancedOrder();
        }
    }

    function check_NotReduceOnlyOrderThatFlipsLongIsSkipped() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;

            st.orderMarketId1 = i;
            st.orderBaseBefore1 = sd(-1e18);
            st.orderBase1 = sd(1.5e18); // flips
            st.orderPriceLimit1 = MAX_PRICE;
            st.isReduceOnly = true;
            st.isNotReduceOnlyImplicit = true;

            executeOrderAndTriggerAdvancedOrder();
        }
    }

    function check_NotReduceOnlyOrderThatExtendsLongIsSkipped() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;

            st.orderMarketId1 = i;
            st.orderBaseBefore1 = sd(1e18);
            st.orderBase1 = sd(1.5e18); // extend
            st.orderPriceLimit1 = MAX_PRICE;
            st.isReduceOnly = true;
            st.isNotReduceOnlyImplicit = true;

            executeOrderAndTriggerAdvancedOrder();
        }
    }

    function check_NotReduceOnlyOrderThatExtendsShortIsSkipped() public {
        mockFreshPrices();

        uint128 lastMarketId = ICoreProxy(sec.core).getLastCreatedMarketId();

        for (uint128 i = 1; i <= lastMarketId; i++) {
            st.nonce = i;

            st.orderMarketId1 = i;
            st.orderBaseBefore1 = sd(-1e18);
            st.orderBase1 = sd(-1.5e18); // extend
            st.orderPriceLimit1 = MIN_PRICE;
            st.isReduceOnly = true;
            st.isNotReduceOnlyImplicit = true;

            executeOrderAndTriggerAdvancedOrder();
        }
    }
}
