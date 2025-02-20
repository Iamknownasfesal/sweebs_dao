#[allow(unused_mut_ref)]
#[test_only]
module sweebs_dao::proposal_tests;

use sui::{
    clock::{Self, Clock},
    test_scenario::{Self as ts, Scenario},
    test_utils::{assert_eq, destroy}
};
use sweebs_dao::{
    allowed_versions::{Self, AV},
    config::{Self, DaoConfig},
    errors,
    proposal::{Self, Proposal},
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

public struct Dapp {
    scenario: Option<Scenario>,
    av: Option<AV>,
    config: Option<DaoConfig>,
    clock: Option<Clock>,
}

#[test]
fun test_new_proposal() {
    let mut dapp = deploy();

    dapp.tx!(|av, config, _, scenario| {
        // Create proposal
        let proposal = proposal::new(
            TITLE.to_string(),
            DESCRIPTION.to_string(),
            START_TIME,
            END_TIME,
            config,
            VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        assert_eq(proposal.status(), proposal::proposal_status_active());
        assert_eq(proposal.winner(), option::none());
        destroy(proposal);
    });

    dapp.end();
}

#[test]
fun test_successful_execution() {
    let mut dapp = deploy();

    dapp.tx!(|av, config, clock, scenario| {
        let mut proposal = proposal::new(
            TITLE.to_string(),
            DESCRIPTION.to_string(),
            START_TIME,
            END_TIME,
            config,
            VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        // Cast 6 yes votes - enough for both quorum and min yes votes
        vote(av, config, scenario, &mut proposal, 0, 6);

        clock.set_for_testing(END_TIME + 1);

        proposal.execute(
            config,
            clock,
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
    });

    dapp.end();
}

#[test]
fun test_vote_and_execute_failed() {
    let mut dapp = deploy();

    dapp.tx!(|av, config, clock, scenario| {
        // Create proposal
        let mut proposal = proposal::new(
            TITLE.to_string(),
            DESCRIPTION.to_string(),
            START_TIME,
            END_TIME,
            config,
            VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        clock.set_for_testing(END_TIME + 1);

        // Execute proposal
        proposal.execute(
            config,
            clock,
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        // Verify proposal was failed
        assert_eq(
            proposal.status(),
            proposal::proposal_status_failed(),
        );

        destroy(proposal);
    });

    dapp.end();
}

#[test]
fun test_quorum_not_met() {
    let mut dapp = deploy();

    dapp.tx!(|av, config, clock, scenario| {
        let mut proposal = proposal::new(
            TITLE.to_string(),
            DESCRIPTION.to_string(),
            START_TIME,
            END_TIME,
            config,
            VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        // Cast only 4 yes votes - not enough for 51% quorum of 10 participants
        vote(av, config, scenario, &mut proposal, 0, 4);

        clock.set_for_testing(END_TIME + 1);

        // Should fail because quorum not met (only 40% voted)
        proposal.execute(
            config,
            clock,
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        assert_eq(
            proposal.status(),
            proposal::proposal_status_failed(),
        );

        destroy(proposal);
    });

    dapp.end();
}

#[test]
#[expected_failure(abort_code = errors::EInvalidTimeRange, location = proposal)]
fun test_invalid_time_range() {
    let mut dapp = deploy();

    dapp.tx!(|av, config, _, scenario| {
        let proposal = proposal::new(
            TITLE.to_string(),
            DESCRIPTION.to_string(),
            2000, // start_time after end_time
            1000, // end_time
            config,
            VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        destroy(proposal);
    });

    dapp.end();
}

#[test]
#[expected_failure(abort_code = errors::EInvalidVoteTypes, location = proposal)]
fun test_empty_vote_types() {
    let mut dapp = deploy();

    dapp.tx!(|av, config, _, scenario| {
        // Try to create proposal with empty vote types
        let proposal = proposal::new(
            TITLE.to_string(),
            DESCRIPTION.to_string(),
            START_TIME,
            END_TIME,
            config,
            vector[], // Empty vote types
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        destroy(proposal);
    });

    dapp.end();
}

#[test]
#[
    expected_failure(
        abort_code = errors::EVoteAlreadyExists,
        location = vote_table,
    ),
]
fun test_duplicate_vote() {
    let mut dapp = deploy();

    dapp.tx!(|av, config, _, scenario| {
        let mut proposal = proposal::new(
            TITLE.to_string(),
            DESCRIPTION.to_string(),
            START_TIME,
            END_TIME,
            config,
            VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        // Create NFT for voting
        let nft = test_nft::new(scenario.ctx());

        // Vote first time
        proposal.vote<NFT>(
            config,
            nft.id(),
            0,
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        // Try to vote again with same NFT
        proposal.vote<NFT>(
            config,
            nft.id(),
            1,
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        destroy(proposal);
        nft.burn();
    });

    dapp.end();
}

#[test]
#[expected_failure(abort_code = errors::EInvalidConfigId, location = proposal)]
fun test_invalid_config_id() {
    let mut dapp = deploy();

    dapp.tx!(|av, config1, _, scenario| {
        let config2 = create_test_config(scenario.ctx());

        // Create proposal with config1
        let mut proposal = proposal::new(
            TITLE.to_string(),
            DESCRIPTION.to_string(),
            START_TIME,
            END_TIME,
            config1,
            VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        // Try to vote using config2 - should fail with EInvalidConfigId
        vote(
            av,
            &config2,
            scenario,
            &mut proposal,
            0,
            1,
        );

        destroy(proposal);
        destroy(config2);
    });

    dapp.end();
}

#[test]
#[
    expected_failure(
        abort_code = errors::EInvalidProposalTiming,
        location = proposal,
    ),
]
fun test_execute_before_end_time() {
    let mut dapp = deploy();

    dapp.tx!(|av, config, clock, scenario| {
        let mut proposal = proposal::new(
            TITLE.to_string(),
            DESCRIPTION.to_string(),
            START_TIME,
            END_TIME,
            config,
            VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        clock.set_for_testing(END_TIME - 5);

        // Try to execute before end time - should fail
        proposal.execute(
            config,
            clock,
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        destroy(proposal);
    });

    dapp.end();
}

#[test]
#[
    expected_failure(
        abort_code = errors::EInvalidProposalStatus,
        location = proposal,
    ),
]
fun test_execute_after_end_time_and_execute_again() {
    let mut dapp = deploy();

    dapp.tx!(|av, config, clock, scenario| {
        let mut proposal = proposal::new(
            TITLE.to_string(),
            DESCRIPTION.to_string(),
            START_TIME,
            END_TIME,
            config,
            VOTE_TYPES.map!(|vote_type| vote_type.to_string()),
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        clock.set_for_testing(END_TIME + 1);

        // Create and vote with 6 NFTs to meet quorum (51% of 10 = 6)
        vote(
            av,
            config,
            scenario,
            &mut proposal,
            0,
            6,
        );

        // Try to execute
        proposal.execute(
            config,
            clock,
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        // Try to execute again - should fail
        proposal.execute(
            config,
            clock,
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        destroy(proposal);
    });

    dapp.end();
}

fun deploy(): Dapp {
    let mut scenario = ts::begin(SENDER);

    allowed_versions::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let av = scenario.take_shared<AV>();
    let config = create_test_config(scenario.ctx());

    let clock = clock::create_for_testing(scenario.ctx());

    Dapp {
        scenario: option::some(scenario),
        av: option::some(av),
        config: option::some(config),
        clock: option::some(clock),
    }
}

fun end(dapp: Dapp) {
    destroy(dapp);
}

fun create_test_config(ctx: &mut TxContext): DaoConfig {
    let mut config = config::new(
        10,
        51,
        2,
        1000,
        2000,
        ctx,
    );

    config.add_nft_type<NFT>();

    config
}

macro fun tx(
    $dapp: &mut Dapp,
    $f: |&AV, &mut DaoConfig, &mut Clock, &mut Scenario|,
) {
    let dapp = $dapp;

    let av = dapp.av.extract();
    let mut config = dapp.config.extract();
    let mut clock = dapp.clock.extract();
    let mut scenario = dapp.scenario.extract();

    $f(&av, &mut config, &mut clock, &mut scenario);

    dapp.av.fill(av);
    dapp.config.fill(config);
    dapp.clock.fill(clock);
    dapp.scenario.fill(scenario);
}

fun vote(
    av: &AV,
    config: &DaoConfig,
    scenario: &mut Scenario,
    proposal: &mut Proposal,
    vote_type: u64,
    vote_amount: u64,
) {
    let mut i = 0;

    while (i < vote_amount) {
        let nft = test_nft::new(scenario.ctx());

        proposal.vote<NFT>(
            config,
            nft.id(),
            vote_type,
            &av.get_allowed_versions(),
            scenario.ctx(),
        );

        test_nft::burn(nft);
        i = i + 1;
    };
}
