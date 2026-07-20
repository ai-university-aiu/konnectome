#!/usr/bin/env bash
# check_layers.sh — enforce the STRICT LAYER RULE for konnectome.
#
# A lower-layer pack may not depend on a higher-layer one. Each pack declares its
# layer with a `layer(N)` fact in its pack.pl; this checker parses the actual
# use_module(library(...)) import graph across konnectome's packs and reports any
# pack that imports a strictly-higher-layer pack. Packs with no layer(N) fact are
# UNDECLARED (a gap to fill), never a violation.
#
# Adapted from the PrologAI reference gate. The one konnectome-specific change:
# the SWI-Prolog library path is extended to include PrologAI's packs, so that
# library(layer) itself (a PrologAI language pack that konnectome reuses, never
# forks) resolves. PROLOGAI_HOME overrides the default location.
#
# Usage: bin/check_layers.sh [PACKS_DIR]   (default scans konnectome's packs/)
# Exit 0 = clean; 1 = at least one upward edge; 2 = could not run.
set -u
# Resolve the konnectome repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# The directory to SCAN is the first argument, or konnectome's packs/ by default.
SCAN_DIR="${1:-packs}"
# Build the library path over konnectome's own packs first.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# Extend the library path with PrologAI's packs so library(layer) and any other
# reused language pack resolve; konnectome reuses PrologAI, it does not copy it.
PROLOGAI_PACKS="${PROLOGAI_HOME:-/home/ccaitwo/PrologAI}/packs"
for d in "$PROLOGAI_PACKS"/*/prolog; do [ -d "$d" ] && LIB="$LIB -p library=$d"; done
# Load the layer construct, print the report, and set the exit code from the violations.
swipl -q $LIB \
  -g "use_module(library(layer)), layer_report_dir('$SCAN_DIR'), layer_check_dir('$SCAN_DIR', V), (V==[] -> halt(0) ; halt(1))" \
  -t "halt(2)" 2>&1
# Propagate swipl's exit code as the gate result.
exit $?
