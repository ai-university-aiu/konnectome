DOCS / HAND-OFF - THE SESSION RECORDS

Created 2026-08-10. Constitution version 12.


WHAT IS IN HERE

Every SUPERSEDED Context Hand-Off document - the session records mandated by the Nineteenth Commandment, from 2026-07-19 onward.

THE CURRENT HAND-OFF IS NOT IN HERE. IT LIVES IN /docs/start-here/ , and it is the ONLY FILE in that directory, which is how you know it is the current one without working anything out.

(UPDATED 2026-08-12, Constitution version 29. It lived at the top level of /docs/ from Constitution version 13 until then. The rule did not change - exactly one Context Hand-Off document stands outside this directory at any moment and it is always the one to read - but the way you SEE that it is the right one did. "The only dated file in /docs/" rested on a NEGATIVE, on what was not in that directory, which is a fact a reader has to check. "The only file in a directory called start-here" rests on a positive fact and states its own instruction. NOTHING ELSE MAY BE PUT IN docs/start-here/ , for exactly that reason.)

That is the Nineteenth Commandment's two-location rule, added at Constitution version 13 on 2026-08-10, and it is the whole reason this directory exists in the shape it does. Before writing a new hand-off, a session SWEEPS whatever it finds in /docs/ into here, and only then writes the new one. Sweep, then write - in that order, in one commit.


WHAT A HAND-OFF IS, AND WHY IT IS TWO THINGS AT ONCE

The Nineteenth Commandment exists because a long session degrades - context rot, and the lost-in-the-middle effect - and because the assistant cannot see its own context window's fill level. So durable state lives on disk and never only in a conversation, and each session writes down what it did, what it decided, what it left open, and what the next session should do first.

THAT MAKES EVERY HAND-OFF TWO DOCUMENTS IN ONE FILE, and the distinction matters more than it looks.

• IT IS A RECORD. Its report of what was built, what was measured, and what was true on its own date is a dated claim, and dated claims are not edited afterwards. Editing one would be falsifying the record rather than updating it - the fault this repository named at slice 43 and has refused twice since.

• IT IS ALSO AN INSTRUCTION. Its reading list, its first-task menu, and any command it tells the next session to run are LIVE, and a live instruction that does not resolve is broken rather than preserved.

THE RULE THAT FOLLOWS, and it is the rule this whole directory was organised under: A HISTORICAL CLAIM IS NOT REPAIRED BY MAKING IT SAY SOMETHING IT DID NOT SAY, AND A LIVE INSTRUCTION IS NOT PRESERVED BY LEAVING IT POINTING AT NOTHING.


HOW TO READ THEM

START IN /docs/start-here/ , NOT IN HERE. The single file in docs/start-here/ is the current hand-off, and it is the entry point. Read it first, in full.

Then read the one it names as its substantive predecessor, which will be in here - AND WHICH IS NOT ALWAYS THE ONE IMMEDIATELY BEFORE IT, because SOME HAND-OFFS ARE SESSION-CLOSE MARKERS RATHER THAN UNITS OF WORK. At least two are markers. Each hand-off says which of its predecessors is the substantive one; trust that rather than the date order.

WHY THE SWEEP IS A PRECONDITION AND NOT A POSTCONDITION, since it is the one part of the protocol that looks backwards at first reading. Writing the new hand-off and THEN moving the old one reads more naturally and fails silently: a session that skips the second half leaves two hand-offs in /docs/ , and the next session reads whichever it happens to open, with nothing anywhere to notice. Sweeping FIRST is self-healing, because it moves whatever it finds however many there are. A skipped step then costs one session of clutter rather than a wrong read. PREFER THE FORM WHOSE FAILURE MODE IS VISIBLE OVER THE FORM WHOSE FAILURE MODE IS A PLAUSIBLE ANSWER - the same rule the fulfilment-audit trigger was rewritten under on the same day.

NAMING. Each file is [DATE]_[SERIAL]_Context_Hand-Off_from_[NAME].txt, where the serial is the next free number for that date starting at 1, and the name is one the writing session chose for itself and explained in its first paragraph. The naming convention is unchanged by the move.


THE FORWARDING NOTE - READ THIS IF YOU ARRIVED HERE FROM AN OLD DOCUMENT

