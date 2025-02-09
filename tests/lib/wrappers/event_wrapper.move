// Copyright (c) DEFI, LDA
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module sweebs_dao::event_wrapper_tests;

use sui::{test_scenario as ts, test_utils::assert_eq};
use sweebs_dao::event_wrapper::emit_event;

public struct A() has copy, drop;

#[test]
fun test_emit_event() {
    let sender = @0x1;
    let mut scenario = ts::begin(sender);

    emit_event<A>(A());

    let tx = scenario.next_tx(sender);

    assert_eq(tx.num_user_events(), 1);

    scenario.end();
}
