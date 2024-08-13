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

Errors so far:

- Code tries to use variable shadowing, but this is (now?) a syntax error. I've removed the local declaration, or renamed the block argument, or added a local declaration inside the block.
- Some method-constructing stuff tries to assign to a block argument: `vars _ nil`, but this is (now?) unassignable. Purpose seems to have been to allow things to get garbage collected. I've removed these statements, hope it doesn't pose a problem.
- Encoder class used to understand `init:context:notifying:` but some API change got rid of `context:`. Code was always passing `nil` anyway so I just removed the param.

Current error: Encoder expects `init: aCue` where `aCue` is a `CompilationCue` holding context for compiling Smalltalk code. ThingLab code calls `init: Object notifying: self`, i.e. just passes class `Object` as the cue ... which doesNotUnderstand the various `CompilationCue` methods. What was their original intent? Why did this work on ParcPlace? I'm guessing they just wanted a dummy cue since they're compiling equation transformation rules into syntax trees.
