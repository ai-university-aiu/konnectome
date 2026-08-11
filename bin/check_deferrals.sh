#!/usr/bin/env bash
# check_deferrals.sh — the DEFERRAL GATE (konnectome build slice 70).
#
# THE RULE: EVERY DEFERRAL MUST NAME THE CONDITION IT IS WAITING ON, AND THAT
# CONDITION MUST STILL BE TRUE.
#
# A konnectome slice sometimes cannot proceed, and says so: it names a blocker
# and defers the work. That sentence is then inherited by every session
# afterwards. THIS GATE IS THE THING THAT RE-EARNS IT. Each entry in
# docs/deferrals/deferral_register.txt hands over two probes - one that succeeds
# while the block stands, one that succeeds once it has lifted - and this script
# runs both, on every run, against the live repository.
#
# WHY IT EXISTS, AND THE CASE IS THIS BUILD'S OWN. The claim "no construct in
# this build carries anything across a tick" was carried by five consecutive
# hand-offs, sat in six documents and one source comment, was quoted approvingly,
# was used to defer two items in writing, AND WAS FALSE THE DAY IT WAS WRITTEN.
# The refutation was one grep away in the same repository for twenty-nine slices.
# Nobody was careless; there was simply nothing anywhere whose job it was to
# check. A LOAD-BEARING CLAIM IN A HAND-OFF IS AN ASSERTION, NOT A MEASUREMENT,
# AND IT INHERITS FORWARD WITHOUT EVER BEING RE-EARNED.
#
# THE DISCRIMINATION RULE, WHICH THIS GATE APPLIES TO ITSELF BEFORE IT APPLIES
# ANYTHING TO THE BUILD. A probe pair whose two halves answer the SAME WAY has
# told nothing apart - both succeeding means the pair is contradictory, both
# failing means it has rotted and no longer describes anything. Either is a
# violation here, and neither is quietly tolerated, because a deferral watched by
# a probe that cannot disagree with itself is exactly the decoration this build
# spent slice 68 learning to name.
#
# WHAT THIS GATE DOES NOT CATCH, STATED HERE RATHER THAN DISCOVERED LATER.
#   (1) IT CANNOT FIND A DEFERRAL NOBODY WROTE DOWN. The register is populated by
#       hand, and a session that defers work in a hand-off and adds no entry is
#       invisible to this script. That residue is a discipline and is the largest
#       one this gate carries.
#   (2) IT CANNOT JUDGE WHETHER A PROBE IS THE RIGHT PROBE. It can prove the two
#       halves disagree; it cannot prove they disagree ABOUT THE RIGHT THING.
#       Only reading the note finds that one.
#   (3) AN UNPROBEABLE ENTRY IS CHECKED FOR NOTHING BUT ITS REASON. Some
#       conditions genuinely cannot be greped - the absence of an argument is not
#       a textual property - and those are admitted, with their reasons, and
#       PRINTED ON EVERY RUN, which is the discrimination gate's own exemption
#       discipline reused rather than reinvented.
#
# Usage:   bin/check_deferrals.sh              # check the standing register
#          bin/check_deferrals.sh --self-test  # prove the gate can fail, on the
#                                              # committed fixture register
# REGISTER overrides the register file (the self-test uses this).
# Exit 0 = clean; exit 1 = at least one deferral is ripe, broken, or malformed.
set -u
# The script's own absolute path, captured BEFORE the cd, so the self-test can
# re-invoke it correctly however it was started.
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
cd "$(dirname "$0")/.." || exit 2
# The register being checked; the self-test points this at the fixture.
REGISTER="${REGISTER:-docs/deferrals/deferral_register.txt}"

