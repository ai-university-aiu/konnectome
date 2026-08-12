KONNECTOME CONSTITUTION - VERSION HISTORY

The dated record of every amendment to /home/ccaitwo/konnectome/CONSTITUTION.md .


THIS FILE IS NOT REQUIRED READING ON A HAND-OFF.

By the owner's instruction of 2026-08-11, a session loading state at the start of its work reads THE
COMMANDMENTS and does not read their history. That instruction is recorded in the Constitution
itself as well as here, so that neither document can lose it alone.

THE REASON IS WHAT THIS FILE IS. It is a RECORD OF DATED ACTS and not a rule in force. Every rule
any entry below describes is already stated, in its final and current form, in the Commandments -
which is precisely why the history can be set aside without anything being lost. A session that read
only this file would know how konnectome's rules got their shape and not one of the rules.


WHEN TO READ IT ANYWAY, and each of these is a real occasion rather than a courtesy.

- WHEN YOU ARE ABOUT TO AMEND THE CONSTITUTION. The entries below are the worked examples of how an
  amendment is written in this project, and several of them argue with each other, which is the most
  useful thing about them.

- WHEN YOU NEED TO KNOW WHY A RULE READS AS IT DOES. A Commandment states what is required; these
  entries state what went wrong before it did. The version 18 pointer audit's lesson - DROP THE PART
  THAT CAN GO STALE RATHER THAN UPDATING IT - is stated here and nowhere else in full.

- WHEN YOU ARE CHASING A COMMANDMENT NUMBER CITED FROM AN OLDER DOCUMENT. THE VERSION 19 ENTRY BELOW
  CARRIES THE RENUMBERING MAP, and it is the only place that map exists. An archived hand-off citing
  the Sixteenth Commandment means something different from what that number means today.

- WHEN A LEDGER OR BUILD-LOG ENTRY POINTS AT "the Constitution's own version N note". Several do.
  They resolve here.


WHAT A SESSION OWES THIS FILE. A session that amends the Constitution writes its entry HERE, in the
same change as the amendment, and updates the version and commandment count in CONSTITUTION.md's
closing block. THE TWO DOCUMENTS MOVE TOGETHER OR THE AMENDMENT IS NOT FINISHED. An amendment whose
history entry was skipped is indistinguishable, one session later, from a rule that was always there.


THE CONVENTIONS THESE ENTRIES FOLLOW, stated once so the next one matches.

Entries run NEWEST FIRST. Each opens "Version N, by the owner's instruction of [date]" - or, where
the change was made under the Sixteenth Commandment's own authority, by naming what occasioned it.
Each states plainly whether A RULE CHANGED, and whether any Commandment was ADDED, REMOVED or
RENUMBERED, because those are the four questions a reader arrives with. Where no rule changed, the
entry says so in as many words; where one did, it says that instead and does not soften it. Several
entries then argue the reasoning at length, and that length is deliberate: the argument is the part
that transfers.


-----------------------------------------------------------------------------


Version 29, by the owner's instruction of 2026-08-12, CREATES docs/start-here/ AND MOVES THE CURRENT
CONTEXT HAND-OFF INTO IT. NO COMMANDMENT WAS ADDED, REMOVED, OR RENUMBERED; the count stands at
twenty-three. A RULE CHANGED, AND THIS ENTRY SAYS SO RATHER THAN CLAIMING OTHERWISE - unlike the
version 28 entry immediately below, which moved only pointers. WHAT CHANGED IS THE LOCATION named in
Steps 2a and 2b of the Twenty-Third Commandment's Hand-Off Protocol. Nothing else in that protocol
did: exactly one Context Hand-Off document stands outside docs/hand-off/ at any moment, it is always
the one to read, the sweep is still a PRECONDITION rather than a postcondition, the naming convention
is untouched, and superseded hand-offs still live in docs/hand-off/ and are still not archived.

BOTH STEPS MOVED IN ONE ACT, AND THAT IS THE MECHANICAL POINT OF THIS AMENDMENT. Step 2a sweeps FROM a
directory and Step 2b writes INTO it, and they are one mechanism. Repointing either alone would leave
a protocol that still runs, still commits, still passes every gate, and quietly stops sweeping - which
is exactly the silent failure the version 13 amendment reordered these two steps to prevent. They were
therefore edited in the same change and the amendment note is attached to both.

WHY THIS IS AN IMPROVEMENT ON WHAT VERSION 13 BUILT RATHER THAN A REVERSAL OF IT, which matters
because version 12 DID reverse this and version 13 reversed it back. Version 12 briefly put every
hand-off, current one included, in docs/hand-off/ ; version 13 brought the current one back up and
gave three reasons. THIS AMENDMENT KEEPS ALL THREE AND STRENGTHENS THE THIRD. The first reason - that
a hand-off is both a dated REPORT and a live INSTRUCTION, and only the newest is ever read as
instruction, so the two should be separated on disk - is untouched and is now expressed by a directory
whose NAME states which of the two you are looking at. The second - that hand-offs should follow the
house rule that only the current member of a series lives outside its own directory - is untouched.

THE THIRD REASON IS THE ONE THAT IMPROVES, AND THE REASONING IS WORTH KEEPING BECAUSE IT IS SUBTLE.
Version 13 wanted "the latest hand-off" to be something a session FINDS rather than DERIVES, because
deriving it meant sorting filenames on date and serial number, and same-day hand-offs, serial
numbering and session-close markers all make that fallible. Its answer was: it is simply the only
dated file in /docs/ . THAT ANSWER WAS CORRECT AND IT RESTED ON A NEGATIVE - it worked because of what
was NOT in that directory, which is a fact a reader must CHECK rather than SEE. Between version 13 and
version 28 the directory held four files and the rule needed a reader to know which three to ignore;
version 28's move to docs/admin/ narrowed it to one; version 29 finishes the job by giving that one
file a directory whose name is an instruction. A SESSION THAT HAS READ NOTHING AT ALL CAN NOW FIND ITS
ENTRY POINT FROM A DIRECTORY LISTING. The rule now rests on a positive fact rather than an absence,
which is the same preference this Constitution has stated three times in other places: prefer the form
whose failure mode is VISIBLE over the form whose failure mode is a plausible answer.

