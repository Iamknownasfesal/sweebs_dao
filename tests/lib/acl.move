// Copyright (c) DEFI, LDA
// SPDX-License-Identifier: Apache-2.0

#[test_only, allow(unused_mut_ref)]
module sweebs_dao::acl_tests;

use std::u64;
use sui::{
    test_scenario::{Self as ts, Scenario},
    test_utils::{destroy, assert_eq}
};
use sweebs_dao::{acl::{Self, ACL, SuperAdmin}, errors};

const ADMIN: address = @0xa11ce;
const NEW_ADMIN: address = @0xdead;

public struct A()

public struct Dapp<phantom T> {
    scenario: Option<Scenario>,
    acl: Option<ACL<T>>,
    super_admin: Option<SuperAdmin<T>>,
}

#[test]
fun test_new() {
    let mut dapp = deploy<A>();

    dapp.tx!(|acl, super_admin_option, _scenario| {
        let super_admin = super_admin_option.borrow();

        assert_eq(acl.admins().size(), 0);
        assert_eq(super_admin.new_admin(), @0x0);
        assert_eq(super_admin.start(), u64::max_value!());
    });

    dapp.end();
}

#[test]
fun test_new_admin() {
    let mut dapp = deploy<A>();

    dapp.tx!(|acl, super_admin_option, scenario| {
        let super_admin = super_admin_option.borrow();

        assert_eq(acl.admins().size(), 0);

        let admin = acl.new_admin(super_admin, scenario.ctx());

        assert_eq(acl.admins().size(), 1);
        assert_eq(acl.is_admin(admin.address()), true);

        acl.destroy_admin(admin);
    });

    dapp.end();
}

#[test]
fun test_revoke() {
    let mut dapp = deploy<A>();

    dapp.tx!(|acl, super_admin_option, scenario| {
        let super_admin = super_admin_option.borrow();

        assert_eq(acl.admins().size(), 0);

        let admin = acl.new_admin(super_admin, scenario.ctx());

        assert_eq(acl.admins().size(), 1);
        assert_eq(acl.is_admin(admin.address()), true);

        acl.revoke(super_admin, admin.address());

        assert_eq(acl.admins().size(), 0);
        assert_eq(acl.is_admin(admin.address()), false);

        acl.destroy_admin(admin);
    });

    dapp.end();
}

#[test]
fun test_sign_in() {
    let mut dapp = deploy<A>();

    dapp.tx!(|acl, super_admin_option, scenario| {
        assert_eq(acl.admins().size(), 0);

        let super_admin = super_admin_option.borrow();

        let admin = acl.new_admin(super_admin, scenario.ctx());

        assert_eq(acl.admins().size(), 1);
        assert_eq(acl.is_admin(admin.address()), true);

        let _witness = acl.sign_in(&admin);

        acl.destroy_admin(admin);
    });

    dapp.end();
}

#[test]
fun test_super_admin_transfer() {
    let mut dapp = deploy<A>();

    dapp.tx!(|_acl, super_admin_option, scenario| {
        let super_admin = super_admin_option.borrow_mut();

        assert_eq(super_admin.new_admin(), @0x0);
        assert_eq(super_admin.start(), u64::max_value!());

        scenario.next_epoch(ADMIN);
        scenario.next_epoch(ADMIN);

        super_admin.start_transfer(NEW_ADMIN, scenario.ctx());

        assert_eq(super_admin.new_admin(), NEW_ADMIN);
        assert_eq(super_admin.start(), 2);

        scenario.next_epoch(ADMIN);
        scenario.next_epoch(ADMIN);
        scenario.next_epoch(ADMIN);
        scenario.next_epoch(ADMIN);

        let super_admin = super_admin_option.extract();

        super_admin.finish_transfer(scenario.ctx());

        scenario.next_epoch(NEW_ADMIN);

        let super_admin = scenario.take_from_sender<SuperAdmin<A>>();

        assert_eq(super_admin.new_admin(), @0x0);
        assert_eq(super_admin.start(), u64::max_value!());

        destroy(super_admin);
    });

    dapp.end();
}

#[
    test,
    expected_failure(
        abort_code = errors::EInvalidNewSuperAdmin,
        location = acl,
    ),
]
fun test_super_admin_transfer_error_same_sender() {
    let mut dapp = deploy<A>();

    dapp.tx!(|_acl, super_admin_option, scenario| {
        let super_admin = super_admin_option.borrow_mut();

        super_admin.start_transfer(ADMIN, scenario.ctx());
    });

    dapp.end();
}

#[
    test,
    expected_failure(
        abort_code = errors::EInvalidNewSuperAdmin,
        location = acl,
    ),
]
fun test_super_admin_transfer_error_zero_address() {
    let mut dapp = deploy<A>();

    dapp.tx!(|_acl, super_admin_option, scenario| {
        let super_admin = super_admin_option.borrow_mut();

        super_admin.start_transfer(@0x0, scenario.ctx());
    });

    dapp.end();
}

#[
    test,
    expected_failure(
        abort_code = errors::EInvalidSuperAdminTransferEpoch,
        location = acl,
    ),
]
fun test_super_admin_finish_transfer_invalid_epoch() {
    let mut dapp = deploy<A>();

    dapp.tx!(|_acl, super_admin_option, scenario| {
        let super_admin = super_admin_option.borrow_mut();

        super_admin.start_transfer(NEW_ADMIN, scenario.ctx());

        scenario.next_epoch(ADMIN);
        scenario.next_epoch(ADMIN);
        scenario.next_epoch(ADMIN);

        let super_admin = super_admin_option.extract();

        super_admin.finish_transfer(scenario.ctx());
    });

    dapp.end();
}

#[test, expected_failure(abort_code = errors::EInvalidAdmin, location = acl)]
fun test_sign_in_error_invalid_admin() {
    let mut dapp = deploy<A>();

    dapp.tx!(|acl, super_admin_option, scenario| {
        let super_admin = super_admin_option.borrow();

        assert_eq(acl.admins().size(), 0);

        let admin = acl.new_admin(super_admin, scenario.ctx());

        acl.revoke(super_admin, admin.address());

        let _witness = acl.sign_in(&admin);

        acl.destroy_admin(admin);
    });

    dapp.end();
}

macro fun tx<$T>(
    $dapp: &mut Dapp<$T>,
    $f: |&mut ACL<$T>, &mut Option<SuperAdmin<$T>>, &mut Scenario|,
) {
    let dapp = $dapp;

    let mut acl = dapp.acl.extract();
    let mut scenario = dapp.scenario.extract();

    $f(&mut acl, &mut dapp.super_admin, &mut scenario);

    dapp.acl.fill(acl);
    dapp.scenario.fill(scenario);
}

fun new_acl<T>(scenario: &mut Scenario): (ACL<T>, SuperAdmin<T>) {
    acl::new<A>(scenario.ctx());

    scenario.next_tx(ADMIN);

    let acl = scenario.take_shared<ACL<T>>();
    let super_admin = scenario.take_from_sender<SuperAdmin<T>>();

    (acl, super_admin)
}

fun deploy<T>(): Dapp<T> {
    let mut scenario = ts::begin(ADMIN);

    let (acl, super_admin) = new_acl(&mut scenario);

    Dapp {
        scenario: option::some(scenario),
        acl: option::some(acl),
        super_admin: option::some(super_admin),
    }
}

fun end<T>(dapp: Dapp<T>) {
    destroy(dapp);
}
