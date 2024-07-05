pragma solidity >=0.8.19 <0.9.0;

library GrantAccountPermissionHashing {
    bytes32 constant GRANT_ACCOUNT_PERMISSION_BY_SIG_TYPEHASH = keccak256(
        //solhint-disable-next-line max-line-length
        "GrantAccountPermissionBySig(uint256 verifyingChainId,uint128 accountId,bytes32 permission,address user,uint256 nonce,uint256 deadline)"
    );

    function mockCalculateDigest(
        uint128 accountId,
        bytes32 permission,
        address user,
        uint256 nonce,
        uint256 deadline,
        address core
    )
        public
        view
        returns (bytes32)
    {
        bytes32 EIP712_REVISION_HASH = keccak256("1");
        bytes32 EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");

        bytes32 hashedMessage = keccak256(
            abi.encode(
                GRANT_ACCOUNT_PERMISSION_BY_SIG_TYPEHASH, block.chainid, accountId, permission, user, nonce, deadline
            )
        );

        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    keccak256(
                        abi.encode(
                            EIP712_DOMAIN_TYPEHASH, keccak256(bytes("Reya")), EIP712_REVISION_HASH, address(core)
                        )
                    ),
                    hashedMessage
                )
            );
        }
        return digest;
    }
}
