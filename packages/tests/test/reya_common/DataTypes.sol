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
    // network
    string REYA_RPC;
    string MAINNET_RPC;
    // other (external) chain id
    uint256 destinationChainId;
    // multisigs
    address multisig;
    // Reya contracts
    address payable core;
    address payable pool;
    address payable perp;
    address oracleManager;
    address payable periphery;
    address payable ordersGateway;
    address payable oracleAdaptersProxy;
    address exchangePass;
    address accountNft;
    // Reya tokens
    address rusd;
    address usdc;
    address weth;
    address wbtc;
    address usde;
    address susde;
    address deusd;
    address sdeusd;
    address rselini;
    address ramber;
    address rhedge;
    address srusd;
    address wsteth;
    // Elixir tokens on Mainnet (Ethereum or Ethereum Sepolia)
    address elixirSdeusd;
    // Reya modules
    address ownerUpgradeModule;
    // Reya variables
    uint128 passivePoolId;
    uint128 passivePoolAccountId;
    // Reya bots
    address coExecutionBot;
    address poolRebalancer;
    address rseliniCustodian;
    address rseliniSubscriber;
    address rseliniRedeemer;
    address ramberCustodian;
    address ramberSubscriber;
    address ramberRedeemer;
    address rhedgeCustodian;
    address rhedgeSubscriber;
    address rhedgeRedeemer;
    address aeLiquidator1;
}

struct DynamicEcosystem {
    mapping(address token => address controller) socketController;
    mapping(address token => address executionHelper) socketExecutionHelper;
    mapping(address token => mapping(uint256 chainId => address connector)) socketConnector;
    mapping(string nodeName => bytes32 nodeId) oracleNodes;
    mapping(uint128 marketId => string nodeName) marketNodeNames;
}
