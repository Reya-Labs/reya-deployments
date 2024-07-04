pragma solidity >=0.8.19 <0.9.0;

uint256 constant ethereumChainId = 1;
uint256 constant arbitrumChainId = 42_161;
uint256 constant optimismChainId = 10;
uint256 constant polygonChainId = 137;
uint256 constant baseChainId = 8453;
uint256 constant ethereumSepoliaChainId = 11_155_111;
uint256 constant arbitrumSepoliaChainId = 421_614;
uint256 constant optimismSepoliaChainId = 11_155_420;
uint256 constant ONE_MINUTE_IN_SECONDS = 60;

struct StaticEcosystem {
    string REYA_RPC;
    address multisig;
    address payable core;
    address payable pool;
    address payable perp;
    address oracleManager;
    address payable periphery;
    address exchangePass;
    address accountNft;
    address rusd;
    address usdc;
    address weth;
    address wbtc;
    address ownerUpgradeModule;
    bytes32 ethUsdNodeId;
    bytes32 btcUsdNodeId;
    bytes32 solUsdNodeId;
    bytes32 ethUsdcNodeId;
    bytes32 btcUsdcNodeId;
    bytes32 solUsdcNodeId;
    bytes32 rusdUsdNodeId;
    bytes32 usdcUsdNodeId;
    uint256 mainChainId;
    uint128 passivePoolId;
    uint128 passivePoolAccountId;
}

struct DynamicEcosystem {
    mapping(address token => address controller) socketController;
    mapping(address token => address executionHelper) socketExecutionHelper;
    mapping(address token => mapping(uint256 chainId => address connector)) socketConnector;
}
