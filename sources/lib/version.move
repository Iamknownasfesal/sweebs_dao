#[allow(implicit_const_copy)]
module sweebs_dao::allowed_versions;

use sui::vec_set::{Self, VecSet};
use sweebs_dao::{acl::AdminWitness, dao::DAO, errors as errors};

// === Constants ===

const PACKAGE_VERSION: u64 = 1;

// === Structs ===

public struct AV has key {
    id: UID,
    allowed_versions: VecSet<u64>,
}

public struct AllowedVersions(vector<u64>) has drop;

// === Initializer ===

fun init(ctx: &mut TxContext) {
    let version = AV {
        id: object::new(ctx),
        allowed_versions: vec_set::singleton(PACKAGE_VERSION),
    };

    transfer::share_object(version);
}

// === Public View Functions ===

public fun get_allowed_versions(self: &AV): AllowedVersions {
    AllowedVersions(*self.allowed_versions.keys())
}

// === Admin Functions ===

public fun add(self: &mut AV, _: &AdminWitness<DAO>, version: u64) {
    self.allowed_versions.insert(version);
}

public fun remove(self: &mut AV, _: &AdminWitness<DAO>, version: u64) {
    assert!(
        version != PACKAGE_VERSION,
        errors::remove_current_version_not_allowed!(),
    );
    self.allowed_versions.remove(&version);
}

// === Public Package Functions ===

public(package) fun assert_pkg_version(self: &AllowedVersions) {
    assert!(
        self.0.contains(&PACKAGE_VERSION),
        errors::outdated_package_version!(),
    );
}

// === Test Functions ===

#[test_only]
public fun init_for_test(ctx: &mut TxContext) {
    init(ctx);
}

#[test_only]
public fun allowed_versions(self: &AV): vector<u64> {
    *self.allowed_versions.keys()
}

#[test_only]
public fun get_allowed_versions_for_testing(version: u64): AllowedVersions {
    AllowedVersions(vector[version])
}

#[test_only]
public fun remove_for_testing(self: &mut AV, version: u64) {
    self.allowed_versions.remove(&version);
}
