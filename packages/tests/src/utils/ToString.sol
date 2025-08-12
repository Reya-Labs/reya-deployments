pragma solidity >=0.8.19 <0.9.0;

function uintToString(uint256 value) pure returns (string memory) {
    if (value == 0) return "0";
    uint256 temp = value;
    uint256 digits = 0;

    while (temp != 0) {
        digits++;
        temp /= 10;
    }

    bytes memory buffer = new bytes(digits);

    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }

    return string(buffer);
}

function bytes32ToHexString(bytes32 data) pure returns (string memory) {
    bytes memory alphabet = "0123456789abcdef";
    bytes memory str = new bytes(2 + 64); // "0x" + 64 hex chars
    str[0] = "0";
    str[1] = "x";

    bytes memory b = abi.encodePacked(data); // convert bytes32 → bytes
    for (uint256 i = 0; i < 32; i++) {
        str[2 + i * 2] = alphabet[uint8(b[i] >> 4)];
        str[3 + i * 2] = alphabet[uint8(b[i] & 0x0f)];
    }

    return string(str);
}
