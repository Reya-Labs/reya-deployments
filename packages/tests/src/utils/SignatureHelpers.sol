pragma solidity >=0.8.19 <0.9.0;

import { Command, EIP712Signature } from "../../src/interfaces/IPeripheryProxy.sol";

bytes32 constant COMMAND_TYPEHASH =
    keccak256("Command(uint8 commandType,bytes inputs,uint128 marketId,uint128 exchangeId)");

bytes32 constant EXECUTE_BY_SIG_TYPEHASH = keccak256(
    //solhint-disable-next-line max-line-length
    "ExecuteBySig(uint256 verifyingChainId,address caller,uint128 accountId,Command[] commands,uint256 nonce,uint256 deadline,bytes extraSignatureData)Command(uint8 commandType,bytes inputs,uint128 marketId,uint128 exchangeId)"
);

function hashCommand(Command memory command) pure returns (bytes32) {
    return keccak256(
        abi.encode(
            COMMAND_TYPEHASH, command.commandType, keccak256(command.inputs), command.marketId, command.exchangeId
        )
    );
}

function hashCommands(Command[] memory commands) pure returns (bytes32) {
    bytes32[] memory hashedCommands = new bytes32[](commands.length);
    for (uint256 i = 0; i < commands.length; i += 1) {
        hashedCommands[i] = hashCommand(commands[i]);
    }

    return keccak256(abi.encodePacked(hashedCommands));
}

function hashExecuteBySigExtended(
    address caller,
    uint128 accountId,
    Command[] memory commands,
    uint256 nonce,
    uint256 deadline,
    bytes32 extraData
)
    view
    returns (bytes32)
{
    return keccak256(
        abi.encode(
            EXECUTE_BY_SIG_TYPEHASH,
            block.chainid,
            caller,
            accountId,
            hashCommands(commands),
            nonce,
            deadline,
            extraData
        )
    );
}

function mockCoreCalculateDigest(address core, bytes32 hashedMessage) pure returns (bytes32) {
    bytes32 EIP712_REVISION_HASH = keccak256("1");
    bytes32 EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");

    bytes32 digest;
    unchecked {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                keccak256(
                    abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes("Reya")), EIP712_REVISION_HASH, address(core))
                ),
                hashedMessage
            )
        );
    }
    return digest;
}
