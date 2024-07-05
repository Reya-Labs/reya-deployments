pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PSlippageForkCheck } from "../../reya_common/trade/PSlippage.fork.c.sol";
import {
    IOrdersGatewayProxy,
    ConditionalOrderDetails,
    EIP712Signature
} from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";
import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";
import { mockCalculateDigest, hashConditionalOrder } from "../../../src/utils/ConditionalOrderHashing.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract SLOrderForkTest is ReyaForkTest {
    bytes32 internal constant MATCH_ORDER = keccak256(bytes("MATCH_ORDER"));

    function test_sample() public {
        IOrdersGatewayProxy og = IOrdersGatewayProxy(sec.ordersGateway);
        (address user, uint256 userPrivateKey) = makeAddrAndKey("user");

        // create and deposit into new margin account
        uint128 accountId = 0;
        {
            uint256 amount = 1_000_000e6;
            deal(sec.usdc, address(sec.periphery), amount);

            mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], amount);
            vm.prank(dec.socketExecutionHelper[sec.usdc]);
            accountId = IPeripheryProxy(sec.periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
            );
        }

        // execute short trade
        executeCoreMatchOrder({ marketId: 1, sender: user, base: sd(-1e18), priceLimit: ud(0), accountId: accountId });

        vm.prank(user);
        ICoreProxy(sec.core).grantAccountPermission(accountId, MATCH_ORDER, address(og));

        uint128[] memory counterpartyAccountIds = new uint128[](1);
        counterpartyAccountIds[0] = sec.passivePoolAccountId;

        (bool isLongOrder, UD60x18 triggerPrice, UD60x18 priceLimit) = (true, ud(0), ud(type(uint256).max));

        ConditionalOrderDetails memory co = ConditionalOrderDetails({
            accountId: accountId,
            marketId: 1,
            exchangeId: 0,
            counterpartyAccountIds: counterpartyAccountIds,
            orderType: 0,
            inputs: abi.encode(isLongOrder, triggerPrice, priceLimit),
            signer: user,
            nonce: 1
        });

        bytes32 hash = hashConditionalOrder(co, block.timestamp + 1);
        bytes32 digest = mockCalculateDigest(hash, address(og));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        EIP712Signature memory sig = EIP712Signature({ v: v, r: r, s: s, deadline: block.timestamp + 1 });

        og.execute(co, sig);
    }
}
