// Copyright (c) DEFI, LDA
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module sweebs_dao::events_tests;

use sui::{test_scenario as ts, test_utils::assert_eq};
use sweebs_dao::{events, test_nft::NFT, vote_type};

#[test]
fun test_end_to_end() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    // Admin events
    events::start_super_admin_transfer(@0x1, 100);
    events::finish_super_admin_transfer(@0x1);
    events::new_admin(@0x1);
    events::revoke_admin(@0x1);

    let object = object::new(scenario.ctx());
    let id = object.to_inner();
    object.delete();

    // Proposal events
    events::propose(
        id,
        b"Test Proposal".to_string(),
        b"This is a test proposal".to_string(),
        100,
        200,
        vector[b"Yes".to_string(), b"No".to_string()],
        scenario.ctx(),
    );
    events::vote<NFT>(id, id, 0, scenario.ctx());
    events::vote<NFT>(id, id, 1, scenario.ctx());
    events::execute(
        id,
        option::some(vote_type::from_string(b"Yes".to_string())),
        scenario.ctx(),
    );

    let effects = scenario.next_tx(sender);

    assert_eq(effects.num_user_events(), 8);

    ts::end(scenario);
}
