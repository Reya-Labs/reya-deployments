// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IReyaOFT {
    error AddressBlacklisted(address account);
    error OwnableUnauthorizedAccount(address account);
    error FeatureUnavailable(bytes32 which);

    function initialize(string memory _name, string memory _symbol, address _delegate) external;
    function addToBlacklist(address account) external;
    function removeFromBlacklist(address account) external;
    function isBlacklisted(address account) external view returns (bool);
    function pause() external;
    function unpause() external;
    function mint(address to, uint256 amount) external;

    // IFeatureFlagModule
    function isFeatureAllowed(bytes32 feature, address account) external view returns (bool);

    // OFT
    struct MessagingParams {
        uint32 dstEid;
        bytes32 receiver;
        bytes message;
        bytes options;
        bool payInLzToken;
    }
    struct MessagingReceipt {
        bytes32 guid;
        uint64 nonce;
        MessagingFee fee;
    }
    struct MessagingFee {
        uint256 nativeFee;
        uint256 lzTokenFee;
    }
    struct SendParam {
        uint32 dstEid; // Destination endpoint ID.
        bytes32 to; // Recipient address.
        uint256 amountLD; // Amount to send in local decimals.
        uint256 minAmountLD; // Minimum amount to send in local decimals.
        bytes extraOptions; // Additional options supplied by the caller to be used in the LayerZero message.
        bytes composeMsg; // The composed message for the send() operation.
        bytes oftCmd; // The OFT command to be executed, unused in default OFT implementations.
    }
    struct OFTLimit {
        uint256 minAmountLD; // Minimum amount in local decimals that can be sent to the recipient.
        uint256 maxAmountLD; // Maximum amount in local decimals that can be sent to the recipient.
    }
    struct OFTReceipt {
        uint256 amountSentLD; // Amount of tokens ACTUALLY debited from the sender in local decimals.
        // @dev In non-default implementations, the amountReceivedLD COULD differ from this value.
        uint256 amountReceivedLD; // Amount of tokens to be received on the remote side.
    }
    struct OFTFeeDetail {
        int256 feeAmountLD; // Amount of the fee in local decimals.
        string description; // Description of the fee.
    }

    function quoteOFT(
        SendParam calldata _sendParam
    ) external view returns (OFTLimit memory, OFTFeeDetail[] memory oftFeeDetails, OFTReceipt memory);
    function quoteSend(SendParam calldata _sendParam, bool _payInLzToken) external view returns (MessagingFee memory);
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory, OFTReceipt memory);
    
    // LayerZero endpoint and peer configuration
    function endpoint() external view returns (address);
    function peers(uint32 eid) external view returns (bytes32);
    function owner() external view returns (address);
    
    // LayerZero receive - called by endpoint when receiving cross-chain messages
    struct Origin {
        uint32 srcEid;
        bytes32 sender;
        uint64 nonce;
    }
    
    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable;

    // IERC20
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}
