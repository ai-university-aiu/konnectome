docs/deferrals/ — THE DEFERRAL REGISTER
=======================================

WHAT IS IN HERE. One file, deferral_register.txt, and it is machine-readable. It records every
condition this build is waiting on, the work each condition is holding up, and TWO PROBES per
condition that let a script decide whether the condition is still true.

WHO READS IT. bin/check_deferrals.sh, the DEFERRAL GATE, which is the sixth of konnectome's gates
and the third to carry a self-test. Its fixture register is at tests/deferral_gate_fixture/ and is
deliberately broken, in the same discipline as the naming and discrimination gate fixtures.

WHY THE DIRECTORY EXISTS RATHER THAN THE ENTRIES LIVING IN THE GATE. The discrimination gate carries
its exemptions inside the script, and that is right for a list only that script consults. This
register is different in kind: it is a document the build WRITES TO, every time a slice defers
something, and a session adding an entry should not have to edit a gate to do it. It is also meant
to be read straight through by a person, which a shell variable is not.

WHERE IT SITS IN THE ORDER OF DOCUMENTS. It is a record and not an authority. It settles nothing; it
only refuses to let a settled-looking sentence go unchecked. Where the register and the ledger
disagree about what was deferred and why, THE LEDGER LEADS and the register entry is corrected -
the ledger is the Fourth Commandment's scoreboard and this is a watchdog on one of its habits.

HOW TO ADD AN ENTRY. Read the format block at the head of deferral_register.txt, write the entry,
and run bin/check_deferrals.sh. If the gate reports the entry UNDISCRIMINATING, the two probes
answer the same way and the entry is not yet watching anything - which is the question this whole
build now asks of everything it writes: WHAT DOES THIS TELL APART?

WHAT THE REGISTER CANNOT DO, stated here so it is never quoted as more than it is. It cannot find a
deferral nobody wrote down. A session that defers work in a hand-off and adds no entry here is
invisible to the gate, and that residue is a discipline rather than a check. The gate's own header
states this first among its limits.
