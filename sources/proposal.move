module sweebs_dao::proposal;

use std::string::String;
use sui::clock::Clock;
use sweebs_dao::{
    allowed_versions::AllowedVersions,
    config::DaoConfig,
    errors,
    events,
    vote_table::{Self, VoteTable},
    vote_type::{Self, VoteType}
};

// === Structs ===

public enum ProposalStatus has copy, drop, store {
    Failed,
    Active,
    Executed(VoteType),
}

public struct ProposalInfo has store, copy, drop {
    /// The proposal index
    number: u64,
    /// The title of the proposal
    title: String,
    /// The description of the proposal
    description: String,
    /// The creator of the proposal
    creator: address,
    /// The total vote value of the proposal
    total_vote_value: u64,
    /// When the users can start voting
    start_time: u64,
    /// Users can no longer vote after the `end_time`.
    end_time: u64,
}

public struct Proposal has key, store {
    id: UID,
    /// The vote types that can be voted on
    vote_types: vector<VoteType>,
    /// The table of votes
    vote_table: VoteTable,
    /// The table of voters -> vote_index
    voter_table: VoteTable,
    /// The info of the proposal
    info: ProposalInfo,
    /// The status of the proposal
    status: ProposalStatus,
    /// The config of the DAO that is being used in this proposal
    config: ID,
}

/// === Public Package Functions ===

public(package) fun new(
    title: String,
    description: String,
    start_time: u64,
    end_time: u64,
    config: &mut DaoConfig,
    vote_types: vector<String>,
    av: &AllowedVersions,
    ctx: &mut TxContext,
): Proposal {
    assert!(vote_types.length() > 0, errors::invalid_vote_types!());
    assert!(start_time < end_time, errors::invalid_time_range!());
    av.assert_pkg_version();

    config.proposal_created();

    let proposal = Proposal {
        id: object::new(ctx),
        vote_types: vote_types.map!(|title| vote_type::from_string(title)),
        vote_table: vote_table::new(ctx),
        voter_table: vote_table::new(ctx),
        info: ProposalInfo {
            number: config.proposal_index(),
            title,
            description,
            creator: tx_context::sender(ctx),
            total_vote_value: 0,
            start_time,
            end_time,
        },
        status: ProposalStatus::Active,
        config: config.id(),
    };

    events::propose(
        proposal.id(),
        title,
        description,
        start_time,
        end_time,
        vote_types,
        ctx,
    );

    proposal
}

public(package) fun vote<NFT: key + store>(
    proposal: &mut Proposal,
    config: &DaoConfig,
    nft: ID,
    vote_index: u64,
    av: &AllowedVersions,
    ctx: &TxContext,
) {
    config.assert_nft_type<NFT>();
    proposal.assert_config_id(config);
    av.assert_pkg_version();

    if (proposal.voter_table.contains(ctx.sender())) {
        let index = proposal.voter_table.get(ctx.sender());

        assert!(vote_index == index, errors::invalid_vote_index!());
    } else {
        proposal.voter_table.add(ctx.sender(), vote_index);
    };

    proposal.vote_table.add(nft, vote_index);
    proposal.vote_types.borrow_mut(vote_index).increment_total_vote_value();
    proposal.increment_total_vote_value();

    events::vote<NFT>(proposal.id(), nft, vote_index, ctx);
}

public(package) fun execute(
    proposal: &mut Proposal,
    config: &DaoConfig,
    clock: &Clock,
    av: &AllowedVersions,
    ctx: &mut TxContext,
) {
    proposal.assert_proposal_active();
    proposal.assert_proposal_timing(clock);
    proposal.assert_config_id(config);
    av.assert_pkg_version();

    let vote_type = get_biggest_vote_type(proposal);

    if (
        config.if_min_yes_votes_met(vote_type.total_vote_value()) && config.if_quorum_met(quorum_threshold(proposal, config))
    ) {
        proposal.status = ProposalStatus::Executed(vote_type);
    } else {
        proposal.status = ProposalStatus::Failed;
    };

    events::execute(proposal.id(), proposal.winner(), ctx);
}

// === Public Package View Functions ===

public(package) fun id(proposal: &Proposal): ID {
    object::id(proposal)
}

public(package) fun status(proposal: &Proposal): ProposalStatus {
    proposal.status
}

public(package) fun winner(proposal: &Proposal): Option<VoteType> {
    match (proposal.status) {
        ProposalStatus::Executed(vote_type) => option::some(vote_type),
        _ => option::none(),
    }
}

// === Private Functions ===

fun get_biggest_vote_type(proposal: &Proposal): VoteType {
    let vote_types = &proposal.vote_types;

    let mut i = 1;
    let mut biggest_vote_type = vote_types.borrow(0);

    while (i < vote_types.length()) {
        let vote_type = vote_types.borrow(i);
        let vote_value = vote_type.total_vote_value();

        if (vote_value > biggest_vote_type.total_vote_value()) {
            biggest_vote_type = vote_type;
        };

        i = i + 1;
    };

    *biggest_vote_type
}

fun increment_total_vote_value(proposal: &mut Proposal) {
    proposal.info.total_vote_value = proposal.info.total_vote_value + 1;
}

fun quorum_threshold(proposal: &Proposal, config: &DaoConfig): u8 {
    (
        (proposal.info.total_vote_value * 100) / config.maximum_amount_of_participants(),
    ) as u8
}

// === Assertions ===

fun assert_config_id(proposal: &Proposal, config: &DaoConfig) {
    assert!(proposal.config == config.id(), errors::invalid_config_id!());
}

fun assert_proposal_active(proposal: &Proposal) {
    assert!(
        proposal.status == ProposalStatus::Active,
        errors::invalid_proposal_status!(),
    );
}

fun assert_proposal_timing(proposal: &Proposal, clock: &Clock) {
    assert!(
        proposal.info.end_time < clock.timestamp_ms(),
        errors::invalid_proposal_timing!(),
    );
}

// === Test Functions ===

#[test_only]
public fun proposal_status_failed(): ProposalStatus {
    ProposalStatus::Failed
}

#[test_only]
public fun proposal_status_active(): ProposalStatus {
    ProposalStatus::Active
}

#[test_only]
public fun proposal_status_executed(vote_type: VoteType): ProposalStatus {
    ProposalStatus::Executed(vote_type)
}
