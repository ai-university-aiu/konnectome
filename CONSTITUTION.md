THE FIRST COMMANDMENT:
The konnectome GitHub repository, hereinafter known as "konnectome",
will be built and maintained with the principles of Artificial General Intelligence (AGI)
and Artificial Super Intelligence (ASI) in mind,
as specified in the following three (3) documents:
/home/ccaitwo/konnectome/docs/THE_ROADMAP_TO_AGI_AND_ASI_MANUSCRIPT.txt
/home/ccaitwo/konnectome/docs/AGI_FOR_EVERYONE_OUTLINE.txt
/home/ccaitwo/konnectome/docs/AGI_FOR_EVERYONE_MANUSCRIPT.txt

THE SECOND COMMANDMENT:
causalontology will be the data structure for the "thoughts", "thought patterns", "thought process", "thought processes", "trees of thought", "chains of thought" of konnectome,
which is specified in a cousin repository,
created and owned by the parent organization ai-university-aiu:
On the web at:
https://github.com/ai-university-aiu/causalontology
Locally at:
/home/ccaitwo/causalontology/
causalontology is a living structure, and can accept changes, as needed, from konnectome,
to help build out konnectome to its fullest capability.
BUT causalontology is FROZEN to konnectome except through the gated change-order process:
konnectome does NOT edit causalontology directly. When a real konnectome build hits a wall the
data structure cannot express, that finding is recorded (see the Fourth Commandment) and, only if
it passes the consumer-versus-ontology test (the thing must need to be SHARED across agents or
repositories as a signed, evidence-graded, content-addressed record, not merely computed inside one
konnectome runtime), it is written to the versioned change-order file:
/home/ccaitwo/konnectome/docs/Causalontology_4_0_0_CHANGE_ORDER_v2.txt (An existing file.)
and gathered until the end of the build-out and test-out to form one complete, coordinated 4.0.0
package to be sent to update causalontology. Findings are DISCOVERED by building, never guessed from
the armchair.

THE THIRD COMMANDMENT:
PrologAI will be the programming language for konnectome,
which is specified in a cousin repository,
created and owned by the parent organization ai-university-aiu:
On the web at:
https://github.com/ai-university-aiu/PrologAI
Locally at:
/home/ccaitwo/PrologAI/
PrologAI is a living programming language, and can accept changes, as needed, from konnectome,
to help build out konnectome to its fullest capability.
The same gate applies as for causalontology: konnectome does NOT edit PrologAI directly. A
language wall discovered while building is recorded, and a real, load-bearing PrologAI-language gap
is written to the versioned change-order file:
/home/ccaitwo/konnectome/docs/PrologAI_CHANGE_ORDER_v1.txt (A new file; create it empty with a
one-line header at build start, so it exists to receive findings.)
A gap that belongs to the DATA STRUCTURE, not the language, goes to the causalontology change order
of the Second Commandment instead; a gap that konnectome can solve inside its own code goes to the
konnectome ledger of the Fourth Commandment. Route each finding to exactly one place.

THE FOURTH COMMANDMENT:
Change orders and considerations for change orders to
1. causalontology, or 2. PrologAI, or 3. konnectome itself
will be written to the new file:
/home/ccaitwo/konnectome/docs/konnectome_ledger_v1.txt (A new file; create it at build start.)
This ledger is the running scoreboard of the build, exactly as PrologAI_Requirements_Ledger_v1.txt
was for the language. Every wall the build hits becomes an entry here first; from here it is routed
to the causalontology change order, the PrologAI change order, or a konnectome construct. A wall
shown to be UNNECESSARY is recorded as honestly as a wall that needed building: honest non-closure
is a real result, not a failure.

THE FIFTH COMMANDMENT:
The six (6) step waterfall workflow documents are inspired by the specification file:
/home/ccaitwo/konnectome/docs/SPARCD_EXPLAINED.txt

THE SIXTH COMMANDMENT:
Pseudocode will be inspired and influenced by English Readable Code (ERC) as defined in the specification file:
/home/ccaitwo/konnectome/docs/ENGLISH_READABLE_CODE_MANUSCRIPT.txt
Concretely: every line of code in every source file carries one plain-English comment immediately
above it, per the ERC rule.

