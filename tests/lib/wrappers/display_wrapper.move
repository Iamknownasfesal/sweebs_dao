// Copyright (c) DEFI, LDA
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module sweebs_dao::display_wrapper_tests;

use sui::{
    display,
    package::Publisher,
    test_scenario as ts,
    test_utils::destroy
};
use sweebs_dao::{dao, display_wrapper, test_nft::NFT};

public struct A() has copy, drop;

#[test]
fun test_emit_event() {
    let sender = @0x1;
    let mut scenario = ts::begin(sender);

    dao::init_for_test(scenario.ctx());

    scenario.next_tx(sender);

    let publisher = scenario.take_from_sender<Publisher>();

    let mut display = display::new<NFT>(&publisher, scenario.ctx());
    display.add(b"name".to_string(), b"Proposal".to_string());
    display.add(
        b"description".to_string(),
        b"This is a test proposal".to_string(),
    );
    display.add(b"image_url".to_string(), b"yessir".to_string());
    display.update_version();

    let display_wrapper = display_wrapper::new(display, scenario.ctx());

    destroy(publisher);
    destroy(display_wrapper);
    scenario.end();
}
