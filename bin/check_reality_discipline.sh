#!/usr/bin/env bash
# check_reality_discipline.sh — the reality-discipline gate (konnectome build slice 17).
#
# The rule this gate enforces: crossing between pretend and reality is pretend_play's job alone.
# The reused PrologAI imagination pack is deliberately unguarded on the shared library path -
# its imagination_promote/3 can move a fact between realities, its imagination_assert/2 can
# write any reality directly, including observed, and its internal store can be written through
# a module-qualified goal. konnectome's refusal to promote pretend into the observed record
# lives in the pretend_play wrapper, so the refusal holds only if no other konnectome pack ever
# reaches around the wrapper. This gate makes that build discipline checkable at the textual
# level: outside packs/pretend_play/, no konnectome file may carry any imagination-pack
# predicate name, any imagination-module qualifier, or the library(imagination) import. A reach
# that constructs both its module name and its call at runtime leaves no textual trace and is
# beyond any textual gate; that residue remains a discipline, stated honestly in the ledger.
#
# Usage: bin/check_reality_discipline.sh
# Exit 0 = the discipline holds; 1 = a pack outside pretend_play touches the imagination pack.
set -u
# Resolve the konnectome repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# Collect every offending line in every file under packs/ outside pretend_play, on a line that
# is code rather than a plain-English comment: a predicate-name reference (imagination_), a
# module-qualified reach (imagination:), or the import that resolves either (library(imagination)).
VIOLATIONS=$(grep -rn -E "imagination[_:]|library\(imagination\)" packs/ \
  | grep -v "^packs/pretend_play/" \
  | grep -v -E "^[^:]*:[0-9]+:[[:space:]]*%" || true)
# An empty collection means every reality crossing goes through pretend_play's guarded interface.
if [ -z "$VIOLATIONS" ]; then
  # Report the clean result in the same voice as the sibling gates.
  echo "Reality-discipline violations: 0 — every reality crossing goes through pretend_play's guarded interface."
  # A clean gate exits zero.
  exit 0
fi
# Name every offending line, so the violation is visible at a glance.
echo "$VIOLATIONS"
# Count the offending lines for the summary.
COUNT=$(echo "$VIOLATIONS" | wc -l | tr -d ' ')
# Report the violation in the same voice as the sibling gates.
echo "Reality-discipline violations: $COUNT — a pack outside pretend_play references the unguarded imagination predicates."
# A dirty gate exits non-zero, so it can block a merge.
exit 1