AND ONE PROHIBITION IS WRITTEN INTO THE COMMANDMENT, FOR THE SAME REASON VERSION 28 FORBADE
docs/admin/archive/ . NOTHING ELSE MAY BE PUT IN docs/start-here/ . A directory meaning "read this
first" stops meaning anything the moment it holds a second file, and a README or a quick-start guide
placed there would be an entirely reasonable-looking act that destroys the property the directory
exists for. The reading LIST belongs inside the hand-off, where it already is.

THE SWEEP OUTSIDE THE CONSTITUTION was small, because the hand-off's location was named in fewer
places than the ledger's: docs/hand-off/README.txt, whose whole subject is this arrangement and which
carries the migration note for anyone following an old path; README.md's directory tree; and the
current hand-off's own DOCS LAYOUT entry, which is a reading list rather than a report and which was
corrected in place for the second time in one day. Superseded hand-offs were again left untouched, and
docs/hand-off/README.txt is where a reader following an old path should land - which is what that file
was already for, and is now for twice over.

Version 28, by the owner's instruction of 2026-08-12, CREATES docs/admin/ AND RELOCATES THE THREE
ADMINISTRATIVE DOCUMENTS INTO IT - the ledger of the Fourth Commandment, the tutorial of the
Eighteenth, and the build log of the Nineteenth. NO COMMANDMENT WAS ADDED, REMOVED, OR RENUMBERED;
the count stands at twenty-three. NO RULE CHANGED IN ANY OF THE THREE COMMANDMENTS: the ledger is
still append-only and still the one scoreboard, the tutorial is still identified by there being
exactly one of it and still archives its superseded versions under the Eleventh Commandment, and the
build log is still unversioned, append-only, and dual-voiced. ONLY DIRECTORIES MOVED.

FIVE POINTERS IN THIS CONSTITUTION MOVED IN THE SAME CHANGE, which is the whole reason this
amendment exists rather than the move being a silent act of housekeeping. The Fourth Commandment's
ledger path, the Tenth's second copy of that same path, the Eighteenth's tutorial-uniqueness
directory, the Nineteenth's build-log path, and the Twenty-Third's hand-off reading list. The rule
being obeyed is the one the version 9 entry wrote down and the version 10 move first tested at
scale: A POINTER IS NOT A STATEMENT, SO A FILE THAT MOVES MUST HAVE EVERY POINTER TO IT MOVED IN THE
SAME CHANGE.

AND THREE LINES WERE DELIBERATELY LEFT ALONE, WHICH IS THE HALF OF THIS AMENDMENT MOST WORTH READING
LATER. The Fourth Commandment's "(A new file; create it at build start.)", the Eighteenth's "Add the
following to /docs/: konnectome_tutorial_v1.txt", and the Nineteenth's parenthetical history of the
build log's renames are all RECORDS OF DATED ACTS and not pointers. A record says where a file WAS
written and what it WAS called; rewriting one to match a later directory would turn a true historical
claim into a false one. This is the version 15 and version 18 argument about the Seventh
Commandment's file list, applied in the direction version 18 did not have to consider: version 18
found a list of six dead paths pretending to be pointers and DROPPED the part that could go stale;
this amendment finds three genuine records sitting beside three genuine pointers and moves only the
pointers. THE TEST THAT SEPARATES THEM IS THE SAME ONE THE ELEVENTH COMMANDMENT USES FOR HAND-OFFS:
WOULD A SESSION EVER FOLLOW THIS LINE TO OPEN A FILE? If yes it is a pointer and it moves; if it only
says what once happened, it is a record and it stands.

WHY A DIRECTORY AT ALL, since the Constitution does not require one and the owner did not have to
give a reason. These three are konnectome's ADMINISTRATIVE RECORD - the scoreboard, the story, and
the guide. Every other kind of document in this repository already had a home: the method documents
in docs/DSPARCD/, konnectome's own assessments in docs/design/, the sources it reads and never edits
in docs/neuroscience/ and docs/principles/, the gated change orders in docs/cousins/, the session
series in docs/hand-off/, the dead versions in docs/archive/. The three that moved here were the
residue - the files that lived at the top level because nothing had ever named what they had in
common. THE EVIDENCE THAT THIS WAS A REAL GAP AND NOT A TIDYING PREFERENCE IS IN THE TENTH
COMMANDMENT'S OWN LINE, which has now had to be chased twice: version 18 repaired it from a bare
filename that did not resolve from the repository root, and version 28 repaints it here. A document
with no directory gets cited three different ways, and each way rots differently.

AND ONE STANDING RULE IS SHARPENED RATHER THAN CHANGED, WHICH IS A SIDE EFFECT WORTH NAMING. The
Twenty-Third Commandment's hand-off discipline says that AT ANY MOMENT EXACTLY ONE CONTEXT HAND-OFF
DOCUMENT SITS IN /docs/ AND IT IS ALWAYS THE ONE TO READ. Before this move /docs/ held four files and
that claim needed a reader to know which three to ignore. AFTER IT, /docs/ HOLDS EXACTLY ONE FILE,
AND IT IS THE HAND-OFF. The rule is unchanged and is now self-evident from the directory listing,
which is the shape this Constitution keeps preferring: the form whose failure mode is VISIBLE over
the form whose failure mode is a plausible answer.

