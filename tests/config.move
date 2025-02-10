// Copyright (c) DEFI, LDA
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module sweebs_dao::config_tests;

use std::type_name;
use sui::{test_scenario as ts, test_utils::{assert_eq, destroy}};
use sweebs_dao::{config, dao, errors, test_nft::NFT};

// Dummy type for testing invalid NFT type
public struct InvalidNFT has key, store {
    id: UID,
}

#[test]
fun test_init() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(sender);

    let dao_config = config::new<NFT>(
        100, // max participants
        51, // quorum
        10, // min yes votes
        1000, // min voting period
        2000, // max voting period
        scenario.ctx(),
    );

    assert_eq(dao_config.maximum_amount_of_participants(), 100);
    assert_eq(dao_config.quorum(), 51);
    assert_eq(dao_config.proposal_index(), 1);
    assert_eq(dao_config.nft_types().contains(&type_name::get<NFT>()), true);

    destroy(dao_config);
    ts::end(scenario);
}

#[test]
fun test_setters() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    scenario.next_tx(sender);

    let mut dao_config = config::new<NFT>(
        100,
        51,
        10,
        1000,
        2000,
        scenario.ctx(),
    );

    // Test setting maximum amount of participants
    dao_config.set_maximum_amount_of_participants(200);
    assert_eq(dao_config.maximum_amount_of_participants(), 200);

    // Test setting quorum
    dao_config.set_quorum(75);
    assert_eq(dao_config.quorum(), 75);

    // Test setting min yes votes
    dao_config.set_min_yes_votes(20);

    // Test setting min voting period
    dao_config.set_min_voting_period(1500);

    // Test setting max voting period
    dao_config.set_max_voting_period(3000);

    // Test adding and removing NFT types
    dao_config.add_nft_type<NFT>();
    assert_eq(dao_config.nft_types().length(), 2);

    dao_config.remove_nft_type<NFT>();
    assert_eq(dao_config.nft_types().length(), 1);

    destroy(dao_config);
    ts::end(scenario);
}

#[test]
fun test_assertions() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(sender);

    let dao_config = config::new<NFT>(
        100,
        51,
        10,
        1000,
        2000,
        scenario.ctx(),
    );

    // Test quorum assertion
    dao_config.assert_quorum(51);
    dao_config.assert_quorum(75);

    // Test maximum participants assertion
    dao_config.assert_maximum_amount_of_participants(100);
    dao_config.assert_maximum_amount_of_participants(50);

    // Test min voting period assertion
    dao_config.assert_min_voting_period(1000);
    dao_config.assert_min_voting_period(1500);

    // Test max voting period assertion
    dao_config.assert_max_voting_period(2000);
    dao_config.assert_max_voting_period(1500);

    // Test NFT type assertion
    dao_config.assert_nft_type<NFT>();

    destroy(dao_config);
    ts::end(scenario);
}

#[test]
fun test_proposal_created() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(sender);

    let mut dao_config = config::new<NFT>(
        100,
        51,
        10,
        1000,
        2000,
        scenario.ctx(),
    );

    assert_eq(dao_config.proposal_index(), 1);
    dao_config.proposal_created();
    assert_eq(dao_config.proposal_index(), 2);

    destroy(dao_config);
    ts::end(scenario);
}

#[
    test,
    expected_failure(
        abort_code = errors::EInvalidQuorum,
        location = config,
    ),
]
fun test_assert_quorum_fails() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(sender);

    let dao_config = config::new<NFT>(
        100,
        51,
        10,
        1000,
        2000,
        scenario.ctx(),
    );

    dao_config.assert_quorum(50); // Should fail as it's less than required quorum

    destroy(dao_config);
    ts::end(scenario);
}

#[
    test,
    expected_failure(
        abort_code = errors::EInvalidMaxParticipants,
        location = config,
    ),
]
fun test_assert_max_participants_fails() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(sender);

    let dao_config = config::new<NFT>(
        100,
        51,
        10,
        1000,
        2000,
        scenario.ctx(),
    );

    dao_config.assert_maximum_amount_of_participants(101); // Should fail as it exceeds max

    destroy(dao_config);
    ts::end(scenario);
}

#[
    test,
    expected_failure(
        abort_code = errors::EInvalidMinVotingPeriod,
        location = config,
    ),
]
fun test_assert_min_voting_period_fails() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(sender);

    let dao_config = config::new<NFT>(
        100,
        51,
        10,
        1000,
        2000,
        scenario.ctx(),
    );

    dao_config.assert_min_voting_period(999); // Should fail as it's less than min

    destroy(dao_config);
    ts::end(scenario);
}

#[
    test,
    expected_failure(
        abort_code = errors::EInvalidMaxVotingPeriod,
        location = config,
    ),
]
fun test_assert_max_voting_period_fails() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(sender);

    let dao_config = config::new<NFT>(
        100,
        51,
        10,
        1000,
        2000,
        scenario.ctx(),
    );

    dao_config.assert_max_voting_period(2001); // Should fail as it exceeds max

    destroy(dao_config);
    ts::end(scenario);
}

#[
    test,
    expected_failure(
        abort_code = errors::EInvalidNFTType,
        location = config,
    ),
]
fun test_assert_nft_type_fails() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(sender);

    let dao_config = config::new<NFT>(
        100,
        51,
        10,
        1000,
        2000,
        scenario.ctx(),
    );

    dao_config.assert_nft_type<InvalidNFT>(); // Should fail as InvalidNFT is not a registered NFT type

    destroy(dao_config);
    ts::end(scenario);
}
