// !!! Auto-generated by codegen, do not edit manually !!!

use std::ffi::{c_int, c_void};

use rustsat::{
    encodings::card::{
        BoundLower, BoundLowerIncremental, BoundUpper, BoundUpperIncremental, EncodeIncremental,
        Totalizer,
    },
    types::Lit,
};

use super::{CClauseCollector, ClauseCollector, MaybeError, VarManager};

/// Creates a new [`Totalizer`] cardinality encoding
#[no_mangle]
#[allow(clippy::missing_safety_doc)]
pub unsafe extern "C" fn tot_new() -> *mut Totalizer {
    Box::into_raw(Box::default())
}

/// Frees the memory associated with a [`Totalizer`]
///
/// # Safety
///
/// `tot` must be a return value of [`tot_new`] and cannot be used afterwards again.
#[no_mangle]
pub unsafe extern "C" fn tot_drop(tot: *mut Totalizer) {
    drop(Box::from_raw(tot));
}

/// Reserves all auxiliary variables that the encoding might need
///
/// All calls to [`tot_encode_ub`] following a call to this function are guaranteed to not increase
/// the value of `n_vars_used`. This does _not_ hold if [`tot_add`] is called in between
///
/// # Safety
///
/// `tot` must be a return value of [`tot_new`] that [`tot_drop`] has not yet been called on.
#[no_mangle]
pub unsafe extern "C" fn tot_reserve(tot: *mut Totalizer, n_vars_used: &mut u32) {
    let mut var_manager = VarManager::new(n_vars_used);
    (*tot).reserve(&mut var_manager);
}

/// Adds a new input literal to a [`Totalizer`] encoding
///
/// # Errors
///
/// - If `lit` is not a valid IPASIR-style literal (e.g., `lit = 0`),
///   [`MaybeError::InvalidLiteral`] is returned
///
/// # Safety
///
/// `tot` must be a return value of [`tot_new`] that [`tot_drop`] has not yet been called on.
#[no_mangle]
pub unsafe extern "C" fn tot_add(tot: *mut Totalizer, lit: c_int) -> MaybeError {
    let Ok(lit) = Lit::from_ipasir(lit) else {
        return MaybeError::InvalidLiteral;
    };
    (*tot).extend([lit]);
    MaybeError::Ok
}
/// Lazily builds the _change in_ cardinality encoding to enable upper bounds in a given range.
/// A change might be added literals or changed bounds.
///
/// The min and max bounds are inclusive. After a call to [`tot_encode_ub`] with `min_bound=2` and
/// `max_bound=4` bound including `<= 2` and `<= 4` can be enforced.
///
/// Clauses are returned via the `collector`. The `collector` function should expect clauses to be
/// passed similarly to `ipasir_add`, as a 0-terminated sequence of literals where the literals are
/// passed as the first argument and the `collector_data` as a second.
///
/// `n_vars_used` must be the number of variables already used and will be incremented by the
/// number of variables used up in the encoding.
///
/// # Panics
///
/// If `min_bound > max_bound`.
///
/// # Safety
///
/// `tot` must be a return value of [`tot_new`] that [`tot_drop`] has not yet been called on.
#[no_mangle]
pub unsafe extern "C" fn tot_encode_ub(
    tot: *mut Totalizer,
    min_bound: usize,
    max_bound: usize,
    n_vars_used: &mut u32,
    collector: CClauseCollector,
    collector_data: *mut c_void,
) {
    assert!(min_bound <= max_bound);
    let mut collector = ClauseCollector::new(collector, collector_data);
    let mut var_manager = VarManager::new(n_vars_used);
    (*tot)
        .encode_ub_change(min_bound..=max_bound, &mut collector, &mut var_manager)
        .expect("CClauseCollector cannot report out of memory");
}

/// Returns an assumption/unit for enforcing an upper bound (`sum of lits <= ub`). Make sure that
/// [`tot_encode_ub`] has been called adequately and nothing has been called afterwards, otherwise
/// [`MaybeError::NotEncoded`] will be returned.
///
/// # Safety
///
/// `tot` must be a return value of [`tot_new`] that [`tot_drop`] has not yet been called on.
#[no_mangle]
pub unsafe extern "C" fn tot_enforce_ub(
    tot: *mut Totalizer,
    ub: usize,
    assump: &mut c_int,
) -> MaybeError {
    match (*tot).enforce_ub(ub) {
        Ok(assumps) => {
            debug_assert_eq!(assumps.len(), 1);
            *assump = assumps[0].to_ipasir();
            MaybeError::Ok
        }
        Err(err) => err.into(),
    }
}
/// Lazily builds the _change in_ cardinality encoding to enable lower bounds in a given range.
/// A change might be added literals or changed bounds.
///
/// The min and max bounds are inclusive. After a call to [`tot_encode_lb`] with `min_bound=2` and
/// `max_bound=4` bound including `>= 2` and `>= 4` can be enforced.
///
/// Clauses are returned via the `collector`. The `collector` function should expect clauses to be
/// passed similarly to `ipasir_add`, as a 0-terminated sequence of literals where the literals are
/// passed as the first argument and the `collector_data` as a second.
///
/// `n_vars_used` must be the number of variables already used and will be incremented by the
/// number of variables used up in the encoding.
///
/// # Panics
///
/// If `min_bound > max_bound`.
///
/// # Safety
///
/// `tot` must be a return value of [`tot_new`] that [`tot_drop`] has not yet been called on.
#[no_mangle]
pub unsafe extern "C" fn tot_encode_lb(
    tot: *mut Totalizer,
    min_bound: usize,
    max_bound: usize,
    n_vars_used: &mut u32,
    collector: CClauseCollector,
    collector_data: *mut c_void,
) {
    assert!(min_bound <= max_bound);
    let mut collector = ClauseCollector::new(collector, collector_data);
    let mut var_manager = VarManager::new(n_vars_used);
    (*tot)
        .encode_lb_change(min_bound..=max_bound, &mut collector, &mut var_manager)
        .expect("CClauseCollector cannot report out of memory");
}

/// Returns an assumption/unit for enforcing a lower bound (`sum of lits >= lb`). Make sure that
/// [`tot_encode_lb`] has been called adequately and nothing has been called afterwards, otherwise
/// [`MaybeError::NotEncoded`] will be returned.
///
/// # Safety
///
/// `tot` must be a return value of [`tot_new`] that [`tot_drop`] has not yet been called on.
#[no_mangle]
pub unsafe extern "C" fn tot_enforce_lb(
    tot: *mut Totalizer,
    lb: usize,
    assump: &mut c_int,
) -> MaybeError {
    match (*tot).enforce_lb(lb) {
        Ok(assumps) => {
            debug_assert_eq!(assumps.len(), 1);
            *assump = assumps[0].to_ipasir();
            MaybeError::Ok
        }
        Err(err) => err.into(),
    }
}
