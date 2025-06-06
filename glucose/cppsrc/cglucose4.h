/*
 * Author: Christoph Jabs - christoph.jabs@helsinki.fi
 *
 * Copyright © 2022 Christoph Jabs, University of Helsinki
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the “Software”), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

#ifndef Glucose_CGlucose4_h
#define Glucose_CGlucose4_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>
#include <stdint.h>

// Same as the internal literal representation
typedef struct c_Lit {
  int x;
} c_Lit;
// Same as the internal variable representation
typedef int c_Var;

// Glucose 4 C API
// The API is roughly IPASIR-like

const char *cglucose4_signature(void);

// These values are returned from _val
const int T_FALSE = -1;
const int T_UNASSIGNED = 0;
const int T_TRUE = 1;

// This value is returned from _solve, _add, and _phase if the solver runs out
// of memory
const int OUT_OF_MEM = 50;

// -----------------------------------------------------------------------------
// API for the solver without preprocessing
typedef struct CGlucose4 CGlucose4;
CGlucose4 *cglucose4_init(void);
void cglucose4_release(CGlucose4 *);

int cglucose4_reserve(CGlucose4 *, c_Var var);
int cglucose4_add_clause(CGlucose4 *, const c_Lit *lits, size_t n_lits);
int cglucose4_solve(CGlucose4 *, const c_Lit *assumps, size_t n_assumps);
int cglucose4_val(CGlucose4 *, c_Lit lit);
void cglucose4_conflict(CGlucose4 *, const c_Lit **conflict,
                        size_t *conflict_len);

int cglucose4_phase(CGlucose4 *, c_Lit lit);
void cglucose4_unphase(CGlucose4 *, c_Var var);

int cglucose4_n_assigns(CGlucose4 *);
int cglucose4_n_clauses(CGlucose4 *);
int cglucose4_n_learnts(CGlucose4 *);
int cglucose4_n_vars(CGlucose4 *);

void cglucose4_set_conf_limit(CGlucose4 *, int64_t limit);
void cglucose4_set_prop_limit(CGlucose4 *, int64_t limit);
void cglucose4_set_no_limit(CGlucose4 *);
void cglucose4_interrupt(CGlucose4 *);

uint64_t cglucose4_decisions(CGlucose4 *);
uint64_t cglucose4_propagations(CGlucose4 *);
uint64_t cglucose4_conflicts(CGlucose4 *);

// Propagates the assumptions, returns 20 if a
// conflict was encountered, 10 if not. The list of propagated literals is
// returned via the `prop_cb`. If the solver runs out of memory, returns
// `OUT_OF_MEM`.
int cglucose4_propcheck(CGlucose4 *, const c_Lit *assumps, size_t n_assumps,
                        int psaving, void (*prop_cb)(void *, c_Lit),
                        void *cb_data);
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// API for the solver with preprocessing
typedef struct CGlucoseSimp4 CGlucoseSimp4;
CGlucoseSimp4 *cglucosesimp4_init(void);
void cglucosesimp4_release(CGlucoseSimp4 *);

int cglucosesimp4_reserve(CGlucoseSimp4 *, c_Var var);
int cglucosesimp4_add_clause(CGlucoseSimp4 *, const c_Lit *lits, size_t n_lits);
int cglucosesimp4_solve(CGlucoseSimp4 *, const c_Lit *assumps,
                        size_t n_assumps);
int cglucosesimp4_val(CGlucoseSimp4 *, c_Lit lit);
void cglucosesimp4_conflict(CGlucoseSimp4 *, const c_Lit **conflict,
                            size_t *conflict_len);

int cglucosesimp4_phase(CGlucoseSimp4 *, c_Lit lit);
void cglucosesimp4_unphase(CGlucoseSimp4 *, c_Var var);

int cglucosesimp4_n_assigns(CGlucoseSimp4 *);
int cglucosesimp4_n_clauses(CGlucoseSimp4 *);
int cglucosesimp4_n_learnts(CGlucoseSimp4 *);
int cglucosesimp4_n_vars(CGlucoseSimp4 *);

void cglucosesimp4_set_conf_limit(CGlucoseSimp4 *, int64_t limit);
void cglucosesimp4_set_prop_limit(CGlucoseSimp4 *, int64_t limit);
void cglucosesimp4_set_no_limit(CGlucoseSimp4 *);
void cglucosesimp4_interrupt(CGlucoseSimp4 *);

uint64_t cglucosesimp4_decisions(CGlucoseSimp4 *);
uint64_t cglucosesimp4_propagations(CGlucoseSimp4 *);
uint64_t cglucosesimp4_conflicts(CGlucoseSimp4 *);

// Propagates the assumptions, returns 20 if a
// conflict was encountered, 10 if not. The list of propagated literals is
// returned via the `prop_cb`. If the solver runs out of memory, returns
// `OUT_OF_MEM`.
int cglucosesimp4_propcheck(CGlucoseSimp4 *, const c_Lit *assumps,
                            size_t n_assumps, int psaving,
                            void (*prop_cb)(void *, c_Lit), void *cb_data);

// Simplification-specific functions
void cglucosesimp4_set_frozen(CGlucoseSimp4 *, c_Var var, int frozen);
int cglucosesimp4_is_frozen(CGlucoseSimp4 *, c_Var var);
int cglucosesimp4_is_eliminated(CGlucoseSimp4 *, c_Var var);
// -----------------------------------------------------------------------------

#ifdef __cplusplus
}
#endif

#endif