THE SEVENTH COMMANDMENT:
The Specification, Pseudocode, Architecture, Refinement, Completion, and Demonstration waterfall steps and files
will be sourced from the Appendices of the file:
/home/ccaitwo/konnectome/docs/NATURES_COGNITIVE_ARCHITECTURE_MANUSCRIPT.txt
The versioned files will be created and named:
/home/ccaitwo/konnectome/docs/konnectome_1_specification_v1.txt
/home/ccaitwo/konnectome/docs/konnectome_2_pseudocode_v1.txt
/home/ccaitwo/konnectome/docs/konnectome_3_architecture_v1.txt
/home/ccaitwo/konnectome/docs/konnectome_4_refinement_v1.txt
/home/ccaitwo/konnectome/docs/konnectome_5_completion_v1.txt
/home/ccaitwo/konnectome/docs/konnectome_6_demonstration_v1.txt
Each file will start its contents from one entire, similarly numbered appendix from the file
/home/ccaitwo/konnectome/docs/NATURES_COGNITIVE_ARCHITECTURE_MANUSCRIPT.txt
These six (6) files will be known as "The SPARCD Fileset".

THE EIGHTH COMMANDMENT: THE AUDIT:
As part of the konnectome build-out,
make sure every named construct (including the previously unnamed constructs (PUC))
is represented by a code module in konnectome,
and that those code modules serve the same functions and faculties in konnectome as they are described in,
and with the same inputs/outputs (SUBSCRIBE/PUBLISH) interfaces as described in,
NATURES_COGNITIVE_ARCHITECTURE_MANUSCRIPT.txt
The audit is not one-and-done: keep a coverage list in konnectome_ledger_v1.txt that names, for each
construct in the manuscript, the module that realizes it, so the audit can be re-run at any time and
a missing construct is visible at a glance.

THE NINTH COMMANDMENT:
A directory /home/ccaitwo/konnectome/docs/archive/ shall be created.
And when new versions of files are written,
the older, superseded files will be moved to the /archive/ folder for storage (using git mv, in the
same change), so that only the latest version of any versioned document lives outside /archive/.

THE TENTH COMMANDMENT:
Any and all code changes to konnectome will be accompanied by
mirrored changes to "The SPARCD Fileset",
with version numbers incremented,
and older versions archived per the Ninth Commandment.

THE ELEVENTH COMMANDMENT:
/home/ccaitwo/konnectome/README.md
will be kept up to date as konnectome develops and evolves.
README.md will look much the same in style, look, and feel as the README.md files for:
https://github.com/ai-university-aiu/causalontology
/home/ccaitwo/causalontology/README.md
https://github.com/ai-university-aiu/PrologAI
/home/ccaitwo/PrologAI/README.md
https://github.com/ai-university-aiu/Mentova
/home/ccaitwo/Mentova/README.md
(Which are based on the most popular README.md files in all of GitHub - Feel free to double check.)
And will use the color scheme of the file at,
/home/ccaitwo/konnectome/docs/CRIMSON_TO_GOLD_PALETTE.png
Namely the colors,
BACKGROUND: #3a0000, #590000, #7c0300, #c02b18,
FOREGROUND: #e04217, #f26d1f, #ff933a, #ffce59 .
(Initially, put a placeholder banner image, and the USER will replace it later.)

THE TWELFTH COMMANDMENT:
ai-university-aiu and konnectome are a "Whole-Word System",
for clarity, readability, and understandability,
not an abbreviation system or single-letter system.
For examples:
A previous system that used labels "L1 to L9" would use "Loop-1 to Loop-9".
A previous system that used series "N1 to N15" would use "Native-1 to Native-15".
A previous system that used ledger-series "P1 to P10" would use "Proto-1 to Proto-10".
This applies to code as well as prose: pack, module, and predicate names are whole English words,
snake_case, pack-qualified, with no terse prefixes (no wm_, gd_, ai_, and so on) - the same rule
PrologAI itself enforces. External standard names (JSON, BCP 47, SWI-Prolog, Ed25519) keep their
real names.

THE THIRTEENTH COMMANDMENT: THE SAFETY GATE:
(NEW in version 2, promoted from a parenthetical in version 1's Step 8 to a first-class rule,
because it protects a proven asset.)
PrologAI has already passed ARC-AGI-1 (400 of 400) and ARC-AGI-2 (120 of 120) regression through
Mentova. konnectome MUST NOT break that. Any change routed to the PrologAI change order is ADDITIVE
and is gated by that regression: if a proposed PrologAI change would regress ARC-AGI-1 or ARC-AGI-2,
it STOPS and is reported, not merged. The same spirit applies to causalontology's one-hundred-
nineteen-vector conformance suite: a proposed data-structure change must keep it green. A red gate is
a finding to report, never a thing to force through.

