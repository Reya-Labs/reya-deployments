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
    uint128 accountId;
    uint128 orderMarketId1;
    SD59x18 orderBase1;
    UD60x18 orderPriceLimit1;
    bool slTpOrder1IsLongOrder;
    UD60x18 slTpOrder1TriggerPrice;
    UD60x18 slTpOrder1PriceLimit;
    uint8 slTpOrder1Type;
}

contract SlTpOrderForkCheck is BaseReyaForkTest {
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

    function executeOrderAndTriggerSlTpOrder() internal {
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

        // check base before SL order
        assertNotEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base, 0);

        // build the conditional order and its signature
        ConditionalOrderDetails memory co;
        OG_EIP712Signature memory coSig;
        {
            // build the counterparty account ids
            uint128[] memory counterpartyAccountIds = new uint128[](1);
            counterpartyAccountIds[0] = sec.passivePoolAccountId;

            // build the conditional order input
            co = ConditionalOrderDetails({
                accountId: st.accountId,
                marketId: st.orderMarketId1,
                exchangeId: 0,
                counterpartyAccountIds: counterpartyAccountIds,
                orderType: st.slTpOrder1Type,
                inputs: abi.encode(st.slTpOrder1IsLongOrder, st.slTpOrder1TriggerPrice, st.slTpOrder1PriceLimit),
                signer: st.user,
                nonce: 1
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
                st.accountId, MATCH_ORDER, sec.ordersGateway, 1, block.timestamp + 1, sec.core
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
        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base, 0);

        // revoke permission to the orders gateway for trades
        {
            bytes32 digest = RevokeAccountPermissionHashing.mockCalculateDigest(
                st.accountId, MATCH_ORDER, sec.ordersGateway, 2, block.timestamp + 1, sec.core
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(st.userPrivateKey, digest);

            Core_EIP712Signature memory sig = Core_EIP712Signature({ v: v, r: r, s: s, deadline: block.timestamp + 1 });

            ICoreProxy(sec.core).revokeAccountPermissionBySig(st.accountId, MATCH_ORDER, sec.ordersGateway, sig);
        }

        // assert that the OG contract does not have the permission after revoking it
        assertFalse(ICoreProxy(sec.core).isAuthorizedForAccount(st.accountId, MATCH_ORDER, address(st.og)));
    }

    function check_slOrderOnShortPosition_ETH() public {
        st.orderMarketId1 = 1;
        st.orderBase1 = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE;

        st.slTpOrder1Type = 0;
        st.slTpOrder1IsLongOrder = true;
        st.slTpOrder1TriggerPrice = MIN_PRICE;
        st.slTpOrder1PriceLimit = MAX_PRICE;

        executeOrderAndTriggerSlTpOrder();
    }

    function check_slOrderOnLongPosition_BTC() public {
        st.orderMarketId1 = 2;
        st.orderBase1 = sd(1e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.slTpOrder1Type = 0;
        st.slTpOrder1IsLongOrder = false;
        st.slTpOrder1TriggerPrice = MAX_PRICE;
        st.slTpOrder1PriceLimit = MIN_PRICE;

        executeOrderAndTriggerSlTpOrder();
    }

    function check_slOrderOnShortPosition_SOL() public {
        st.orderMarketId1 = 3;
        st.orderBase1 = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE;

        st.slTpOrder1Type = 0;
        st.slTpOrder1IsLongOrder = true;
        st.slTpOrder1TriggerPrice = MIN_PRICE;
        st.slTpOrder1PriceLimit = MAX_PRICE;

        executeOrderAndTriggerSlTpOrder();
    }

    function check_tpOrderOnShortPosition_ETH() public {
        st.orderMarketId1 = 1;
        st.orderBase1 = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE;

        st.slTpOrder1Type = 1;
        st.slTpOrder1IsLongOrder = true;
        st.slTpOrder1TriggerPrice = MAX_PRICE;
        st.slTpOrder1PriceLimit = MAX_PRICE;

        executeOrderAndTriggerSlTpOrder();
    }

    function check_tpOrderOnLongPosition_BTC() public {
        st.orderMarketId1 = 2;
        st.orderBase1 = sd(1e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.slTpOrder1Type = 1;
        st.slTpOrder1IsLongOrder = false;
        st.slTpOrder1TriggerPrice = MIN_PRICE;
        st.slTpOrder1PriceLimit = MIN_PRICE;

        executeOrderAndTriggerSlTpOrder();
    }

    function check_tpOrderOnShortPosition_SOL() public {
        st.orderMarketId1 = 3;
        st.orderBase1 = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE;

        st.slTpOrder1Type = 1;
        st.slTpOrder1IsLongOrder = true;
        st.slTpOrder1TriggerPrice = MAX_PRICE;
        st.slTpOrder1PriceLimit = MAX_PRICE;

        executeOrderAndTriggerSlTpOrder();
    }
}
