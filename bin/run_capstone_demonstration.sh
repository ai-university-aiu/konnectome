#!/usr/bin/env bash
# run_capstone_demonstration.sh — boot the mind, run it, and print its glass-box story.
#
# The SWI-Prolog library path is built over konnectome's own packs first, then
# extended with PrologAI's packs, so the capstone can use_module its konnectome
# siblings and any reused PrologAI language pack (for example library(causal_core)).
# PROLOGAI_HOME overrides PrologAI's location.
#
# Usage: bin/run_capstone_demonstration.sh [num_ticks]
# The optional num_ticks is an integer of at least six; the default is ten.
# Exit 0 = the story printed; 1 = the demonstration could not load or run.
set -u
# Resolve the konnectome repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# The number of heartbeat ticks is the optional first argument, defaulting to ten.
TICKS="${1:-10}"
# Refuse a tick argument that is not a plain whole number, before it reaches the mind.
case "$TICKS" in ''|*[!0-9]*) echo "usage: bin/run_capstone_demonstration.sh [num_ticks]"; exit 1;; esac
# Build the library path over konnectome's own packs first.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# Extend it with PrologAI's packs so reused language packs resolve.
PROLOGAI_PACKS="${PROLOGAI_HOME:-/home/ccaitwo/PrologAI}/packs"
for d in "$PROLOGAI_PACKS"/*/prolog; do [ -d "$d" ] && LIB="$LIB -p library=$d"; done
# Load the capstone quietly, print the story, and halt; a load or run failure exits non-zero.
swipl -q $LIB -g "use_module(library(capstone_demonstration)), capstone_demonstration_run($TICKS), halt" -t "halt(1)"
# Propagate swipl's exit code as the result.
exit $?
