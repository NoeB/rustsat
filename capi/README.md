[![License](https://img.shields.io/crates/l/rustsat?style=for-the-badge)](./LICENSE)

<!-- cargo-rdme start -->

# C-API For RustSAT

In the C-API, literals are represented as IPASIR literals.

This is the C-API for RustSAT. Currently this API is very minimal and not the focus of this
project. For now, only the API of certain encodings is available.

For the API itself, see `rustsat.h`. To use RustSAT from an external project, build this crate
and link against `librustsat_capi.a` (produced by `cargo` in `target/release`).

For some more pointers for how to use the C-API, the
[tests](https://github.com/chrjabs/rustsat/tree/main/capi/tests) might be a good starting
point.

<!-- cargo-rdme end -->
