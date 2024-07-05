pragma solidity >=0.8.19 <0.9.0;

import { ConditionalOrderDetails } from "../../src/interfaces/IOrdersGatewayProxy.sol";

library ConditionalOrderHashing {
    bytes32 private constant _CONDITIONAL_ORDER_DETAILS_TYPEHASH = keccak256(
        //solhint-disable-next-line max-line-length
        "ConditionalOrderDetails(uint128 accountId,uint128 marketId,uint128 exchangeId,uint128[] counterpartyAccountIds,uint8 orderType,bytes inputs,address signer,uint256 nonce)"
    );

    bytes32 private constant _CONDITIONAL_ORDER_TYPEHASH = keccak256(
        //solhint-disable-next-line max-line-length
        "ConditionalOrder(uint256 verifyingChainId,uint256 deadline,ConditionalOrderDetails order)ConditionalOrderDetails(uint128 accountId,uint128 marketId,uint128 exchangeId,uint128[] counterpartyAccountIds,uint8 orderType,bytes inputs,address signer,uint256 nonce)"
    );

    function mockCalculateDigest(
        ConditionalOrderDetails memory order,
        uint256 deadline,
        address orderGateway
    )
        public
        view
        returns (bytes32)
    {
        bytes32 EIP712_REVISION_HASH = keccak256("1");
        bytes32 EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");

        bytes32 hashedMessage = keccak256(
            abi.encode(_CONDITIONAL_ORDER_TYPEHASH, block.chainid, deadline, hashConditionalOrderDetails(order))
        );

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

    function hashConditionalOrderDetails(ConditionalOrderDetails memory order) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _CONDITIONAL_ORDER_DETAILS_TYPEHASH,
                order.accountId,
                order.marketId,
                order.exchangeId,
                keccak256(abi.encodePacked(order.counterpartyAccountIds)),
                order.orderType,
                keccak256(order.inputs),
                order.signer,
                order.nonce
            )
        );
    }
}
