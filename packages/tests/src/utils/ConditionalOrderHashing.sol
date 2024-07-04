/*
Licensed under the Reya License (the "License"); you
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/core/LICENSE
*/
pragma solidity >=0.8.19 <0.9.0;

import { ConditionalOrderDetails } from "../../src/interfaces/IOrdersGatewayProxy.sol";

bytes32 constant _CONDITIONAL_ORDER_DETAILS_TYPEHASH = keccak256(
    //solhint-disable-next-line max-line-length
    "ConditionalOrderDetails(uint128 accountId,uint128 marketId,uint128 exchangeId,uint128[] counterpartyAccountIds,uint8 orderType,bytes inputs,address signer,uint256 nonce)"
);

bytes32 constant _CONDITIONAL_ORDER_TYPEHASH = keccak256(
    //solhint-disable-next-line max-line-length
    "ConditionalOrder(uint256 verifyingChainId,uint256 deadline,ConditionalOrderDetails order)ConditionalOrderDetails(uint128 accountId,uint128 marketId,uint128 exchangeId,uint128[] counterpartyAccountIds,uint8 orderType,bytes inputs,address signer,uint256 nonce)"
);

function mockCalculateDigest(bytes32 hashedMessage, address orderGateway) pure returns (bytes32) {
        bytes32 EIP712_REVISION_HASH = keccak256("1");
        bytes32 EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");

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

function hashConditionalOrderDetails(ConditionalOrderDetails memory order) pure returns (bytes32) {
    return keccak256(
        abi.encode(
            _CONDITIONAL_ORDER_DETAILS_TYPEHASH,
            order.accountId,
            order.marketId,
            order.exchangeId,
            order.counterpartyAccountIds,
            order.orderType,
            order.inputs,
            order.signer,
            order.nonce
        )
    );
}

function hashConditionalOrder(ConditionalOrderDetails memory order, uint256 deadline) view returns (bytes32) {
    // note, the nonce is already part of the order object

    return
        keccak256(abi.encode(_CONDITIONAL_ORDER_TYPEHASH, block.chainid, deadline, hashConditionalOrderDetails(order)));
}
