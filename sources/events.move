module sweebs_dao::events;

use std::{string::String, type_name::{Self, TypeName}};
use sweebs_dao::{event_wrapper::emit_event, vote_type::VoteType};

// === Structs ===

public struct StartSuperAdminTransfer has copy, drop {
    new_admin: address,
    start: u64,
}

public struct FinishSuperAdminTransfer(address) has copy, drop;

public struct NewAdmin(address) has copy, drop;

public struct RevokeAdmin(address) has copy, drop;

public struct Propose has copy, drop {
    id: ID,
    title: String,
    description: String,
    start_time: u64,
    end_time: u64,
    vote_type_titles: vector<String>,
}

public struct Vote has copy, drop {
    proposal_id: ID,
    sender: address,
    nft_id: ID,
    nft_type: TypeName,
    vote_type: u64,
}

public struct Execute has copy, drop {
    proposal_id: ID,
    result: Option<VoteType>,
}

// === Package Functions ===

public(package) fun start_super_admin_transfer(new_admin: address, start: u64) {
    emit_event(StartSuperAdminTransfer {
        new_admin,
        start,
    });
}

public(package) fun finish_super_admin_transfer(new_admin: address) {
    emit_event(FinishSuperAdminTransfer(new_admin));
}

public(package) fun new_admin(admin: address) {
    emit_event(NewAdmin(admin));
}

public(package) fun revoke_admin(admin: address) {
    emit_event(RevokeAdmin(admin));
}

public(package) fun propose(
    id: ID,
    title: String,
    description: String,
    start_time: u64,
    end_time: u64,
    vote_type_titles: vector<String>,
    _: &mut TxContext,
) {
    emit_event(Propose {
        id,
        title,
        description,
        start_time,
        end_time,
        vote_type_titles,
    });
}

public(package) fun vote<NFT: key + store>(
    proposal_id: ID,
    nft_id: ID,
    vote_type: u64,
    ctx: &TxContext,
) {
    emit_event(Vote {
        sender: ctx.sender(),
        proposal_id,
        nft_id,
        nft_type: type_name::get<NFT>(),
        vote_type,
    });
}

public(package) fun execute(
    proposal_id: ID,
    result: Option<VoteType>,
    _: &mut TxContext,
) {
    emit_event(Execute {
        proposal_id,
        result,
    });
}
