module sweebs_dao::vote_table;

use sui::dynamic_field as df;
use sweebs_dao::errors;

// === Structs ===

public struct VoteTable has store, key {
    id: UID,
}

// === Public-Mutative Functions ===

public(package) fun new(ctx: &mut TxContext): VoteTable {
    VoteTable { id: object::new(ctx) }
}

public(package) fun add<T: copy + drop + store>(
    self: &mut VoteTable,
    object: T,
    vote_index: u64,
) {
    assert!(!self.contains(object), errors::vote_already_exists!());
    df::add(&mut self.id, object, vote_index);
}

public(package) fun get<T: copy + drop + store>(
    self: &VoteTable,
    object: T,
): u64 {
    *df::borrow(&self.id, object)
}

// === Public-View Functions ===

public(package) fun contains<T: copy + drop + store>(
    self: &VoteTable,
    object: T,
): bool {
    df::exists_(&self.id, object)
}

public(package) fun destruct(self: VoteTable) {
    let VoteTable { id } = self;
    object::delete(id);
}
