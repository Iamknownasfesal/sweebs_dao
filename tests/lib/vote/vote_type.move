#[test_only]
module sweebs_dao::vote_type_tests;

use sui::test_utils::assert_eq;
use sweebs_dao::vote_type;

#[test]
fun test_new() {
    let name = b"Yes".to_string();
    let total_vote_value = 0;
    let vote_type = vote_type::new(name, total_vote_value);

    assert_eq(vote_type::name(&vote_type), name);
    assert_eq(vote_type::total_vote_value(&vote_type), total_vote_value);
}

#[test]
fun test_from_string() {
    let name = b"No".to_string();
    let vote_type = vote_type::from_string(name);

    assert_eq(vote_type::name(&vote_type), name);
    assert_eq(vote_type::total_vote_value(&vote_type), 0);
}

#[test]
fun test_increment_total_vote_value() {
    let name = b"Abstain".to_string();
    let mut vote_type = vote_type::new(name, 0);

    // Test initial value
    assert_eq(vote_type::total_vote_value(&vote_type), 0);

    // Test after increment
    vote_type::increment_total_vote_value(&mut vote_type);
    assert_eq(vote_type::total_vote_value(&vote_type), 1);

    // Test multiple increments
    vote_type::increment_total_vote_value(&mut vote_type);
    vote_type::increment_total_vote_value(&mut vote_type);
    assert_eq(vote_type::total_vote_value(&vote_type), 3);
}
