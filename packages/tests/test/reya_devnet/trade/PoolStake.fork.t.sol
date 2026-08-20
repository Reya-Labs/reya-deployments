pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";
import { ActionMetadata, Action } from "../../../src/interfaces/ICoreProxy.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

/**
 * @title PoolStakeForkTest (Devnet)
 * @notice Behavioural coverage for devnet's OWN passive pool — the pool the
 *         genesis seed created and the sRUSD margin price flows from.
 * @dev The cronos PoolStake suite drives staking through periphery commands,
 *      which revert under the perpOB deployment; these tests call the pool's
 *      tokenized entrypoints directly, which is also what the genesis seed
 *      and any devnet staker actually use. Stakers must be sRUSD
 *      authorizedHolders (shares are minted to them as sRUSD), so the tests
 *      allowlist their actor exactly the way the deployment allowlisted the
 *      owner for the seed.
 */
contract PoolStakeForkTest is ReyaForkTest {
    uint128 constant POOL_ID = 1;

    function _allowlistedStaker(string memory name) internal returns (address staker) {
        staker = makeAddr(name);
        vm.prank(sec.multisig);
        ITokenProxy(sec.srusd).addToFeatureFlagAllowlist(keccak256(bytes("authorizedHolder")), staker);
    }

    function _stake(address staker, uint256 rusdAmount) internal returns (uint256 sharesMinted) {
        deal(sec.rusd, staker, rusdAmount);
        vm.startPrank(staker);
        ITokenProxy(sec.rusd).approve(sec.pool, rusdAmount);
        sharesMinted = IPassivePoolProxy(sec.pool).addLiquidityTokenized(
            POOL_ID, staker, rusdAmount, 0, ActionMetadata({ action: Action.StakeTokenized, onBehalfOf: staker })
        );
        vm.stopPrank();
    }

    /// UNIVERSAL share-conservation invariant, valid regardless of how
    /// liquidity was staked.
    ///
    /// Both stake paths always mint sRUSD (Stake.mintOrBurn is unconditional);
    /// they differ only in the recipient. Tokenized stakes mint to the staker;
    /// untokenized stakes mint to the POOL ITSELF and additionally record the
    /// claim in ShareBalances, which is what getShareSupply returns. So:
    ///
    ///   sRUSD.totalSupply()      = tokenized (held by stakers) + untokenized
    ///   pool.getShareSupply()    = untokenized only
    ///   sRUSD.balanceOf(pool)    = the pool's custody of untokenized shares
    ///
    /// The conservation law is therefore balanceOf(pool) == getShareSupply():
    /// the pool custodies exactly one sRUSD per untokenized share it has
    /// recorded. NOTE the tempting `totalSupply() == getShareSupply()` is NOT
    /// an invariant — it holds only if no liquidity is tokenized, the exact
    /// opposite of devnet, where all of it is.
    function test_Devnet_ShareConservation() public view {
        require(
            ITokenProxy(sec.srusd).balanceOf(sec.pool) == IPassivePoolProxy(sec.pool).getShareSupply(POOL_ID),
            "pool sRUSD custody != recorded untokenized share supply"
        );
        require(ITokenProxy(sec.srusd).totalSupply() > 0, "no shares at all (genesis seed missing?)");
    }

    /// Intent pin (devnet-specific, unlike the invariant above): every devnet
    /// share is tokenized, so the untokenized ledger should be empty. A
    /// non-zero value means someone staked through the legacy path.
    function test_Devnet_NoUntokenizedShares() public view {
        require(
            IPassivePoolProxy(sec.pool).getShareSupply(POOL_ID) == 0,
            "legacy untokenized share ledger must stay empty on devnet"
        );
    }

    /// Share-price identity, mirroring the pool's own computeSharePrice:
    /// margin (rUSD, 6dp) rescaled to share precision (30dp), divided by the
    /// sRUSD supply at 18dp — and the oracle node serves exactly it.
    function test_Devnet_SharePriceIdentity() public view {
        uint256 margin = IPassivePoolProxy(sec.pool).getPoolMarginBalance(POOL_ID);
        uint256 supply = ITokenProxy(sec.srusd).totalSupply();
        require(supply > 0, "pool has no shares (genesis seed missing?)");
        uint256 price = IPassivePoolProxy(sec.pool).getSharePrice(POOL_ID);
        require(price == (margin * 1e24) * 1e18 / supply, "share price != margin/supply identity");

        NodeOutput.Data memory out = IOracleManagerProxy(sec.oracleManager).process(sec.srusdUsdcPoolNodeId);
        require(out.price == price, "oracle node price != pool share price");
    }

    /// Stake → unstake round-trip: staking mints shares at the share price,
    /// unstaking them all returns the rUSD (within rounding dust), and the
    /// share price is invariant under the pair — staking is not a PnL event.
    function testFuzz_Devnet_StakeUnstakeRoundTrip(uint256 rusdAmount) public {
        rusdAmount = bound(rusdAmount, 1e6, 1_000_000e6);
        address staker = _allowlistedStaker("staker");

        uint256 priceBefore = IPassivePoolProxy(sec.pool).getSharePrice(POOL_ID);
        uint256 supplyBefore = ITokenProxy(sec.srusd).totalSupply();

        uint256 shares = _stake(staker, rusdAmount);
        require(shares > 0, "stake minted no shares");
        require(ITokenProxy(sec.srusd).balanceOf(staker) == shares, "shares not received as sRUSD");
        require(ITokenProxy(sec.srusd).totalSupply() == supplyBefore + shares, "supply did not grow by minted shares");

        uint256 priceMid = IPassivePoolProxy(sec.pool).getSharePrice(POOL_ID);
        require(_approxEq(priceMid, priceBefore, 1e6), "share price moved on stake");

        vm.prank(staker);
        uint256 rusdOut = IPassivePoolProxy(sec.pool).removeLiquidityTokenized(
            POOL_ID, shares, 0, ActionMetadata({ action: Action.UnstakeTokenized, onBehalfOf: staker })
        );

        require(ITokenProxy(sec.rusd).balanceOf(staker) == rusdOut, "unstake proceeds not received");
        // one unit of rUSD (6dp) rounding dust allowed on the round-trip
        require(rusdOut <= rusdAmount && rusdAmount - rusdOut <= 1, "round-trip lost more than dust");

        require(ITokenProxy(sec.srusd).totalSupply() == supplyBefore, "supply did not return to baseline");
        require(
            _approxEq(IPassivePoolProxy(sec.pool).getSharePrice(POOL_ID), priceBefore, 1e6),
            "share price moved over the round-trip"
        );
    }

    /// The conservation law must survive an arbitrary stake, not just the
    /// deployment's own genesis seed.
    function testFuzz_Devnet_ShareConservationHoldsAfterStake(uint256 rusdAmount) public {
        rusdAmount = bound(rusdAmount, 1e6, 1_000_000e6);
        address staker = _allowlistedStaker("conservationStaker");
        _stake(staker, rusdAmount);
        require(
            ITokenProxy(sec.srusd).balanceOf(sec.pool) == IPassivePoolProxy(sec.pool).getShareSupply(POOL_ID),
            "conservation broken by a tokenized stake"
        );
    }

    /// Share price is monotone in pool margin and independent of who holds
    /// the shares: two sequential stakes must mint at the same rate when no
    /// PnL happens in between.
    function testFuzz_Devnet_StakeRateIsPriceConsistent(uint256 amountA, uint256 amountB) public {
        amountA = bound(amountA, 1e6, 100_000e6);
        amountB = bound(amountB, 1e6, 100_000e6);

        uint256 sharesA = _stake(_allowlistedStaker("rateStakerA"), amountA);
        uint256 sharesB = _stake(_allowlistedStaker("rateStakerB"), amountB);

        // sharesA/amountA == sharesB/amountB, cross-multiplied to avoid
        // division; 1e18 absolute tolerance covers 30dp/6dp rounding.
        uint256 lhs = sharesA * amountB;
        uint256 rhs = sharesB * amountA;
        require(_approxEq(lhs, rhs, 1e18), "stake rate drifted between two consecutive stakes");
    }

    function _approxEq(uint256 a, uint256 b, uint256 tol) internal pure returns (bool) {
        return a >= b ? a - b <= tol : b - a <= tol;
    }
}
