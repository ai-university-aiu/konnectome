#!/usr/bin/env bash
# check_pack_naming.sh — enforce the Whole-Word System (Twelfth Commandment).
# Copied from the PrologAI reference gate so konnectome enforces the identical
# rule, and extended at slice 26. Six checks, all merge blockers:
#   (1) PREDICATE prefix — every pack's predicates must be prefixed with the
#       pack's own whole-word name (tick_engine_run, not te_run).
#   (2) MINORITY straggler prefix — a pack may not carry a SECOND terse/retired
#       prefix cluster.
#   (3) PACK NAME — the directory/module/manifest name must be whole words, not
#       an abbreviation and not an un-underscored concatenation.
#   (4) SWI-STDLIB — a pack must not be named for an installed SWI stdlib module.
#   (5) TEST PRESENCE — every pack must ship test/test_<name>.pl.
#   (6) UNPREFIXED helper — every clause head DEFINED in the pack module must
#       begin with the pack's own prefix (or the sanctioned prologai_ namespace).
#       This closes the slice-22 hole: a one-off helper bearing no known terse
#       stem (numlist_or_empty proved it) slipped past the cluster checks above,
#       because one-off clusters were ignored and unknown long stubs passed.
#
# Usage:   bin/check_pack_naming.sh              # scan every pack
#          bin/check_pack_naming.sh tick_engine  # scan named packs only
#          bin/check_pack_naming.sh --self-test  # prove the gate can fail, on the
#                                                # committed fixture pack (exit 0
#                                                # iff the fixture is caught)
# PACKS_ROOT overrides the scanned packs directory (the self-test uses this).
# Exit 0 = clean; exit 1 = at least one violation.
set -u
# The script's own absolute path, captured BEFORE the cd so the self-test can
# re-invoke it correctly however it was started (a relative $0 dies after a cd).
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
cd "$(dirname "$0")/.." || exit 2
# The packs directory being scanned; the self-test points this at the fixture tree.
PACKS_ROOT="${PACKS_ROOT:-packs}"

