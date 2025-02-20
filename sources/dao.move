module sweebs_dao::dao;

use sui::package;
use sweebs_dao::{acl, config};

// === Structs ===

public struct DAO() has drop;

// === Constants ===

const MAXIMUM_AMOUNT_OF_PARTICIPANTS: u64 = 3333;
const QUORUM: u8 = 15;
const MIN_YES_VOTES: u64 = 400;

// === Initializer ===

fun init(otw: DAO, ctx: &mut TxContext) {
    acl::new<DAO>(ctx);

    let publisher = package::claim(otw, ctx);

    transfer::public_transfer(publisher, ctx.sender());

    let config = config::new(
        MAXIMUM_AMOUNT_OF_PARTICIPANTS,
        QUORUM,
        MIN_YES_VOTES,
        ctx,
    );

    transfer::public_share_object(config);
}

// === Test Only Functions ===

#[test_only]
public fun init_for_test(ctx: &mut TxContext) {
    init(DAO(), ctx);
}
