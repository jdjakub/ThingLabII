Original readme:

```
The second release of ThingLab II consists of the following files:

	README			-- this file
	ThingLabII.v2.st	-- Smalltalk code for the basic system
	Things.v2.st		-- Smalltalk code for the Primitive Things
	Demos.v2.st		-- Smalltalk code for a set of Demos (optional)
	ThingLabII.form		-- startup picture (optional)
	ThingManual.text	-- the manual, in plain text form
	ThingManual.word3.02	-- the manual, in Word 3.02 form

Please see the manual for installation directions. You'll need ParcPlace
Smalltalk-80 version 2.3 for the system to run correctly.  (There are no
plans to port it to a more recent version of Smalltalk.)

When FTP-ing these files, use ASCII mode for all files except ThingLabII.form
and ThingManual.word3.02, which should be transfered in BINARY mode.

========================================

In addition to the files listed above, the file SIGGRAPH_Demo.tar.Z is a
compressed tar file containing a ThingLab II demo prepared for a SIGGRAPH
tutorial by Bjorn Freeman-Benson.  It runs on the Macintosh under System 6.x.
SIGGRAPH-Demo.st.Z is the corresponding source file (which runs only under
ParcPlace release 2.3).

```

# This fork

I'm a recent (zealous) convert to Squeak after visiting HPI, so I'm not too knowledgable yet. I've been following [Lawson English's youtube tutorials](https://www.youtube.com/watch?v=Es7RyllOS-M&list=PL6601A198DF14788D) and the [Squeak By Example 6.0](https://squeak.org/#documentation) ebook.

Instructions:
- Squeak 6.0
- Projects > Create MVC Project
- Click on it to enter it
- Left click world menu > Open > File list
- Navigate to ThingLabII.v2.st
- Right click > fileIn entire file
- Currently fixing the errors as they come and committing back to ThingLabII.v2.st
- Navigate to ST80-extras.st, fileIn
- Now you can `ThingLabIIControlPanel open.`
- Manually apply the patches in `parser-newer.st` (sorry)
- Now you can fileIn Things.v2.st, proceed past constraint errors
- Now you can `PartsBinView openOn: (PartsBin topBin).`
- Currently fixing UI related errors

Errors so far:

- Code tries to use variable shadowing, but this is (now?) a syntax error. I've removed the local declaration, or renamed the block argument, or added a local declaration inside the block.
- Some method-constructing stuff tries to assign to a block argument: `vars _ nil`, but this is (now?) unassignable. Purpose seems to have been to allow things to get garbage collected. I've removed these statements, hope it doesn't pose a problem.
- Encoder class used to understand `init:context:notifying:` but some API change got rid of `context:`. Code was always passing `nil` anyway so I just removed the param.
- Equations use the Smalltalk compiler classes to obtain a syntax tree. Encoder expects `init: aCue` where `aCue` is a `CompilationCue` holding context for compiling Smalltalk code. ThingLab code calls `init: Object notifying: self`, i.e. just passes class `Object` as the cue ... which doesNotUnderstand the various `CompilationCue` methods. I'm guessing they just wanted a dummy cue, so now I create one, with a dummy environment to handle "undeclared" messages.
- Squeak Blocks now send a supportsFullBlocks message, this has been added to EquationEncoder.
- ThingLab defines its own `CustomMenu` class, or perhaps tries to redefine/extend one in its 1989 environment. Squeak already has a `CustomMenu` class with more / different stuff, which clashes and causes critical menu failures which prevents debugging. Renamed this to `ThingLabCustomMenu`.
- ThingLab defines its own `drawFrom:to:`/`privateDrawFrom:to:` in `BitBlt`, which seems to work OK in an MVC project but utterly breaks the parent Morphic project. Renamed to `thingLabDrawFrom`, etc.
- Parse tree stuff in ThingLab tests for `isMemberOf: VariableNode`, but debugging reveals that all the intended instances seem to be `LiteralVariableNode`, a subclass presumably added in Squeak. The main call site required for constraint formula compilation has been changed to use `isKindOf` instead, but the other usages should probably also be updated.
- Random API changes: ThingLab wants methods `black:` and `black` on `DisplayMedium`, which have been polyfilled. Similarly, code calls `unitVector` on `Point` which has also been polyfilled.
- Many differences in Form/Font/graphics etc methods between 1989 and 2024. Fonts/styles now need copying before modification. In the old days of the monochrome display, there was no need for a `Color` class, or even anything called "color", so drawing methods took a `mask:` param and methods `black`, `white`, `gray`, etc. lived in `Form`. Seems to be a reliable rule that `mask:` -> `fillColor:` and `Form <colorName>` -> `Color <colorName>`.
- Squeak lacks ST80 MVC classes like `SwitchView`, `IconView` etc. as can be attested in old manuals in google search results ([ref1](http://stephane.ducasse.free.fr/FreeBooks/InsideST/InsideSmalltalkII.pdf), [ref2](https://www.lri.fr/~mbl/ENS/FONDIHM/2013/papers/Krasner-JOOP88.pdf)). Thanks to [Rochus Keller's work](https://github.com/rochus-keller/Smalltalk), I obtained the `Smalltalk-80.sources` and ported SwitchView/Controller to colour-screen MVC (ST80-extras.st)
- ThingLab refers to a `Cursor hand` but it's not present even in the ST80 sources. Using `Cursor webLink` instead. API change `Sensor mousePoint` -> `Sensor cursorPoint`, fingers crossed this means the same thing.

Current error: the very last line of the original ThingLabII.v2.st calls `initializeYellowButtonMenu` on all instances of ScreenController, but one or more doesNotUnderstand. Next round of errors seem to be about interfacing with ST80 MVC stuff as it exists in Squeak 6.0. Hurrah.

For now, we can ignore the UI errors and attempt to fileIn the Things library in the workspace:

```smalltalk
(FileStream fileNamed: 'Things.v2.st') fileIn
```

Current errors are first "failed to resolve constraints" (ignore) and then related to graphics API changes.

NB: Fixing these errors has been a *delight* compared to every other programming system I've ever used, because it's a live homogenous system, I can edit the code in the debugger and restart from that stack frame, inspect/browse anything and it was all pretty intuitive for me to figure out ... hence why I have the zeal of a new convert. The future has been here for 44 years, obscured by history, bad business decisions and Worse Is Better...