# --self-test: run this gate against the committed fixture register - a register
# that deliberately carries one deferral whose block has lifted and one whose
# probe pair cannot disagree - and succeed ONLY if the gate catches both. A gate
# must be proven able to fail before it is trusted to pass, which is the naming
# gate's rule and the discrimination gate's rule before it.
if [ "${1:-}" = "--self-test" ]; then
  report="$(REGISTER=tests/deferral_gate_fixture/deferral_register.txt "$SELF" 2>&1)"; status=$?
  # The fixture must FAIL the gate, fail it for BOTH planted faults by name, and
  # fail it for NOTHING ELSE - so the self-test proves these checks specifically.
  if [ $status -ne 0 ] \
     && echo "$report" | grep -q "RIPE       \[fixture_block_that_has_lifted\]" \
     && echo "$report" | grep -q "UNDISCRIMINATING \[fixture_probe_pair_that_cannot_disagree\]" \
     && [ "$(echo "$report" | grep -cE "^(RIPE|BROKEN|UNDISCRIMINATING|MALFORMED)")" -eq 2 ]; then
    echo "SELF-TEST PASS: the gate catches the fixture's lifted block and its undiscriminating pair."
    exit 0
  fi
  # Anything else means the gate has stopped telling a live deferral from a dead
  # one, which is the single thing it exists to do.
  echo "SELF-TEST FAIL: the gate did not catch the fixture as expected."
  echo "$report"
  exit 1
fi

# A register that is not there is refused loudly rather than read as an empty
# register - an empty register and a missing one are indistinguishable in the
# clean message, and only one of them is good news.
if [ ! -f "$REGISTER" ]; then
  echo "MALFORMED [register] — no deferral register at $REGISTER."
  exit 1
fi

# Running totals for the summary line.
TOTAL=0
DEFERRED=0
TAKEN_UP=0
UNPROBEABLE=0
VIOLATIONS=0

