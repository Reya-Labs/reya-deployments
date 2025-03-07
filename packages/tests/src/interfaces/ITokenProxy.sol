// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface ITokenProxy {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function burn(address target, uint256 amount) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external;

    function isInitialized() external view returns (bool);

    function mint(address target, uint256 amount) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Transfer(address indexed from, address indexed to, uint256 amount);
    error AlreadyInitialized();
    error FeatureUnavailable(bytes32 which);
    error InsufficientAllowance(uint256 required, uint256 existing);
    error InsufficientBalance(uint256 required, uint256 existing);
    error InvalidParameter(string parameter, string reason);
    error NotInitialized();
    error Unauthorized(address addr);

    function addToFeatureFlagAllowlist(bytes32 feature, address account)
        external;

    function getAdmins(bytes32 feature)
        external
        view
        returns (address[] memory);

    function getDeniers(bytes32 feature)
        external
        view
        returns (address[] memory);

    function getFeatureFlagAllowAll(bytes32 feature)
        external
        view
        returns (bool);

    function getFeatureFlagAllowlist(bytes32 feature)
        external
        view
        returns (address[] memory);

    function getFeatureFlagDenyAll(bytes32 feature)
        external
        view
        returns (bool);

    function isFeatureAllowed(bytes32 feature, address account)
        external
        view
        returns (bool);

    function removeFromFeatureFlagAllowlist(bytes32 feature, address account)
        external;

    function setAdmins(bytes32 feature, address[] memory admins) external;

    function setDeniers(bytes32 feature, address[] memory deniers) external;

    function setFeatureFlagAllowAll(bytes32 feature, bool allowAll) external;

    function setFeatureFlagDenyAll(bytes32 feature, bool denyAll) external;

    event FeatureFlagAdminsReset(bytes32 indexed feature, address[] admins);
    event FeatureFlagAllowAllSet(bytes32 indexed feature, bool allowAll);
    event FeatureFlagAllowlistAdded(bytes32 indexed feature, address account);
    event FeatureFlagAllowlistRemoved(bytes32 indexed feature, address account);
    event FeatureFlagDeniersReset(bytes32 indexed feature, address[] deniers);
    event FeatureFlagDenyAllSet(bytes32 indexed feature, bool denyAll);
    error AddressZero();
    error ValueAlreadyInSet();
    error ValueNotInSet();

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

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"type":"function","name":"allowance","inputs":[{"name":"owner","type":"address","internalType":"address"},{"name":"spender","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"approve","inputs":[{"name":"spender","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"balanceOf","inputs":[{"name":"owner","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"burn","inputs":[{"name":"target","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"decimals","inputs":[],"outputs":[{"name":"","type":"uint8","internalType":"uint8"}],"stateMutability":"view"},{"type":"function","name":"decreaseAllowance","inputs":[{"name":"spender","type":"address","internalType":"address"},{"name":"subtractedValue","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"increaseAllowance","inputs":[{"name":"spender","type":"address","internalType":"address"},{"name":"addedValue","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"initialize","inputs":[{"name":"tokenName","type":"string","internalType":"string"},{"name":"tokenSymbol","type":"string","internalType":"string"},{"name":"tokenDecimals","type":"uint8","internalType":"uint8"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"isInitialized","inputs":[],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"mint","inputs":[{"name":"target","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"name","inputs":[],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"symbol","inputs":[],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"totalSupply","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"transfer","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"transferFrom","inputs":[{"name":"from","type":"address","internalType":"address"},{"name":"to","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"event","name":"Approval","inputs":[{"name":"owner","type":"address","indexed":true,"internalType":"address"},{"name":"spender","type":"address","indexed":true,"internalType":"address"},{"name":"amount","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"Transfer","inputs":[{"name":"from","type":"address","indexed":true,"internalType":"address"},{"name":"to","type":"address","indexed":true,"internalType":"address"},{"name":"amount","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"error","name":"AlreadyInitialized","inputs":[]},{"type":"error","name":"FeatureUnavailable","inputs":[{"name":"which","type":"bytes32","internalType":"bytes32"}]},{"type":"error","name":"InsufficientAllowance","inputs":[{"name":"required","type":"uint256","internalType":"uint256"},{"name":"existing","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"InsufficientBalance","inputs":[{"name":"required","type":"uint256","internalType":"uint256"},{"name":"existing","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"InvalidParameter","inputs":[{"name":"parameter","type":"string","internalType":"string"},{"name":"reason","type":"string","internalType":"string"}]},{"type":"error","name":"NotInitialized","inputs":[]},{"type":"error","name":"Unauthorized","inputs":[{"name":"addr","type":"address","internalType":"address"}]},{"type":"function","name":"addToFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"getAdmins","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getDeniers","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagAllowAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagDenyAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"isFeatureAllowed","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"removeFromFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setAdmins","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"admins","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setDeniers","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"deniers","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setFeatureFlagAllowAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"allowAll","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setFeatureFlagDenyAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"denyAll","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"FeatureFlagAdminsReset","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"admins","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"FeatureFlagAllowAllSet","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"allowAll","type":"bool","indexed":false,"internalType":"bool"}],"anonymous":false},{"type":"event","name":"FeatureFlagAllowlistAdded","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"account","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"FeatureFlagAllowlistRemoved","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"account","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"FeatureFlagDeniersReset","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"deniers","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"FeatureFlagDenyAllSet","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"denyAll","type":"bool","indexed":false,"internalType":"bool"}],"anonymous":false},{"type":"error","name":"AddressZero","inputs":[]},{"type":"error","name":"ValueAlreadyInSet","inputs":[]},{"type":"error","name":"ValueNotInSet","inputs":[]},{"type":"function","name":"acceptOwnership","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"getImplementation","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"nominateNewOwner","inputs":[{"name":"newNominatedOwner","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"nominatedOwner","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"owner","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"renounceNomination","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"simulateUpgradeTo","inputs":[{"name":"newImplementation","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"upgradeTo","inputs":[{"name":"newImplementation","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"OwnerChanged","inputs":[{"name":"oldOwner","type":"address","indexed":false,"internalType":"address"},{"name":"newOwner","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"OwnerNominated","inputs":[{"name":"newOwner","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"Upgraded","inputs":[{"name":"self","type":"address","indexed":true,"internalType":"address"},{"name":"implementation","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"error","name":"ImplementationIsSterile","inputs":[{"name":"implementation","type":"address","internalType":"address"}]},{"type":"error","name":"NoChange","inputs":[]},{"type":"error","name":"NotAContract","inputs":[{"name":"contr","type":"address","internalType":"address"}]},{"type":"error","name":"NotNominated","inputs":[{"name":"addr","type":"address","internalType":"address"}]},{"type":"error","name":"UpgradeSimulationFailed","inputs":[]},{"type":"error","name":"ZeroAddress","inputs":[]}]
*/