AND docs/admin/archive/ DOES NOT EXIST AND MUST NOT BE CREATED. The Eleventh Commandment names
exactly one archive, at docs/archive/ , and the superseded tutorials stay in it. A relocation of a
live document is not a licence to give it a private archive, and this is written down because the
next session to bump the tutorial will be standing in a new directory with an obvious wrong thing to
do one keystroke away.

Version 27, by the owner's instruction of 2026-08-11, MOVES THIS VERSION HISTORY OUT OF THE
CONSTITUTION AND INTO THIS FILE, and declares it not required reading on a hand-off. NO COMMANDMENT
WAS ADDED, REMOVED, OR RENUMBERED; the count stands at twenty-three. NO COMMANDMENT'S TEXT WAS
EDITED, and not one word of the entries below was altered in the move.

A RULE CHANGED, AND THIS ENTRY SAYS SO RATHER THAN CLAIMING OTHERWISE - which is the discipline the
version 22 entry established and this one inherits. What changed is a READING OBLIGATION: the
Constitution was previously read whole at the start of every session, and its history is now
explicitly excluded from that reading. Nothing about any Commandment's force is different. But a
session that skips this file is now FOLLOWING the rules rather than cutting a corner, and that is a
real change and is the owner's instruction.

THE OWNER'S REASON, AND IT IS A MEASUREMENT RATHER THAN A PREFERENCE. The version history had grown
to roughly four hundred lines - very nearly a third of the document - and every session was reading
all of it before doing any work. The Twenty-Third Commandment exists because a session's context
window is finite and degrades as it fills. SPENDING A THIRD OF THE CONSTITUTION'S BUDGET ON DATED
RECORDS OF ACTS ALREADY REFLECTED IN THE RULES IS SPENDING IT ON THE WRONG THIRD.

WHY THE SPLIT IS SAFE, WHICH IS THE PART THAT NEEDED CHECKING RATHER THAN ASSERTING. A history entry
cannot be load-bearing on its own, because every rule it describes has already been written into the
Commandment it amended - that is what an amendment IS in this document. The entries were checked for
the one exception that would have broken this: something stated ONLY in the history and nowhere in
the rules. THERE IS EXACTLY ONE, AND IT IS THE VERSION 19 RENUMBERING MAP, which no Commandment
carries because it describes a change to numbering rather than a rule. It is named in this file's
head as a standing reason to open the file, so it is findable by a reader who does not know it
exists.

WHAT STAYS IN THE CONSTITUTION. The VERSION and the COMMANDMENT COUNT, in a short closing block that
also points here. Those two facts are the ones most often quoted from the document and the ones a
reader most often needs without opening anything else, so moving them would have traded a large
saving for a small daily cost. The pointer beside them carries the not-required-reading rule as
well, so neither document can lose that instruction alone.

AND THE POINTER RULE OF THE FIRST COMMANDMENT'S VERSION 9 NOTE IS HONOURED HERE: a file that moves
must have every pointer to it moved in the same change. The live pointers at this history are in the
ledger and the build log, and they read "the Constitution's own version N note" - a form that still
resolves, in one hop, because CONSTITUTION.md now says where the history went. Those two documents
are APPEND-ONLY and their entries are DATED RECORDS, so they are not rewritten; the version 8 note
recorded in the ledger is the standing precedent for that restraint, where a mechanical sweep
rewrote a history note and would have made it describe an action that never happened.


Version 26, by the owner's instruction of 2026-08-11, adds THE TWENTY-SECOND COMMANDMENT, THE
JUDGEMENT-CALL PROTOCOL, and QUALIFIES the Eighth Commandment's read-only rule to admit the corpus
update run it establishes. The hand-off protocol is renumbered from the Twenty-Second to the
Twenty-Third, which is the version 19 standing rule working exactly as written for the third time.
Commandments 1 through 21 are unchanged in number.

WHAT IT SETTLES. This build is good at flagging judgement calls and had no rule about what happens
to one afterwards. A flagged call could sit as a permanent refusal indefinitely, and several have -
one observation has now been declined five times. The Commandment makes a flagged call WORK rather
than a resting place, in a fixed order: read the corpus beneath the finding; if it settles the
question, BUILD IT IN THE SAME ACT; if the corpus is silent or incomplete, search the published
literature; file what the search finds in docs/evidence/ and never straight into the corpus; then
build what the evidence supports, and where it supports nothing, record that the refusal has now
survived a search rather than only a reading.

WHY THE SEARCH IS FENCED. The obvious way to write this rule is to let a search update the corpus
directly, and that would have been the one change capable of destroying the corpus's usefulness. This
build's own name for its oldest failure is AN INVENTED VALUE THAT HAS LEARNED TO CITE. A search result
filed inside the north star is that failure at the scale of a document: it would wear the corpus's
authority for every session afterwards, and no later reader could tell it apart from the corpus's own
text. So evidence lives in its own directory, is outranked by the north star by its own first
paragraph, and reaches the corpus only through the update run.

AND THE CORPUS IS NO LONGER FROZEN FOREVER, WHICH IS THE OWNER'S OWN INSTRUCTION AND THE HALF THAT
NEEDED THE MOST CARE. The corpus is kept full, complete and current by careful measured update runs
EVERY TENTH HAND-OFF, under six rules: the run is its own act and never done inside a slice; it is
ADDITIVE ONLY and never alters or deletes what the corpus already says; every added block carries its
provenance on its face; only evidence already standing before the run may be folded in, and only
where a corpus gap was recorded; a promoted block never outranks the corpus's own text; and the
Safety Gate stands over it. The read-only rule was protecting the corpus from being quietly rewritten
by whichever slice found it inconvenient. That protection is untouched. What is now permitted is a
deliberate, dated, sourced, additive act on a stated cadence, which is a different thing entirely.

