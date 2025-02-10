module sweebs_dao::display_wrapper;

use sui::display::Display;

// === Structs ===

public struct DisplayWrapper<phantom T: key> has key, store {
    id: UID,
    display: Display<T>,
}

// === Public-Mutative Functions ===

public(package) fun new<T: key>(
    display: Display<T>,
    ctx: &mut TxContext,
): DisplayWrapper<T> {
    DisplayWrapper {
        id: object::new(ctx),
        display,
    }
}
