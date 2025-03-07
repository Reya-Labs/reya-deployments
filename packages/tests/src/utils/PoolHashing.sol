pragma solidity >=0.8.19 <0.9.0;

library PoolHashing {
    bytes32 internal constant REMOVE_LIQUIDITY_TYPEHASH = keccak256(
        //solhint-disable-next-line max-line-length
        "RemoveLiquidityBySig(uint256 verifyingChainId,address caller,address owner,uint128 poolId,uint256 sharesAmount,uint256 minOut,uint256 nonce,uint256 deadline,bytes extraSignatureData)"
    );

    function mockCalculateDigest(
        address caller,
        address owner,
        uint128 poolId,
        uint256 sharesAmount,
        uint256 minOut,
        uint256 nonce,
        uint256 deadline,
        bytes memory extraData,
        address pool
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 EIP712_REVISION_HASH = keccak256("1");
        bytes32 EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");

        bytes32 hashedMessage = keccak256(
            abi.encode(
                REMOVE_LIQUIDITY_TYPEHASH,
                block.chainid,
                caller,
                owner,
                poolId,
                sharesAmount,
                minOut,
                nonce,
                deadline,
                keccak256(extraData)
            )
        );

        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    keccak256(
                        abi.encode(
                            EIP712_DOMAIN_TYPEHASH, keccak256(bytes("Reya")), EIP712_REVISION_HASH, address(pool)
                        )
                    ),
                    hashedMessage
                )
            );
        }
        return digest;
    }
}
