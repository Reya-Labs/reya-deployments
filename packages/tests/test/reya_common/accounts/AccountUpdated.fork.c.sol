pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";

/// @dev Minimal inline view on the core 1.0.28 AccountUpdated sequence getter, kept out of
/// the shared ICoreProxy ABI so pre-orderbook routers keep compiling without it.
interface IAccountUpdatedSequence {
    function getLatestAccountUpdatedEventSequenceNumber() external view returns (uint128);
}

/**
 * @title AccountUpdatedForkCheck
 * @notice Fork test for the AccountUpdated event sequence counter introduced in core 1.0.28.
 * @dev The core router now emits `AccountUpdated(eventSequenceNumber, accountId, owner,
 *      mainAccountId, blockTimestamp)` whenever either the owner or the mainAccountId of an
 *      account changes, with a monotonic sequence number exposed via
 *      `getLatestAccountUpdatedEventSequenceNumber()`. This check asserts the sequence
 *      increments across two successive account-mutating actions.
 */
contract AccountUpdatedForkCheck is BaseReyaForkTest {
    function check_AccountUpdatedSequenceIncrements() internal {
        (address owner1,) = makeAddrAndKey("accountUpdatedOwner1");
        (address owner2,) = makeAddrAndKey("accountUpdatedOwner2");

        uint128 seqBefore = IAccountUpdatedSequence(sec.core).getLatestAccountUpdatedEventSequenceNumber();

        vm.prank(sec.multisig);
        ICoreProxy(sec.core).createAccount(owner1);
        uint128 seqAfter1 = IAccountUpdatedSequence(sec.core).getLatestAccountUpdatedEventSequenceNumber();
        assertGt(seqAfter1, seqBefore, "createAccount should emit AccountUpdated");

        vm.prank(sec.multisig);
        ICoreProxy(sec.core).createAccount(owner2);
        uint128 seqAfter2 = IAccountUpdatedSequence(sec.core).getLatestAccountUpdatedEventSequenceNumber();
        assertGt(seqAfter2, seqAfter1, "second createAccount should increment sequence number again");
    }
}