Version 25, on the writing of the vision-set analysis's version 4 at slice 58, DROPS A VERSION NUMBER
FROM THE EIGHTH COMMANDMENT'S POINTER at that analysis. NO COMMANDMENT WAS ADDED, REMOVED, OR
RENUMBERED, and NO RULE CHANGED; the count stands at twenty-two.

WHY THIS IS A REPAIR AND NOT A REPOINTING, WHICH IS THE WHOLE INTEREST OF IT. Version 11 repointed
this same line from _v1 to _v3 and changed no rule. That was correct and it was insufficient, and the
proof is that the line went stale again at the very next write of the document it points at. A
version number written into a pointer at a document THIS CONSTITUTION REQUIRES TO BE KEPT CURRENT is
not merely at risk of rotting - it is guaranteed to rot, on a schedule this Constitution itself sets.

THE FIX IS THE ONE THE VERSION 18 AUDIT ALREADY WROTE DOWN AND THIS LINE WAS NOT REACHED BY: WHEN A
RECORD REFERS TO A LIVE DOCUMENT, DROP THE PART THAT CAN GO STALE RATHER THAN UPDATING IT. The line
now names docs/design/ and the document's NUMBER, 01, together with the uniqueness rule that
identifies the current version - the same technique the Eighteenth Commandment uses for the tutorial.
The number is durable where the version is not: docs/design/ was numbered 01 through 10 in reading
and fulfilment order, and 01 is this analysis whatever version it reaches.

AND THE GENERAL FORM IS WORTH STATING ONCE, because two Commandments have now needed it: A POINTER AT
A DOCUMENT THAT IS REQUIRED TO BE MAINTAINED MUST IDENTIFY IT BY SOMETHING THAT MAINTENANCE DOES NOT
CHANGE. A directory, a number, or a uniqueness rule survives maintenance. A version suffix is the one
part of a filename that maintenance is certain to alter.

Version 24, by the owner's instruction of 2026-08-11, REPOINTS THE SIXTH COMMANDMENT. The English
Readable Code manuscript moves from the top level of /docs/ into docs/principles/ , and the
Commandment's pointer follows it. NO COMMANDMENT WAS ADDED, REMOVED, OR RENUMBERED, and NO RULE
CHANGED; the count stands at twenty-two.

WHAT THE MOVE SETTLES. The principles directory was created at version 17 to hold the First
Commandment's three documents, and its category was stated there as INHERITED, LIVE, AND NOT
NEUROSCIENCE. The ERC manuscript met all three tests and was outside it anyway - a specification
konnectome was HANDED AND BUILDS BY, sitting among the documents konnectome WRITES. That it is cited
by the Sixth Commandment rather than the First is no objection, because the directory is named for
the word PRINCIPLES and not for a Commandment number.

AND THE TOP LEVEL OF /docs/ IS NOW EXACTLY WHAT ITS OWN README CLAIMED IT WAS. That claim -
"reserved for konnectome's OWN live working documents" - was written at version 17 while this
inherited manuscript sat there contradicting it. Four files remain: the ledger, the build log, the
tutorial, and the current hand-off. Every one is written BY konnectome, and everything inherited,
superseded, or addressed elsewhere now lives in a named sub-directory.

Version 23, by the owner's instruction of 2026-08-11, UNVERSIONS THE LEDGER. The Fourth
Commandment's document is renamed from konnectome_ledger_v1.txt to konnectome_ledger.txt, and both
of this Constitution's pointers at it - in the Fourth Commandment and in the Tenth - are repointed.
NO COMMANDMENT WAS ADDED, REMOVED, OR RENUMBERED; the count stands at twenty-two.

NO RULE CHANGED, and the contrast with version 22 immediately below is the instructive part. That
entry HAD to change a rule, because the Nineteenth Commandment declared the build log "a versioned
document under the Eleventh Commandment" in so many words, and the rename made that declaration
false. This Constitution never made that declaration about the ledger. The suffix was not a rule
here - it was only ever part of a filename chosen at build start - so dropping it contradicts nothing
and releases nothing from any discipline.

THE TWO DOCUMENTS ARE THE SAME KIND OF THING, AND NOW LOOK IT. Both are append-only: the build log
"grows with the build", and every wall "becomes an entry here first". Neither can ever be superseded,
so neither can ever have a superseded version to archive. The proof for the ledger is cleaner than
the proof for the build log was: docs/archive/ has never held a konnectome_ledger at all, across
fifty-five slices, because the _v1 was written once and nothing could ever bump it.

THE RULE THIS LEAVES BEHIND, STATED ONCE AND COVERING BOTH. A version suffix belongs on a document
that gets SUPERSEDED - written afresh so that a previous whole is replaced - and not on one that is
merely APPENDED TO. Restart is the only event that can version an append-only document, and it is
handled the same way in both Commandments: the standing unsuffixed file moves to docs/archive/ under
a _vN name in the same change, and a fresh unsuffixed file begins.

Version 22, by the owner's instruction of 2026-08-11, UNVERSIONS THE BUILD LOG. The Nineteenth
Commandment's document is renamed from BUILDING_KONNECTOME_v2.txt to building_konnectome.txt, and the
parenthetical that declared it "a versioned document under the Eleventh Commandment" is replaced.
NO COMMANDMENT WAS ADDED, REMOVED, OR RENUMBERED; the count stands at twenty-two.

