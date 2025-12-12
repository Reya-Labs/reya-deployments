pragma solidity >=0.8.19 <0.9.0;

import { FillDetails } from "../interfaces/IOrdersGatewayProxy.sol";

library FillHashing {
    bytes32 private constant _FILL_DETAILS_TYPEHASH = keccak256(
        //solhint-disable-next-line max-line-length
        "FillDetails(uint64 accountOrderId,uint64 counterpartyOrderId,uint256 baseDelta,uint256 price,uint256 nonce)"
    );

    bytes32 private constant _FILL_TYPEHASH = keccak256(
        //solhint-disable-next-line max-line-length
        "Fill(uint256 verifyingChainId,uint256 deadline,FillDetails fill)FillDetails(uint64 accountOrderId,uint64 counterpartyOrderId,uint256 baseDelta,uint256 price,uint256 nonce)"
    );

    function mockCalculateDigest(
        FillDetails memory fill,
        uint256 deadline,
        address orderGateway
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 EIP712_REVISION_HASH = keccak256("1");
        bytes32 EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");

        bytes32 hashedMessage = keccak256(abi.encode(_FILL_TYPEHASH, block.chainid, deadline, hashFillDetails(fill)));

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

    function hashFillDetails(FillDetails memory fill) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _FILL_DETAILS_TYPEHASH,
                fill.accountOrderId,
                fill.counterpartyOrderId,
                fill.baseDelta,
                fill.price,
                fill.nonce
            )
        );
    }
}
