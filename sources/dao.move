module sweebs_dao::dao;

use sui::package;
use sweebs_dao::acl;

// === Structs ===

public struct DAO() has drop;

// === Initializer ===

fun init(otw: DAO, ctx: &mut TxContext) {
    acl::new<DAO>(ctx);

    let publisher = package::claim(otw, ctx);

    transfer::public_transfer(publisher, ctx.sender());
}

// === Test Only Functions ===

#[test_only]
public fun init_for_test(ctx: &mut TxContext) {
    init(DAO(), ctx);
}
