// Copyright (c) DEFI, LDA
// SPDX-License-Identifier: Apache-2.0

#[test_only, allow(unused_mut_ref)]
module sweebs_dao::version_tests;

use sui::{
    test_scenario::{Self as ts, Scenario},
    test_utils::{assert_eq, destroy}
};
use sweebs_dao::{acl, allowed_versions::{Self, AV}, errors};

const ADMIN: address = @0x1;

public struct Dapp {
    scenario: Option<Scenario>,
    allowed_versions: Option<AV>,
}

#[test]
fun test_init() {
    let mut dapp = deploy();

    dapp.tx!(|av, _| {
        assert_eq(av.allowed_versions(), vector[1]);
    });

    dapp.end();
}

#[test]
fun test_admin_functions() {
    let mut dapp = deploy();

    dapp.tx!(|av, _| {
        let witness = acl::sign_in_for_test();

        assert_eq(av.allowed_versions(), vector[1]);

        av.add(&witness, 2);

        av.add(&witness, 3);

        assert_eq(av.allowed_versions(), vector[1, 2, 3]);

        av.remove(&witness, 2);

        assert_eq(av.allowed_versions(), vector[1, 3]);
    });

    dapp.end();
}

#[test]
fun test_assert_pkg_version() {
    let mut dapp = deploy();

    dapp.tx!(|av, _| {
        av.get_allowed_versions().assert_pkg_version();

        let witness = acl::sign_in_for_test();

        av.add(&witness, 2);

        allowed_versions::get_allowed_versions_for_testing(
            1,
        ).assert_pkg_version();
    });

    dapp.end();
}

#[
    test,
    expected_failure(
        abort_code = errors::EOutdatedPackageVersion,
        location = allowed_versions,
    ),
]
fun test_outdated_package_version() {
    let mut dapp = deploy();

    dapp.tx!(|av, _| {
        let allowed_versions_witness = av.get_allowed_versions();

        allowed_versions_witness.assert_pkg_version();

        av.remove_for_testing(1);

        let witness = acl::sign_in_for_test();

        av.add(&witness, 2);

        assert_eq(av.allowed_versions(), vector[2]);

        av.get_allowed_versions().assert_pkg_version();
    });

    dapp.end();
}

#[
    test,
    expected_failure(
        abort_code = errors::ERemoveCurrentVersionNotAllowed,
        location = allowed_versions,
    ),
]
fun test_remove_current_version_not_allowed() {
    let mut dapp = deploy();

    dapp.tx!(|av, _| {
        let witness = acl::sign_in_for_test();

        av.remove(&witness, 1);
    });

    dapp.end();
}

macro fun tx($dapp: &mut Dapp, $f: |&mut AV, &mut Scenario|) {
    let dapp = $dapp;

    let mut allowed_versions = dapp.allowed_versions.extract();
    let mut scenario = dapp.scenario.extract();

    $f(&mut allowed_versions, &mut scenario);

    dapp.allowed_versions.fill(allowed_versions);
    dapp.scenario.fill(scenario);
}

fun deploy(): Dapp {
    let mut scenario = ts::begin(ADMIN);

    allowed_versions::init_for_test(scenario.ctx());

    scenario.next_tx(ADMIN);

    let allowed_versions = scenario.take_shared<AV>();

    Dapp {
        scenario: option::some(scenario),
        allowed_versions: option::some(allowed_versions),
    }
}

fun end(dapp: Dapp) {
    destroy(dapp)
}