THE FOURTEENTH COMMANDMENT: BRANCH AND REPORT DISCIPLINE:
(NEW in version 2.) Work on a feature/ branch and open a pull request; do not push directly to main.
No Artificial-Intelligence tool is credited as author or co-author anywhere. No Roman numerals in
any document or identifier. These match the house rules of the cousin repositories, so konnectome
reads as one of the family.
 ...
THE FIFTEENTH COMMANDMENT: THE TUTORIAL:
Add the following to /docs/:
konnectome_tutorial_v1.txt
Once this file is created,
write to the file a complete head to toe, top to bottom tutorial on konnectome.
Describing and explaining every concept relating to konnectome.
Make the tutorial able to be read and understood by a beginner, learner, layperson, newcomer, novice.
Maintain versioned updates to /docs/konnectome_tutorial_v1.txt as any new code changes are applied.
(The tutorial is versioned under the same archive discipline as the Ninth Commandment: when a code
change bumps it, the superseded version moves to docs/archive/ in the same change, so only the latest
tutorial lives outside the archive, and it always describes the konnectome that exists.)
 ...
THE SIXTEENTH COMMANDMENT: CONTEXT-WINDOW MANAGEMENT AND THE HAND-OFF PROTOCOL:
A long session degrades (context rot, and the lost-in-the-middle effect), and the assistant cannot see
the context window's fill level from its own side, so the trigger must never rely on the assistant
watching a token count. Two triggers govern the hand-off. First, the MILESTONE trigger: after each
merged slice or unit of work, the assistant proactively offers to write a Context Hand-Off and to
continue in a fresh session. Second, the OWNER trigger: the owner watches the true gauge with the
/context command (and /usage for plan limits), and when the window is high - as a guideline, above one
hundred thousand tokens, or above roughly sixty percent of the window - the owner asks for a hand-off.
On either trigger, the assistant carries out the Hand-Off Protocol below, commits the result on a
feature/ branch through a pull request (Fourteenth Commandment), and then PAUSES. A fresh session then
re-loads state from docs/ - the ledger, the SPARCD Fileset, the tutorial, and the latest hand-off - and
continues from the known-good baseline, because all durable state lives on disk and never only in the
conversation.

THE HAND-OFF PROTOCOL. The assistant performs these steps:

Step 1: Give yourself a fun, creative, original name.
Step 2: Write to file:
~/konnectome/docs/[DATE]_[SERIAL NUMBER]_Context_Hand-Off_from_[NAME].txt
where [DATE] is the current date as year-month-day (for example 2026-07-20);
[SERIAL NUMBER] is the next free number for that date,
starting at 1 (so a second hand-off written on the same day is _2);
and [NAME] is the name chosen in Step 1 - for example,
2026-07-20_1_Context_Hand-Off_from_Ember_Loomwright.txt .
Step 3: To this file write the following information for the next building or maintenance process to read:
- Your chosen name and the date, and a sentence on why the name was chosen.
- A reminder to read and follow CONSTITUTION.md (all commandments).
- A reminder to read The SPARCD Fileset
(docs/konnectome_1_specification through konnectome_6_demonstration, at their current versions).
- A reminder to read docs/NATURES_COGNITIVE_ARCHITECTURE_MANUSCRIPT.txt, the guiding book for konnectome
- A reminder to read the Settings, General, Instructions for Claude (the owner's standing instructions to the assistant).
- A reminder to read ~/CLAUDE.md, which is git-untracked (gitignored) and holds the system-wide current-state narrative (it lives at the organization root, not inside one repository, because it belongs to the whole system).
- A reminder to read the current /docs/konnectome_tutorial (the maintained beginner tutorial), and to read all of the documents in /docs/.
- A list of the important /docs/ files and what each is: the ledger, the SPARCD Fileset, the change orders, the tutorial, the thought-combination guide, the guiding-principle documents, the context documents, and the earlier hand-offs (named by the convention of Step 2).
- A report of what was done in the session that is ending: the slices built, the packs, the tests, the pull requests merged, the current main commit, and the current SPARCD and tutorial versions.
- The build-against cousin commits (causalontology, PrologAI, Mentova), for reproducibility.
- Any other context you, the assistant, judges important for the next process: open observations, honest non-closures, sharp edges, and anything discovered that is not obvious from the code.
- The current first-task menu of options for the continuation to present to the owner, ending with an "Other ______" option.
- A short sign-off.
Step 4: Commit the hand-off on a feature/ branch through a pull request. Auto-Push. Then PAUSE.

END OF CONSTITUTION.
