pragma solidity >=0.8.19 <0.9.0;

import { OracleDataPayload } from "../../src/interfaces/IPassivePerpProxyV2.sol";

library OracleDataPayloadHashing {
    bytes32 private constant _ORACLE_DATA_PAYLOAD_TYPEHASH = keccak256(
        //solhint-disable-next-line max-line-length
        "OracleDataPayload(uint256 verifyingChainId,uint256 deadline,uint128 marketId,uint256 timestamp,uint8 dataType,bytes data,address publisher)"
    );

    function mockCalculateDigest(
        OracleDataPayload memory payload,
        uint256 deadline,
        address passivePerpProxy
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 EIP712_REVISION_HASH = keccak256("1");
        bytes32 EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");

        bytes32 hashedMessage = keccak256(
            abi.encode(
                _ORACLE_DATA_PAYLOAD_TYPEHASH,
                block.chainid,
                deadline,
                payload.marketId,
                payload.timestamp,
                uint8(payload.dataType),
                keccak256(payload.data),
                payload.publisher
            )
        );

        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    keccak256(
                        abi.encode(
                            EIP712_DOMAIN_TYPEHASH, keccak256(bytes("Reya")), EIP712_REVISION_HASH, passivePerpProxy
                        )
                    ),
                    hashedMessage
                )
            );
        }
        return digest;
    }
}
