module sweebs_dao::interface;

use kiosk::personal_kiosk::PersonalKioskCap;
use std::string::String;
use sui::{clock::Clock, kiosk::{Kiosk, KioskOwnerCap}};
use sweebs_dao::{
    acl::AdminWitness,
    allowed_versions::AllowedVersions,
    config::DaoConfig,
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
    clock: &Clock,
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
        clock,
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
    av: &AllowedVersions,
    clock: &Clock,
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
    clock: &Clock,
    ctx: &mut TxContext,
) {
    proposal.vote<NFT>(config, object::id(nft), vote_index, av, clock, ctx);
}

public fun vote_from_kiosk<NFT: key + store>(
    proposal: &mut Proposal,
    config: &DaoConfig,
    kiosk: &mut Kiosk,
    kiosk_owner_cap: &mut KioskOwnerCap,
    nfts: vector<ID>,
    vote_index: u64,
    av: &AllowedVersions,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    nfts.do!(|nft| {
        proposal.vote<NFT>(
            config,
            object::id(kiosk.borrow_mut<NFT>(kiosk_owner_cap, nft)),
            vote_index,
            av,
            clock,
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
    clock: &Clock,
    ctx: &mut TxContext,
) {
    nfts.do!(|nft| {
        proposal.vote<NFT>(
            config,
            object::id(kiosk.borrow_mut<NFT>(kiosk_owner_cap.borrow(), nft)),
            vote_index,
            av,
            clock,
            ctx,
        );
    });
}

// === Public Config Functions ===

public fun set_maximum_amount_of_participants(
    config: &mut DaoConfig,
    _: &AdminWitness<DAO>,
    maximum_amount_of_participants: u64,
    _: &mut TxContext,
) {
    config.set_maximum_amount_of_participants(
        maximum_amount_of_participants,
    );
}

public fun set_quorum(
    config: &mut DaoConfig,
    _: &AdminWitness<DAO>,
    quorum: u8,
    _: &mut TxContext,
) {
    config.set_quorum(quorum);
}

public fun set_min_yes_votes(
    config: &mut DaoConfig,
    _: &AdminWitness<DAO>,
    min_yes_votes: u64,
    _: &mut TxContext,
) {
    config.set_min_yes_votes(min_yes_votes);
}

public fun add_nft_type<NFT: key + store>(
    config: &mut DaoConfig,
    _: &AdminWitness<DAO>,
    _: &mut TxContext,
) {
    config.add_nft_type<NFT>();
}

public fun remove_nft_type<NFT: key + store>(
    config: &mut DaoConfig,
    _: &AdminWitness<DAO>,
    _: &mut TxContext,
) {
    config.remove_nft_type<NFT>();
}
