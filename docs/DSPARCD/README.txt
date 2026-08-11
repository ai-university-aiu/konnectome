DOCS / DSPARCD - THE METHOD AND ITS SEVEN PHASE FILES

Created 2026-08-10. Constitution version 15.


WHAT IS IN HERE

Eight files: THE DSPARCD FILESET, which is seven of them, and the specification of the method itself, which is the eighth.


THE DSPARCD FILESET - THE SEVEN

"The DSPARCD Fileset" is a term the Seventh Commandment defines, and it means exactly these seven files and no others. Each one is a phase of the waterfall, and each is a living document that grows as konnectome is built.

• konnectome_0_definition_v1.txt - DEFINITION. What konnectome IS in one sentence and what it is NOT in eight. READ THIS ONE FIRST. It is deliberately SHORT and must stay short. Where it and a later phase disagree, THE DEFINITION LEADS and the later phase is corrected; only the Constitution outranks it.

• konnectome_1_specification_v54.txt - SPECIFICATION. The problem defined completely before any code is written.

• konnectome_2_pseudocode_v54.txt - PSEUDOCODE, written in English Readable Code.

• konnectome_3_architecture_v54.txt - ARCHITECTURE. Components, interfaces, data model.

• konnectome_4_refinement_v54.txt - REFINEMENT. Test-driven iteration; what the tests found.

• konnectome_5_completion_v54.txt - COMPLETION. The measured state of the build.

• konnectome_6_demonstration_v54.txt - DEMONSTRATION. What can now be shown that could not be shown before.

NOTE THE VERSION NUMBERS AND WHY ONE OF THEM DIFFERS. Six of the seven are at v48 and move together, because the Twelfth Commandment requires that any code change be accompanied by mirrored changes to the whole Fileset with version numbers incremented. THE DEFINITION IS AT v1 AND HAS NEVER BEEN SUPERSEDED, because it states a concept rather than a state, and a concept that needed a new version every slice would not have been a concept.


THE EIGHTH FILE, WHICH IS NOT A MEMBER OF THE FILESET

• DSPARCD_EXPLAINED.txt - the specification of the METHOD, named by the FIFTH Commandment.

It sits here because it specifies the seven phases the other files are, and a reader looking for the method should not have to look in two places. BUT IT IS NOT PART OF "THE DSPARCD FILESET", which the Seventh Commandment defines as exactly seven files. That distinction is kept because the Constitution makes it precise, and a directory listing is not a definition.


WHAT DSPARCD IS, IN ONE PARAGRAPH

DSPARCD is SPARCD with a DEFINITION phase in front of it: Definition, Specification, Pseudocode, Architecture, Refinement, Completion, Demonstration. THE DEFINITION PHASE ANSWERS THE ONE QUESTION EVERY OTHER PHASE ASSUMES HAS BEEN ANSWERED - what is this thing, and what is it NOT. Every requirement, module and slice must trace to the concept in konnectome_0_definition or to a principle in it; anything tracing to neither is out of scope or belongs on its non-goals list.

The superseded SPARCD_EXPLAINED.txt is archived under the Eleventh Commandment at docs/archive/SPARCD_EXPLAINED.txt, not deleted, because the six phases it specifies are unchanged and that history is part of the record.


HOW THESE FILES GROW - AND WHERE THE OLD VERSIONS GO

Every code change is accompanied by mirrored changes to the Fileset with version numbers incremented (the Twelfth Commandment), and the superseded versions are moved to docs/archive/ (the Eleventh).

THE SUPERSEDED VERSIONS DO NOT GO INTO A docs/DSPARCD/archive/ . There is no such directory and there should not be: the Eleventh Commandment names exactly one archive for the whole repository, and a second one would split a rule that is currently in one place.

In practice each phase file carries a KONNECTOME REALIZATION LOG section per slice, appended at its foot, written in that phase's own voice. That is why the files grow rather than being rewritten, and why the version number moves by one each time.


THE FORWARDING NOTE - READ THIS IF YOU ARRIVED HERE FROM AN OLD DOCUMENT

Before 2026-08-10 these eight files lived directly in /docs/ . If you are following a path that begins docs/konnectome_ and names one of the seven phases, or a path naming the method specification, and it does not resolve, the file is here: insert DSPARCD/ after docs/ and the path is correct. No file was renamed, edited or deleted; all eight moves are pure renames.

ONE THING THAT LOOKS LIKE A BROKEN POINTER AND IS NOT. The Seventh Commandment lists the seven files at their _v1 names, because that list says they "will be created and named" and is therefore a record of the naming convention AT CREATION. Six of those seven _v1 files are in docs/archive/ , correctly, and those six lines are left pointing there. The seventh, the Definition, is still at v1 and so its line names a CURRENT file and moved here with it. A LINE THAT NAMES A LIVE FILE IS A POINTER; A LINE THAT NAMES A RETIRED ONE IS A RECORD - and that one list holds both.
