#[test_only]
module sweebs_dao::vote_table_tests;

use sui::{test_scenario as ts, test_utils::assert_eq};
use sweebs_dao::{errors, vote_table};

#[test]
fun test_end_to_end() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    // Create a new vote table
    let mut vote_table = vote_table::new(scenario.ctx());

    // Create a dummy object ID for testing
    let dummy_obj = object::new(scenario.ctx());
    let dummy_id = object::uid_to_inner(&dummy_obj);
    object::delete(dummy_obj);

    // Test contains before adding
    assert_eq(vote_table::contains(&vote_table, dummy_id), false);

    // Add a vote
    vote_table::add(&mut vote_table, dummy_id, 1);

    // Test contains after adding
    assert_eq(vote_table::contains(&vote_table, dummy_id), true);

    // Cleanup
    vote_table::destruct(vote_table);
    ts::end(scenario);
}

#[test]
#[
    expected_failure(
        abort_code = errors::EVoteAlreadyExists,
        location = vote_table,
    ),
]
fun test_add_duplicate_vote() {
    let sender = @0x0;
    let mut scenario = ts::begin(sender);

    let mut vote_table = vote_table::new(scenario.ctx());

    let dummy_obj = object::new(scenario.ctx());
    let dummy_id = object::uid_to_inner(&dummy_obj);
    object::delete(dummy_obj);

    // Add vote first time - should succeed
    vote_table::add(&mut vote_table, dummy_id, 1);

    // Add vote second time - should fail
    vote_table::add(&mut vote_table, dummy_id, 2);

    vote_table::destruct(vote_table);
    ts::end(scenario);
}
