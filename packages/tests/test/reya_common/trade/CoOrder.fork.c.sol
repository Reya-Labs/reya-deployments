pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import {
    IOrdersGatewayProxy,
    ConditionalOrderDetails,
    EIP712Signature as OG_EIP712Signature
} from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";
import {
    ICoreProxy,
    EIP712Signature as Core_EIP712Signature,
    Command as Command_Core,
    CommandType
} from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { ConditionalOrderHashing } from "../../../src/utils/ConditionalOrderHashing.sol";
import { GrantAccountPermissionHashing } from "../../../src/utils/GrantAccountPermissionHashing.sol";
import { RevokeAccountPermissionHashing } from "../../../src/utils/RevokeAccountPermissionHashing.sol";
import {
    StorkSignedPayload,
    StorkPricePayload,
    IOracleAdaptersProxy
} from "../../../src/interfaces/IOracleAdaptersProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

struct LocalState {
    IOrdersGatewayProxy og;
    address user;
    uint256 userPrivateKey;
    uint256 nonce;
    uint128 accountId;
    uint128 orderMarketId1;
    SD59x18 prevPositionBase;
    SD59x18 orderBase1;
    UD60x18 orderPriceLimit1;
    bool coOrder1IsLongOrder; // irrelevant for Limit order
    UD60x18 coOrder1TriggerPrice;
    UD60x18 coOrder1PriceLimit; // irrelevant for Limit order
    uint8 coOrder1Type;
    bool noExecution;
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

    function executeOrderAndTriggerCoOrder()
        internal
        returns (ConditionalOrderDetails memory, OG_EIP712Signature memory)
    {
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

        if (st.coOrder1Type == 3 || st.coOrder1Type == 4) {
            executeCoreMatchOrder({
                marketId: st.orderMarketId1,
                sender: st.user,
                base: st.prevPositionBase,
                priceLimit: st.orderPriceLimit1,
                accountId: st.accountId
            });

            // check base before SL/TP order
            assertEq(
                IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base,
                st.prevPositionBase.unwrap(),
                "previous position base"
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

            if (st.coOrder1Type == 3 || st.coOrder1Type == 4) {
                inputs = abi.encode(st.orderBase1, st.coOrder1PriceLimit);
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

        if (st.noExecution) {
            return (co, coSig);
        }

        // generate the EIP712 signature and execute the SL order
        vm.prank(sec.coExecutionBot);
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

        if (st.coOrder1Type == 3 || st.coOrder1Type == 4) {
            assertEq(
                IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(st.orderMarketId1, st.accountId).base,
                st.orderBase1.unwrap() + st.prevPositionBase.unwrap(),
                "balance post order"
            );
        }

        return (co, coSig);
    }

    function check_slOrderOnShortPosition(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.orderBase1 = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE;

        st.coOrder1Type = 0;
        st.coOrder1IsLongOrder = true;
        st.coOrder1TriggerPrice = MIN_PRICE;
        st.coOrder1PriceLimit = MAX_PRICE;

        executeOrderAndTriggerCoOrder();
    }

    function check_slOrderOnLongPosition(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.orderBase1 = sd(1e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.coOrder1Type = 0;
        st.coOrder1IsLongOrder = false;
        st.coOrder1TriggerPrice = MAX_PRICE;
        st.coOrder1PriceLimit = MIN_PRICE;

        executeOrderAndTriggerCoOrder();
    }

    function check_tpOrderOnShortPosition(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.orderBase1 = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE;

        st.coOrder1Type = 1;
        st.coOrder1IsLongOrder = true;
        st.coOrder1TriggerPrice = MAX_PRICE;
        st.coOrder1PriceLimit = MAX_PRICE;

        executeOrderAndTriggerCoOrder();
    }

    function check_tpOrderOnLongPosition(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.orderBase1 = sd(1e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.coOrder1Type = 1;
        st.coOrder1IsLongOrder = false;
        st.coOrder1TriggerPrice = MIN_PRICE;
        st.coOrder1PriceLimit = MIN_PRICE;

        executeOrderAndTriggerCoOrder();
    }

    function check_shortLimitOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.orderBase1 = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE; // irrelevant

        st.coOrder1Type = 2;
        st.coOrder1IsLongOrder = false; // irrelevant
        st.coOrder1TriggerPrice = MIN_PRICE;
        st.coOrder1PriceLimit = MIN_PRICE; //irrelevant

        executeOrderAndTriggerCoOrder();
    }

    function check_longLimitOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.orderBase1 = sd(1e18);
        st.coOrder1Type = 2;
        st.coOrder1TriggerPrice = MAX_PRICE;

        executeOrderAndTriggerCoOrder();
    }

    function check_extendingLongMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(1e18);
        st.orderPriceLimit1 = MAX_PRICE; // irrelevant

        st.coOrder1Type = 3;
        st.orderBase1 = sd(1e18);
        st.coOrder1PriceLimit = MAX_PRICE; //irrelevant

        executeOrderAndTriggerCoOrder();
    }

    function check_extendingShortMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE;

        st.coOrder1Type = 3;
        st.orderBase1 = sd(-1e18);
        st.coOrder1PriceLimit = MIN_PRICE;

        executeOrderAndTriggerCoOrder();
    }

    function check_flippingLongMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(1e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.coOrder1Type = 3;
        st.orderBase1 = sd(-1.5e18);
        st.coOrder1PriceLimit = MIN_PRICE;

        executeOrderAndTriggerCoOrder();
    }

    function check_flippingShortMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE; // irrelevant

        st.coOrder1Type = 3;
        st.coOrder1IsLongOrder = false; // irrelevant
        st.orderBase1 = sd(1.5e18);
        st.coOrder1PriceLimit = MAX_PRICE; //irrelevant

        executeOrderAndTriggerCoOrder();
    }

