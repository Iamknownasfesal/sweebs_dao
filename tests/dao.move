// Copyright (c) DEFI, LDA
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module sweebs_dao::dao_tests;

use std::u64;
use sui::{
    package::Publisher,
    test_scenario as ts,
    test_utils::{assert_eq, destroy}
};
use sweebs_dao::{acl::{ACL, SuperAdmin}, dao::{Self, DAO}};

#[test]
fun test_init() {
    let sender = @0x0;

    let mut scenario = ts::begin(sender);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(sender);

    let super_admin = scenario.take_from_sender<SuperAdmin<DAO>>();
    let acl = scenario.take_shared<ACL<DAO>>();

    assert_eq(acl.admins().size(), 0);
    assert_eq(super_admin.new_admin(), @0x0);
    assert_eq(super_admin.start(), u64::max_value!());

    let publisher = scenario.take_from_sender<Publisher>();

    assert_eq(*publisher.module_(), b"dao".to_ascii_string());

    destroy(publisher);
    destroy(super_admin);
    destroy(acl);
    destroy(scenario);
}