Before 2026-08-10 every hand-off lived directly in /docs/ . If you are following a path of the form docs/[DATE]_..._Context_Hand-Off_from_... and it does not resolve, the file is here: insert hand-off/ after docs/ and the path is correct. No file was renamed, edited or deleted.

ONE EXCEPTION HELD FROM 2026-08-10 TO 2026-08-12 AND HAS NOW LAPSED, AND THE LAPSE IS SAID PLAINLY BECAUSE IT SIMPLIFIES THE FORWARDING RULE RATHER THAN COMPLICATING IT: the CURRENT hand-off used to sit at the top level of /docs/ , so its old-style path was still correct and a resolving path meant you had found the live one. SINCE CONSTITUTION VERSION 29 THE CURRENT HAND-OFF IS IN /docs/start-here/ , SO NO PATH OF THE FORM docs/[DATE]_..._Context_Hand-Off_from_... RESOLVES ANY MORE - every one of them is now an old path, every one of them leads here or to docs/start-here/ , and there is no longer a case in which following one lands you on the live document by accident. So the forwarding rule above now has no exception at all: an unresolving hand-off path always means this directory, and the live document is always the single file in docs/start-here/ .

TWO CATEGORIES OF POINTER WERE FIXED IN THE SAME CHANGE, and both were live instructions rather than records.

• THE NINETEENTH COMMANDMENT'S HAND-OFF PROTOCOL, STEP 2, which is where a session learns WHERE TO WRITE a hand-off. THIS WAS THE POINTER THAT MATTERED MOST, and the reason generalises: Step 2 is not a reference to a file, it is an INSTRUCTION TO CREATE ONE, so a stale path there would not have failed loudly - it would have succeeded, in the wrong directory, every time, forever. A broken read is noisy; a broken write is silent.

• THE FULFILMENT-AUDIT TRIGGER, which several documents told a session to evaluate with a shell glob over docs/ . After the move that glob matches nothing and returns ZERO - and zero is not obviously wrong for a count, so a session would have read it as "the audit is nowhere near due" and been exactly wrong. The standing instruction in the ledger's SCHEDULED AUDIT note now uses a recursive find instead of a glob, so that it survives the next reorganisation without anybody remembering to fix it. A TRIGGER WHOSE FAILURE MODE IS A PLAUSIBLE ANSWER IS WORSE THAN NO TRIGGER.

WHAT WAS DELIBERATELY LEFT ALONE. The bodies of the twenty-eight hand-offs dated before 2026-08-10 still carry their original paths, including the paths by which they cite one another. Those are dated records and their paths were correct on their own dates. The single exception is the newest hand-off, whose reading line and audit command WERE corrected and which carries a dated forward note at its foot explaining what changed after it was written - because it is not only a record, it is the live entry point the next session reads first.

TWO DATED SLICE NOTES IN THE LEDGER ALSO QUOTE THE SUPERSEDED GLOB, correctly for their own dates. If you run one of those it will return zero and it is not a count. The ledger's SCHEDULED AUDIT note is the authority on the trigger and says so.


WHY THESE ARE NOT IN /docs/archive/

Because they are a SERIES and not a set of VERSIONS, and the Eleventh Commandment governs versions.

A superseded hand-off is not a new version of an older one. Each records a DIFFERENT session, and none replaces any other. That is the opposite of what /archive/ is for: the archive holds konnectome_tutorial_v12 and konnectome_1_specification_v41, which are superseded drafts of documents that still exist in better form.

THE TEST THAT SEPARATES THEM, added to the Eleventh Commandment at Constitution version 14: WOULD A SESSION EVER BE TOLD TO READ THIS FILE?

Nothing in this repository ever instructs anyone to read an archived file. Every reference to /archive/ in the Constitution is preservation language - a superseded document is not deleted and remains readable - which is a promise about the record rather than a reading list.

A SUPERSEDED HAND-OFF IS REQUIRED READING. Each one names which of its predecessors is the substantive one, and the current hand-off's own first part sends the next session to it by name.

/archive/ HOLDS DEAD VERSIONS. THIS DIRECTORY HOLDS A LIVING SERIES.


WHAT THE HAND-OFFS ARE NOT

They are not a measure of build progress, and the count of them is not a count of work done. At least two are session-close markers. Any audit triggered on the number of hand-off documents should check that before treating the count as a measure of how much has been built - a warning first recorded by the Rhodium Marchwright hand-off and carried by every one since.
