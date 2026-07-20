#!/usr/bin/env bash
# run_pack_tests.sh — run one konnectome pack's PLUnit (Prolog Unit) test suite.
#
# The SWI-Prolog library path is built over konnectome's own packs first, then
# extended with PrologAI's packs, so a konnectome pack can use_module both its own
# siblings and any reused PrologAI language pack (for example library(causal_core)).
# PROLOGAI_HOME overrides PrologAI's location.
#
# Usage: bin/run_pack_tests.sh <pack_name>
# Exit 0 = all tests passed; 1 = a test failed or the suite could not load.
set -u
# Resolve the konnectome repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# The pack whose test suite to run is the first argument.
PACK="${1:?usage: bin/run_pack_tests.sh <pack_name>}"
# The test file follows the fixed per-pack convention.
TEST_FILE="packs/$PACK/test/test_$PACK.pl"
# Fail early with a clear message if the test file is missing.
[ -f "$TEST_FILE" ] || { echo "no test file at $TEST_FILE"; exit 1; }
# Build the library path over konnectome's own packs first.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# Extend it with PrologAI's packs so reused language packs resolve.
PROLOGAI_PACKS="${PROLOGAI_HOME:-/home/ccaitwo/PrologAI}/packs"
for d in "$PROLOGAI_PACKS"/*/prolog; do [ -d "$d" ] && LIB="$LIB -p library=$d"; done
# Run the suite; run_tests fails the goal on any failure, and halt(1) sets a non-zero exit on a load error.
swipl $LIB -g "run_tests, halt" -t "halt(1)" "$TEST_FILE"
# Propagate swipl's exit code as the result.
exit $?
