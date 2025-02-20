module sweebs_dao::dao;

use sui::package;
use sweebs_dao::{acl, config};

// === Structs ===

public struct DAO() has drop;

// === Constants ===

const MAXIMUM_AMOUNT_OF_PARTICIPANTS: u64 = 4444;
const QUORUM: u8 = 51;
const MIN_YES_VOTES: u64 = 200;
const MIN_VOTING_PERIOD: u64 = 10_000_000;
const MAX_VOTING_PERIOD: u64 = 10_000_000;

// === Initializer ===

fun init(otw: DAO, ctx: &mut TxContext) {
    acl::new<DAO>(ctx);

    let publisher = package::claim(otw, ctx);

    transfer::public_transfer(publisher, ctx.sender());

    let config = config::new(
        MAXIMUM_AMOUNT_OF_PARTICIPANTS,
        QUORUM,
        MIN_YES_VOTES,
        MIN_VOTING_PERIOD,
        MAX_VOTING_PERIOD,
        ctx,
    );

    transfer::public_share_object(config);
}

// === Test Only Functions ===

#[test_only]
public fun init_for_test(ctx: &mut TxContext) {
    init(DAO(), ctx);
}