A RULE CHANGED, and this note says so rather than claiming otherwise, because every other entry in
this history that touched a filename was a REPOINTING that changed no rule and was careful to say so.
This one is different in kind and the difference is worth reading. The owner's observation is that the
build log is not a versioned document at all - it is simply appended to, like a log - AND THE
COMMANDMENT ITSELF ALREADY SAID SO, three lines below the parenthetical now removed: "The log is
append-only and grows with the build". An append-only document is never superseded, so it never has a
superseded version to archive, so the archive discipline it was placed under had nothing to act on.
The Commandment held both claims at once for nineteen versions, and the rename is what it looks like
to resolve the contradiction in favour of the half that describes what the document actually does.

THE EVIDENCE WAS IN THE FILENAME THE WHOLE TIME. The suffix sat at _v2 through fifty-five slices and
never moved, because nothing ever bumped it - which is exactly the signature of a version number on a
document that has no versions. Its one bump was not a supersession but a RESTART, and the two files
that restart produced keep their archived names, because an archived file's name records what it was
called when it was archived.

Version 21, by the owner's instruction of 2026-08-10, adds THE TWENTY-FIRST COMMANDMENT, THE ORDER OF
RESORT, and corrects an over-strict reading that had grown up around versions 19 and 20. The hand-off
protocol is renumbered from the Twenty-First to the Twenty-Second, which is the version 19 standing
rule working exactly as written: a new Commandment is inserted BEFORE it and renumbers it upward in
the same change. Commandments 1 through 20 are unchanged in number.

WHAT WAS OVER-STRICT, AND IT WAS THIS ASSISTANT'S READING RATHER THAN THE OWNER'S TEXT. Version 20
put the owner's word CHEATING into the Sixteenth Commandment beside the limit "not a licence to invent
a value", and the assistant's own explanation of it drew the line in the wrong place - as though
konnectome must never choose a number at all. THE OWNER CORRECTED IT: konnectome will sometimes have
to invent a number to make the system go green and work, and there is absolutely nothing wrong with
that, provided what was done and why it worked is documented.

THE CORRECTION IS SHARPER THAN THE THING IT CORRECTS, AND THE BUILD ALREADY HELD THE EVIDENCE FOR IT.
Its own name for the failure is AN INVENTED VALUE THAT HAS LEARNED TO CITE - and the offence is in the
SECOND HALF. THE SIN WAS NEVER INVENTING. THE SIN IS DISGUISING. A number konnectome chose, standing
openly as a number konnectome chose, is honest engineering; the same number wearing a citation it did
not earn is the fault.

WHAT THE NEW COMMANDMENT SETTLES. It states the ORDER: logic and reason, then the neuroscience library
and the principles library, then derivation, then refusal - and only then DECLARED INVENTION, as the
protocol of LAST resort, with what was tried, why it was chosen, why it worked, and its konnectome
authorship on its face in the code.

TWO ARGUMENTS FROM THE OWNER ARE CARRIED INTO IT VERBATIM IN SUBSTANCE. EDISON TESTED THOUSANDS OF
FILAMENTS, each one a number plugged into an equation nobody could yet solve from first principles -
and that search was not a lapse in method, it WAS the method where theory had run out. AND THE
PERIODIC TABLE'S BUILDERS, meeting a hole, wrote down that SOMETHING MUST GO HERE and described what
it would have to be like; those declared holes were later filled by real elements, and the declaration
is what made that possible. konnectome is modelling a mind from a corpus that does not state every
quantity such a thing needs, so A VALUE IT MUST CHOOSE MARKS A HOLE IN THE SCIENCE AS MUCH AS A HOLE
IN THE BUILD, and recorded properly it is a candidate contribution back to the science of the mind.
The Ninth Commandment already says exactly this about kludges - "not an embarrassment to hide but a
candidate discovery to publish" - and this Commandment says it of a number.

THE FOURTH COMMANDMENT GAINS A CLARIFYING NOTE FOR THE SAME REASON AND CHANGES NO RULE. "Findings are
discovered by building, never guessed from the armchair" had been read as forbidding empirical
determination. NOTE WHERE EDISON WAS: AT THE BENCH, NOT IN THE ARMCHAIR. An armchair guess is a value
asserted without trial and without record; a bench determination is a value found by trying, kept
because it worked, and written down with its evidence. The Commandment forbids the first and describes
the second.

AND THE SIXTEENTH COMMANDMENT'S LIMIT IS REPHRASED TO MATCH, pointing at the new Commandment: fix what
is wrong, and where you must fill in what is unknown, SIGN YOUR NAME TO IT.

Version 20, by the owner's instruction of 2026-08-10, CLARIFIES ONE LIMIT INSIDE THE SIXTEENTH
COMMANDMENT and changes nothing else. NO COMMANDMENT WAS ADDED, REMOVED OR RENUMBERED, AND NO RULE
CHANGED - the limit is the same limit, said better.

WHAT CHANGED AND WHY. The limit read "IT IS NOT A LICENCE TO INVENT A VALUE", which is accurate and
abstract. The owner supplied the concrete word for it: CHEATING. That word is now in the Commandment,
attributed, because it does in one syllable what the previous phrasing needed a paragraph for - it
tells a reader not merely what the rule forbids but WHY IT FEELS LIKE THE RIGHT THING TO DO AT THE
TIME, which is the part a rule against it has to defeat.

The clarification also states the REPAIR-VERSUS-DECISION line explicitly, since that is the actual
test a session applies, and it names why this limit belongs to THIS Commandment rather than being a
general piety: this Commandment removes the pause in which an assistant would have stopped and asked,
and that pause was catching two different things - what it should not do alone, and what it did not
know. Removing it is right for the first and dangerous for the second.

