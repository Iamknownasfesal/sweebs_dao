module sweebs_dao::acl;

use std::u64;
use sui::vec_set::{Self, VecSet};
use sweebs_dao::{errors as errors, events as events};

// === Constants ===

// @dev Each epoch is roughly 1 day
const THREE_EPOCHS: u64 = 3;

// === Structs ===

public struct AdminWitness<phantom T>() has drop;

public struct SuperAdmin<phantom T> has key {
    id: UID,
    new_admin: address,
    start: u64,
}

public struct Admin<phantom T> has key, store {
    id: UID,
}

public struct ACL<phantom T> has key {
    id: UID,
    admins: VecSet<address>,
}

// === Admin Operations ===

public fun new_admin<T>(
    acl: &mut ACL<T>,
    _: &SuperAdmin<T>,
    ctx: &mut TxContext,
): Admin<T> {
    let admin = Admin<T> {
        id: object::new(ctx),
    };

    acl.admins.insert(admin.id.to_address());

    events::new_admin(admin.id.to_address());

    admin
}

public fun new_and_transfer<T>(
    acl: &mut ACL<T>,
    super_admin: &SuperAdmin<T>,
    new_admin: address,
    ctx: &mut TxContext,
) {
    transfer::public_transfer(acl.new_admin(super_admin, ctx), new_admin);
}

public fun revoke<T>(acl: &mut ACL<T>, _: &SuperAdmin<T>, old_admin: address) {
    acl.admins.remove(&old_admin);

    events::revoke_admin(old_admin);
}

public fun is_admin<T>(acl: &ACL<T>, admin: address): bool {
    acl.admins.contains(&admin)
}

public fun sign_in<T>(acl: &ACL<T>, admin: &Admin<T>): AdminWitness<T> {
    assert!(is_admin(acl, admin.id.to_address()), errors::invalid_admin!());

    AdminWitness()
}

public fun destroy_admin<T>(acl: &mut ACL<T>, admin: Admin<T>) {
    let Admin { id } = admin;

    if (acl.admins.contains(&id.to_address())) {
        acl.admins.remove(&id.to_address())
    };

    id.delete();
}

// === Transfer Super Admin ===

public fun start_transfer<T>(
    super_admin: &mut SuperAdmin<T>,
    new_admin: address,
    ctx: &mut TxContext,
) {
    // dev Destroy it instead for the Sui rebate
    assert!(
        new_admin != @0x0 && new_admin != ctx.sender(),
        errors::invalid_new_super_admin!(),
    );

    super_admin.start = ctx.epoch();
    super_admin.new_admin = new_admin;

    events::start_super_admin_transfer(new_admin, super_admin.start);
}

public fun finish_transfer<T>(
    mut super_admin: SuperAdmin<T>,
    ctx: &mut TxContext,
) {
    assert!(
        ctx.epoch() > super_admin.start + THREE_EPOCHS,
        errors::invalid_super_admin_transfer_epoch!(),
    );

    let new_admin = super_admin.new_admin;
    super_admin.new_admin = @0x0;
    super_admin.start = u64::max_value!();

    transfer::transfer(super_admin, new_admin);

    events::finish_super_admin_transfer(new_admin);
}

// @dev This is irreversible, the contract does not offer a way to create a new
// super admin
public fun destroy<T>(super_admin: SuperAdmin<T>) {
    let SuperAdmin { id, .. } = super_admin;
    id.delete();
}

// === Package Functions ===

public(package) fun new<T>(ctx: &mut TxContext) {
    let super_admin = SuperAdmin<T> {
        id: object::new(ctx),
        new_admin: @0x0,
        start: u64::max_value!(),
    };

    let acl = ACL<T> {
        id: object::new(ctx),
        admins: vec_set::empty(),
    };

    transfer::share_object(acl);
    transfer::transfer(super_admin, ctx.sender());
}

// === Test Functions ===

#[test_only]
public fun sign_in_for_test<T>(): AdminWitness<T> {
    AdminWitness()
}

#[test_only]
public fun admins<T>(acl: &ACL<T>): &VecSet<address> {
    &acl.admins
}

#[test_only]
public fun super_admin_new_admin<T>(super_admin: &SuperAdmin<T>): address {
    super_admin.new_admin
}

#[test_only]
public fun start<T>(super_admin: &SuperAdmin<T>): u64 {
    super_admin.start
}

#[test_only]
public fun addr<T>(admin: &Admin<T>): address {
    admin.id.to_address()
}

#[test_only]
public use fun addr as Admin.address;

// === Test Aliases ===

#[test_only]
public use fun super_admin_new_admin as SuperAdmin.new_admin;
