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
    // Camelot contracts
    address camelotYakRouter;
    address camelotSwapPublisher;
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
    // node ids for spot prices
    bytes32 rusdUsdNodeId;
    bytes32 usdcUsdStorkNodeId;
    bytes32 ethUsdStorkNodeId;
    bytes32 ethUsdcStorkNodeId;
    bytes32 usdeUsdStorkNodeId;
    bytes32 usdeUsdcStorkNodeId;
    bytes32 susdeUsdStorkNodeId;
    bytes32 susdeUsdcStorkNodeId;
    bytes32 deusdUsdStorkNodeId;
    bytes32 deusdUsdcStorkNodeId;
    bytes32 sdeusdDeusdStorkNodeId;
    bytes32 sdeusdUsdcStorkNodeId;
    // node ids for mark prices
    bytes32 ethUsdStorkMarkNodeId;
    bytes32 ethUsdcStorkMarkNodeId;
    bytes32 btcUsdStorkMarkNodeId;
    bytes32 btcUsdcStorkMarkNodeId;
    bytes32 solUsdStorkMarkNodeId;
    bytes32 solUsdcStorkMarkNodeId;
    bytes32 arbUsdStorkMarkNodeId;
    bytes32 arbUsdcStorkMarkNodeId;
    bytes32 opUsdStorkMarkNodeId;
    bytes32 opUsdcStorkMarkNodeId;
    bytes32 avaxUsdStorkMarkNodeId;
    bytes32 avaxUsdcStorkMarkNodeId;
    bytes32 mkrUsdStorkMarkNodeId;
    bytes32 mkrUsdcStorkMarkNodeId;
    bytes32 linkUsdStorkMarkNodeId;
    bytes32 linkUsdcStorkMarkNodeId;
    bytes32 aaveUsdStorkMarkNodeId;
    bytes32 aaveUsdcStorkMarkNodeId;
    bytes32 crvUsdStorkMarkNodeId;
    bytes32 crvUsdcStorkMarkNodeId;
    bytes32 uniUsdStorkMarkNodeId;
    bytes32 uniUsdcStorkMarkNodeId;
    bytes32 suiUsdStorkMarkNodeId;
    bytes32 suiUsdcStorkMarkNodeId;
    bytes32 tiaUsdStorkMarkNodeId;
    bytes32 tiaUsdcStorkMarkNodeId;
    bytes32 seiUsdStorkMarkNodeId;
    bytes32 seiUsdcStorkMarkNodeId;
    bytes32 zroUsdStorkMarkNodeId;
    bytes32 zroUsdcStorkMarkNodeId;
    bytes32 xrpUsdStorkMarkNodeId;
    bytes32 xrpUsdcStorkMarkNodeId;
    bytes32 wifUsdStorkMarkNodeId;
    bytes32 wifUsdcStorkMarkNodeId;
    bytes32 pepe1kUsdStorkMarkNodeId;
    bytes32 pepe1kUsdcStorkMarkNodeId;
    bytes32 popcatUsdStorkMarkNodeId;
    bytes32 popcatUsdcStorkMarkNodeId;
    bytes32 dogeUsdStorkMarkNodeId;
    bytes32 dogeUsdcStorkMarkNodeId;
    bytes32 kshibUsdStorkMarkNodeId;
    bytes32 kshibUsdcStorkMarkNodeId;
    bytes32 kbonkUsdStorkMarkNodeId;
    bytes32 kbonkUsdcStorkMarkNodeId;
    bytes32 aptUsdStorkMarkNodeId;
    bytes32 aptUsdcStorkMarkNodeId;
    bytes32 bnbUsdStorkMarkNodeId;
    bytes32 bnbUsdcStorkMarkNodeId;
    bytes32 jtoUsdStorkMarkNodeId;
    bytes32 jtoUsdcStorkMarkNodeId;
    bytes32 adaUsdStorkMarkNodeId;
    bytes32 adaUsdcStorkMarkNodeId;
    bytes32 ldoUsdStorkMarkNodeId;
    bytes32 ldoUsdcStorkMarkNodeId;
    bytes32 polUsdStorkMarkNodeId;
    bytes32 polUsdcStorkMarkNodeId;
    bytes32 nearUsdStorkMarkNodeId;
    bytes32 nearUsdcStorkMarkNodeId;
    bytes32 ftmUsdStorkMarkNodeId;
    bytes32 ftmUsdcStorkMarkNodeId;
    bytes32 enaUsdStorkMarkNodeId;
    bytes32 enaUsdcStorkMarkNodeId;
    bytes32 eigenUsdStorkMarkNodeId;
    bytes32 eigenUsdcStorkMarkNodeId;
    bytes32 pendleUsdStorkMarkNodeId;
    bytes32 pendleUsdcStorkMarkNodeId;
    bytes32 goatUsdStorkMarkNodeId;
    bytes32 goatUsdcStorkMarkNodeId;
    bytes32 grassUsdStorkMarkNodeId;
    bytes32 grassUsdcStorkMarkNodeId;
    bytes32 kneiroUsdStorkMarkNodeId;
    bytes32 kneiroUsdcStorkMarkNodeId;
}

struct DynamicEcosystem {
    mapping(address token => address controller) socketController;
    mapping(address token => address executionHelper) socketExecutionHelper;
    mapping(address token => mapping(uint256 chainId => address connector)) socketConnector;
}