AND THIS AMENDMENT IS ITSELF THE SIXTEENTH COMMANDMENT'S FIRST EXERCISE, which is worth noting because
it demonstrates the shape rather than describing it. The owner invited a clarification; the assistant
made it without a second round of approval, under the authority granted; and the record of what was
done and why went into the build log, which is the single condition the grant carries.

Version 19, by the owner's instruction of 2026-08-10, does three things. IT ADDS THE SIXTEENTH
COMMANDMENT, AUTO-FIX-ALL, granting the assistant the authority to repair any problem it finds on the
single condition that the repair is recorded in the build log. IT MOVES THE HAND-OFF PROTOCOL TO THE
END, where it is renumbered from the Nineteenth to the Twenty-First, with a standing rule that it
remains last and that a new Commandment is inserted BEFORE it. And it therefore RENUMBERS THREE
COMMANDMENTS displaced by the insertion. NO COMMANDMENT WAS REMOVED AND NO RULE CHANGED.

THIS IS THE FIRST AMENDMENT SINCE VERSION 5 TO RENUMBER ANYTHING, and every version note between
those two has proudly said so. The reason it is safe now is the owner's own: OLD HAND-OFFS DO NOT
MATTER, ONLY THE CURRENT HAND-OFF MATTERS. The property those notes were protecting - that a
commandment number cited from an archived hand-off still lands on the right rule - was protecting a
reading nobody performs. The current hand-off is the only one read as instruction, and it is rewritten
every session.

THE MAP, FOR THE ONE HAND-OFF THAT MATTERS AND FOR ANY LIVE DOCUMENT STILL CARRYING AN OLD NUMBER:

    OLD 16, Branch and report discipline  ->  NEW 17
    OLD 17, The tutorial                  ->  NEW 18
    OLD 18, The build log                 ->  NEW 19
    OLD 19, The hand-off protocol         ->  NEW 21   (moved to last)
    OLD 20, The north star                ->  NEW 20   (unchanged)
    Commandments 1 through 15 are unchanged.

WHY AUTO-FIX-ALL WAS PLACED AT SIXTEEN RATHER THAN APPENDED. It is a broad grant of authority to
change things, and the Fifteenth Commandment is the one inviolable limit on what may be changed.
Placing the grant immediately after the limit means the two are read in one breath and the grant
cannot be quoted without it. Appending it at the end would have separated a power from its
constraint by six Commandments, which is exactly how a power gets misread.

WHY THE HAND-OFF PROTOCOL BELONGS LAST, STATED AS A RULE AND NOT A PREFERENCE. It is the protocol a
session runs when its context window is full - which is precisely the moment it can no longer be
trusted to read carefully, to search patiently, or to hold the middle of a long document. Every other
Commandment is read while there is room to read. This one is read when there is not, so it should be
found by going to the end rather than by hunting. A session adding a twenty-second Commandment inserts
it before this one and renumbers this one upward in the same change.

AND ONE CADENCE IS RELAXED BY THE SAME INSTRUCTION, recorded here because a future session would
otherwise reinstate it from an old hand-off. COUSIN CONFORMANCE NEED NOT BE RE-MEASURED ON A SHORT
CYCLE. Earlier hand-offs set a trigger of three or four sessions and the figure is now four sessions
old; the owner has relaxed it to longer stretches. The Fifteenth Commandment is untouched by this: a
conformance suite that is RUN must still be green, and a red gate is still a finding to report. What
changed is how often it is run, not what a run means.

Version 18, by the
owner's instruction of 2026-08-10, does two things: it adds THE TWENTIETH COMMANDMENT, declaring the
two NEUROSCIENCE OF COGNITION documents the north star and mandating their analysis run and gap
analysis; and it carries out A FULL POINTER AUDIT of this document, the first one run as an audit
rather than as a consequence of moving files. NO COMMANDMENT WAS REMOVED, NO COMMANDMENT WAS
RENUMBERED, AND NO RULE CHANGED.
WHAT THE POINTER AUDIT DID. Every file path in this Constitution was extracted and resolved against
the file-system. Six live pointers were wrong and are fixed, each with its own note at the site: the
SEVENTH Commandment's list of seven DSPARCD paths, six of which were dead absolute paths sitting
where a reader looks for a live one; the TENTH Commandment's ledger, named as a bare filename that
resolved from nowhere; the SEVENTEENTH Commandment's tutorial maintenance instruction, naming a
version archived fifty slices ago; the NINETEENTH Commandment's bare README.txt; the EIGHTH
Commandment's file count for the north-star directory; and the stale version number inside the
Seventh's own LOCATED note.
AND THE AUDIT FOUND ITS OWN LESSON, WHICH IS WORTH MORE THAN THE SIX FIXES. EVERY ONE OF THE SIX WAS
A PLACE WHERE THIS CONSTITUTION HAD WRITTEN DOWN A FACT THAT WAS NEVER PART OF THE RULE IT WAS
STATING. A directory in a naming convention. A version number in a maintenance instruction. A file
count in a location statement. In each case the Commandment's actual claim was durable and the
decoration around it was not, and the decoration is what rotted and what misled. VERSION 17 HAD
ALREADY DISCOVERED THIS AND STATED IT EXACTLY - "WHEN A RECORD REFERS TO A LIVE LIST, THE FIX IS TO
DROP THE PART THAT CAN GO STALE, NOT TO UPDATE IT OR TO FREEZE IT" - and applied it to a single line.
This audit applies it everywhere it reaches. A COMMANDMENT SHOULD STATE THE RULE AND POINT AT THE
DIRECTORY; THE DIRECTORY CAN BE READ, AND A SENTENCE CANNOT BE RE-READ BY ANYTHING BUT A HUMAN.
WHAT WAS DELIBERATELY NOT CHANGED, and each was checked rather than skipped. The version 8, 9, 10,
11, 12, 13, 14, 15, 16 and 17 notes name paths as they stood on the dates those amendments were made;
those are DATED RECORDS OF DATED ACTS and rewriting them would put today's paths inside yesterday's
history. The First Commandment's version 9 note names the predecessor manuscript at its old path in
the past tense and gives its archive location in the same sentence, which is correct as written. The
Seventeenth Commandment's creation line, and the Nineteenth's example hand-off filename, are records
and examples respectively. The Fifteenth Commandment's "one-hundred-nineteen-vector conformance
suite" is a claim about a COUSIN REPOSITORY and was left alone deliberately: causalontology's own
README carries both a 119-vector and a 137-check figure, so the number here is ambiguous in its
SOURCE, and the Fourth Commandment's rule is that findings are DISCOVERED by building rather than
guessed from the armchair. It is recorded as an open question rather than silently corrected.