    function check_partialReduceLongMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(2e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.coOrder1Type = 4;
        st.orderBase1 = sd(-1.5e18);
        st.coOrder1PriceLimit = MIN_PRICE;

        executeOrderAndTriggerCoOrder();
    }

    function check_partialReduceShortMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(-2e18);
        st.orderPriceLimit1 = MIN_PRICE;

        st.coOrder1Type = 4;
        st.orderBase1 = sd(1.5e18);
        st.coOrder1PriceLimit = MAX_PRICE;

        executeOrderAndTriggerCoOrder();
    }

    function check_fullReduceLongMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(1e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.coOrder1Type = 4;
        st.orderBase1 = sd(-1e18);
        st.coOrder1PriceLimit = MIN_PRICE;

        executeOrderAndTriggerCoOrder();
    }

    function check_fullReduceShortMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;

        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE;

        st.coOrder1Type = 4;
        st.coOrder1IsLongOrder = false;
        st.orderBase1 = sd(1e18);
        st.coOrder1PriceLimit = MAX_PRICE;

        executeOrderAndTriggerCoOrder();
    }

    function check_revertWhenExtendingLongReduceMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;

        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(1e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.coOrder1Type = 4;
        st.coOrder1IsLongOrder = false;
        st.orderBase1 = sd(1e18);
        st.coOrder1PriceLimit = MAX_PRICE;
        st.noExecution = true;

        (ConditionalOrderDetails memory co, OG_EIP712Signature memory sig) = executeOrderAndTriggerCoOrder();

        st.og = IOrdersGatewayProxy(sec.ordersGateway);

        vm.prank(sec.coExecutionBot);
        vm.expectRevert();
        st.og.execute(co, sig);
    }

    function check_revertWhenExtendingShortReduceMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;

        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE;

        st.coOrder1Type = 4;
        st.coOrder1IsLongOrder = false;
        st.orderBase1 = sd(-1e18);
        st.coOrder1PriceLimit = MIN_PRICE;
        st.noExecution = true;

        (ConditionalOrderDetails memory co, OG_EIP712Signature memory sig) = executeOrderAndTriggerCoOrder();

        st.og = IOrdersGatewayProxy(sec.ordersGateway);

        vm.prank(sec.coExecutionBot);
        vm.expectRevert();
        st.og.execute(co, sig);
    }

    function check_revertWhenFlipLongReduceMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;

        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(1e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.coOrder1Type = 4;
        st.coOrder1IsLongOrder = false;
        st.orderBase1 = sd(-1.5e18);
        st.coOrder1PriceLimit = MIN_PRICE;
        st.noExecution = true;

        (ConditionalOrderDetails memory co, OG_EIP712Signature memory sig) = executeOrderAndTriggerCoOrder();

        st.og = IOrdersGatewayProxy(sec.ordersGateway);

        vm.prank(sec.coExecutionBot);
        vm.expectRevert();
        st.og.execute(co, sig);
    }

    function check_revertWhenFlipShortReduceMarketOrder(uint128 marketId) public {
        mockFreshPrices();

        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(-1e18);
        st.orderPriceLimit1 = MIN_PRICE;

        st.coOrder1Type = 4;
        st.coOrder1IsLongOrder = false;
        st.orderBase1 = sd(1.5e18);
        st.coOrder1PriceLimit = MAX_PRICE;
        st.noExecution = true;

        (ConditionalOrderDetails memory co, OG_EIP712Signature memory sig) = executeOrderAndTriggerCoOrder();

        st.og = IOrdersGatewayProxy(sec.ordersGateway);

        vm.prank(sec.coExecutionBot);
        vm.expectRevert();
        st.og.execute(co, sig);
    }

    function check_specialOrderGatewayPermissionToExecuteInCore() public {
        uint128[] memory counterpartyAccountIds = new uint128[](1);
        counterpartyAccountIds[0] = sec.passivePoolAccountId;
        (st.user, st.userPrivateKey) = makeAddrAndKey("user");
        uint128 accountId = createAccountAndDeposit();

        uint128 marketId = 1;

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] = Command_Core({
            commandType: uint8(CommandType.MatchOrder),
            inputs: abi.encode(counterpartyAccountIds, abi.encode(1e18, MAX_PRICE)),
            marketId: marketId,
            exchangeId: 1
        });

        mockFreshPrices();

        ICoreProxy core = ICoreProxy(sec.core);

        // it should not fail when sent from order gateway
        vm.prank(sec.ordersGateway);
        core.execute(accountId, commands);

        // it should fail when sent from random address
        vm.prank(address(277));
        vm.expectRevert(abi.encodeWithSelector(ICoreProxy.AccountPermissionDenied.selector, accountId, address(277)));
        core.execute(accountId, commands);
    }

    function check_batchExecute() public {
        mockFreshPrices();

        uint128 marketId = 1;
        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(2e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.coOrder1Type = 4;
        st.orderBase1 = sd(-1.5e18);
        st.coOrder1PriceLimit = MIN_PRICE;
        st.noExecution = true;

        (ConditionalOrderDetails memory co, OG_EIP712Signature memory sig) = executeOrderAndTriggerCoOrder();

        st.og = IOrdersGatewayProxy(sec.ordersGateway);

        ConditionalOrderDetails[] memory coList = new ConditionalOrderDetails[](1);
        coList[0] = co;

        OG_EIP712Signature[] memory sigList = new OG_EIP712Signature[](1);
        sigList[0] = sig;

        vm.prank(sec.coExecutionBot);
        (bytes[] memory outputs) = st.og.batchExecute(coList, sigList);

        assertEq(outputs.length, 1);
        assertGt(outputs[0].length, 0);
    }

    function check_updatePricesAndBatchExecute() public {
        mockFreshPrices();

        uint128 marketId = 1;
        st.nonce = marketId;
        st.orderMarketId1 = marketId;
        st.prevPositionBase = sd(2e18);
        st.orderPriceLimit1 = MAX_PRICE;

        st.coOrder1Type = 4;
        st.orderBase1 = sd(-1.5e18);
        st.coOrder1PriceLimit = MIN_PRICE;
        st.noExecution = true;

        (ConditionalOrderDetails memory co, OG_EIP712Signature memory sig) = executeOrderAndTriggerCoOrder();

        st.og = IOrdersGatewayProxy(sec.ordersGateway);

        ConditionalOrderDetails[] memory coList = new ConditionalOrderDetails[](1);
        coList[0] = co;

        OG_EIP712Signature[] memory sigList = new OG_EIP712Signature[](1);
        sigList[0] = sig;

        (address futurePublisher, uint256 futurePublisherPK) = makeAddrAndKey("futurePublisher");

        // create a StorkPricePayload and sign it
        StorkSignedPayload memory storkSignedPayload =
            createSignedPricePayload(futurePublisher, futurePublisherPK, block.timestamp);

        // authorize the publisher
        vm.prank(sec.multisig);
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).addToFeatureFlagAllowlist(
            keccak256(bytes("publishers")), futurePublisher
        );

        bytes[] memory signedOffchainDataArray = new bytes[](1);
        signedOffchainDataArray[0] = abi.encode(storkSignedPayload);

        vm.prank(sec.coExecutionBot);
        (bytes[] memory outputs) = st.og.updatePricesAndBatchExecute(signedOffchainDataArray, coList, sigList);

        assertEq(outputs.length, 1);
        assertGt(outputs[0].length, 0);

        StorkPricePayload memory existingPricePayload =
            IOracleAdaptersProxy(sec.oracleAdaptersProxy).getLatestPricePayload("ETH/USD");
        assertEq(existingPricePayload.assetPairId, "ETH/USD");
        assertEq(existingPricePayload.timestamp, block.timestamp);
        assertEq(existingPricePayload.price, 3000e18);
    }
}
