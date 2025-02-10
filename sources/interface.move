module sweebs_dao::interface;

use kiosk::personal_kiosk::PersonalKioskCap;
use std::string::String;
use sui::{clock::Clock, kiosk::{Kiosk, KioskOwnerCap}};
use sweebs_dao::{
    acl::AdminWitness,
    allowed_versions::AllowedVersions,
    config::{Self, DaoConfig},
    dao::DAO,
    proposal::{Self, Proposal}
};

// === Public Proposal Functions ===

public fun propose(
    _: &AdminWitness<DAO>,
    config: &mut DaoConfig,
    title: String,
    description: String,
    start_time: u64,
    end_time: u64,
    vote_type_titles: vector<String>,
    av: &AllowedVersions,
    ctx: &mut TxContext,
): Proposal {
    proposal::new(
        title,
        description,
        start_time,
        end_time,
        config,
        vote_type_titles,
        av,
        ctx,
    )
}

#[allow(lint(share_owned))]
public fun share_proposal(proposal: Proposal, _: &mut TxContext) {
    transfer::public_share_object(proposal);
}

public fun execute(
    proposal: &mut Proposal,
    config: &DaoConfig,
    clock: &Clock,
    av: &AllowedVersions,
    ctx: &mut TxContext,
) {
    proposal.execute(config, clock, av, ctx);
}

public fun vote<NFT: key + store>(
    proposal: &mut Proposal,
    config: &DaoConfig,
    nft: &NFT,
    vote_index: u64,
    av: &AllowedVersions,
    ctx: &mut TxContext,
) {
    proposal.vote<NFT>(config, object::id(nft), vote_index, av, ctx);
}

public fun vote_from_kiosk<NFT: key + store>(
    proposal: &mut Proposal,
    config: &DaoConfig,
    kiosk: &mut Kiosk,
    kiosk_owner_cap: &mut KioskOwnerCap,
    nfts: vector<ID>,
    vote_index: u64,
    av: &AllowedVersions,
    ctx: &mut TxContext,
) {
    nfts.do!(|nft| {
        proposal.vote<NFT>(
            config,
            object::id(kiosk.borrow_mut<NFT>(kiosk_owner_cap, nft)),
            vote_index,
            av,
            ctx,
        );
    });
}

public fun vote_from_personal_kiosk<NFT: key + store>(
    proposal: &mut Proposal,
    config: &DaoConfig,
    kiosk: &mut Kiosk,
    kiosk_owner_cap: &mut PersonalKioskCap,
    nfts: vector<ID>,
    vote_index: u64,
    av: &AllowedVersions,
    ctx: &mut TxContext,
) {
    nfts.do!(|nft| {
        proposal.vote<NFT>(
            config,
            object::id(kiosk.borrow_mut<NFT>(kiosk_owner_cap.borrow(), nft)),
            vote_index,
            av,
            ctx,
        );
    });
}

// === Public Config Functions ===

public fun new_config<NFT: key + store>(
    _: &AdminWitness<DAO>,
    maximum_amount_of_participants: u64,
    quorum: u8,
    min_yes_votes: u64,
    min_voting_period: u64,
    max_voting_period: u64,
    ctx: &mut TxContext,
): DaoConfig {
    config::new<NFT>(
        maximum_amount_of_participants,
        quorum,
        min_yes_votes,
        min_voting_period,
        max_voting_period,
        ctx,
    )
}

#[allow(lint(share_owned))]
public fun share_config(config: DaoConfig, _: &mut TxContext) {
    transfer::public_share_object(config);
}

public fun set_maximum_amount_of_participants(
    config: &mut DaoConfig,
    witness: &AdminWitness<DAO>,
    maximum_amount_of_participants: u64,
    _: &mut TxContext,
) {
    config.set_maximum_amount_of_participants(
        witness,
        maximum_amount_of_participants,
    );
}

public fun set_quorum(
    config: &mut DaoConfig,
    witness: &AdminWitness<DAO>,
    quorum: u8,
    _: &mut TxContext,
) {
    config.set_quorum(witness, quorum);
}

public fun set_min_yes_votes(
    config: &mut DaoConfig,
    witness: &AdminWitness<DAO>,
    min_yes_votes: u64,
    _: &mut TxContext,
) {
    config.set_min_yes_votes(witness, min_yes_votes);
}

public fun set_min_voting_period(
    config: &mut DaoConfig,
    witness: &AdminWitness<DAO>,
    min_voting_period: u64,
    _: &mut TxContext,
) {
    config.set_min_voting_period(witness, min_voting_period);
}

public fun set_max_voting_period(
    config: &mut DaoConfig,
    witness: &AdminWitness<DAO>,
    max_voting_period: u64,
    _: &mut TxContext,
) {
    config.set_max_voting_period(witness, max_voting_period);
}

public fun add_nft_type<NFT: key + store>(
    config: &mut DaoConfig,
    witness: &AdminWitness<DAO>,
    _: &mut TxContext,
) {
    config.add_nft_type<NFT>(witness);
}

public fun remove_nft_type<NFT: key + store>(
    config: &mut DaoConfig,
    witness: &AdminWitness<DAO>,
    _: &mut TxContext,
) {
    config.remove_nft_type<NFT>(witness);
}