Version 17, by
the owner's instruction of 2026-08-10, records the move of the FIRST COMMANDMENT'S THREE NAMED
DOCUMENTS into docs/principles/ , and repoints all three. NO COMMANDMENT WAS REMOVED, NO COMMANDMENT
WAS RENUMBERED, NO RULE CHANGED, AND NO DOCUMENT WAS EDITED. Only the directory moved.
WHY A DIRECTORY OF THEIR OWN RATHER THAN ANY EXISTING ONE. They are INHERITED - konnectome did not
write them - which rules out the top level, now reserved for konnectome's own live working documents.
They are LIVE GUIDANCE - this Commandment is a standing instruction to build with their principles in
mind - which rules out docs/archive/ , holding superseded versions, and docs/provenance/ , holding a
closed programme's record that nobody is told to read. And they are NOT NEUROSCIENCE, which rules out
docs/neuroscience/ , whose own README states that its boundary is AUTHORSHIP AND NOT SUBJECT: these
three pass the authorship half and fail the subject half, so putting them there would have made that
directory's name a lie.
THE NAME IS THIS COMMANDMENT'S OWN WORD. It says konnectome is built "with the PRINCIPLES of
Artificial General Intelligence (AGI) and Artificial Super Intelligence (ASI) in mind". Two
alternatives were rejected for stated reasons rather than taste: docs/agi/ would put a bare acronym
where the FOURTEENTH Commandment requires whole words, and docs/vision/ would collide head-on with
"the Vision Document Set", which is this Constitution's term for the NEUROSCIENCE corpus - two
different sets under one word being exactly the naming collision the mode-register read spent a page
resolving.
ONE PATH IN THE VERSION 9 NOTE ABOVE WAS SHORTENED RATHER THAN REPOINTED, and the distinction is
deliberate. That note records a CHECK performed on 2026-08-09 and said the successor "follows the
same docs/AGI_FOR_EVERYONE_OUTLINE.txt named on the line above". Repointing it would have put a
2026-08-10 path inside a 2026-08-09 record; leaving it would have made it disagree with the very line
it points at. It now names the file WITHOUT a directory, which is true whatever directory holds it
and lets "the line above" resolve to whatever the live list says. WHEN A RECORD REFERS TO A LIVE LIST,
THE FIX IS TO DROP THE PART THAT CAN GO STALE, NOT TO UPDATE IT OR TO FREEZE IT.

Version 16, by
the owner's instruction of 2026-08-10, records the move of the FIVE INHERITED PROVENANCE DOCUMENTS
into docs/provenance/ - the record of the ten-wave programme that PRECEDED konnectome and produced
the foundation it was built on. NO COMMANDMENT WAS REMOVED, NO COMMANDMENT WAS RENUMBERED, NO RULE
CHANGED, AND NO INHERITED DOCUMENT WAS EDITED. The Fourth Commandment gains a LOCATED note, because
it names PrologAI_Requirements_Ledger_v1.txt as the MODEL konnectome's own ledger was built on and
had only ever named it as a bare filename - a reference that resolved by convention rather than by
path, and had quietly stopped resolving in /docs/ .
NOTE THE CLASS OF DOCUMENT THIS DIRECTORY HOLDS, because it is a third kind beside the two the
Eleventh Commandment already distinguishes. It is not a superseded VERSION, so it does not belong in
docs/archive/ - none of the five has a successor that replaced it. It is not a live working document
either. IT IS INHERITED RECORD: written by a programme that closed, describing work konnectome did
not do, kept because konnectome stands on its result. The test of version 14 applies and gives the
answer directly - nothing instructs a session to read these, and nothing should, until somebody needs
to know WHY the foundation is shaped as it is.

Version 15, by
the owner's instruction of 2026-08-10, records the move of THE DSPARCD FILESET and the method
specification DSPARCD_EXPLAINED.txt into docs/DSPARCD/ . TWO LIVE POINTERS ARE REPOINTED - the Fifth
Commandment's, at the method specification, and the Nineteenth's reading reminder, at the fileset -
and the Seventh gains a LOCATED note stating where the fileset lives, because it named the files
without ever naming their directory. NO COMMANDMENT WAS REMOVED, NO COMMANDMENT WAS RENUMBERED, NO
RULE CHANGED, AND NO PHASE FILE WAS EDITED. Only the directory moved.
NOTE WHAT WAS DELIBERATELY NOT REWRITTEN, because it is the same distinction version 14 drew between
a record and an instruction: the Seventh Commandment's list of seven _v1 paths says the files "will
be created and named", which is a record of the naming convention at creation, and every one of those
_v1 files is correctly in docs/archive/ today. Rewriting them would have turned a creation record
into a false present-tense claim. The LOCATED note carries the live location instead.