# --self-test: run this gate against the committed fixture pack - a pack that
# deliberately carries an unprefixed helper with no known terse stem - and
# succeed ONLY if the gate catches it. A gate must be proven able to fail
# before it is trusted to pass.
if [ "${1:-}" = "--self-test" ]; then
  # Run the gate over the fixture tree, capturing its report.
  report="$(PACKS_ROOT=tests/naming_gate_fixture "$SELF" 2>&1)"; status=$?
  # The fixture must FAIL the gate, fail it for the unprefixed helper by name,
  # and fail it for NOTHING ELSE - so the self-test proves the sixth check
  # specifically, not some other check happening to fire.
  if [ $status -ne 0 ] \
     && echo "$report" | grep -q "VIOLATION \[UNPREFIXED\]" \
     && [ "$(echo "$report" | grep -c "VIOLATION \[")" -eq 1 ]; then
    echo "SELF-TEST PASS: the gate catches the fixture's unprefixed helper."
    exit 0
  fi
  # Anything else means the hole is open again.
  echo "$report"
  echo "SELF-TEST FAIL: the fixture's unprefixed helper was NOT caught - the slice-22 hole is open."
  exit 1
fi

# Abbreviation stems that may never appear as a segment of a pack name.
BANNED_STEMS=" autom seq sym xf xform nbr aggr hist dist pos op ops cmp comp inv sig hyp induct quant crypto ros mcp sona vsa a2a acp anp coocc cooccur rowcol colorop sizeop posop naggr nmode varstat symtab condxf seqinfer ruleinfer objxf objrel objbound iochan multipair multicolor vec2 xsel taskcat transformgen periodfix rowsig gridxform gridtransform "
# Retired shared prefix that must now read prologai_ (the sanctioned namespace).
RETIRED_SHARED=" pai "
# Short helper stubs that are real English words / conventional predicates and
# are fine as minority prefixes (so is_valid, eq_, id_ are not false-flagged).
GENERIC_OK=" is eq ok no id on at up in of to do go my as if "
# SWI-Prolog stdlib module names: a pack must not be named one of these, or the
# pack shadows the stdlib module on the library path. Queried live from the
# installed SWI, with a hardcoded core fallback when swipl is unavailable.
SWI_STDLIB=" $(swipl -q -g "absolute_file_name(swi(library),D),atom_concat(D,'/*.pl',P),expand_file_name(P,Fs),forall(member(F,Fs),(file_base_name(F,B),file_name_extension(N,pl,B),write(N),write(' '))),halt" 2>/dev/null) "
[ "${SWI_STDLIB// /}" = "" ] && SWI_STDLIB=" aggregate apply arithmetic assoc broadcast charsio check clpfd csv dcg debug dicts error gensym heaps http lists main option ordsets pairs pcre persistency random rbtrees readutil record settings sgml shell sort statistics strings tables table tabling terms thread ugraphs url when yall "
# Concatenation heads: a pack name starting with one of these followed by more
# letters with NO underscore is a jammed concatenation (gridblend -> grid_blend).
CONCAT_HEADS='^(grid|scene|multi)[a-z]{2,}$'

declare -A PREFIX_OF
violations=0
scanned=0
targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=($(ls -d "$PACKS_ROOT"/*/ 2>/dev/null | xargs -r -n1 basename))

is_banned_name() { # $1 = pack name -> 0 if the NAME is an abbreviation/concatenation
  local name="$1" seg
  # any underscore-segment that is a banned abbreviation stem
  local IFS='_'
  for seg in $name; do
    case "$BANNED_STEMS" in *" $seg "*) return 0 ;; esac
  done
  # un-underscored concatenation of a known head word plus more letters
  [[ "$name" =~ $CONCAT_HEADS ]] && return 0
  return 1
}

for p in "${targets[@]}"; do
  # (5) TEST PRESENCE — every pack must ship an in-pack PLUnit test, or it never
  # enters the per-pack regression and can rot invisibly.
  if [ ! -f "$PACKS_ROOT/$p/test/test_$p.pl" ]; then
    violations=$((violations+1))
    echo "VIOLATION [NO-TEST]  pack '$p' has no test/test_$p.pl (not in the per-pack regression; can rot invisibly)"
  fi
  f="$PACKS_ROOT/$p/prolog/$p.pl"
  [ -f "$f" ] || continue
  scanned=$((scanned+1))

  # (3) pack NAME must be whole words
  if is_banned_name "$p"; then
    violations=$((violations+1))
    echo "VIOLATION [NAME]  pack '$p' is an abbreviation/concatenation (use whole words, underscore-separated)"
  fi

  # (4) pack NAME must not shadow an SWI-Prolog stdlib module
  case "$SWI_STDLIB" in
    *" $p "*)
      violations=$((violations+1))
      echo "VIOLATION [SWI-STDLIB]  pack '$p' shadows SWI stdlib library($p) (pick a distinct whole-word name)" ;;
  esac

  # (6) UNPREFIXED helper — every clause head defined in the pack must carry
  # the pack's own prefix or the sanctioned prologai_ namespace. Clause heads
  # sit at column 0 in the house style; directives start with ':-' and are not
  # matched; body goals are indented and are not matched. EVERY prolog/*.pl
  # file in the pack is scanned, not only the main module, so a helper cannot
  # hide in a second source file.
  for src in "$PACKS_ROOT/$p/prolog/"*.pl; do
    # A pack with no source files has nothing to scan here.
    [ -f "$src" ] || continue
    # Read every distinct name that begins a line of this source file.
    mapfile -t heads < <(grep -oE '^[a-z][a-z0-9_]*' "$src" 2>/dev/null | sort -u)
    for h in "${heads[@]}"; do
      # The pack's own prefix is the rule; a bare zero-argument head named exactly
      # for the pack is the same rule at arity zero.
      case "$h" in "$p"|"${p}_"*) continue ;; esac
      # The sanctioned shared namespace is allowed.
      case "$h" in prologai_*) continue ;; esac
      # Anything else defined here is an unprefixed helper — the slice-22 hole.
      violations=$((violations+1))
      echo "VIOLATION [UNPREFIXED]  pack '$p' defines '$h' without its own prefix in $(basename "$src") (should begin '${p}_')"
    done
  done

  # collect every col-0 predicate prefix cluster with its count
  mapfile -t clusters < <(grep -oE '^[a-z][a-z0-9]*_' "$f" 2>/dev/null | sort | uniq -c | sort -rn)
  [ ${#clusters[@]} -eq 0 ] && continue
  pre=$(echo "${clusters[0]}" | awk '{print $2}')     # dominant
  PREFIX_OF["$pre"]="${PREFIX_OF[$pre]:-} $p"

  # (1) dominant prefix must be pack-qualified
  case "${p}_" in
    "$pre"*) : ;;
    *) violations=$((violations+1))
       stub="${pre%_}"; kind="mismatched"; [ ${#stub} -le 3 ] && kind="TERSE"
       echo "VIOLATION [$kind]  pack '$p' uses predicate prefix '${pre}' (should be '${p}_')" ;;
  esac

  # (2) minority straggler clusters (count >= 2) that are terse / retired / banned
  for c in "${clusters[@]}"; do
    cnt=$(echo "$c" | awk '{print $1}'); cpre=$(echo "$c" | awk '{print $2}')
    [ "$cpre" = "$pre" ] && continue                  # skip the dominant one
    [ "$cnt" -lt 2 ] && continue                      # ignore one-offs
    case "${p}_" in "$cpre"*) continue ;; esac        # a sub-prefix of the pack name is fine
    stub="${cpre%_}"
    [ "$cpre" = "prologai_" ] && continue             # sanctioned shared namespace
    flag=0
    case "$GENERIC_OK" in *" $stub "*) ;; *) [ ${#stub} -eq 2 ] && flag=1 ;; esac
    case "$BANNED_STEMS" in *" $stub "*) flag=1 ;; esac
    case "$RETIRED_SHARED" in *" $stub "*) flag=1 ;; esac
    if [ "$flag" -eq 1 ]; then
      violations=$((violations+1))
      echo "VIOLATION [STRAGGLER]  pack '$p' carries a second prefix '${cpre}' (${cnt} preds; should be '${p}_' or prologai_)"
    fi
  done
done
echo "---"
collisions=0
for pre in "${!PREFIX_OF[@]}"; do
  set -- ${PREFIX_OF[$pre]}
  if [ "$#" -gt 1 ]; then collisions=$((collisions+1)); echo "COLLISION  prefix '${pre}' shared by:$(printf ' %s' "$@")"; fi
done
echo "---"
echo "scanned=$scanned  violations=$violations  colliding_prefixes=$collisions"
# A run that scanned nothing proves nothing: a stray PACKS_ROOT or a missing
# packs directory must fail loudly rather than pass vacuously.
if [ "$scanned" -eq 0 ]; then
  echo "ERROR: no packs scanned under '$PACKS_ROOT' - refusing to report a vacuous pass"
  exit 2
fi
[ "$violations" -eq 0 ] && exit 0 || exit 1
