// Copyright (c) DEFI, LDA
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module sweebs_dao::test_nft;

use sui::{package, transfer_policy as policy, tx_context::sender};

public struct TEST_NFT has drop {}
public struct NFT has key, store {
    id: UID,
}

#[allow(lint(share_owned))]
fun init(otw: TEST_NFT, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);
    let (policy, policy_cap) = policy::new<NFT>(&publisher, ctx);
    transfer::public_share_object(policy);
    transfer::public_transfer(publisher, sender(ctx));
    transfer::public_transfer(policy_cap, sender(ctx));
}

public fun new(ctx: &mut TxContext): NFT {
    NFT { id: object::new(ctx) }
}

public fun burn(nft: NFT) {
    let NFT { id } = nft;
    object::delete(id);
}

public fun id(nft: &NFT): ID {
    object::id(nft)
}

#[test_only]
public fun test_init(ctx: &mut TxContext) {
    init(TEST_NFT {}, ctx);
}
