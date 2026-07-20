#!/usr/bin/env bash
# check_layer_binding.sh — gate the LAYER-TO-STRATUM BINDING for konnectome.
#
# The strict layer rule checks that pack layers are ORDERED correctly. This gate
# additionally checks that a stratum-primary pack's declared layer is CONSISTENT
# with the ordinal of the stratum it declares (an order-preserving correspondence,
# not equality). A pack with a layer but no usable stratum is UNBOUND — a gap,
# never a violation — so with no strata source this gate is a clean no-op, which
# is konnectome's situation until it declares strata.
#
# Adapted from the PrologAI reference gate; the one change is that the library
# path is extended with PrologAI's packs so library(layer) resolves.
#
# Usage: bin/check_layer_binding.sh [PACKS_DIR] [STRATA_SOURCE]
# Exit 0 = clean; 1 = a binding violation; 2 = error.
set -u
# Resolve the konnectome repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# The packs directory to check (default: konnectome's own packs).
PACKS_DIR="${1:-$PWD/packs}"
# The strata source directory (default: empty, meaning no strata are known yet).
STRATA_SOURCE="${2:-}"
# Build the library path over konnectome's own packs first.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# Extend it with PrologAI's packs so library(layer) resolves (reuse, not fork).
PROLOGAI_PACKS="${PROLOGAI_HOME:-/home/ccaitwo/PrologAI}/packs"
for d in "$PROLOGAI_PACKS"/*/prolog; do [ -d "$d" ] && LIB="$LIB -p library=$d"; done
# Load the layer construct, print the binding report, and exit non-zero on any violation.
swipl -q $LIB \
  -g "use_module(library(layer)), layer_bind_report_dir('$PACKS_DIR', '$STRATA_SOURCE'), layer_bind_check_dir('$PACKS_DIR', '$STRATA_SOURCE', V), (V==[] -> halt(0) ; halt(1))" \
  -t "halt(2)" 2>&1
# Propagate swipl's exit code as the gate result.
exit $?
