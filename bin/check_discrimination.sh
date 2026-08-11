#!/usr/bin/env bash
# check_discrimination.sh — the DISCRIMINATION GATE (konnectome build slice 68).
#
# THE RULE: EVERY NAMED REFUSAL MUST BE PROVEN ABLE TO FIRE.
#
# A konnectome pack refuses aloud, by name: domain_error(some_complaint, What),
# existence_error(some_complaint, What), or a thrown error term of its own. Each
# such refusal is a claim that a particular thing is not allowed. This gate
# requires the pack's own test suite to contain a test naming that complaint, so
# that the refusal has been SHOWN to fire at least once.
#
# WHY THIS GATE EXISTS, AND IT IS THE SESSION THAT BUILT IT WRITING ITS OWN
# LESSON INTO A SCRIPT. Slice 65 found a condition that could never fail, and
# slice 67 found a claim carried through five hand-offs that nothing had ever
# checked. Both were correct-looking, both answered every question put to them,
# and neither could be found by running it, because running it is exactly what
# they survive. The question that finds this family is not "is it right" but
# WHAT DOES THIS TELL APART - and for a named refusal that question is
# mechanically checkable: has anybody ever made it fire?
#
# WHAT THIS GATE DOES NOT CATCH, STATED HERE RATHER THAN DISCOVERED LATER,
# BECAUSE A GATE THAT OVERSTATES ITS REACH IS THE VERY FAULT IT IS POLICING.
#   (1) IT WOULD NOT HAVE CAUGHT SLICE 66'S OVER-STRICT BAN. That refusal had a
#       test proving it fires. Its fault was being STRICTER THAN ITS SOURCE,
#       which is a code-versus-document divergence and no textual gate can see
#       it. Only reading the authority finds that one.
#   (2) IT WOULD NOT HAVE CAUGHT SLICE 65'S FREE PRIORITY DIRECTLY. That is a
#       CONDITION rather than a refusal - it returns a term, it does not throw -
#       and this gate looks only at throws. The generalisation to every branch of
#       every judgement is real and is deliberately NOT attempted here, because
#       "was this branch produced by the build's own machinery, or handed its
#       inputs by a test" is not a textual property.
#   (3) A TEST THAT MERELY MENTIONS THE COMPLAINT ATOM SATISFIES IT. The check is
#       textual. A pack could satisfy this gate with a comment. That residue is a
#       discipline, stated honestly, exactly as the reality-discipline gate states
#       its own.
# What it DOES catch is the case both of this session's findings were instances
# of at the level it can see: a rule nobody has ever shown can say no.
#
# Usage:   bin/check_discrimination.sh              # scan every pack
#          bin/check_discrimination.sh supervisor   # scan named packs only
#          bin/check_discrimination.sh --self-test  # prove the gate can fail, on
#                                                   # the committed fixture pack
# PACKS_ROOT overrides the scanned packs directory (the self-test uses this).
# Exit 0 = clean; exit 1 = at least one unproven refusal.
set -u
# The script's own absolute path, captured BEFORE the cd, so the self-test can
# re-invoke it correctly however it was started.
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
cd "$(dirname "$0")/.." || exit 2
# The packs directory being scanned; the self-test points this at the fixture tree.
PACKS_ROOT="${PACKS_ROOT:-packs}"

