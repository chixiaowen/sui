// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module sui::prover {
    use sui::object;

    #[verify_only]
    /// The intrinsic map type simulated by a dummy struct
    struct Map<phantom K: copy + drop, phantom V> has store {}
    spec Map {
        pragma intrinsic = map,
        map_spec_new = map_new,
        map_spec_get = map_get,
        map_spec_set = map_set,
        map_spec_del = map_del,
        map_spec_len = map_len,
        map_spec_has_key = map_contains;
    }

    /// Create a new map with no entries, emulated by a fake native function
    spec native fun map_new<K: copy + drop, V: store>(): Map<K, V>;

    /// Obtain the number of key-value pairs in the map
    spec native fun map_len<K, V>(m: Map<K, V>): num;

    /// Check whether the map contains a certain key
    spec native fun map_contains<K, V>(m: Map<K, V>, k: K): bool;

    /// Update the map at `(k, v)` and return the updated map
    spec native fun map_set<K, V>(m: Map<K, V>, k: K, v: V): Map<K, V>;

    /// Delete the map at key `k` and return the updated map
    spec native fun map_del<K, V>(m: Map<K, V>, k: K): Map<K, V>;

    /// Get the value `v` associated with key `k`, if `k` does not exist,
    /// return an uninterpreted value.
    spec native fun map_get<K, V>(m: Map<K, V>, k: K): V;

    const OWNED: u64 = 1;
    const SHARED: u64 = 2;
    const IMMUTABLE: u64 = 3;

    // "public" functions to be used in specs as an equivalent of core Prover's builtins

    /// Verifies if a given object it owned.
    spec fun owned<T: key>(obj: T): bool {
        let addr = object::id(obj).bytes;
        exists<object::Ownership>(addr) &&
            global<object::Ownership>(addr).status == OWNED
    }

    /// Verifies if a given object is owned.
    spec fun owned_by<T: key>(obj: T, owner: address): bool {
        let addr = object::id(obj).bytes;
        exists<object::Ownership>(addr) &&
            global<object::Ownership>(addr).status == OWNED &&
            global<object::Ownership>(addr).owner == owner
    }

    /// Verifies if a given object is shared.
    spec fun shared<T: key>(obj: T): bool {
        let addr = object::id(obj).bytes;
        exists<object::Ownership>(addr) &&
            global<object::Ownership>(addr).status == SHARED
    }

    /// Verifies if a given object is immutable.
    spec fun immutable<T: key>(obj: T): bool {
        let addr = object::id(obj).bytes;
        exists<object::Ownership>(addr) &&
            global<object::Ownership>(addr).status == IMMUTABLE
    }

    /// Verifies if a given object has field with a given name.
    spec fun has_field<T: key, K: copy + drop + store>(obj: T, name: K): bool {
        let uid = object::borrow_uid(obj);
        uid_has_field<K>(uid, name)
    }

    /// Returns number of K-type fields of a given object.
    spec fun num_fields<T: key, K: copy + drop + store>(obj: T): u64 {
        let uid = object::borrow_uid(obj);
        uid_num_fields<K>(uid)
    }

    // "helper" function - may also be used in specs but mostly opaque ones defining behavior of key
    // framework functions

    spec fun uid_has_field<K: copy + drop + store>(uid: object::UID, name: K): bool {
        let addr = object::uid_to_address(uid);
        exists<object::DynamicFields<K>>(addr) && contains(global<object::DynamicFields<K>>(addr).names, name)
    }

    spec fun uid_num_fields<K: copy + drop + store>(uid: object::UID): u64 {
        let addr = object::uid_to_address(uid);
        if (!exists<object::DynamicFields<K>>(addr)) {
            0
        } else {
            len(global<object::DynamicFields<K>>(addr).names)
        }
    }

    // remove an element at index from a vector and return the resulting vector (redirects to a
    // function in vector theory)
    spec native fun vec_remove<T>(v: vector<T>, elem_idx: u64): vector<T>;
}
