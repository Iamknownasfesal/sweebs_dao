// Copyright (c) DEFI, LDA
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module sweebs_dao::errors_tests;

use sui::test_utils::assert_eq;
use sweebs_dao::errors;

#[test]
fun test_end_to_end() {
    // Test admin related errors
    assert_eq(errors::invalid_super_admin_transfer_epoch!(), 0);
    assert_eq(errors::invalid_new_super_admin!(), 1);
    assert_eq(errors::invalid_admin!(), 2);

    // Test version related errors
    assert_eq(errors::outdated_package_version!(), 3);
    assert_eq(errors::remove_current_version_not_allowed!(), 4);

    // Test configuration related errors
    assert_eq(errors::invalid_max_participants!(), 5);
    assert_eq(errors::invalid_min_voting_period!(), 6);
    assert_eq(errors::invalid_max_voting_period!(), 7);

    // Test NFT and voting related errors
    assert_eq(errors::invalid_nft_type!(), 8);
    assert_eq(errors::vote_already_exists!(), 9);
    assert_eq(errors::invalid_config_id!(), 10);
    assert_eq(errors::invalid_vote_types!(), 11);
    assert_eq(errors::invalid_time_range!(), 12);
    assert_eq(errors::invalid_proposal_status!(), 13);
    assert_eq(errors::invalid_proposal_timing!(), 14);
}
