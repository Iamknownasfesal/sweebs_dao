module sweebs_dao::vote_type;

use std::string::String;

// === Structs ===

public struct VoteType has store, copy, drop {
    /// The name of the {VoteType}.
    name: String,
    /// Total vote value
    total_vote_value: u64,
}

// === Public-Mutative Functions ===

public fun new(name: String, total_vote_value: u64): VoteType {
    VoteType { name, total_vote_value }
}

public fun increment_total_vote_value(self: &mut VoteType) {
    self.total_vote_value = self.total_vote_value + 1;
}

public fun from_string(name: String): VoteType {
    VoteType { name, total_vote_value: 0 }
}

// === Public-View Functions ===

public fun name(self: &VoteType): String {
    self.name
}

public fun total_vote_value(self: &VoteType): u64 {
    self.total_vote_value
}

// === Test Functions ===

#[test_only]
public fun create_for_test(name: String, total_vote_value: u64): VoteType {
    new(name, total_vote_value)
}