Version 14, by
the owner's instruction of 2026-08-10, adds one clarifying paragraph to the Eleventh Commandment
stating that it governs VERSIONS and not SERIES, and that Context Hand-Off documents are therefore
not archived under it. NO COMMANDMENT WAS REMOVED, NO COMMANDMENT WAS RENUMBERED, AND NO RULE
CHANGED - nothing moves, nothing is renamed, and no existing behaviour is different. IT CLOSES A
READING RATHER THAN A GAP: as originally worded this Commandment could reasonably be read as covering
hand-offs, so a later session tidying them into /archive/ would have been FOLLOWING the Constitution
rather than breaking it, and would have buried a series that is required reading among hundreds of
superseded drafts that are not. IT ALSO CORRECTS A LOOSE SENTENCE IN VERSION 13's OWN REASONING,
which said the two-location rule makes hand-offs follow this Commandment's house rule; they follow
its SHAPE - only the current one lives outside its directory - and not its DESTINATION, and version
13's argument was right about the first and imprecise about the second.

Version 13, by
the owner's instruction of 2026-08-10, gives the Hand-Off Protocol a TWO-LOCATION rule: the CURRENT
hand-off lives in /docs/ and every SUPERSEDED one lives in /docs/hand-off/ , so exactly one Context
Hand-Off document sits in /docs/ at any moment and it is always the one to read. Step 2 becomes Steps
2a and 2b - SWEEP, THEN WRITE - and Step 4 requires both in one commit. NO COMMANDMENT WAS REMOVED,
NO COMMANDMENT WAS RENUMBERED, no naming convention changed, and no hand-off was edited. This
supersedes the location half of version 12 while keeping its directory; version 12's own reasoning -
that Step 2 is an instruction to CREATE a file and so a stale path there fails silently rather than
loudly - is what this amendment extends, by making the whole step self-healing rather than merely
correct.

Version 12, by
the owner's instruction of 2026-08-10, records the move of the twenty-nine Context Hand-Off documents
into docs/hand-off/ and repoints the Nineteenth Commandment's Hand-Off Protocol at the new path. NO
COMMANDMENT WAS REMOVED, NO COMMANDMENT WAS RENUMBERED, NO RULE CHANGED, AND NO HAND-OFF WAS EDITED
except the newest, which is the live entry point rather than only a record. Only the directory moved.
NOTE WHY THIS ONE POINTER MATTERED MORE THAN THE OTHERS REPOINTED TODAY: Step 2 of the protocol is
not a reference to a file, it is an INSTRUCTION TO CREATE ONE, so a stale path there does not fail
loudly - it succeeds, in the wrong directory, every time, forever.

Version 11, by
the owner's instruction of 2026-08-10, repoints the Eighth Commandment's named analysis from _v1 to
_v3, the version current on that date. NO COMMANDMENT WAS REMOVED, NO COMMANDMENT WAS RENUMBERED,
AND NO RULE CHANGED - only the version in a path. It is recorded as its own version rather than
folded into version 10 because the two changes are different acts on different days' work: version
10 moved files, version 11 follows a document that was rewritten.

Version 10, by
the owner's instruction of 2026-08-10, records the move of every SOURCE neuroscience document into
docs/neuroscience/ : the thirty-eight-document Vision Document Set of the Eighth Commandment, and the
guiding book named by the Seventh and Tenth Commandments. THREE COMMANDMENTS CARRIED A PATH TO A
MOVED FILE AND ALL THREE ARE CORRECTED HERE - the Seventh, the Tenth, and the Nineteenth's hand-off
protocol - together with the Eighth, which now states where the set lives. NO COMMANDMENT WAS
REMOVED, NO COMMANDMENT WAS RENUMBERED, NO RULE CHANGED, AND NO SOURCE DOCUMENT WAS EDITED. Only
paths moved. This amendment exists because of the rule version 9 wrote down and this change is the
first real test of it: A POINTER IS NOT A STATEMENT, SO A FILE THAT MOVES MUST HAVE EVERY POINTER TO
IT MOVED IN THE SAME CHANGE. A session citing a commandment by number from an older hand-off will
still land on the right one; a session following a PATH from a hand-off written before 2026-08-10
will not, and the ledger's DOCS REORGANISATION note says so and says where to look instead.

Version 9, by the
owner's instruction of 2026-08-09, adopts AGI_FOR_EVERYONE_MANUSCRIPT_v2.txt as the third document
of the First Commandment, in place of its predecessor, which is archived rather than deleted. NO
COMMANDMENT WAS REMOVED, NO COMMANDMENT WAS RENUMBERED, and no rule changed: only the third of the
First Commandment's three named documents was re-pointed at its own successor, after that successor
was checked to contain the predecessor. A session citing a commandment by number from an older
hand-off will still land on the right one.

Version 8, by the
owner's instruction of 2026-08-09, adopts DSPARCD in place of SPARCD: the Fifth Commandment is
re-pointed at docs/DSPARCD_EXPLAINED.txt and names the seventh phase, the Seventh Commandment gains
konnectome_0_definition at the front and renames the fileset to "The DSPARCD Fileset", and the
Twelfth and Nineteenth Commandments follow the rename. NO COMMANDMENT WAS REMOVED, NO COMMANDMENT WAS
RENUMBERED, and the six existing phases are unchanged - DSPARCD adds at the front and takes nothing
away. A session citing a commandment by number from an older hand-off will therefore still land on
the right one.


END OF VERSION HISTORY.