# Walk the register. An entry is any line carrying the :: separator; the prose
# above THE ENTRIES is skipped because none of it does. Reading on a file
# descriptor other than standard input keeps the probes below from swallowing
# the rest of the register when one of them reads standard input.
while IFS= read -r LINE <&3; do
  # AN ENTRY IS A LINE THAT BEGINS WITH AN IDENTIFIER IN COLUMN ONE FOLLOWED BY
  # THE SEPARATOR, and nothing else in the file is. Matching on the separator
  # alone was the first version of this check and it read the register's own
  # prose about the separator as three malformed entries - a parser that cannot
  # tell a rule from an instance of the rule.
  echo "$LINE" | grep -qE "^[a-z][a-z0-9_]* :: " || continue
  # Split the entry on the double-colon separator, trimming the spaces around it.
  IDENTIFIER="$(echo "$LINE" | awk -F' :: ' '{print $1}')"
  STATUS="$(echo "$LINE" | awk -F' :: ' '{print $2}')"
  SUBJECT="$(echo "$LINE" | awk -F' :: ' '{print $3}')"
  STANDS="$(echo "$LINE" | awk -F' :: ' '{print $4}')"
  LIFTS="$(echo "$LINE" | awk -F' :: ' '{print $5}')"
  NOTE="$(echo "$LINE" | awk -F' :: ' '{print $6}')"
  TOTAL=$((TOTAL + 1))

  # AN ENTRY MISSING ITS SUBJECT OR ITS NOTE IS REFUSED BEFORE IT IS PROBED. A
  # deferral that cannot say what it is holding up, or why its probes are the
  # right ones, is a sentence wearing a register entry.
  if [ -z "$(echo "$SUBJECT" | tr -d '[:space:]')" ] || [ -z "$(echo "$NOTE" | tr -d '[:space:]')" ]; then
    echo "MALFORMED [$IDENTIFIER] — an entry must name what it holds up and why its probes are right."
    VIOLATIONS=$((VIOLATIONS + 1))
    continue
  fi

  # An unprobeable entry runs no probe and is PRINTED, with its reason, on every
  # run - because an admitted gap nobody reads is the silence this gate exists
  # to break, exactly as the discrimination gate says of its exemptions.
  if [ "$STATUS" = "unprobeable" ]; then
    echo "UNPROBEABLE [$IDENTIFIER] — $SUBJECT"
    echo "             $NOTE"
    UNPROBEABLE=$((UNPROBEABLE + 1))
    continue
  fi

  # A status this gate does not know is refused rather than assumed harmless.
  if [ "$STATUS" != "deferred" ] && [ "$STATUS" != "taken_up" ]; then
    echo "MALFORMED [$IDENTIFIER] — unknown status '$STATUS'; expected deferred, taken_up, or unprobeable."
    VIOLATIONS=$((VIOLATIONS + 1))
    continue
  fi

  # A probeable entry with a missing probe cannot be checked and is not allowed
  # to pass as though it had been. THE ABSENCE OF A PROBE IS WRITTEN AS THE WORD
  # none RATHER THAN AS AN EMPTY FIELD: an empty field is invisible both to a
  # reader and to a field splitter, and the first version of this gate lost an
  # entry's note to exactly that ambiguity.
  if [ -z "$(echo "$STANDS" | tr -d '[:space:]')" ] || [ -z "$(echo "$LIFTS" | tr -d '[:space:]')" ] \
     || [ "$STANDS" = "none" ] || [ "$LIFTS" = "none" ]; then
    echo "MALFORMED [$IDENTIFIER] — a $STATUS entry must carry both probes; use status unprobeable instead."
    VIOLATIONS=$((VIOLATIONS + 1))
    continue
  fi

  # Run both probes. Output is discarded; only the exit status is the answer.
  if sh -c "$STANDS" >/dev/null 2>&1; then STANDS_SAYS=yes; else STANDS_SAYS=no; fi
  # The second probe is run whatever the first said, because the interesting
  # faults are precisely the cases where the two agree.
  if sh -c "$LIFTS" >/dev/null 2>&1; then LIFTS_SAYS=yes; else LIFTS_SAYS=no; fi

  # THE PAIR IS JUDGED BEFORE THE DEFERRAL IS. Two probes that answer the same
  # way have told nothing apart, and which way they agreed does not rescue them.
  if [ "$STANDS_SAYS" = "$LIFTS_SAYS" ]; then
    if [ "$STANDS_SAYS" = "yes" ]; then
      echo "UNDISCRIMINATING [$IDENTIFIER] — both probes succeed, so the pair cannot tell a standing block from a lifted one."
    else
      echo "UNDISCRIMINATING [$IDENTIFIER] — both probes fail, so the pair has rotted and no longer describes anything."
    fi
    VIOLATIONS=$((VIOLATIONS + 1))
    continue
  fi

  # A DEFERRED entry is warranted while the block stands and the lift has not
  # happened. The other way round means the thing it was waiting for is here.
  if [ "$STATUS" = "deferred" ]; then
    if [ "$STANDS_SAYS" = "yes" ]; then
      echo "DEFERRED   [$IDENTIFIER] — $SUBJECT"
      DEFERRED=$((DEFERRED + 1))
    else
      echo "RIPE       [$IDENTIFIER] — the block has lifted and the work is still deferred: $SUBJECT"
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
    continue
  fi

  # A TAKEN_UP entry is a standing regression guard: the thing that unblocked it
  # must still be there. If it is not, something was undone and the conclusions
  # drawn from it are now unsupported.
  if [ "$LIFTS_SAYS" = "yes" ]; then
    echo "TAKEN UP   [$IDENTIFIER] — $SUBJECT"
    TAKEN_UP=$((TAKEN_UP + 1))
  else
    echo "BROKEN     [$IDENTIFIER] — this was taken up and the thing that unblocked it is gone: $SUBJECT"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done 3< "$REGISTER"

# Report in the same voice as the sibling gates.
if [ "$VIOLATIONS" -eq 0 ]; then
  echo "Deferral violations: 0 of $TOTAL — every deferred block still stands, and everything taken up is still standing taken up."
  # The unprobeable count is printed on its own line rather than folded into the
  # clean message, so a reader can never quote "zero violations" without it -
  # the same discipline the naming gate's collision count is held to.
  echo "Deferred: $DEFERRED | Taken up: $TAKEN_UP | Unprobeable: $UNPROBEABLE — each unprobeable reason is printed above."
  exit 0
fi
# A dirty gate names its count and exits non-zero, so it can block a merge.
echo "Deferral violations: $VIOLATIONS of $TOTAL — a deferral nobody re-earns is a sentence the build has stopped checking."
exit 1
