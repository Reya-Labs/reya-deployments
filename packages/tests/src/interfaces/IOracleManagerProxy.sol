// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IOracleManagerProxy {
    function getNode(bytes32 nodeId)
        external
        pure
        returns (NodeDefinition.Data memory node);

    function getNodeId(
        uint8 nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external pure returns (bytes32 nodeId);

    function process(bytes32 nodeId)
        external
        view
        returns (NodeOutput.Data memory node);

    function registerNode(
        uint8 nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32 nodeId);

    function setMaxStaleDuration(bytes32 nodeId, uint256 maxStaleDuration)
        external;

    event MaxStaleDurationUpdated(bytes32 nodeId, uint256 maxStaleDuration);
    event NodeRegistered(
        bytes32 nodeId,
        uint8 nodeType,
        bytes parameters,
        bytes32[] parents
    );
    error InvalidNodeDefinition(NodeDefinition.Data nodeType);
    error InvalidPrice();
    error NegativePrice(int256 price, address redstone);
    error NodeNotRegistered(bytes32 nodeId);
    error OverflowInt256ToUint256();
    error OverflowUint256ToInt256();
    error PRBMath_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator);
    error StalePriceDetected(bytes32 nodeId);
    error Unauthorized(address addr);
    error UnprocessableNode(bytes32 nodeId);

    function acceptOwnership() external;

    function getImplementation() external view returns (address);

    function nominateNewOwner(address newNominatedOwner) external;

    function nominatedOwner() external view returns (address);

    function owner() external view returns (address);

    function renounceNomination() external;

    function simulateUpgradeTo(address newImplementation) external;

    function upgradeTo(address newImplementation) external;

    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerNominated(address newOwner);
    event Upgraded(address indexed self, address implementation);
    error ImplementationIsSterile(address implementation);
    error NoChange();
    error NotAContract(address contr);
    error NotNominated(address addr);
    error UpgradeSimulationFailed();
    error ZeroAddress();
}

interface NodeDefinition {
    struct Data {
        uint8 nodeType;
        bytes parameters;
        bytes32[] parents;
        uint256 maxStaleDuration;
    }
}

interface NodeOutput {
    struct Data {
        uint256 price;
        uint256 timestamp;
    }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"type":"function","name":"getNode","inputs":[{"name":"nodeId","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"node","type":"tuple","internalType":"struct NodeDefinition.Data","components":[{"name":"nodeType","type":"uint8","internalType":"enum NodeDefinition.NodeType"},{"name":"parameters","type":"bytes","internalType":"bytes"},{"name":"parents","type":"bytes32[]","internalType":"bytes32[]"},{"name":"maxStaleDuration","type":"uint256","internalType":"uint256"}]}],"stateMutability":"pure"},{"type":"function","name":"getNodeId","inputs":[{"name":"nodeType","type":"uint8","internalType":"enum NodeDefinition.NodeType"},{"name":"parameters","type":"bytes","internalType":"bytes"},{"name":"parents","type":"bytes32[]","internalType":"bytes32[]"}],"outputs":[{"name":"nodeId","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"process","inputs":[{"name":"nodeId","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"node","type":"tuple","internalType":"struct NodeOutput.Data","components":[{"name":"price","type":"uint256","internalType":"uint256"},{"name":"timestamp","type":"uint256","internalType":"uint256"}]}],"stateMutability":"view"},{"type":"function","name":"registerNode","inputs":[{"name":"nodeType","type":"uint8","internalType":"enum NodeDefinition.NodeType"},{"name":"parameters","type":"bytes","internalType":"bytes"},{"name":"parents","type":"bytes32[]","internalType":"bytes32[]"}],"outputs":[{"name":"nodeId","type":"bytes32","internalType":"bytes32"}],"stateMutability":"nonpayable"},{"type":"function","name":"setMaxStaleDuration","inputs":[{"name":"nodeId","type":"bytes32","internalType":"bytes32"},{"name":"maxStaleDuration","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"MaxStaleDurationUpdated","inputs":[{"name":"nodeId","type":"bytes32","indexed":false,"internalType":"bytes32"},{"name":"maxStaleDuration","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"NodeRegistered","inputs":[{"name":"nodeId","type":"bytes32","indexed":false,"internalType":"bytes32"},{"name":"nodeType","type":"uint8","indexed":false,"internalType":"enum NodeDefinition.NodeType"},{"name":"parameters","type":"bytes","indexed":false,"internalType":"bytes"},{"name":"parents","type":"bytes32[]","indexed":false,"internalType":"bytes32[]"}],"anonymous":false},{"type":"error","name":"InvalidNodeDefinition","inputs":[{"name":"nodeType","type":"tuple","internalType":"struct NodeDefinition.Data","components":[{"name":"nodeType","type":"uint8","internalType":"enum NodeDefinition.NodeType"},{"name":"parameters","type":"bytes","internalType":"bytes"},{"name":"parents","type":"bytes32[]","internalType":"bytes32[]"},{"name":"maxStaleDuration","type":"uint256","internalType":"uint256"}]}]},{"type":"error","name":"InvalidPrice","inputs":[]},{"type":"error","name":"NegativePrice","inputs":[{"name":"price","type":"int256","internalType":"int256"},{"name":"redstone","type":"address","internalType":"contract IAggregatorV3Interface"}]},{"type":"error","name":"NodeNotRegistered","inputs":[{"name":"nodeId","type":"bytes32","internalType":"bytes32"}]},{"type":"error","name":"OverflowInt256ToUint256","inputs":[]},{"type":"error","name":"OverflowUint256ToInt256","inputs":[]},{"type":"error","name":"PRBMath_MulDiv_Overflow","inputs":[{"name":"x","type":"uint256","internalType":"uint256"},{"name":"y","type":"uint256","internalType":"uint256"},{"name":"denominator","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"StalePriceDetected","inputs":[{"name":"nodeId","type":"bytes32","internalType":"bytes32"}]},{"type":"error","name":"Unauthorized","inputs":[{"name":"addr","type":"address","internalType":"address"}]},{"type":"error","name":"UnprocessableNode","inputs":[{"name":"nodeId","type":"bytes32","internalType":"bytes32"}]},{"type":"function","name":"acceptOwnership","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"getImplementation","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"nominateNewOwner","inputs":[{"name":"newNominatedOwner","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"nominatedOwner","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"owner","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"renounceNomination","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"simulateUpgradeTo","inputs":[{"name":"newImplementation","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"upgradeTo","inputs":[{"name":"newImplementation","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"OwnerChanged","inputs":[{"name":"oldOwner","type":"address","indexed":false,"internalType":"address"},{"name":"newOwner","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"OwnerNominated","inputs":[{"name":"newOwner","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"Upgraded","inputs":[{"name":"self","type":"address","indexed":true,"internalType":"address"},{"name":"implementation","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"error","name":"ImplementationIsSterile","inputs":[{"name":"implementation","type":"address","internalType":"address"}]},{"type":"error","name":"NoChange","inputs":[]},{"type":"error","name":"NotAContract","inputs":[{"name":"contr","type":"address","internalType":"address"}]},{"type":"error","name":"NotNominated","inputs":[{"name":"addr","type":"address","internalType":"address"}]},{"type":"error","name":"UpgradeSimulationFailed","inputs":[]},{"type":"error","name":"ZeroAddress","inputs":[]}]
*/