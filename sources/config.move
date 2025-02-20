module sweebs_dao::config;

use std::type_name::{Self, TypeName};
use sweebs_dao::errors;

public struct DaoConfig has key, store {
    id: UID,
    /// The total amount of maximum votes that can be cast
    maximum_amount_of_participants: u64,
    /// The quorum percentage required for a proposal to pass (0-100)
    quorum: u8,
    /// The minimum number of yes votes required for a proposal to pass
    min_yes_votes: u64,
    /// The amount of proposals created
    proposal_index: u64,
    /// TypeName of the NFT used for voting power
    nft_types: vector<TypeName>,
}

// === Package Functions ===

public(package) fun new(
    maximum_amount_of_participants: u64,
    quorum: u8,
    min_yes_votes: u64,
    ctx: &mut TxContext,
): DaoConfig {
    DaoConfig {
        id: object::new(ctx),
        maximum_amount_of_participants,
        quorum,
        min_yes_votes,
        proposal_index: 1,
        nft_types: vector[],
    }
}

public(package) fun proposal_created(dao_config: &mut DaoConfig) {
    dao_config.proposal_index = dao_config.proposal_index + 1;
}

// === Public-Mutative Functions ===

public(package) fun set_maximum_amount_of_participants(
    dao_config: &mut DaoConfig,
    maximum_amount_of_participants: u64,
) {
    dao_config.maximum_amount_of_participants = maximum_amount_of_participants;
}

public(package) fun set_quorum(dao_config: &mut DaoConfig, quorum: u8) {
    dao_config.quorum = quorum;
}

public(package) fun set_min_yes_votes(
    dao_config: &mut DaoConfig,
    min_yes_votes: u64,
) {
    dao_config.min_yes_votes = min_yes_votes;
}

public(package) fun add_nft_type<NFT: key + store>(dao_config: &mut DaoConfig) {
    dao_config.nft_types.push_back(type_name::get<NFT>());
}

public(package) fun remove_nft_type<NFT: key + store>(
    dao_config: &mut DaoConfig,
) {
    let (exist, index) = dao_config.nft_types.index_of(&type_name::get<NFT>());

    assert!(exist);

    dao_config.nft_types.remove(index);
}

// === Public-View Functions ===

public(package) fun id(dao_config: &DaoConfig): ID {
    object::id(dao_config)
}

public(package) fun quorum(dao_config: &DaoConfig): u8 {
    dao_config.quorum
}

public(package) fun nft_types(dao_config: &DaoConfig): vector<TypeName> {
    dao_config.nft_types
}

public(package) fun proposal_index(dao_config: &DaoConfig): u64 {
    dao_config.proposal_index
}

public(package) fun maximum_amount_of_participants(
    dao_config: &DaoConfig,
): u64 {
    dao_config.maximum_amount_of_participants
}

// === Assertions ===

public(package) fun assert_maximum_amount_of_participants(
    dao_config: &DaoConfig,
    maximum_amount_of_participants: u64,
) {
    assert!(
        maximum_amount_of_participants <= dao_config.maximum_amount_of_participants,
        errors::invalid_max_participants!(),
    );
}

public(package) fun assert_nft_type<NFT: key + store>(dao_config: &DaoConfig) {
    let (exist, _) = dao_config.nft_types.index_of(&type_name::get<NFT>());
    assert!(exist, errors::invalid_nft_type!());
}

// === Public Package Functions ===

public(package) fun if_min_yes_votes_met(
    dao_config: &DaoConfig,
    min_yes_votes: u64,
): bool {
    min_yes_votes >= dao_config.min_yes_votes
}

public(package) fun if_quorum_met(dao_config: &DaoConfig, quorum: u8): bool {
    quorum >= dao_config.quorum
}
