pragma solidity >=0.8.19 <0.9.0;

import { OrderDetails } from "../../src/interfaces/IOrdersGatewayProxyV2.sol";

library OrderDetailsHashing {
    bytes32 private constant _ORDER_DETAILS_TYPEHASH = keccak256(
        //solhint-disable-next-line max-line-length
        "OrderDetails(uint128 accountId,uint128 marketId,uint128 exchangeId,uint8 orderType,int256 quantity,uint256 limitPrice,uint256 triggerPrice,uint8 timeInForce,uint64 clientOrderId,bool reduceOnly,uint256 expiresAfter,address signer,uint256 nonce)"
    );

    bytes32 private constant _ORDER_TYPEHASH = keccak256(
        //solhint-disable-next-line max-line-length
        "Order(uint256 verifyingChainId,uint256 deadline,OrderDetails order)OrderDetails(uint128 accountId,uint128 marketId,uint128 exchangeId,uint8 orderType,int256 quantity,uint256 limitPrice,uint256 triggerPrice,uint8 timeInForce,uint64 clientOrderId,bool reduceOnly,uint256 expiresAfter,address signer,uint256 nonce)"
    );

    function mockCalculateDigest(
        OrderDetails memory order,
        uint256 deadline,
        address orderGateway
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 EIP712_REVISION_HASH = keccak256("1");
        bytes32 EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");

        bytes32 hashedMessage = keccak256(abi.encode(_ORDER_TYPEHASH, block.chainid, deadline, hashOrderDetails(order)));

        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    keccak256(
                        abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes("Reya")), EIP712_REVISION_HASH, orderGateway)
                    ),
                    hashedMessage
                )
            );
        }
        return digest;
    }

    function hashOrderDetails(OrderDetails memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _ORDER_DETAILS_TYPEHASH,
                order.accountId,
                order.marketId,
                order.exchangeId,
                uint8(order.orderType),
                order.quantity,
                order.limitPrice,
                order.triggerPrice,
                order.timeInForce,
                order.clientOrderId,
                order.reduceOnly,
                order.expiresAfter,
                order.signer,
                order.nonce
            )
        );
    }
}
