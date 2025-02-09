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

// === Public Functions ===

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
public fun share_proposal(proposal: Proposal) {
    transfer::public_share_object(proposal);
}

public fun execute(
    proposal: &mut Proposal,
    config: &DaoConfig,
    clock: &Clock,
    av: &AllowedVersions,
    ctx: &mut TxContext,
) {
    proposal::execute(proposal, config, clock, av, ctx);
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
