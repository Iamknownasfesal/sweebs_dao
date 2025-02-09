module sweebs_dao::vote_table;

use sui::dynamic_field as df;
use sweebs_dao::errors;

// === Structs ===

public struct VoteTable has store, key {
    id: UID,
}

// === Public-Mutative Functions ===

public fun new(ctx: &mut TxContext): VoteTable {
    VoteTable { id: object::new(ctx) }
}

public fun add(self: &mut VoteTable, nft: ID, vote_index: u64) {
    assert!(!self.contains(nft), errors::vote_already_exists!());
    df::add(&mut self.id, nft, vote_index);
}

// === Public-View Functions ===

public fun contains(self: &VoteTable, nft: ID): bool {
    df::exists_(&self.id, nft)
}

public fun destruct(self: VoteTable) {
    let VoteTable { id } = self;
    object::delete(id);
}
