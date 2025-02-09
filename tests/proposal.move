#[test_only]
module sweebs_dao::proposal_tests;

use sui::{clock, test_scenario as ts, test_utils::{assert_eq, destroy}};
use sweebs_dao::{
    acl,
    allowed_versions::{Self, AV},
    config,
    dao,
    errors,
    proposal,
    test_nft::{Self, NFT},
    vote_table,
    vote_type
};

const SENDER: address = @0x0;
const TITLE: vector<u8> = b"Test Proposal";
const DESCRIPTION: vector<u8> = b"This is a test proposal";
const START_TIME: u64 = 1000;
const END_TIME: u64 = 2000;
const VOTE_TYPES: vector<vector<u8>> = vector[b"Yes", b"No", b"Abstain"];

#[test]
fun test_new_proposal() {
    let mut scenario = ts::begin(SENDER);

    // Initialize DAO and get necessary objects
    dao::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let witness = acl::sign_in_for_test();
    let mut dao_config = config::new<NFT>(
        &witness,
        100, // max participants
        51, // quorum
        10, // min yes votes
        500, // min voting period
        2000, // max voting period
        scenario.ctx(),
    );

    allowed_versions::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let av = scenario.take_shared<AV>();

    // Create proposal
    let proposal = proposal::new(
        TITLE.to_string(),
        DESCRIPTION.to_string(),
        START_TIME,
        END_TIME,
        &mut dao_config,
        VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    // Verify proposal state
    assert_eq(proposal.status(), proposal::proposal_status_active());
    assert_eq(proposal.winner(), option::none());

    destroy(proposal);
    destroy(dao_config);
    destroy(av);
    ts::end(scenario);
}

#[test]
fun test_successful_execution() {
    let mut scenario = ts::begin(SENDER);
    dao::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);
    let witness = acl::sign_in_for_test();
    let mut dao_config = config::new<NFT>(
        &witness,
        10, // max participants
        51, // quorum
        5, // min yes votes
        500,
        2000,
        scenario.ctx(),
    );

    allowed_versions::init_for_test(scenario.ctx());
    scenario.next_tx(SENDER);
    let av = scenario.take_shared<AV>();

    let mut proposal = proposal::new(
        TITLE.to_string(),
        DESCRIPTION.to_string(),
        START_TIME,
        END_TIME,
        &mut dao_config,
        VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    // Cast 6 yes votes - enough for both quorum and min yes votes
    let mut i = 0;
    while (i < 6) {
        let nft = test_nft::new(scenario.ctx());
        proposal.vote<NFT>(
            &dao_config,
            nft.id(),
            0, // Vote "Yes"
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        nft.burn();
        i = i + 1;
    };

    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(END_TIME + 1);

    proposal.execute(
        &dao_config,
        &clock,
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    // Verify proposal was executed successfully
    assert_eq(
        proposal.status(),
        proposal::proposal_status_executed(
            vote_type::create_for_test(b"Yes".to_string(), 6),
        ),
    );

    destroy(proposal);
    destroy(dao_config);
    destroy(clock);
    destroy(av);
    ts::end(scenario);
}

#[test]
fun test_vote_and_execute_failed() {
    let mut scenario = ts::begin(SENDER);

    // Initialize DAO
    dao::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let witness = acl::sign_in_for_test();
    let mut dao_config = config::new<NFT>(
        &witness,
        10, // Lower max participants for easier testing
        51, // 51% quorum
        8, // min yes votes
        500,
        2000,
        scenario.ctx(),
    );

    allowed_versions::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let av = scenario.take_shared<AV>();

    // Create proposal
    let mut proposal = proposal::new(
        TITLE.to_string(),
        DESCRIPTION.to_string(),
        START_TIME,
        END_TIME,
        &mut dao_config,
        VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    // Create and vote with 6 NFTs to meet quorum (51% of 10 = 6)
    let mut i = 0;

    while (i < 7) {
        let nft = test_nft::new(scenario.ctx());

        proposal.vote<NFT>(
            &dao_config,
            nft.id(),
            0, // Vote "Yes"
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        nft.burn();
        i = i + 1;
    };

    // Create clock and set time after end_time
    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(END_TIME + 1);

    // Execute proposal
    proposal.execute(
        &dao_config,
        &clock,
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    // Verify proposal was executed (should be Executed since we have enough Yes
    // votes)
    assert_eq(
        proposal.status(),
        proposal::proposal_status_failed(),
    );

    destroy(proposal);
    destroy(dao_config);
    destroy(clock);
    destroy(av);
    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = errors::EInvalidTimeRange, location = proposal)]
fun test_invalid_time_range() {
    let mut scenario = ts::begin(SENDER);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let witness = acl::sign_in_for_test();
    let mut dao_config = config::new<NFT>(
        &witness,
        100,
        51,
        10,
        500,
        2000,
        scenario.ctx(),
    );

    allowed_versions::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let av = scenario.take_shared<AV>();

    // Try to create proposal with end_time before start_time
    let proposal = proposal::new(
        TITLE.to_string(),
        DESCRIPTION.to_string(),
        2000, // start_time after end_time
        1000, // end_time
        &mut dao_config,
        VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    destroy(proposal);
    abort 69420
}

#[test]
#[expected_failure(abort_code = errors::EInvalidVoteTypes, location = proposal)]
fun test_empty_vote_types() {
    let mut scenario = ts::begin(SENDER);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let witness = acl::sign_in_for_test();
    let mut dao_config = config::new<NFT>(
        &witness,
        100,
        51,
        10,
        500,
        2000,
        scenario.ctx(),
    );

    allowed_versions::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let av = scenario.take_shared<AV>();

    // Try to create proposal with empty vote types
    let proposal = proposal::new(
        TITLE.to_string(),
        DESCRIPTION.to_string(),
        START_TIME,
        END_TIME,
        &mut dao_config,
        vector[], // Empty vote types
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    destroy(proposal);
    abort 69420
}

#[test]
#[
    expected_failure(
        abort_code = errors::EVoteAlreadyExists,
        location = vote_table,
    ),
]
fun test_duplicate_vote() {
    let mut scenario = ts::begin(SENDER);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let witness = acl::sign_in_for_test();
    let mut dao_config = config::new<NFT>(
        &witness,
        100,
        51,
        10,
        500,
        2000,
        scenario.ctx(),
    );

    allowed_versions::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let av = scenario.take_shared<AV>();

    let mut proposal = proposal::new(
        TITLE.to_string(),
        DESCRIPTION.to_string(),
        START_TIME,
        END_TIME,
        &mut dao_config,
        VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    // Create NFT for voting
    let nft = test_nft::new(scenario.ctx());

    // Vote first time
    proposal.vote<NFT>(
        &dao_config,
        nft.id(),
        0,
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    // Try to vote again with same NFT
    proposal.vote<NFT>(
        &dao_config,
        nft.id(),
        1,
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    abort 69420
}

#[test]
#[expected_failure(abort_code = errors::EInvalidQuorum, location = config)]
fun test_quorum_not_met() {
    let mut scenario = ts::begin(SENDER);
    dao::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);
    let witness = acl::sign_in_for_test();
    let mut dao_config = config::new<NFT>(
        &witness,
        10, // max participants
        51, // quorum
        2, // min yes votes - set low to isolate quorum test
        500,
        2000,
        scenario.ctx(),
    );

    allowed_versions::init_for_test(scenario.ctx());
    scenario.next_tx(SENDER);
    let av = scenario.take_shared<AV>();

    let mut proposal = proposal::new(
        TITLE.to_string(),
        DESCRIPTION.to_string(),
        START_TIME,
        END_TIME,
        &mut dao_config,
        VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    // Cast only 4 yes votes - not enough for 51% quorum of 10 participants
    let mut i = 0;
    while (i < 4) {
        let nft = test_nft::new(scenario.ctx());
        proposal.vote<NFT>(
            &dao_config,
            nft.id(),
            0, // Vote "Yes"
            &av.get_allowed_versions(),
            scenario.ctx(),
        );
        test_nft::burn(nft);
        i = i + 1;
    };

    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(END_TIME + 1);

    // Should fail because quorum not met (only 40% voted)
    proposal.execute(
        &dao_config,
        &clock,
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    abort 69420
}

#[test]
#[expected_failure(abort_code = errors::EInvalidConfigId, location = proposal)]
fun test_invalid_config_id() {
    let mut scenario = ts::begin(SENDER);
    dao::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);
    let witness = acl::sign_in_for_test();

    // Create two different configs
    let mut dao_config1 = config::new<NFT>(
        &witness,
        10,
        51,
        5,
        500,
        2000,
        scenario.ctx(),
    );

    let dao_config2 = config::new<NFT>(
        &witness,
        10,
        51,
        5,
        500,
        2000,
        scenario.ctx(),
    );

    allowed_versions::init_for_test(scenario.ctx());
    scenario.next_tx(SENDER);
    let av = scenario.take_shared<AV>();

    // Create proposal with config1
    let mut proposal = proposal::new(
        TITLE.to_string(),
        DESCRIPTION.to_string(),
        START_TIME,
        END_TIME,
        &mut dao_config1,
        VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    // Try to vote using config2 - should fail with EInvalidConfigId
    let nft = test_nft::new(scenario.ctx());
    proposal.vote<NFT>(
        &dao_config2, // Wrong config
        nft.id(),
        0,
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    abort 69420
}

#[test]
#[
    expected_failure(
        abort_code = errors::EInvalidProposalTiming,
        location = proposal,
    ),
]
fun test_execute_before_end_time() {
    let mut scenario = ts::begin(SENDER);
    dao::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);
    let witness = acl::sign_in_for_test();
    let mut dao_config = config::new<NFT>(
        &witness,
        10,
        51,
        5,
        500,
        2000,
        scenario.ctx(),
    );

    allowed_versions::init_for_test(scenario.ctx());
    scenario.next_tx(SENDER);
    let av = scenario.take_shared<AV>();

    let mut proposal = proposal::new(
        TITLE.to_string(),
        DESCRIPTION.to_string(),
        START_TIME,
        END_TIME,
        &mut dao_config,
        VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(END_TIME - 5);

    // Try to execute before end time - should fail
    proposal.execute(
        &dao_config,
        &clock,
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    abort 69420
}

#[test]
#[
    expected_failure(
        abort_code = errors::EInvalidProposalStatus,
        location = proposal,
    ),
]
fun test_execute_after_end_time_and_execute_again() {
    let mut scenario = ts::begin(SENDER);
    dao::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);
    let witness = acl::sign_in_for_test();
    let mut dao_config = config::new<NFT>(
        &witness,
        10,
        51,
        5,
        500,
        2000,
        scenario.ctx(),
    );

    allowed_versions::init_for_test(scenario.ctx());
    scenario.next_tx(SENDER);
    let av = scenario.take_shared<AV>();

    let mut proposal = proposal::new(
        TITLE.to_string(),
        DESCRIPTION.to_string(),
        START_TIME,
        END_TIME,
        &mut dao_config,
        VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(END_TIME + 1);

    // Create and vote with 6 NFTs to meet quorum (51% of 10 = 6)
    let mut i = 0;

    while (i < 7) {
        let nft = test_nft::new(scenario.ctx());
        let nft_id = nft.id();

        proposal.vote<NFT>(
            &dao_config,
            nft_id,
            0, // Vote "Yes"
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        test_nft::burn(nft);
        i = i + 1;
    };

    // Try to execute
    proposal.execute(
        &dao_config,
        &clock,
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    // Try to execute again - should fail
    proposal.execute(
        &dao_config,
        &clock,
        &av.get_allowed_versions(),
        scenario.ctx(),
    );

    abort 69420
}
