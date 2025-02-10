module sweebs_dao::errors;

// === Public Package Functions ===

#[test_only]
const EInvalidSuperAdminTransferEpoch: u64 = 0;

public(package) macro fun invalid_super_admin_transfer_epoch(): u64 {
    0
}

#[test_only]
const EInvalidNewSuperAdmin: u64 = 1;

public(package) macro fun invalid_new_super_admin(): u64 {
    1
}

#[test_only]
const EInvalidAdmin: u64 = 2;

public(package) macro fun invalid_admin(): u64 {
    2
}

#[test_only]
const EOutdatedPackageVersion: u64 = 3;

public(package) macro fun outdated_package_version(): u64 {
    3
}

#[test_only]
const ERemoveCurrentVersionNotAllowed: u64 = 4;

public(package) macro fun remove_current_version_not_allowed(): u64 {
    4
}

#[test_only]
const EInvalidMaxParticipants: u64 = 5;

public(package) macro fun invalid_max_participants(): u64 {
    5
}

#[test_only]
const EInvalidMinVotingPeriod: u64 = 6;

public(package) macro fun invalid_min_voting_period(): u64 {
    6
}

#[test_only]
const EInvalidMaxVotingPeriod: u64 = 7;

public(package) macro fun invalid_max_voting_period(): u64 {
    7
}

#[test_only]
const EInvalidNFTType: u64 = 8;

public(package) macro fun invalid_nft_type(): u64 {
    8
}

#[test_only]
const EVoteAlreadyExists: u64 = 9;

public(package) macro fun vote_already_exists(): u64 {
    9
}

#[test_only]
const EInvalidConfigId: u64 = 10;

public(package) macro fun invalid_config_id(): u64 {
    10
}

#[test_only]
const EInvalidVoteTypes: u64 = 11;

public(package) macro fun invalid_vote_types(): u64 {
    11
}

#[test_only]
const EInvalidTimeRange: u64 = 12;

public(package) macro fun invalid_time_range(): u64 {
    12
}

#[test_only]
const EInvalidProposalStatus: u64 = 13;

public(package) macro fun invalid_proposal_status(): u64 {
    13
}

#[test_only]
const EInvalidProposalTiming: u64 = 14;

public(package) macro fun invalid_proposal_timing(): u64 {
    14
}
