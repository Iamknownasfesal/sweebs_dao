module sweebs_dao::event_wrapper;

use sui::event::emit;

// === Structs ===

public struct Event<T: copy + drop>(T) has copy, drop;

// === Public Package Functions ===

public(package) fun emit_event<T: copy + drop>(event: T) {
    emit(Event(event));
}