# --self-test: run this gate against the committed fixture pack - a pack that
# deliberately carries a refusal no test proves - and succeed ONLY if the gate
# catches it. A gate must be proven able to fail before it is trusted to pass,
# which is the naming gate's own rule and is doubly apt for THIS gate, whose
# whole subject is checks that have never said no.
if [ "${1:-}" = "--self-test" ]; then
  report="$(PACKS_ROOT=tests/discrimination_gate_fixture "$SELF" 2>&1)"; status=$?
  # The fixture must FAIL the gate, fail it for the unproven refusal by name, and
  # fail it for NOTHING ELSE - so the self-test proves this check specifically.
  if [ $status -ne 0 ] \
     && echo "$report" | grep -q "UNPROVEN \[fixture_refusal_nobody_proves\]" \
     && [ "$(echo "$report" | grep -c "UNPROVEN \[")" -eq 1 ]; then
    echo "SELF-TEST PASS: the gate catches the fixture's unproven refusal."
    exit 0
  fi
  # Anything else means the gate has stopped discriminating, which would be a
  # particularly embarrassing way for this gate in particular to fail.
  echo "SELF-TEST FAIL: the gate did not catch the fixture as expected."
  echo "$report"
  exit 1
fi

# ---------------------------------------------------------------------------
# THE EXEMPTIONS, AND EVERY ONE CARRIES ITS REASON
# ---------------------------------------------------------------------------
#
# A REFUSAL THAT CANNOT FIRE TODAY MAY STAND, BUT ONLY WHERE IT SAYS SO AND SAYS
# WHY. That is slice 66's rule for an admitted fault, arriving at a gate two
# slices later and for the same argument: a softened rule whose exceptions cannot
# be listed is a hole, and a softened rule whose exceptions each carry their
# argument is a design. THE REASON IS MANDATORY AND AN EMPTY ONE IS REFUSED
# BELOW - an exemption that cannot state its case is exactly the silent pass this
# gate exists to prevent.
#
# EVERY EXEMPTION HERE IS THE SAME SHAPE, WHICH IS WHY THEY ARE WORTH LISTING
# RATHER THAN DELETING: each is a FUTURE-DRIFT TRIPWIRE. It guards not against an
# input any caller can supply today but against a table, a mode set, or a reused
# cousin pack changing under it later. That is a legitimate thing for a refusal to
# be. It is NOT a legitimate thing for a refusal to be by accident, which is why
# each line names the exact change that would make it live.
#
# Format: pack|complaint|the reason it cannot fire today and what would change that.
EXEMPTIONS="
archetype|archetype_gate_transfer_function|Cannot fire while the gate transfer table has exactly two closed rows (open, closed) and archetype_gate_law/3 covers both. Becomes live the day a row is added to the transfer table without a matching law.
archetype|mode_transition|Cannot fire while the gate has exactly two modes, because the broadcast_thrown rows are a complete bijection on them, so the only mode that is declared and not current is the one the table names. Becomes live the day a third mode is added without a matching thrown row.
category_formation|category_formation_unrenamable_concept|Cannot fire while PrologAI concept_formation mints every identifier with gensym(con_, Id), so the con_ prefix always matches. It is a CROSS-PACK CONTRACT tripwire and becomes live the day that reused engine changes its naming scheme.
self_provenance|self_provenance_refused|Cannot fire while causal_core defines semantic errors for four kinds and none of them is assertion or retraction, which are the only kinds this pack ever mints. It is a PARITY HOOK and becomes live the day causal_core grows a rule for either kind.
"

# Refuse an exemption that does not state its case, before any pack is scanned.
# An exemption with an empty reason would be a silent pass wearing a list entry.
echo "$EXEMPTIONS" | while IFS="|" read -r ex_pack ex_name ex_reason; do
  # Skip the blank lines the quoted list begins and ends with.
  [ -n "$ex_pack" ] || continue
  # An exemption missing its pack, its complaint, or its reason is refused aloud.
  if [ -z "$ex_name" ] || [ -z "$(echo "$ex_reason" | tr -d "[:space:]")" ]; then
    echo "MALFORMED EXEMPTION [$ex_pack] — an exemption must name a pack, a complaint, and a reason."
    exit 2
  fi
done || exit 2

# The packs to scan: the named ones, or every pack under the scanned root.
if [ "$#" -gt 0 ]; then
  PACKS="$*"
else
  PACKS="$(for d in "$PACKS_ROOT"/*/; do basename "$d"; done)"
fi

# Running totals for the summary line.
TOTAL=0
UNPROVEN=0
EXEMPTED=0

# Walk each pack, extracting its named refusals and checking each against its tests.
for PACK in $PACKS; do
  SRC="$PACKS_ROOT/$PACK/prolog/$PACK.pl"
  TEST="$PACKS_ROOT/$PACK/test/test_$PACK.pl"
  # A pack with no module file is not this gate's business; the naming gate owns that.
  [ -f "$SRC" ] || continue
  # Strip whole-line comments before extracting, so a refusal DESCRIBED in prose
  # is not mistaken for a refusal the code makes. Every konnectome source line
  # carries a plain-English comment above it, so this matters.
  CODE="$(grep -v -E "^[[:space:]]*%" "$SRC")"
  # The complaint atoms: the first argument of each standard error term, plus the
  # functor of any error term the pack throws itself. instantiation_error is
  # excluded because it names no complaint of the pack's own.
  NAMES="$( { echo "$CODE" | grep -oE "(domain_error|existence_error|type_error|permission_error)\([[:space:]]*[a-z][A-Za-z0-9_]*" \
                           | sed -E "s/.*\([[:space:]]*//"
             echo "$CODE" | grep -oE "throw\([[:space:]]*error\([[:space:]]*[a-z][A-Za-z0-9_]*" \
                           | sed -E "s/.*error\([[:space:]]*//" \
                           | grep -v "^instantiation_error$"
           } | sort -u )"
  # A pack that refuses nothing has nothing to prove, and that is not a violation.
  [ -n "$NAMES" ] || continue
  # Check each complaint against the pack's own test suite.
  for NAME in $NAMES; do
    TOTAL=$((TOTAL + 1))
    # A refusal is PROVEN when the pack's tests name its complaint. A pack with no
    # test file at all proves nothing, and the naming gate blocks that separately.
    if [ -f "$TEST" ] && grep -q "\b$NAME\b" "$TEST"; then
      continue
    fi
    # An EXEMPTED refusal is allowed to stand and is REPORTED ANYWAY, with its
    # reason, because an exemption nobody reads is the same silence as an unproven
    # refusal. Every run of this gate prints the full list of things it let past.
    REASON="$(echo "$EXEMPTIONS" | grep "^$PACK|$NAME|" | cut -d'|' -f3-)"
    if [ -n "$REASON" ]; then
      echo "EXEMPT   [$NAME] in $PACK — $REASON"
      EXEMPTED=$((EXEMPTED + 1))
      continue
    fi
    # Name the unproven refusal, so the violation is actionable at a glance.
    echo "UNPROVEN [$NAME] in $SRC — no test in $TEST makes this refusal fire."
    UNPROVEN=$((UNPROVEN + 1))
  done
done

# Report in the same voice as the sibling gates.
if [ "$UNPROVEN" -eq 0 ]; then
  echo "Unproven refusals: 0 of $TOTAL — every named refusal is shown able to fire by a test, or is exempted with its reason."
  # The exemption count is printed on its own line rather than folded into the
  # clean message, so a reader can never quote "zero unproven" without it - the
  # same discipline the naming gate's colliding-prefix count is held to.
  echo "Exempted refusals: $EXEMPTED — cannot fire today; each reason is printed above."
  exit 0
fi
# A dirty gate names its count and exits non-zero, so it can block a merge.
echo "Unproven refusals: $UNPROVEN of $TOTAL — a refusal nobody has shown can say no has never told anything apart."
exit 1
