// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { ICoreProxy, CollateralConfig, ParentCollateralConfig } from "../../../src/interfaces/ICoreProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";
import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

/**
 * @title CollateralMirrorForkTest
 * @notice Pins devnet's mirror of mainnet's full 12-token collateral set.
 * @dev Core walks the ENTIRE supporting-collateral set on every margin
 *      computation, so this set is not just a feature list -- one unresolvable
 *      parent oracle in it reverts every fill, liquidation and funding update
 *      on the venue. That is exactly what the legacy Cronos sRUSD entry did
 *      before its node was repaired.
 *
 *      Expected values mirror omnibus/reya_devnet.toml; when a collateral is
 *      added or its economics change there, this file is the paired change.
 */
contract CollateralMirrorForkTest is ReyaForkTest {
    // Oracle manager node types (omnibus/utils/constants.toml).
    uint8 internal constant NODE_TYPE_DIV_REDUCER = 1;
    uint8 internal constant NODE_TYPE_CONSTANT = 3;
    uint8 internal constant NODE_TYPE_STORK_OFFCHAIN_LOOKUP = 4;

    /// sdeUSD's frozen closing price, as registered by the shared
    /// oracle_manager/configs/constants/sdeusd_usdc_closing.toml. Mainnet
    /// prices sdeUSD off this same constant -- neither environment has a live
    /// sdeUSD feed -- so pinning the literal here pins mainnet parity, not a
    /// devnet quirk.
    uint256 internal constant SDEUSD_CLOSING_PRICE = 1_068_966_036_300_082_784;

    /// The legacy Cronos sRUSD: retired, but still a registered collateral,
    /// so it stays in the set Core walks. Same literal DevnetConfig uses.
    address internal constant LEGACY_SRUSD = 0xb9F531A54Fc0E9AdCa1b931d9533B4e49bB2fAD6;

    // The three LM share tokens. Devnet does not deploy these -- it reuses the
    // Cronos deployments, so these are the same addresses the omnibus carries
    // as rselini/ramber/rhedgeProxyAddress.
    address internal constant RSELINI = 0xbA8ae4D2A147c54c3aBA123e8e01937AF505FC3c;
    address internal constant RAMBER = 0x125FD68Ec0ab65ce9606DeD99e8F19C286f9E534;
    address internal constant RHEDGE = 0xFB9eeD7a6F3100dB35c94B214917a0A64AEC1a97;

    // ------------------------------------------------------------------
    // helpers: derive the node id from its DEFINITION rather than pinning a
    // hash, so the assertion says which feed the collateral prices off.
    // ------------------------------------------------------------------

    function storkLeafNode(string memory assetPairId) internal view returns (bytes32) {
        return IOracleManagerProxy(sec.oracleManager).getNodeId(
            NODE_TYPE_STORK_OFFCHAIN_LOOKUP, abi.encode(sec.oracleAdaptersProxy, assetPairId), new bytes32[](0)
        );
    }

    /// base/USDC, the shape every non-constant collateral parent uses.
    function storkDivNode(string memory baseAssetPairId) internal view returns (bytes32) {
        bytes32[] memory parents = new bytes32[](2);
        parents[0] = storkLeafNode(baseAssetPairId);
        parents[1] = storkLeafNode("USDCUSD");
        return IOracleManagerProxy(sec.oracleManager).getNodeId(NODE_TYPE_DIV_REDUCER, "", parents);
    }

    function constantNode(uint256 price) internal view returns (bytes32) {
        return IOracleManagerProxy(sec.oracleManager).getNodeId(NODE_TYPE_CONSTANT, abi.encode(price), new bytes32[](0));
    }

    function supportingCollaterals() internal view returns (address[] memory) {
        address quote = IPassivePoolProxy(sec.pool).getPoolQuoteToken(sec.passivePoolId);
        uint128 poolId = ICoreProxy(sec.core).getCollateralPoolIdOfAccount(sec.passivePoolAccountId);
        return ICoreProxy(sec.core).getSupportingCollaterals(poolId, quote);
    }

    function isSupporting(address token) internal view returns (bool) {
        address[] memory supporting = supportingCollaterals();
        for (uint256 i = 0; i < supporting.length; i++) {
            if (supporting[i] == token) return true;
        }
        return false;
    }

    // ------------------------------------------------------------------
    // the set
    // ------------------------------------------------------------------

    /// EXACT set, both directions. A missing token means the mirror is
    /// incomplete; an EXTRA one means an unreviewed token entered the margin
    /// walk, which is the failure mode that can brick the venue.
    function test_Devnet_CollateralMirror_ExactSupportingSet() public view {
        address[] memory expected = new address[](12);
        expected[0] = sec.weth;
        expected[1] = sec.srusd; // devnet's own
        expected[2] = LEGACY_SRUSD; // retired but still registered
        expected[3] = sec.wbtc;
        expected[4] = sec.wsteth;
        expected[5] = sec.usde;
        expected[6] = sec.susde;
        expected[7] = sec.deusd;
        expected[8] = sec.sdeusd;
        expected[9] = RSELINI;
        expected[10] = RAMBER;
        expected[11] = RHEDGE;

        address[] memory supporting = supportingCollaterals();
        require(
            supporting.length == expected.length,
            string.concat(
                "collateral mirror: supporting set size ",
                vm.toString(supporting.length),
                " != expected ",
                vm.toString(expected.length)
            )
        );

        for (uint256 i = 0; i < expected.length; i++) {
            require(
                isSupporting(expected[i]),
                string.concat("collateral mirror: expected collateral missing ", vm.toString(expected[i]))
            );
        }
    }

    /// The three LM tokens are registered AND their REYALM# feeds resolve.
    ///
    /// These two facts have to be asserted together. Core walks the entire
    /// supporting-collateral set on EVERY margin computation, so a registered
    /// LM token whose node does not resolve reverts every fill, liquidation
    /// and funding update on the venue -- which is precisely what kept them
    /// out until their prices were seeded (see
    /// devnet/oracle_adapters/seed_lm_token_prices.toml).
    ///
    /// The freshness half is the subtle one. Nothing pushes REYALM# on any
    /// chain: reya-off-chain filters REYA* out of the Stork subscription
    /// chain-wide, and the adapters serve these pairs from their own
    /// LmTokenPrice storage instead. An UNSEEDED pair returns the empty
    /// payload ("", 0, 0), and timestamp 0 fails the node's 180s
    /// maxStaleDuration with StalePriceDetected -- so "unpriced" surfaces as
    /// staleness, not as a zero price. A SEEDED pair is stamped with
    /// block.timestamp at READ time, so it is permanently fresh with no
    /// pusher at all. Asserting timestamp == block.timestamp pins that
    /// mechanism: if someone ever re-points these at a pushed feed, this line
    /// is the one that tells them the staleness model changed.
    function test_Devnet_CollateralMirror_LmTokensRegisteredAndPriced() public view {
        string[3] memory pairs = ["REYALM#SELINIUSDC", "REYALM#AMBERUSDC", "REYALM#HEDGEUSDC"];
        address[3] memory tokens = [RSELINI, RAMBER, RHEDGE];

        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                isSupporting(tokens[i]),
                string.concat("collateral mirror: LM token not registered ", vm.toString(tokens[i]))
            );

            NodeOutput.Data memory output = IOracleManagerProxy(sec.oracleManager).process(storkLeafNode(pairs[i]));
            require(output.price > 0, string.concat("collateral mirror: ", pairs[i], " resolves to a zero price"));
            require(
                output.timestamp == block.timestamp,
                string.concat(
                    "collateral mirror: ",
                    pairs[i],
                    " no longer stamps the read time -- a static LM seed would now be able to go stale"
                )
            );
        }
    }

    // ------------------------------------------------------------------
    // per-collateral economics and pricing
    // ------------------------------------------------------------------

    function checkCollateral(
        address token,
        string memory label,
        uint256 expectedHaircut,
        uint256 expectedAeInsuranceFee,
        uint256 expectedAeDiscount,
        bytes32 expectedNode,
        uint8 expectedDecimals
    )
        internal
        view
    {
        (CollateralConfig memory cfg, ParentCollateralConfig memory parent,) =
            ICoreProxy(sec.core).getCollateralConfig(1, token);

        require(cfg.depositingEnabled, string.concat(label, ": depositing disabled"));
        require(cfg.autoExchangeInsuranceFee == expectedAeInsuranceFee, string.concat(label, ": AE insurance fee"));
        require(parent.priceHaircut == expectedHaircut, string.concat(label, ": price haircut"));
        require(parent.autoExchangeDiscount == expectedAeDiscount, string.concat(label, ": AE discount"));
        require(parent.collateralAddress == sec.rusd, string.concat(label, ": parent collateral != rUSD"));
        require(parent.oracleNodeId == expectedNode, string.concat(label, ": parent oracle node"));

        // Decimals are load-bearing, not cosmetic: every cap, auto-exchange
        // threshold and dust threshold is scaled through parseUnits(..,
        // <token>TokenDecimals) in the omnibus. wBTC at 8 rather than 18 is
        // the one that silently mis-scales a cap by 1e10 if it drifts.
        require(
            IERC20Decimals(token).decimals() == expectedDecimals,
            string.concat(label, ": decimals changed -- omnibus caps are scaled against this")
        );
    }

    /// Economics mirrored verbatim from mainnet, and the feed each one prices
    /// off, derived from its node definition rather than a pinned hash.
    function test_Devnet_CollateralMirror_ParamsAndFeeds() public view {
        checkCollateral(sec.wbtc, "wbtc", 0.1e18, 0.01e18, 0.02e18, storkDivNode("WBTCUSD"), 8);
        checkCollateral(sec.wsteth, "wsteth", 0.1e18, 0.01e18, 0.02e18, storkDivNode("WSTETHUSD"), 18);
        checkCollateral(sec.usde, "usde", 0.075e18, 0, 0.01e18, storkDivNode("USDEUSD"), 18);
        checkCollateral(sec.susde, "susde", 0.075e18, 0.005e18, 0.005e18, storkDivNode("SUSDEUSD"), 18);
        checkCollateral(sec.deusd, "deusd", 0.075e18, 0.005e18, 0.005e18, storkDivNode("DEUSDUSD"), 18);
        // sdeUSD is the one that does NOT price off a live feed, on either
        // environment: mainnet pins it to the same frozen closing constant.
        checkCollateral(sec.sdeusd, "sdeusd", 0.075e18, 0.005e18, 0.005e18, constantNode(SDEUSD_CLOSING_PRICE), 18);

        // The LM tokens price off a BARE REYALM# leaf, not the base/USDC div
        // node every other collateral uses -- the adapters already serve these
        // pairs quoted in USDC, so there is nothing to divide by. Economics are
        // mainnet's verbatim (cp1Rusd_rselini_* etc. in the omnibus).
        checkCollateral(RSELINI, "rselini", 0.075e18, 0.005e18, 0.005e18, storkLeafNode("REYALM#SELINIUSDC"), 18);
        checkCollateral(RAMBER, "ramber", 0.075e18, 0.005e18, 0.005e18, storkLeafNode("REYALM#AMBERUSDC"), 18);
        checkCollateral(RHEDGE, "rhedge", 0.075e18, 0.005e18, 0.005e18, storkLeafNode("REYALM#HEDGEUSDC"), 18);
    }

    /// Every mirrored collateral prices. The config-closure walk covers this
    /// generically; asserting it per token here turns "some collateral is
    /// broken" into a named failure, and pins the sdeUSD constant's value.
    function test_Devnet_CollateralMirror_AllParentsPrice() public view {
        address[] memory supporting = supportingCollaterals();
        for (uint256 i = 0; i < supporting.length; i++) {
            (, ParentCollateralConfig memory parent,) = ICoreProxy(sec.core).getCollateralConfig(1, supporting[i]);
            uint256 price = IOracleManagerProxy(sec.oracleManager).process(parent.oracleNodeId).price;
            require(price > 0, string.concat("collateral mirror: zero price for ", vm.toString(supporting[i])));
        }

        require(
            IOracleManagerProxy(sec.oracleManager).process(constantNode(SDEUSD_CLOSING_PRICE)).price
                == SDEUSD_CLOSING_PRICE,
            "collateral mirror: sdeUSD closing constant drifted from the mainnet-parity value"
        );
    }
}
