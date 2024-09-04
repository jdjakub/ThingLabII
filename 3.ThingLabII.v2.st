"ThingLabII System of (20 May 1990 3:31:38 pm )"!

"Copyright (c) 1989 and 1990, Regents of the University of Washington.
Permission is granted to use or reproduce this program for research
and development purposes only. For information regarding the use of this
program in a commercial product, contact:

	Office of Technology Transfer
	University of Washington
	4225 Roosevelt Way NE, Suite 301
	Seattle, WA  98105

ThingLab II was written between 1988 and 1990 by John Maloney and
Bjorn N. Freeman-Benson with the guidance of Alan Borning."!

"---"!

!Form class methodsFor: 'ThingLab compatibility'!
extent: extentPoint fromArray: anArray offset: offsetPoint
	"Answer an instance of me of depth 1 with bitmap initialized from anArray."
	
	| array |
	array := anArray.
	"For some reason, in 2024, intialising a 1-bit 16x16 Form requires 32-bit values to work properly.
	It's like there's a minimum 32x32 size for 1-bit Forms, idk.
	SEE ALSO: Comment in Cursor>>extent:fromArray:offset:, which already does this so must be detected..."
	self ~= Cursor and: [extentPoint x = 16 ifTrue: [
		array := anArray collect: [:v | v << 16]]].
	^ (self extent: extentPoint depth: 1)
		offset: offsetPoint;
		initFromArray: array! !

"---"!

!Number methodsFor: 'ThingLabII'!

asNonZero
	"To avoid divide-by-zero errors, answer a very small number if I am zero."

	^(self = 0)
		ifTrue: [0.0000000001]
		ifFalse: [self]! !

!Symbol methodsFor: 'ThingLabII'!

path
	"Answer an array of the part names that comprise the compound path selector. For example, '#fat.cat.hat path' returns an array of three symbols, #fat, #cat, and #hat."

	| result currentPart |
	result _ OrderedCollection new.
	currentPart _ WriteStream on: (String new: 16).
	self do:
		[: ch |
		 (ch = $.)
			ifTrue:
				[result addLast: currentPart contents asSymbol.
				 currentPart reset]
			ifFalse: [currentPart nextPut: ch]].
	result addLast: currentPart contents asSymbol.
	^result asArray! !

!BitBlt methodsFor: 'ThingLabII'!

thingLabDrawFrom: p1 to: p2
	"This line drawing method was improved by John Maloney to do more intelligent clipping. If the line (p1,p2) is entirely INSIDE the clipping box, this method gives results that are identical to the original line drawing method. If the line is entirely OUTSIDE the clipping box, it detects this early and avoids the cost of drawing it. Finally, if the line is PARTIALLY inside the clipping box, the portion entirely inside the clipping box computed and can be drawn by the primitive. If the pen form is large, you may notice a slight difference from the results given by the normal drawFrom:to: method on the right/bottom of the clipping box."

	| offset startPoint endPoint clipOrigin clipCorner clippedLine |
	width _ sourceForm width.
	height _ sourceForm height.
	offset _ sourceForm offset.

	"always draw down, or at least left-to-right"
	((p1 y = p2 y and: [p1 x < p2 x])
		or: [p1 y < p2 y])
			ifTrue: [startPoint _ p1 + offset. endPoint _ p2 + offset]
			ifFalse: [startPoint _ p2 + offset. endPoint _ p1 + offset].

	"The clipping rectangle specified by the sender is intersected with the destination form. Then the corner of the result is inset by the extent of the pen form. This clipping rectangle is used to compute 'clippedLine'. clipped line is a triple <visibleFlag, startPoint, endPoint>. If visibleFlag is false, no part of the line is visible in the clipping box. If visibleFlag is true, clippedLine can be drawn with the primitive, which is fast."
	clipOrigin _ (clipX@clipY) max: (0@0).
	clipCorner _ (clipWidth@clipHeight) min: (destForm extent).
	clippedLine _
		(ClippingRectangle
			origin: clipOrigin
			corner: clipCorner - (width@height))
				clipFrom: startPoint to: endPoint.

	(clippedLine first)
		ifTrue:
			["draw the visible part of the line"
			 self privateThingLabDrawFrom: (clippedLine at: 2) to: (clippedLine at: 3)]
		ifFalse:
			["the line is entirely outside the clipping region"].!

privateThingLabDrawFrom: p1 to: p2
	"Added by John Maloney for faster line drawing."

	destX _ p1 x rounded.
	destY _ p1 y rounded.
	self drawLoopX: ((p2 x - p1 x) rounded) Y: ((p2 y - p1 y) rounded)! !

!Object methodsFor: 'ThingLabII'!

destroy
	"'Destroy' is ThingLabII-ese for 'release'."

	self release.!

filterOwners: aCollection
	"Filter the 'allOwners' method and the collection used to collect all owners out of the given collection."

	| filtered allOwnersMethod |
	filtered _ aCollection copy.
	allOwnersMethod _ aCollection
		detect:
			[: e |
			 (e isMemberOf: MethodContext) and:
			 [((e receiver class) 
				selectorAtMethod: e method
				setClass: [: mc | "ignore"]) == #allOwners]]
		ifNone: [^self].
	filtered remove: allOwnersMethod.
	filtered _ filtered select:
		[: e |
		 ((e isMemberOf: OrderedCollection) and:
		  [e includes: allOwnersMethod]) not].
	^filtered!

includesRoot: aCollection
	"Answer true if the given collection includes the system dictionary 'Smalltalk'."

	aCollection do:
		[: element |
		 (element == Smalltalk) ifTrue: [^true].
		 (element class isMemberOf: Metaclass) ifTrue: [^true].
		 (Smalltalk includesKey: element) ifTrue: [^true]].
	^false!

isThing
	"Answer true if I am a Thing. Normal Smalltalk Objects are not Things."

	^false!

traceOwners
	"Build the transitive closure of the 'owners' relation. That is, starting with me, add my owners, then my owners' owners, then their owners, and so on until no new objects are added or until we encounter the 'Smalltalk' object, the globals dictionary."

	| allOwners allRoots toDo obj owners |
	allOwners _ IdentitySet new: 100.
	allRoots _ OrderedCollection new.
	toDo _ OrderedCollection new.
	toDo add: self.
	[toDo isEmpty] whileFalse:
		[obj _ toDo removeFirst.
		 owners _ nil.
		 Smalltalk primGarbageCollect.
		 owners _ obj allOwners.
		 owners remove: thisContext ifAbsent: [].
		 owners remove: allOwners ifAbsent: [].
		 owners remove: allRoots ifAbsent: [].
		 owners remove: toDo ifAbsent: [].
		 owners remove: obj ifAbsent: [].
		 owners remove: owners ifAbsent: [].
		 owners _ self filterOwners: owners.
		 (self includesRoot: owners)
			ifTrue: [allRoots add: obj]
			ifFalse:
				[owners do:
					[: owner |
					 ((allOwners includes: owner) or:
					  [allRoots includes: owner]) ifFalse:
						[allOwners add: owner.
						 toDo add: owner]]].
		 Transcript show: allOwners size printString; cr].
	^Array	
		with: allOwners asOrderedCollection
		with: allRoots!

warning: ignored
	"Browsing the senders of this message can be used to find 'soft' spots in the ThingLabII implementation."! !

!ClassDescription methodsFor: 'ThingLabII'!

organization: anOrganizer

	organization _ anOrganizer! !

!ScreenController methodsFor: 'ThingLabII'!

announceThingLabII: aForm
	"If the given form is not nil, then pop up the ThingLabII intro picture and wait until the user clicks the mouse."

	(aForm notNil)
		ifTrue: [IntroPicture openOn: aForm].!

openControlPanel
	"Pop up the ThingLabII Control Panel."

	ThingLabIIControlPanel open.!

openTopBin
	"Open a ThingLabII PartsBin view."

	PartsBinView openOn: (PartsBin topBin).!

quit
	"Save this image and quit from Smalltalk, quit without saving the image, or return to normal operations, depending on the respose of the user to a menu query."

	| menu index |
	menu _ PopUpMenu
		labels:
' Save, then quit 
 Quit, without saving 
 Continue '
		lines: #(1 2).
	index _ menu startUp.
	(index = 1)
		ifTrue: ["self save: true"].		"save, then quit"
	(index = 2)
		ifTrue: [Smalltalk quit].		"quit without saving"

	"otherwise, resume normal Smalltalk operations"!

save
	"Do a system snapshot but don't quit."

	self save: false.	"continue after saving"!

save: quitAfterSaving
	"Do a system snapshot and quit if 'quitAfterSaving' is true. We pop up the ThingLabII Intro window after saving so it will be the first thing the user see when re-starting the saved image. This means that it also pops up after the save operation. Popping up the ThingLabII Intro window can be disabled by holding down the shift key while performing this operation."

	| prefix form |
	prefix _ Smalltalk getImagePrefix.
	prefix isEmpty ifTrue: [^self].
	form _ nil.
	sensor leftShiftDown ifFalse:
		[(FileDirectory includesKey: 'ThingLabII.form')
			ifTrue: [form _ Form readFrom: 'ThingLabII.form']].
	Smalltalk saveAs: prefix thenQuit: quitAfterSaving.
	self announceThingLabII: form.	"This is a noop if form is nil."! !

!ScreenController class methodsFor: 'ThingLabII class initialization'!

initialize
	"Initialize the System Menu."

	"ScreenController initialize.
	ScreenController allInstancesDo: [:c | c initializeYellowButtonMenu]"

	ScreenYellowButtonMenu _
		PopUpMenu
			labels: 
'restore display
garbage collect
exit project
browser
workspace
file list
file editor
terminal
project
ThingLabII Parts Bin
ThingLabII Control Panel
system transcript
system workspace
desk top
save
quit'
			lines: #(3 9 11 12 13).
	ScreenYellowButtonMessages _
			#(restoreDisplay garbageCollect exitProject
			openBrowser openWorkspace openFileList openFileEditor 
			openCshView  openProject 
			openTopBin openControlPanel
			openTranscript openSystemWorkspace 
			openDeskTop save quit).! !

!AssignmentNode methodsFor: 'ThingLabII'!

apply: aBlock

	(aBlock value: self)
		ifTrue:
			[variable apply: aBlock.
			 value apply: aBlock].!

specificMatch: aTree using: matchDict
	"See ParseNode>specificMatch:using:"

	^(variable match: aTree variable using: matchDict) and:
	  [value match: aTree value using: matchDict]!

transformBy: aBlock

	| result |
	result _ self copy.
	result
		variable: (variable transformBy: aBlock)
		value: (value transformBy: aBlock).
	^aBlock value: result!

value

	^value!

variable

	^variable! !

!BlockNode methodsFor: 'ThingLabII'!

apply: aBlock

	(aBlock value: self) ifTrue:
		[statements do:
			[: statement | statement apply: aBlock]].!

arguments: args

	arguments _ args.!

specificMatch: aTree using: matchDict
	"See ParseNode>specificMatch:using:"

	(statements size = aTree statements size) ifFalse: [^false].
	statements with: aTree statements do:
		[: s1 : s2 |
		 (s1 match: s2 using: matchDict) ifFalse: [^false]].

	^true	"all statements match"!

statements

	^statements!

statements: statementList

	statements _ statementList.!

transformBy: aBlock

	| result |
	result _ self copy.
	result arguments:
		(arguments collect:
			[: arg | arg transformBy: aBlock]).
	result statements:
		(statements collect:
			[: statement | statement transformBy: aBlock]).
	^aBlock value: result! !

!CascadeNode methodsFor: 'ThingLabII'!

apply: aBlock

	(aBlock value: self)
		ifTrue:
			[receiver apply: aBlock.
			 messages do:
				[: msg | msg apply: aBlock]].!

specificMatch: aTree using: matchDict
	"See ParseNode>specificMatch:using:"

	(receiver match: aTree receiver using: matchDict) ifFalse: [^false].
	(messages size =  aTree messages size) ifFalse: [^false].
	messages with: aTree messages do:
		[: m1 : m2 |
		 (m1 match: m2 using: matchDict) ifFalse: [^false]].

	^true	"receiver and messages all match"!

transformBy: aBlock

	| result |
	result _ self copy.
	result
		receiver: (receiver transformBy: aBlock)
		messages:
			(messages collect:
				[: msg | msg transformBy: aBlock]).
	^aBlock value: result! !

!LeafNode methodsFor: 'ThingLabII'!

apply: aBlock

	aBlock value: self.!

transformBy: aBlock

	^aBlock value: self copy! !

!LiteralNode methodsFor: 'ThingLabII'!

specificMatch: aTree using: matchDict
	"See ParseNode>specificMatch:using:"

	^key = aTree key! !

!MessageNode methodsFor: 'ThingLabII'!

apply: aBlock

	(aBlock value: self)
		ifTrue:
			[receiver notNil
				ifTrue: [receiver apply: aBlock].
			 arguments do: [: arg | arg apply: aBlock]].!

arguments

	^arguments!

arguments: argList

	arguments _ argList.!

moveVariableToFarLeft: aVariable
	"Move the variable with this key as far left as possible using the message 'swapSides'."

	| newMe count oldMe argWithVar i newArg |
	newMe _ self copy.
	count _ arguments size + 2.
	[(count > 0) and:
       [((newMe receiver allVariables includes: aVariable) not) and: 
		[oldMe _ newMe.
		 newMe _ newMe swapSides.
		 newMe ~= oldMe]]]
			whileTrue: [count _ count - 1].
	(count = 0) ifTrue:
		[self error: 'Never found the variable while swapping'].
	(newMe receiver allVariables includes: aVariable)
		ifTrue:
			[newMe receiver:
				(newMe receiver moveVariableToFarLeft: aVariable)]
		ifFalse: 
			[argWithVar _ newMe arguments
				detect: [: arg | arg allVariables includes: aVariable]
				ifNone: [self error:
						'Can''t find the variable in the swapped equation'].
			 i _ newMe arguments indexOf: argWithVar.
			 newArg _
				(newMe arguments at: i) moveVariableToFarLeft: aVariable.
			 newMe arguments at: i put: newArg].
	^newMe!

receiver

	^receiver!

receiver: newReceiver

	receiver _ newReceiver.!

selector

	^selector!

specificMatch: aTree using: matchDict
	"See ParseNode>specificMatch:using:"

	(receiver match: aTree receiver using: matchDict) ifFalse: [^false].
	(selector match: aTree selector using: matchDict) ifFalse: [^false].
	(arguments size = aTree arguments size) ifFalse: [^false].
	arguments with: aTree arguments do:
		[: arg1 : arg2 |
		 (arg1 match: arg2 using: matchDict) ifFalse: [^false]].

	^true	"receiver, selector, and arguments all match"!

transformBy: aBlock

	| result |
	result _ self copy.
	(receiver notNil) ifTrue:
		[result receiver: (receiver transformBy: aBlock)].
	result arguments:
		(arguments collect:
			[: arg | arg transformBy: aBlock]).
	^aBlock value: result! !

!MethodNode methodsFor: 'ThingLabII'!

apply: aBlock

	(aBlock value: self)
		ifTrue:
			[block apply: aBlock].!

arguments: argList

	arguments _ argList.!

block

	^block!

block: theBlock

	block _ theBlock.!

specificMatch: aTree using: matchDict
	"See ParseNode>specificMatch:using:"

	(self selector = aTree selector) ifFalse: [^false].
	(block match: aTree block using: matchDict) ifFalse: [^false].
	(arguments size = aTree arguments size) ifFalse: [^false].
	arguments with: aTree arguments do:
		[: arg1 : arg2 |
		 (arg1 match: arg2 using: matchDict) ifFalse: [^false]].

	^true	"selector, block, and arguments all match"!

transformBy: aBlock

	| result |
	result _ self copy.
	result arguments:
		(arguments collect:
			[: arg | arg transformBy: aBlock]).
	result block: (block transformBy: aBlock).
	^aBlock value: result! !

!ParseNode methodsFor: 'ThingLabII-Equations'!

match: targetTree using: matchDict 
	"Match myself as a pattern against the target tree and answer true if a match is found. Sometimes I represent a pattern and my variables may match complete subtrees of targetTree. In such cases, the sender supplies an empty Dictionary, matchDict, that is used to map pattern variables to the corresponding subtrees of the target tree. After the match, the dictionary can be used to find which variables matched which subtrees. Sometimes it is desirable to find an exact match, with no variable substitutions. This case is indicated by supplying a 'nil' matchDict. See VariableNode>match:using for further details."

	^(targetTree isMemberOf: self class) and:
	  [self specificMatch: targetTree using: matchDict]!

moveVariableToFarLeft: aVariable
	"Move the variable with this key as far left as possible using the message 'swapSides'."

	self subclassResponsibility!

removeNodesSurrounding: aVariable
	"Repeatedly apply restructuring rules until the given variable has been isolated. If at any point we fail to find a restructuring rule to apply, report and error and give up."

	| dictOrNil theTree newTree |
	theTree _ self.
	[(theTree receiver isMemberOf: VariableNode)
		and: [theTree receiver key = aVariable]]
		whileFalse: 
			[EquationTranslator restructureRules
				detect: 
					[: rule | 
					 dictOrNil _ rule matches: theTree.
					 dictOrNil notNil
						and: [newTree _ rule applyUsing: dictOrNil.
							newTree receiver allVariables includes: aVariable]]
				ifNone:
					[^self error: 'Can''t reduce the left side because
no rule matches the equation:
	', theTree printString].
			theTree _ newTree].

	^theTree!

restructureForAssigningTo: aVarKey

	(self isMemberOf: MessageNode) ifFalse:
		[self error: 'Implementation Error: Expected a MessageNode'].

	(self allVariables includes: aVarKey) ifFalse:
		[self error: 'The equation:
	', self printString, '
does not contain the desired variable:
	', aVarKey].

	^(self moveVariableToFarLeft: aVarKey)
		removeNodesSurrounding: aVarKey!

specificMatch: aTree using: matchDict
	"Assuming aTree is a ParseNode like me, do a field-by-field comparison between us and answer true if we match. See match:using for further details."

	self subclassResponsibility!

swapSides
	"Apply the first re-order rule that matches me and return the resulting parse tree. If no rule matches me, return myself."

	| dictOrNil |
	EquationTranslator reorderRules do: 
		[: rule | 
		 dictOrNil _ rule matches: self.
		 (dictOrNil notNil) ifTrue:
			[^rule applyUsing: dictOrNil]].
	^self! !

!ParseNode methodsFor: 'ThingLabII'!

allVariables
	"Answer a set containing all variables used in this parse tree."

	| vars |
	vars _ IdentitySet new.
	self apply:
		[: node |
		 (node isMemberOf: VariableNode)
			ifTrue: [vars add: node name asSymbol].
		 true].

	self removePredefinedVarsFrom: vars.
	^vars!

assignedTo
	"Answer a collection of the variables assigned to in this parse tree."

	| vars |
	vars _ IdentitySet new.
	self apply:
		[: node |
		 (node isMemberOf: AssignmentNode)
			ifTrue: [vars add: node variable name asSymbol].
		 true].

	self removePredefinedVarsFrom: vars.
	^vars!

referenced
	"Answer a collection of the variables that are referenced but not assigned to in this parse tree."

	| vars |
	vars _ IdentitySet new.
	self apply:
		[: node |
		 (node isKindOf: VariableNode)
			ifTrue: [vars add: node name asSymbol. true]
			ifFalse:
				[(node isMemberOf: AssignmentNode)
					ifTrue: [vars addAll: node value referenced. false]
					ifFalse: [true]]].

	self removePredefinedVarsFrom: vars.
	^vars!

removePredefinedVarsFrom: varList
	"Remove the pre-defined variable names from the given collection."

	#(self super true false nil thisContext) do:
		[: predefinedVar |
			varList remove: predefinedVar ifAbsent: []].!

transformBy: aBlock
	"Answer a copy of the parse tree whose root is me, transformed by the given block. The block takes one argument, some kind of ParseNode, and returns some transformation of the node (or the node itself). For example, the null transformation (which copies the parse tree) is:
	aParseTree transformBy: [: node | node]"

	self subclassResponsibility! !

!ReturnNode methodsFor: 'ThingLabII'!

apply: aBlock

	(aBlock value: self)
		ifTrue:
			[expr apply: aBlock].!

expr

	^expr!

expr: expression

	expr _ expression.!

specificMatch: aTree using: matchDict
	"See ParseNode>specificMatch:using:"

	^expr match: aTree expr using: matchDict!

transformBy: aBlock

	| result |
	result _ self copy.
	result expr: (expr transformBy: aBlock).
	^aBlock value: result! !

!SelectorNode methodsFor: 'ThingLabII'!

specificMatch: aTree using: matchDict
	"See ParseNode>specificMatch:using:"

	^key = aTree key! !

!VariableNode methodsFor: 'ThingLabII'!

mapBy: mappingDict
 
	^mappingDict at: key ifAbsent: [self]!

match: targetTree using: matchDict
	"A variable in a pattern may represent an entire subtree. However, if the variable appears multiple times in the pattern then the associated subtree must be the same each time. There are two ways to use the match:using: function: 1.) allowing variables to match arbitrary subtrees or 2.) requiring an exact match (to verify that two subtrees are identical). We indicate the difference by supplying a 'nil' matchDict when we wish to make an exact match."

	| binding |
	(matchDict isNil)
		ifTrue:
			["we must have an exact match"
			 ^(targetTree isMemberOf: VariableNode) and:
			   [name = targetTree name & key = targetTree key]]
		ifFalse:
			[binding _ matchDict
						at: key
						ifAbsent:
							[matchDict at: key put: targetTree.
							 ^true].
			 "if we already have a binding for this variable the binding must exactly match the current subtree"
			 ^binding match: targetTree using: nil].!

moveVariableToFarLeft: aVariable
	"Move the variable with this key as far left as possible using the message 'swapSides'. This is a noop for variable nodes."

	^self!

name

	^name! !

Object subclass: #GraphLayout
	instanceVariableNames: 'vertexCount vertices transitions lengths springConstants forces maxForce '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Layout'!


!GraphLayout methodsFor: 'initialize-release'!

placeVerticesAroundCircle
	"Place vertices evenly spaced around a circle."

	| deltaTheta theta |
	deltaTheta _ (Float pi * 2.0) / vertexCount asFloat.
	theta _ Float pi / 2.0.
	vertices do:
		[: v |
		 v x: 170 + (70 * theta cos).
		 v y: 170 + (70 * theta sin).
		 theta _ theta + deltaTheta].!

setupConstants
	"Calculate the spring and length constants for each pair of vertices. Since these are symmetric relations, we need only compute half the matrix; the other half is filled in by symmetry. We assume that the vertices list and transition matrix have already been initialized."

	| maxDistance distances arcLength idealLength springConst |
	vertexCount _ vertices size.
	distances _ ShortestPaths computeDistances: transitions.
	maxDistance _ 1.
	distances rows do:
		[: row |
		 row do:
			[: dist | (dist > maxDistance) ifTrue: [maxDistance _ dist]]].
	arcLength _ (200 // maxDistance) max: 75.
	lengths _ Matrix square: vertexCount.
	springConstants _ Matrix square: vertexCount.
	1 to: (vertexCount - 1) do:
		[: i |
		(i+1) to: vertexCount do:
			[: j || dist |
			 dist _ distances row: i col: j.
			 idealLength _ (arcLength * dist) asFloat.
			 springConst _ 0.30 / (dist * dist) asFloat.	"unstable if const >> 0.35"
			 lengths row: i col: j put: idealLength.
			 lengths row: j col: i put: idealLength.
			 springConstants row: i col: j put: springConst.
			 springConstants row: j col: i put: springConst]].!

vertices: vertexList transitions: transitionMatrix
	"Layout the connected graph with the given set of vertices and transition matrix. If the graph is not connect, its components should be laid out individually."

	vertices _ vertexList.
	transitions _ transitionMatrix.
	self setupConstants.
	self placeVerticesAroundCircle.! !

!GraphLayout methodsFor: 'force-based method'!

computeForces
	"Compute the forces vector. The force on each vertex is the vector sum of the component forces of all springs attached to the vertex."

	| i j lengthsRow springConstantsRow vectorX vectorY dist idealLength magnitude forceX forceY totalForce |

	forces _ (1 to: vertexCount) collect: [: ii | 0.0@0.0].
	i _ 1.
	[i < vertexCount] whileTrue:
		[lengthsRow _ lengths row: i.
		 springConstantsRow _ springConstants row: i.
		 j _ i + 1.
		 [j <= vertexCount] whileTrue:
			[vectorX _ (vertices at: i) x - (vertices at: j) x.
			 vectorY _ (vertices at: i) y - (vertices at: j) y.
			 dist _ ((vectorX * vectorX) + (vectorY * vectorY)) sqrt.
			 (dist = 0.0)
				ifTrue:
					["generate arbitrary force vector if vertices coincide"
					 magnitude _ 10.0.
					 forceX _ magnitude.
					 forceY _ 0.0]
				ifFalse:
					[idealLength _ (lengthsRow at: j).
					 magnitude _
						(springConstantsRow at: j) * (idealLength - dist) / dist.
					 forceX _ vectorX * magnitude.
					 forceY _ vectorY * magnitude].

			 "Note: a positive vector = an outward force on both vertices"
			 totalForce _ forces at: i.
			 totalForce x: (totalForce x + forceX).
			 totalForce y: (totalForce y + forceY).
			 totalForce _ forces at: j.
			 totalForce x: (totalForce x - forceX).
			 totalForce y: (totalForce y - forceY).
			 j _ j + 1].
		i _ i + 1].!

movePoints
	"Assume that forceVector has been computed. Move each point in response to the combined forces on it."

	| i delta xMagnitude yMagnitude |
	maxForce _ 0.0.
	i _ 1.
	[i <= vertexCount] whileTrue:
		[delta _ forces at: i.
		 (vertices at: i) moveBy: delta.

		 xMagnitude _ delta x.
		 (xMagnitude < 0.0) ifTrue:
			[xMagnitude _ xMagnitude negated].
		 (xMagnitude > maxForce) ifTrue:
			[maxForce _ xMagnitude].

		 yMagnitude _ delta y.
		 (yMagnitude < 0.0) ifTrue:
			[yMagnitude _ yMagnitude negated].
		 (yMagnitude > maxForce) ifTrue:
			[maxForce _ yMagnitude].
		 i _ i + 1].!

solve

	| v |
	maxForce _ 10.0.		"ensure that loop is executed once"
	[maxForce > 0.1] whileTrue:
		[self computeForces.
		 self movePoints].
	self updateGlyphs.! !

!GraphLayout methodsFor: 'animation'!

doStep
	"Do one solution step and answer true if we are done."

	self computeForces.
	self movePoints.
	self updateGlyphs.
	^maxForce < 0.1!

updateGlyphs
	"Update all the glyphs pointed to by entries in the vertex table."

	vertices do:
		[: v | v location: (v x rounded@v y rounded)].!

updateVertices
	"Update all the vertices from their glyphs if the glyphs have moved."

	vertices do:
		[: v |
		 (v x rounded = v location x) ifFalse:
			[v x: v location x].
		 (v y rounded = v location y) ifFalse:
			[v y: v location y]].! !

BitEditor subclass: #NotifyingBitEditor
	instanceVariableNames: 'client doneFlag '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Support'!


!NotifyingBitEditor methodsFor: 'menu messages'!

accept
	"The edited information should now be accepted by the view."

	view accept.
	(client notNil) ifTrue: [client acceptChange].!

cancel
	"The undo all edits (since the last accept)."

	super cancel.!

clear
	"Clear my form."

	view workingForm white.
	view displayView.!

close
	"Close this bit editor without accepting the edits."

	(client notNil) ifTrue: [client doneEditing].
	doneFlag _ true.	"make controller let go..."
	view topView controller close.!

collapse

	view topView controller collapse.!

done
	"Accept the edited bitmap and close this bit editor."

	self accept.
	(client notNil) ifTrue: [client doneEditing].
	doneFlag _ true.	"make controller let go..."
	view topView controller close.!

move

	view topView controller move.!

newLabel

	view topView controller newLabel.!

under

	view topView controller under.! !

!NotifyingBitEditor methodsFor: 'private'!

client: anObject

	doneFlag _ false.
	client _ anObject.!

initializeYellowButtonMenu

	self
		yellowButtonMenu:
			(PopUpMenu
				labels: 'clear\accept\cancel\done' withCRs
				lines: #(1))
		yellowButtonMessages:
			#(clear accept cancel done).
	self
		blueButtonMenu:
			(PopUpMenu
				labels: 'new label\under\move\collapse\close' withCRs
				lines: #(1 4))
		blueButtonMessages:
			#(newLabel under move collapse close).!

isControlActive

	^self viewHasCursor
		& sensor keyboardPressed not
		& doneFlag not! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NotifyingBitEditor class
	instanceVariableNames: ''!


!NotifyingBitEditor class methodsFor: 'instance creation'!

installClient: client in: aScheduledView

	aScheduledView subViews do: [: v |
		(v controller isMemberOf: self)
			ifTrue: [v controller client: client]].!

openOnForm: aForm at: magnifiedLocation scale: scaleFactor notify: client
	"Create and schedule a BitEditor on the form aForm. Show the small and  magnified view of aForm."

	| aScheduledView |
	aScheduledView _ self
		bitEdit: aForm
		at: magnifiedLocation
		scale: scaleFactor
		remoteView: nil.
	self installClient: client in: aScheduledView.
	(aScheduledView controller)
		blueButtonMenu: nil blueButtonMessages: nil.
	aScheduledView controller openDisplayAt:
		aScheduledView displayBox topLeft +
			(aScheduledView displayBox extent / 2)!

openOnForm: aForm client: client

	| scaleFactor |
	scaleFactor _ 4@4.
	self openOnForm: aForm
		at: (self locateMagnifiedView: aForm scale: scaleFactor) topLeft
		scale:scaleFactor
		notify: client.! !

Object subclass: #WalkEquation
	instanceVariableNames: 'constant vars '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Module Compiler'!
WalkEquation comment:
'I represent a walkabout strength equation of the form:
	(((constant weakest: a) weakest: b) weakest: c)
where a, b, and c are references to variables whose strength will not be known until run-time. I fold constant terms as I am created.

Strength cooperates with me by turning expressesions of the form:
	aStrength weakest: aWalkEquation
into:
	aWalkEquation weakest: aStrength
so that I respond with a new WalkEquation.'!


!WalkEquation methodsFor: 'initialize-release'!

constant: aStrength vars: varList

	constant _ aStrength.
	vars _ varList.! !

!WalkEquation methodsFor: 'access'!

constant
	"Answer the constant part of me."

	^constant!

vars
	"Answer my variable list."

	^vars! !

!WalkEquation methodsFor: 'operations'!

sameAs: aStrength
	"Answer true if I am constant and I am equal to the given strength."

	(constant isNil | vars isEmpty not) ifTrue: [^false].
	^constant sameAs: aStrength!

simplify
	"Remove redundant 'required' constant. That is, if my constant part is 'required' and my vars list is not empty, the constant part can be omitted since 'required' is the upper bound on constraint strengths anyway."

	((constant notNil) and:
	 [(constant sameAs: Strength required) & (vars isEmpty not)]) ifTrue:
		[constant _ nil].!

strongest: strengthOrEquation
	"Answer a new WalkEquation that is the maximum of myself and the given Strength or WalkEquation."

	| constPart |
	(strengthOrEquation isMemberOf: Strength)
		ifTrue:	"it's a Strength"
			[^WalkEquation
				constant:
					((constant isNil)
						ifTrue: [strengthOrEquation]
						ifFalse: [self constant strongest: strengthOrEquation])
				vars: self vars]
		ifFalse:	"it's another WalkEquation"
			[constPart _
				(self constant isNil)
					ifTrue: [strengthOrEquation constant]	"mine is nil, use his"
					ifFalse:
						[(strengthOrEquation constant isNil)
							ifTrue: [self constant]			"his is nil, use mine"
							ifFalse: 					"neither is nil, so combine"
								[self constant strongest:
										strengthOrEquation constant]].
			 ^WalkEquation
				constant: constPart
				vars: (self vars, strengthOrEquation vars)]!

weakest: strengthOrEquation
	"Answer a new WalkEquation that is the minimum of myself and the given Strength or WalkEquation."

	| constPart |
	(strengthOrEquation isMemberOf: Strength)
		ifTrue:	"it's a Strength"
			[^WalkEquation
				constant:
					((constant isNil)
						ifTrue: [strengthOrEquation]
						ifFalse: [self constant weakest: strengthOrEquation])
				vars: self vars]
		ifFalse:	"it's another WalkEquation"
			[constPart _
				(self constant isNil)
					ifTrue: [strengthOrEquation constant]	"mine is nil, use his"
					ifFalse:
						[(strengthOrEquation constant isNil)
							ifTrue: [self constant]			"his is nil, use mine"
							ifFalse: 					"neither is nil, so combine"
								[self constant weakest:
										strengthOrEquation constant]].
			 ^WalkEquation
				constant: constPart
				vars: (self vars, strengthOrEquation vars)]! !

!WalkEquation methodsFor: 'code generation'!

putVarExpr: varList on: aStream
	"Append to the given stream a code string for an expression of the form:
		(a weakest: (b weakest: (c weakest: (d))))."

	aStream nextPut: $(.
	(varList size == 1)
		ifTrue:
			[varList first strengthCodeStringOn: aStream]
		ifFalse:
			[varList first strengthCodeStringOn: aStream.
			 aStream nextPutAll: ' weakest: '; cr; tab; tab.
			 self putVarExpr: (varList copyFrom: 2 to: varList size) on: aStream].	
	aStream nextPut: $).!

storeOn: aStream
	"Append the code for this walkabout strength equation to the given stream."

	aStream nextPut: $(.
	"store the constant part if it exists and is not an unneeded 'required'"
	(constant notNil) ifTrue:
		[constant storeOn: aStream.
		 (vars isEmpty) ifFalse:
			[aStream nextPutAll: ' weakest: '; cr; tab;tab]].
	self putVarExpr: vars on: aStream.
	aStream nextPut: $).! !

!WalkEquation methodsFor: 'printing'!

printOn: aStream

	aStream nextPutAll: 'WEqn('.
	(constant notNil) ifTrue:
		[constant printOn: aStream.
		 aStream nextPutAll: ' min: '].
	vars do:
		[: v |
		 v printOn: aStream.
		 aStream nextPutAll: ' min: '].
	(constant notNil | vars isEmpty not) ifTrue:
		[aStream skip: -6].
	aStream nextPutAll: ')'.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WalkEquation class
	instanceVariableNames: ''!


!WalkEquation class methodsFor: 'instance creation'!

constant: aSymbol

	^self new
		constant: (Strength of: aSymbol)
		vars: OrderedCollection new!

constant: aStrength vars: varList

	^self new
		constant: aStrength
		vars: varList!

external: aVariable

	^self new
		constant: nil
		vars: (OrderedCollection with: aVariable)! !

Object subclass: #DebugPartitionRecord
	instanceVariableNames: 'constraintRecords solver solutionIndex neverLaidOut cycleFlag '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Debugger'!
DebugPartitionRecord comment:
'This class describes a partition of the constraint graph being debugged. It consists of a collection of DebugConstraintRecords, a constraint solver, and a GraphLayout object for the partition.'!


!DebugPartitionRecord methodsFor: 'accessing'!

constraintRecords

	^constraintRecords!

constraintRecords: aCollectionOfConstraintRecords

	neverLaidOut _ true.
	constraintRecords _ aCollectionOfConstraintRecords.!

neverLaidOut

	^neverLaidOut!

solution
	"Zero is the current solution. Positive integers are alternative possible solutions."

	^solutionIndex - 1!

solution: aNumber
	"Zero is the current solution. Positive integers are alternative possible solutions."

	solutionIndex _ aNumber + 1.
	self updateGlyphs.
	self setCycleFlag.!

solver

	^solver!

solver: aMultiSolver

	solver _ aMultiSolver.! !

!DebugPartitionRecord methodsFor: 'operations'!

animateOn: aView
	"Animate the placement algorithm."

	| layoutTool done |
	layoutTool _ self graphLayoutTool.
	layoutTool updateVertices.
	done _ false.
	[done | Sensor anyButtonPressed] whileFalse:
		[done _ layoutTool doStep.
		 self centerConstraints.
		 aView displaySafe: [aView displayScene]].!

centerConstraints
	"Center the constraints of this partition."

	| centerOfGraph |
	centerOfGraph _
		(constraintRecords inject: 0@0 into: [: sum : c | sum + c glyph location]) //
			(constraintRecords size).
	constraintRecords do:
		[: cRec | cRec centerConstraint: centerOfGraph].!

findAllSolutions
	"This can be very expensive for large partitions!! Find and record all the possible solutions for this partition so that the user may browse through them."

	| allSolutions cRec solutions |
	allSolutions _ solver computeSolutions; allSolutions.
	1 to: constraintRecords size do:
		[: constraintIndex |
		 cRec _ constraintRecords at: constraintIndex.
		 solutions _ allSolutions collect: [: methods | methods at: constraintIndex].
		 solutions addFirst: cRec solutions first.	"remember the current solution"
		 cRec solutions: solutions].!

graphLayoutTool

	| vertices transitions constraintVars n j |
	vertices _ IdentitySet new: 40.
	constraintRecords do:
		[: cRec | vertices addAll: cRec varGlyphs].
	vertices _ vertices asOrderedCollection.
	transitions _ (Matrix square: vertices size) fill: 1000.	"infinite distance"
	1 to: vertices size do:
		[: i |
		 (vertices at: i) label: i.
		 transitions row: i col: i put: 0].					"zero distance from i to i"
	constraintRecords do:
		[: cRec |
		 constraintVars _ cRec varGlyphs.
		 n _ constraintVars size.
		 1 to: (n - 1) do:
			[: v1 || i |
			 i _ (constraintVars at: v1) label.
			 (v1 + 1) to: n do:
				[: v2 |
				 j _ (constraintVars at: v2) label.
				 "distance of one between each pair of vertices joined by a constraint"
				 transitions row: i col: j put: 1.
				 transitions row: j col: i put: 1]]].

	^GraphLayout new vertices: vertices transitions: transitions!

initialLayout
	"Construct an initial layout of the graph."

	| layoutTool done |
	layoutTool _ self graphLayoutTool.
	2 timesRepeat: [layoutTool doStep].
	self centerConstraints.
	neverLaidOut _ false.!

setCycleFlag
	"Set the cycleFlag if the current solution has a cycle."

	| methodList method |
	methodList _ OrderedCollection new: 100.
	constraintRecords do:
		[: cRec |
		 method _ cRec solutions at: solutionIndex.
		 methodList add: method].
	cycleFlag _ solver hasCycle: methodList.!

solutionCount
	"Answer the number of possible alternate solutions for this partition."
	"Detail: The first solution in the solutions list is the current solution, which we don't count."

	^constraintRecords first solutions size - 1!

solutionHasCycle
	"Answer true if the current solution has a cycle."

	^cycleFlag!

toggleLabels
	"Toggle the visibility of the constraint labels of this partition."

	(constraintRecords first glyph labelIsHidden)
		ifTrue: [constraintRecords do: [: c | c glyph showLabel]]
		ifFalse: [constraintRecords do: [: c | c glyph hideLabel]].!

updateCurrentSolution
	"Update the current solution."

	constraintRecords do:
		[: cRec | cRec updateCurrentSolution].!

updateGlyphs
	"Update the constraint glyphs to reflect the selected solution."

	constraintRecords do:
		[: cRec | cRec updateGlyph: solutionIndex].! !

Object subclass: #TranslationRule
	instanceVariableNames: 'from to '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Equations'!
TranslationRule comment:
'I am a replacement rule for transforming one parse tree with another. I consists of two parse trees representing patterns, a "from" tree and a "to" tree. The variables in these parse trees represent arbitrary subtrees.

I am used by finding an instance of me whose "from" tree matches the target parse tree. This transformation rule is then "applied" by filling in a copy of its "to" tree with the subtrees of the target parse tree corresponding to the variables of the "from" tree and answering the resulting parse tree.
'!


!TranslationRule methodsFor: 'initialization'!

from: fromString to: toString
	"Create parse trees for the expressions represented by my arguments. Verify that the output pattern does not reference any variable that was not part of the input pattern. It is permissible to leave one or more input variables out of the output pattern, although such a transform will naturally lose information."

	| parseTree fromVars toVars |
	parseTree _ EquationParser parse: ('dummy ', fromString) readStream.
	from _ parseTree block statements first.
	parseTree _ EquationParser parse: ('dummy ', toString) readStream.
	to _ parseTree block statements first.

	"check for output vars that were not in the input pattern"
	fromVars _ from allVariables.
	toVars _ to allVariables.
	toVars do:
		[: v |
		 (fromVars includes: v) ifFalse:
		 	[self error: 'Equation Tree Mismatch:
''from'' tree does not contain variable ''', v, '''']].! !

!TranslationRule methodsFor: 'match and apply'!

applyUsing: mappingDict
	"Apply this rule by making the variable substitutions given by mappingDict in the output side of the rule. mappingDict was build during matching."

	^to transformBy:		"transformBy: makes a copy of the tree"
		[: node |
		 (node isMemberOf: VariableNode)
			ifTrue: [node mapBy: mappingDict]
			ifFalse: [node]]!

matches: targetParseTree
	"Match the input pattern of this rule against the given parse tree, collecting mappings from variables to subtrees in a dictionary. If the match succeeds, answer the match dictionary. If it fails, answer nil."

	| matchDict |
	matchDict _ Dictionary new.
	^(from match: targetParseTree using: matchDict)
		ifTrue: [matchDict]
		ifFalse: [nil]! !

!TranslationRule methodsFor: 'printing'!

printOn: aStream

	from printOn: aStream.
	aStream nextPutAll: '-->'.
	to printOn: aStream.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TranslationRule class
	instanceVariableNames: ''!


!TranslationRule class methodsFor: 'instance creation'!

from: fromString to: toString
	"Create parse trees for the expressions represented by my arguments."

	^self new from: fromString to: toString! !

Object subclass: #Matrix
	instanceVariableNames: 'rows '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Layout'!


!Matrix methodsFor: 'public'!

col: column
	"Answer the column with the given index. Column are numbered from 1 to N."

	^rows collect: [: row | row at: column]!

columnCount
	"Answer the number of columns in this matrix."

	^(rows at: 1) size!

copy
	"Answer a copy of myself."

	^(self class basicNew) setRows: (rows collect: [: row | row copy])!

fill: aValue
	"Fill the matrix with the given value."

	| rowSize |
	rowSize _ self rowCount.
	rows _ rows collect: [: ignore | Array new: rowSize withAll: aValue].!

row: row
	"Answer the row with the given index. Rows are numbered from 1 to N."

	^rows at: row!

row: row col: column
	"Answer the element at the given location."

	^(rows at: row) at: column!

row: row col: column put: element
	"Store the given element at the given location."

	(rows at: row) at: column put: element.!

rowCount
	"Answer the number of rows in this matrix."

	^rows size!

rows
	"Answer a collection of my rows."

	^rows! !

!Matrix methodsFor: 'printing'!

printOn: aStream

	aStream nextPut: $[.
	rows do:
		[: row |
		 row printOn: aStream.
		 aStream cr].
	aStream skip: -1.
	aStream nextPut: $].! !

!Matrix methodsFor: 'private'!

initialRows: rowCount columns: columnCount
	"Make an empty matix with the given number of rows and columns."

	rows _ (1 to: rowCount) collect:
				[: row | Array new: columnCount].!

setRows: arrayOfRows
	"Replace my rows with the given array of rows. Used by copy."

	rows _ arrayOfRows.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Matrix class
	instanceVariableNames: ''!


!Matrix class methodsFor: 'instance creation'!

rows: rowCount columns: columnCount
	"Answer a Matrix with the given numbers of rows and columns, initially filled with nils."

	^(self basicNew) initialRows: rowCount columns: columnCount!

square: size
	"Answer a square Matrix with 'size' rows and columns, initially filled with nils."

	^(self basicNew) initialRows: size columns: size! !

Object subclass: #ModulePartition
	instanceVariableNames: 'id constraints varTable solutions '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Module Compiler'!
ModulePartition comment:
'A ThingPartition is used during module compilation to keep track of the possible solutions for a given partition of the constraint graph. Each partition is eventually compiled into a ModuleConstraint.

	id			<Integer>	unique id for this partition
	constraints	{Constraint}	the constraints for this partition
	solutions		{{method}}	the solutions for this parition
							(a solution is a set of methods)
	varType		<Dictionary>	maps each variable (a ThingData) to one of:
					#external	-- the variable is an external part
					#internal	-- the variable is an internal part
					#temporary	-- the variable does not hold state
									between calls to the satisfier'!


!ModulePartition methodsFor: 'initialize-release'!

on: constraintList
	"Initialize this instance with the given constraints."

	constraints _ constraintList.
	id _ nil.			"filled in later"
	varTable _ nil.	"filled in later"
	solutions _ nil.	"filled in later"! !

!ModulePartition methodsFor: 'operations'!

buildVariableTable
	"Build a table of all the variables referenced by my constraints."
	"Details: Due to merges, there may be numerous paths (references) for the same variable. The thingData for all refererences will be the same, however, so we use thingDatas to keep track of the variables that have been recorded in the table."

	| recordedVars thingData |
	varTable _ OrderedCollection new.
	recordedVars _ IdentitySet new: 20.
	constraints do:
		[: c |
		 (c variables) do:
			[: ref |
			 thingData _ ref thingData.
			 (recordedVars includes: thingData) ifFalse:
				[varTable add: (ModuleVarTableEntry on: ref).
				 recordedVars add: thingData]]].!

computeSolutions
	"Compute all possible solutions to the constraints in this partition."

	| extVars |
	extVars _ OrderedCollection new: varTable size.
	varTable do:
		[: entry |
		 (entry isExternal) ifTrue:
			[extVars add: entry thingData]].
	solutions _
		(MultiSolver solutionsFor: constraints externalVars: extVars) collect:
			[: s | ModuleSolution on: s].!

declareExternalVars: externalRefs
	"Build the variable table and identify the external variables."

	self buildVariableTable.
	varTable do:
		[: entry |
		 ref _ externalRefs
			detect: [: reff | reff thingData == entry thingData]
			ifNone: [nil].
		 (ref notNil) ifTrue:
			[entry makeExternal: ref]].!

hasExternalVars
	"Answer true if this partition has at least one external variable."

	varTable do:
		[: entry | (entry isExternal) ifTrue: [^true]].
	^false	"has only no external variables"!

initializeInternalVarsFor: newModule
	"Initialize the internal variables for the new Module."

	| instIndex |
	varTable do:
		[: var |
		 (var isInternal) ifTrue:
			[instIndex _ newModule class instVarNames indexOf: var name.
			 instIndex _ instIndex + newModule class superclass instOffset.
			 newModule instVarAt: instIndex put: var value]].!

isEmpty
	"Answer true if I contain no constraints."

	^constraints isEmpty!

removeExternalPartConstraints: externalConstraints
	"Remove all constraints that appear in the given list. This method is used to remove constraints owned by external parts."

	constraints _ constraints select:
		[: c | (externalConstraints includes: c) not].!

setID: aNumber
	"Set the ID of this partition."

	id _ aNumber.! !

!ModulePartition methodsFor: 'analysis'!

analyzeSolutions
	"Process all the solutions, computing their walkabout strength equations and dependency lists. Filter out any solutions that we don't like."

	| externalVars newSolutions checkEqn |
	"build a dictionary of external variables for use with currentDependencies:"
	externalVars _ IdentityDictionary new.
	varTable do:
		[: var | (var isExternal) ifTrue:
			[externalVars at: var thingData put: var]].

	"examine all solutions"
	newSolutions _ OrderedCollection new: solutions size.
	solutions do:
		[: solution |
		 self apply: solution.
		 checkEqn _ self currentIsPossibleEquation.
		 (checkEqn isFalse not & self solutionOkay) ifTrue:
			[solution isPossibleEquation: checkEqn.
			 solution plan: (self extractPlan).
			 self recordDependencies: externalVars in: solution.
			 newSolutions addLast: solution]].

	"classify the variables"
	varTable do: [: var | var classify].

	solutions _ newSolutions.!

apply: aSolution
	"Apply the given solution, computing ancestors and walk strengths. The latter quantity is computed symbolically since we don't know the walkabout strengths of the external variables at compile time."

	"first, initialize the variables"
	varTable do:
		[: entry |
		 (entry isExternal)
			ifTrue: [entry thingData initExternal: entry]
			ifFalse: [entry thingData initInternal]].

	"then, satisfy all constraints using the methods of the given solution"
	aSolution methods with: constraints do:
		[: method : constraint |
		 (method isNil)
			ifTrue: [constraint whichMethod: nil]
			ifFalse:
				[constraint satisfyWith: method.
				 DeltaBluePlanner
					addPropagateFrom: constraint
					execFlag: false]].!

currentIsPossibleEquation
	"Answer the walkabout strength check equation for the current solution."

	| walkEqn thingDatas orTerm |
	walkEqn _ ModuleConjunction new.
	constraints do:
		[: c |
		 (c isSatisfied) ifFalse:
			["unsatisfied constraints must not demand satisfaction"
			 thingDatas _ c thingDatas.
			 c methods do:
				[: m |
				 orTerm _ ModuleDisjunction new.
				 m outDatasIn: thingDatas do:
				 	[: v |
					 orTerm
						strength: (c strength)
						weakerOrEq: (v walkStrength)].
				 walkEqn addOrTerm: orTerm]]].

	"the propagated walk strengths must be strong enough to override their outputs"
	varTable do:
		[: entry |
		 (entry isOutput) ifTrue:
			[walkEqn var: entry weakerOrEq: entry thingData walkStrength]].

	^walkEqn!

extractPlan
	"Extract a plan for the current solution."

	| thingDatas |
	thingDatas _ IdentitySet new: varTable size.
	varTable do: [: v | thingDatas add: v thingData].
	^(DeltaBluePlanner extractPlanFromThingDatas: thingDatas optimizeStays: false)
		collect: [: c | c whichMethod]!

recordDependencies: externalVarDict in: aSolution
	"Record the variable dependencies and walkabout strength equations for all output variables of the current solution. We only record dependencies among the external variables. Also record the status of all variables to help with later classification."

	| outWalkEqns dependencyList varTD ancestorVars externalAncestor |
	outWalkEqns _ OrderedCollection new.
	dependencyList _ OrderedCollection new.
	varTable do:
		[: var |
		 var recordCurrentStatus.
		 (var isOutput) ifTrue:
			[varTD _ var thingData.
			 outWalkEqns add: varTD walkStrength.
			 ancestorVars _ OrderedCollection new.
			 varTD ancestors do:
				[: ancestorTD |
				 externalAncestor _ externalVarDict at: ancestorTD ifAbsent: [nil].
				 (externalAncestor notNil)
					ifTrue: [ancestorVars add: externalAncestor]].
			 dependencyList add:
				(ModuleDependency
					outVar: var
					dependsOn: ancestorVars
					stay: varTD stay
					stayStrength: varTD walkStrength)]].
	aSolution dependencies: dependencyList.
	aSolution outWalkEqns: outWalkEqns.!

solutionOkay
	"Answer false if we don't like the currently applied solution. We don't like solutions in which all external variables are outputs having walk strengths of absoluteWeakest."

	varTable do:
		[: var |
		 (var isExternal) ifTrue:
			[(var isOutput) ifFalse: [^true].
			 (var thingData walkStrength sameAs: Strength absoluteWeakest)
				ifFalse: [^true]]].
	^false! !

!ModulePartition methodsFor: 'compilation'!

allocateInternalVariables: lastId
	"Give my internal variables names like 'internal3' starting with the first id following lastId. Answer the last id that I allocated."

	| varId |
	varId _ lastId.
	varTable do:
		[: var |
		 (var isInternal) ifTrue:
			[varId _ varId + 1.
			 var name: 'internal', varId printString]].
	^varId!

compileFor: moduleThing
	"Compile the isPossible, execute, and propagate methods for each solution of this partition. Add the compiled methods to the class of the given ModuleThing. It is assumed that the class contains instance variables for the external and internal parts."

	| externalVars methods prefix newConstraint |
	"set up: name variables and collect the external ones"
	self nameVars.
	externalVars _ varTable select: [: v | v isExternal].

	"build a ModuleMethod for each solution"
	methods _ OrderedCollection new: solutions size.
	prefix _ 'p', id printString.
	1 to: solutions size do:
		[: solutionIndex |
		 BusyCursor inc.
		 methods add:
			((solutions at: solutionIndex)
				methodFor: moduleThing
				namePrefix: (prefix, 'm', solutionIndex printString)
				constraints: constraints
				externalVars: externalVars
				varTable: varTable)].

	"construct and bind the new Module constraint"
	newConstraint _ Constraint
		symbols: (externalVars collect: [: v | v name])
		methods: methods.
	newConstraint
		bind: (externalVars collect: [: v | (v reference) root: moduleThing])
		strength: #required.

	"answer the newly created Module constraint"
	^newConstraint!

nameVars
	"Name all my non-internal variables for use during compilation. This must be done after variable classification. The internal variables are named separately using allocateInternalVariables:."

	| externals constants temps |
	externals _ constants _ temps _ 0.
	varTable do:
		[: var |
		 (var isExternal) ifTrue:
			[externals _ externals + 1.
			 var name: 'v', externals printString].
		 (var isConstant) ifTrue:
			[constants _ constants + 1.
			 var name: 'c', constants printString].
		 (var isTemporary) ifTrue:
			[temps _ temps + 1.
			 var name: 't', temps printString]].! !

!ModulePartition methodsFor: 'printing'!

printOn: aStream

	aStream cr; nextPutAll: 'ModulePartition('.
	aStream nextPutAll: constraints size printString.
	((constraints size = 0) | (constraints size > 1))
		ifTrue: [aStream nextPutAll: ' constraints, ']
		ifFalse: [aStream nextPutAll: ' constraint, '].
	aStream nextPutAll: solutions size printString.
	((solutions size = 0) | (solutions size > 1))
		ifTrue: [aStream nextPutAll: ' solutions)']
		ifFalse: [aStream nextPutAll: ' solution)'].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModulePartition class
	instanceVariableNames: ''!


!ModulePartition class methodsFor: 'instance creation'!

on: constraintList
	"Create a new instance of me on the given collection of constraints."

	^self new on: constraintList! !

Collection subclass: #PriorityQueue
	instanceVariableNames: 'contents last '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Layout'!
	

!PriorityQueue methodsFor: 'public'!

add: newElement
	"Insert the given element in the receiver at the proper location."

	(contents size == last) ifTrue:
		["queue is full, so double the size of 'contents' to make room"
		 contents _ contents, (Array new: last)].
	last _ last + 1.
	contents at: last put: newElement.
	newElement index: last.
	self pushUpFrom: last.!

comment
	"The elements of a PriorityQueue must repond to the messages 'index:' and 'index'. The 'index:' message may be a noop but the 'index' message must either answer the last value provided to the element via the 'index:' message or else nil. This behavior is necessary to allow fast relocation of elements when their priorities change."!

do: aBlock
	"Evaluate aBlock with each of the receiver's elements as the argument."

	| i |
	i _ 1.
	[i <= last] whileTrue:
		[aBlock value: (contents at: i).
		 i _ i + 1].!

peekMin
	"Answer the least element of the receiver without removing it."

	(last == 0) ifTrue: [^self errorEmptyCollection].
	"The root is the smallest element."
	^contents at: 1!

relocate: targetElement
	"Find a new position for the given element after it has changed."

	| target parent leftChild |
	target _ targetElement index.
	(target == nil) ifTrue:
		[target _ self indexOfOrNil: targetElement.
		 (target == nil) ifTrue: [^self]].

	parent _ target bitShift: -1.
	(parent == 0)
		ifTrue: ["target is the root; it has no parent"]
		ifFalse:
			[(targetElement < (contents at: parent)) ifTrue:
				["target smaller than parent, push up"
				 ^self pushUpFrom: target]].

	leftChild _ target bitShift: 1.
	(leftChild <= last)
		ifFalse: ["target is a leaf; it has no children"]
		ifTrue:
			[(targetElement > (contents at: leftChild)) ifTrue:
				["target larger than left child, push down"
				 self pushDownFrom: target].
			 (leftChild ~~ last) ifTrue:
				[(targetElement > (contents at: leftChild + 1)) ifTrue:
					["target has, and is larger than, right child, push down"
					 self pushDownFrom: target]]]

	"if we get here, then targetElement did not need to move"!

remove: oldObject ifAbsent: anExceptionBlock

	self shouldNotImplement.!

removeAll
	"Make the receiver empty."

	last _ 0.!

removeMin
	"Remove and answer the least element of the receiver."

	| smallest oldLast |
	(last == 0) ifTrue: [^self errorEmptyCollection].

	"The root is the smallest element."
	smallest _ contents at: 1.

	"Remove the last element and replace the root it. Then push it down."
	oldLast _ contents at: last.
	contents at: last put: nil.
	last _ last - 1.
	contents at: 1 put: oldLast.
	oldLast index: 1.
	self pushDownFrom: 1.
	^smallest!

size
	"Answer how many elements the receiver contains."

	^last! !

!PriorityQueue methodsFor: 'private'!

indexOfOrNil: anElement
	"Answer the index of the given element or nil if it is not in the receiver."

	| i |
	i _ 1.
	[i <= last] whileTrue:
		[((contents at: i) == anElement) ifTrue: [^i].
		 i _ i + 1].
	^nil!

initialize: initialSize
	"Allocate initial space for the given number of elements."

	contents _ Array new: initialSize.
	last _ 0.!

initializeWithVertices: vertexList except: vertexIndex cost: initialCost
	"Special add function for support of ShortestPaths. The receiver is first emptied, then all the elements of the given collection except the vertex with the given index are added without regard to order. The elements are given the specified initial cost."

	| count i element |
	count _ vertexList size.
	(contents size < count) ifTrue:
		[contents _ Array new: count].
	last _ 0.
	i _ 1.
	[i <= count] whileTrue:
		[(i == vertexIndex) ifFalse:
			[element _ vertexList at: i.
		 	 last _ last + 1.
			 contents at: last put: element.
		 	 element index: last.
			 element cost: initialCost].
		 i _ i + 1].!

pushDownFrom: index
	"Push the element at index i down through the tree until it is smaller than its children or until it is a leaf with no children."

	| leaves parent left right child parentElement childElement |
	leaves _ last bitShift: -1.
	parent _ index.
	[parent <= leaves] whileTrue:	"while parent is not a leaf:"
		[left _ parent bitShift: 1.
		 right _ left + 1.
		 (left == last)
			ifTrue:
				["left is an only-child"
				 child _ left]
			ifFalse:
		 		["select the smaller child"
				 ((contents at: left) < (contents at: right))
					ifTrue: [child _ left]
					ifFalse: [child _ right]].
		 parentElement _ contents at: parent.
		 childElement _ contents at: child.
		 (parentElement > childElement)
			ifTrue:
				["push to next level"
				 contents at: parent put: childElement.
				 childElement index: parent.
				 contents at: child put: parentElement.
				 parentElement index: child.
				 parent _ child]
			ifFalse:
				["parent is smaller than its children; cannot push farther"
				 ^self]].
	"pushed all the way to a leaf"
	^self!

pushUpFrom: index
	"Push the element at the given index up through the tree until it is smaller than its children or until it is the root."

	| child parent childElement parentElement |
	child _ index.
	[(child == 1) ifTrue: [^self].	"child is the root, so it has no parent"
	 parent _ child bitShift: -1.
	 childElement _ contents at: child.
	 parentElement _ contents at: parent.
	 (childElement < parentElement)] whileTrue:
		[contents at: child put: parentElement.
		 parentElement index: child.
		 contents at: parent put: childElement.
		 childElement index: parent.
		 child _ parent].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PriorityQueue class
	instanceVariableNames: ''!


!PriorityQueue class methodsFor: 'instance creation'!

new
	"Answer a new instance of me."

	^self new: 10!

new: aNumber
	"Answer a new instance with the given initial size."

	^self basicNew initialize: aNumber! !

StringHolder subclass: #ThingDefiner
	instanceVariableNames: 'client view '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Things-Support'!


!ThingDefiner methodsFor: 'initialize-release'!

client: clientObject
	"Register a client object. This client will be updated with the prototype of the newly defined Thing when the user does 'accept'. My initial text is derived from the Thing currently held by the client. The client may be any object the understands the messages #thing and #thing:. If the client object is nil, a new Thing is created but noone is informed."

	client _ clientObject.
	(client notNil) ifTrue:
		[contents _ client thing definitionString].!

view: aView
	"Set my view to the given view."

	view _ aView.! !

!ThingDefiner methodsFor: 'operation'!

contents: aString
	"Define a new Thing based on the text that the user has just 'accepted'. Notify the client, if any, of the new Thing's prototype."

	| tree thingName partNames parts nonThingPart type newThing |
	tree _  (EquationParser parse: ('dummy ', aString) readStream)
				block statements first.
	(tree isMemberOf: VariableNode) ifTrue:
		[thingName _ tree name asSymbol.
		 ((Smalltalk includesKey: thingName) and:
		   [(Smalltalk at: thingName) inheritsFrom: Thing])
			ifTrue:
				[newThing _ (Smalltalk at: thingName) new.
				 contents _ newThing definitionString.
				 self changed.
				 (client notNil) ifTrue:
					[client thing: newThing].
				 ^self]
			ifFalse:
				[^self error: thingName asString, ' is not a Thing']].
	thingName _ tree receiver name.
	"get partNames and omit trailing colons"
	partNames _ tree selector key keywords.
	partNames _ partNames collect: [: n | n copyFrom: 1 to: n size - 1].
	"get parts"
	nonThingPart _ nil.
	parts _ tree arguments.
	parts _ parts collect:
		[: t |
		 type _ t name asSymbol.
		 ((Smalltalk includesKey: type) and:
		   [(Smalltalk at: type) inheritsFrom: Thing])
			ifTrue: [(Smalltalk at: type) prototype]
			ifFalse: [nonThingPart]].
	newThing _ Thing
		defineNewThingNamed: thingName
		withParts: partNames
		toHold: parts.
	(client notNil) ifTrue:
		[client thing: newThing].
	(view notNil) ifTrue:
		[view model updateCaches.
		 view displaySafe: [view displayView]].!

open
	"Open a view for this ThingDefiner. This call does not return."
	"ThingDefiner open"

	| thingDefinerView topView |
	thingDefinerView _ StringHolderView container: self.
	topView _ SpecialSystemView new.
	topView borderWidth: 1.
	topView model: thingDefinerView model.
	topView addSubView: thingDefinerView.
	topView label: 'Thing Definer'.
	topView minimumSize: 100@50.
	topView icon: (Icon constantNamed: #default).
	topView controller open! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ThingDefiner class
	instanceVariableNames: ''!


!ThingDefiner class methodsFor: 'instance creation'!

open
	"Open a new ThingDefiner with no client object or view."
	"ThingDefiner open"

	(self new)
		client: nil;
		view: nil;
		open!

openOn: clientObject view: aView
	"Open a new ThingDefiner for the given client object. The client should understand the messages #thing and #thing:. The view, if non-nil, is updated after the client is changed."

	(self new)
		client: clientObject;
		view: aView;
		open! !

Object subclass: #ModuleDependency
	instanceVariableNames: 'outVar dependsOn stay stayStrength '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Module Compiler'!
ModuleDependency comment:
'I am used to record the input/output relationships between external variables for one solution of one partition during the Module compilation process.'!


!ModuleDependency methodsFor: 'access'!

dependsOn
	"Answer the variables on which outVar depends."

	^dependsOn!

outVar
	"Answer the output variable of this dependency."

	^outVar!

outVar: aVar dependsOn: varList stay: stayFlag stayStrength: aStrength
	"Initialize myself with the given values. aVar is dependent on the variables in varList. If stayFlag is true, then the outputs are stay with the given strength. If false, then the output stay flags are must be computed at run time as the logical 'AND' of the input stay flags and the output strengths must be computed by evaluating strength equations."

	outVar _ aVar.
	dependsOn _ varList asOrderedCollection copy.
	stay _ stayFlag.
	(stay == true)
		ifTrue: [stayStrength _ aStrength]
		ifFalse: [stayStrength _ nil].	"stayStrength is undefined if stay is false"!

stay

	^stay!

strengthString
	"Answer an expression representing the strength at which I am fixed. This operation should only be called if I answer true to the #stay message."

	^stayStrength storeString! !

!ModuleDependency methodsFor: 'printing'!

printOn: aStream

	aStream nextPut: $[.
	outVar printOn: aStream.
	aStream nextPutAll: ' depends on: '.
	dependsOn do:
		[: var |
		 var printOn: aStream.
		 aStream space].
	(dependsOn isEmpty) ifFalse: [aStream skip: -1].
	aStream nextPut: $]; cr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModuleDependency class
	instanceVariableNames: ''!


!ModuleDependency class methodsFor: 'instance creation'!

outVar: aVar dependsOn: varList stay: stayFlag stayStrength: aStrength
	"Create and answer a new dependency relation."

	^(self new)
		outVar: aVar
		dependsOn: varList
		stay: stayFlag
		stayStrength: aStrength! !

Object subclass: #Strength
	instanceVariableNames: 'symbolicValue arithmeticValue '
	classVariableNames: 'AbsoluteStrongest AbsoluteWeakest Required StrengthConstants StrengthTable '
	poolDictionaries: ''
	category: 'ThingLabII'!
Strength comment:
'Strengths are used to measure the relative priority of constraints. The hierarchy of available strengths is determined by the class variable StrengthTable (see my class initialization method). Because Strengths are invariant, references to Strength instances are shared (i.e. all references to "Strength of: #required" point to the same instance). New strengths may be inserted in the strength hierarchy.'!


!Strength methodsFor: 'comparing'!

leq: aStrength
	"This is shorthand for 'notStronger: aStrength' (read 'less-than or equal'). This cryptic message is used to make the code for module method 'isPossible' tests more consise and readable. The code given is equivalent to '(self stronger: strength2) not'."

	^arithmeticValue >= aStrength arithmeticValue!

notStronger: aStrength
	"Answer true if I am the same or weaker than the given Strength. This code is equivalent to:

	^(self stronger: aStrength) not"

	^arithmeticValue >= aStrength arithmeticValue!

sameAs: aStrength
	"Answer true if I am the same strength as the given Strength."

	^arithmeticValue = aStrength arithmeticValue!

stronger: aStrength
	"Answer true if I am stronger than the given Strength."

	^arithmeticValue < aStrength arithmeticValue!

weaker: aStrength
	"Answer true if I am weaker than the given Strength."

	^arithmeticValue > aStrength arithmeticValue! !

!Strength methodsFor: 'max/min'!

strongest: aStrength
	"Answer the stronger of myself and aStrength."

	(aStrength class == WalkEquation) ifTrue:
		[^aStrength strongest: self].

	(aStrength stronger: self)
		ifTrue: [^aStrength]
		ifFalse: [^self].!

weakest: aStrength
	"Answer the weaker of myself and aStrength."

	(aStrength class == WalkEquation) ifTrue:
		[^aStrength weakest: self].

	(aStrength weaker: self)
		ifTrue: [^aStrength]
		ifFalse: [^self].! !

!Strength methodsFor: 'printing'!

printOn: aStream
	"Append a string which represents my strength onto aStream."

	aStream nextPutAll: '%', symbolicValue, '%'.!

storeOn: aStream

	aStream nextPutAll: '(Strength of: #', self asSymbol, ')'.! !

!Strength methodsFor: 'converting'!

asSymbol
	"Answer myself as a symbol."

	^symbolicValue! !

!Strength methodsFor: 'private'!

arithmeticValue
	"Answer my arithmetic value. Used for comparisons. Note that STRONGER constraints have SMALLER arithmetic values."

	^arithmeticValue!

initializeWith: symVal
	"Record my symbolic value and reset my arithmetic value."

	symbolicValue _ symVal.
	self resetValue.!

resetValue
	"Lookup my symbolic value in the StrengthTable and reset my internal value."

	arithmeticValue _ StrengthTable at: symbolicValue.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Strength class
	instanceVariableNames: ''!


!Strength class methodsFor: 'instance creation'!

of: aSymbol
	"Answer an instance with the specified strength."

	^StrengthConstants at: aSymbol! !

!Strength class methodsFor: 'class initialization'!

initialize
	"Initialize the symbolic strength table. Fix the internally caches values of all existing instances."
	"Strength initialize"

	StrengthTable _ Dictionary new.
	StrengthTable at: #absoluteStrongest put: -1000.
	StrengthTable at: #required put: 0.
	StrengthTable at: #strongPreferred put: 1.
	StrengthTable at: #preferred put: 2.
	StrengthTable at: #strongDefault put: 3.
	StrengthTable at: #default put: 4.
	StrengthTable at: #weakDefault put: 5.
	StrengthTable at: #absoluteWeakest put: 1000.

	StrengthConstants _ Dictionary new.
	StrengthTable associations do:
		[: assoc |
			StrengthConstants
				at: (assoc key)
				put: ((super new) initializeWith: (assoc key))].

	"Fix arithmetic values stored in all instances."
	Strength allInstancesDo:
		[: strength | strength resetValue].

	AbsoluteStrongest _ Strength of: #absoluteStrongest.
	AbsoluteWeakest _ Strength of: #absoluteWeakest.
	Required _ Strength of: #required.! !

!Strength class methodsFor: 'constants'!

absoluteStrongest

	^AbsoluteStrongest!

absoluteWeakest

	^AbsoluteWeakest!

required

	^Required! !

Object subclass: #NeedToClone
	instanceVariableNames: 'data '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Things'!
NeedToClone comment:
'During cloning, the NeedToClone class is used to mark those instance variables in a Thing that have not yet been cloned. For example, a copy of a Thing is made and then some of the instance variables are replaced by doing:

	constraints _ (NeedToClone with: constraints).

This indicates that constraints still needs cloning, and that the old value is available as ''constraints data''.
'!


!NeedToClone methodsFor: 'access'!

data

	^data!

data: anObject

	data _ anObject.! !

!NeedToClone methodsFor: 'printing'!

printOn: aStream

	aStream nextPutAll: 'NeedToClone('.
	data printOn: aStream.
	aStream nextPutAll: ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NeedToClone class
	instanceVariableNames: ''!


!NeedToClone class methodsFor: 'instance creation'!

with: anObject

	^self new data: anObject! !

Object subclass: #Partitioner
	instanceVariableNames: 'unexamined '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Module Compiler'!
Partitioner comment:
'I am used to divide the constraints of a constraint graph into a set of disjoint partitions.'!


!Partitioner methodsFor: 'public'!

partition: aThing
	"Partition all constraints on aThing and its subparts."

	| thingDatas |
	thingDatas _ IdentitySet new: 50.
	aThing allThingDatasInto: thingDatas.
	^self partitionThingDatas: thingDatas!

partitionConstraints: constraints
	"Similar to partition:, but starts with a set of constraints rather than a Thing."

	| thingDatas |
	thingDatas _ IdentitySet new: 50.
	constraints do:
		[: c |
		 c variables do:
			[: v | thingDatas add: v thingData]].
	^self partitionThingDatas: thingDatas!

partitionThingDatas: thingDatas
	"Partition all constraints on parts of aThing."

	| mark partitions |
	mark _ self chooseMark.
	unexamined _ thingDatas asOrderedCollection.
	partitions _ OrderedCollection new: 100.
	[unexamined isEmpty] whileFalse:
		[partitions addLast: (self extractPartition: mark)].
	^partitions! !

!Partitioner methodsFor: 'private'!

chooseMark
	"Select a mark value."

	^Time millisecondClockValue max: 1!

extractPartition: mark
	"Extract a partition. A partition is a collection of related constraints."

	| partition toDo td |
	partition _ IdentitySet new: 50.		"constraints in this partition"
	toDo _ OrderedCollection new: 50.		"thingDatas to examine further"
	toDo add: unexamined first.
	[toDo isEmpty] whileFalse:
		[td _ toDo removeFirst.
		 (td mark == mark) ifFalse:
			[unexamined remove: td ifAbsent: [].	"td is in this partition"
			 td mark: mark.
			 td constraints do:
				[: c |
				 partition add: c.
				 c variables do:
					[: ref | toDo add: ref thingData]]]].
	^partition asOrderedCollection! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Partitioner class
	instanceVariableNames: ''!


!Partitioner class methodsFor: 'general inquiries'!

partition: aThing
	"Partition the constraints of the given Thing. Answer a collection of constraint lists, one for each partition. Each constraint of the given Thing will appear in exactly one of the partitions."

	^self new partition: aThing! !

Object subclass: #EquationTranslator
	instanceVariableNames: 'theEquationTree theVariables '
	classVariableNames: 'ReorderRules RestructureRules '
	poolDictionaries: ''
	category: 'ThingLabII-Equations'!


!EquationTranslator methodsFor: 'public access'!

computeMethods
	"Attempt to solve the equation for each variable and answer an Array of assignment statements (as strings, not parse trees) containing the solutions."

	| newTree stream body |
	^theVariables asArray collect: 
		[: var |
		 newTree _ theEquationTree transformBy: [: node | node].		"copy tree"
		 newTree _ newTree restructureForAssigningTo: var.
		 "build the assignment statement string in stream"
		 stream _ (String new: 100) writeStream.
		 stream nextPutAll: var asString.
		 stream nextPutAll: ' _ '.
		 body _ newTree arguments first printString.
		 body _ body copyFrom: 2 to: body size - 1.	"strip off {} brackets"
		 stream nextPutAll: body.
		 stream contents]!

setEquationString: aString
	"Initialize myself from the given equation string. Parse the string and collect a list of the equation's variables."

	| parseTree |
	parseTree _ EquationParser parse: ('dummy ', aString) readStream.
	theEquationTree _ parseTree block statements first.
	theVariables _ theEquationTree allVariables asOrderedCollection.

	(parseTree block statements size > 2) ifTrue:
		[self error: 'Equations may not have multiple statements:
	', parseTree block printString].

	((theEquationTree isMemberOf: MessageNode) and:
	  [theEquationTree selector key = #=]) ifFalse:
		[self error: 'This is not an equality equation:
	', theEquationTree printString].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EquationTranslator class
	instanceVariableNames: ''!


!EquationTranslator class methodsFor: 'class initialization'!

initialize
	"This is a simple set of rules for manipulating equations. It has three inherent limitations. First, many of the functions that the Numbers class supports are not one-to-one. The inverse of such functions was chosen arbitrarily. Second, the inverse of some functions is not onto, thus functions like max: are not supported. Finally, rewriting boolean expressions will produce equations that this rewriting system cannot further rewrite."
	"EquationTranslator initialize"

	ReorderRules _ OrderedCollection new.
	RestructureRules _ OrderedCollection new.

	self initializeNormalArithmeticRules.
	self initializeSpecialArithmeticRules.	"these have non-unique inverses"
	self initializeUnaryFunctionRules.
	self initializeTrigFunctionRules.
	self initializeMathematicalFunctionRules.
	self initializeSpecialFunctionRules.
	self initializeCoercingRules.

	"The following rules can be removed if booleans are not needed:"
	self initializeTestingRules.			"these have non-unique inverses"
	self initializeComparingRules.		"these have non-unique inverses"
	self initializeBooleanFunctionRules.!

initializeBooleanFunctionRules

	| tr |
	tr _ TranslationRule.	"abbreviation"
	ReorderRules
		add: (tr from: 'a & b' to: 'b & a');
		add: (tr from: 'a | b' to: 'b | a');
		add: (tr from: 'a xor: b' to: 'b xor: a').
	RestructureRules
		add: (tr from: 'a not = b' to: 'a = b not');
		"add: (tr from: '(a & b) = c' to: 'a = c');"		"???"
		"add: (tr from: '(a | b) = c' to: 'a = c');"			"???"
		add: (tr from: '(a xor: b) = c' to: 'a = (b xor: c)').!

initializeCoercingRules

	| tr |
	tr _ TranslationRule.	"abbreviation"
	RestructureRules
		add: (tr from: 'a asFloat = b' to: 'a = b');
		add: (tr from: 'a asInteger = b' to: 'a = b');
		add: (tr from: 'a asFraction = b' to: 'a = b').!

initializeComparingRules

	| tr |
	tr _ TranslationRule.	"abbreviation"
	RestructureRules
		add: (tr from: '(a < b) = c' to: 'a = (c ifTrue: [b - 1] ifFalse: [b])');
		add: (tr from: '(a < b) = c' to: 'b = (c ifTrue: [a + 1] ifFalse: [a])');
		add: (tr from: '(a <= b) = c' to: 'a = (c ifTrue: [b] ifFalse: [b + 1])');
		add: (tr from: '(a <= b) = c' to: 'b = (c ifTrue: [a] ifFalse: [a - 1])');
		add: (tr from: '(a = b) = c' to: 'a = (c ifTrue: [b] ifFalse: [b + 1])');
		add: (tr from: '(a = b) = c' to: 'b = (c ifTrue: [a] ifFalse: [a + 1])');
		add: (tr from: '(a ~= b) = c' to: 'a = (c ifTrue: [b + 1] ifFalse: [b])');
		add: (tr from: '(a ~= b) = c' to: 'b = (c ifTrue: [a + 1] ifFalse: [a])');
		add: (tr from: '(a > b) = c' to: 'a = (c ifTrue: [b + 1] ifFalse: [b])');
		add: (tr from: '(a > b) = c' to: 'b = (c ifTrue: [a - 1] ifFalse: [a])');
		add: (tr from: '(a >= b) = c' to: 'a = (c ifTrue: [b] ifFalse: [b - 1])');
		add: (tr from: '(a >= b) = c' to: 'b = (c ifTrue: [a] ifFalse: [a + 1])').!

initializeMathematicalFunctionRules

	| tr |
	tr _ TranslationRule.	"abbreviation"
	RestructureRules
		add: (tr from: 'a exp = b' to: 'a = b ln');
		add: (tr from: 'a ln = b' to: 'a = b exp');
		add: (tr from: '(a log: b) = c' to: 'a = (b raisedTo: c)');
		add: (tr from: '(a log: b) = c' to: 'b = (a raisedTo: c reciprocal)');
		add: (tr from: '(a raisedTo: b) = c' to: 'a = (a raisedTo: b reciprocal)');
		add: (tr from: '(a raisedTo: b) = c' to: 'b = (c log: a)').!

initializeNormalArithmeticRules

	| tr |
	tr _ TranslationRule.	"abbreviation"
	ReorderRules
		add: (tr from: 'a = b' to: 'b = a');
		add: (tr from: 'a + b' to: 'b + a');
		add: (tr from: 'a - b' to: 'b negated + a');
		add: (tr from: 'a * b' to: 'b * a').
	RestructureRules
		add: (tr from: '(a + b) = c' to: 'a = (c - b)');
		add: (tr from: '(a - b) = c' to: 'a = (b + c)');
		add: (tr from: '(a * b) = c' to: 'a = (c / b)');
		add: (tr from: '(a / b) = c' to: 'a = (b * c)');
		add: (tr from: '(a / b) = c' to: 'b = (a / c)').!

initializeSpecialArithmeticRules

	| tr |
	tr _ TranslationRule.	"abbreviation"
	RestructureRules
		add: (tr from: '(a // b) = c' to: 'a = (b * c)');
		add: (tr from: '(a // b) = c' to: 'b = (a // c)');
		add: (tr from: '(a quo: b) = c' to: 'a = (b * c)');
		add: (tr from: '(a quo: b) = c' to: 'b = (a quo: c)');
		add: (tr from: '(a rem: b) = c' to: 'a = c');
		add: (tr from: '(a rem: b) = c' to: 'b = (a - c)');
		add: (tr from: '(a \\ b) = c' to: 'a = c');
		add: (tr from: '(a \\ b) = c' to: 'b = (a - c)');
		add: (tr from: '(a roundTo: b) = c' to: 'a = c');
		add: (tr from: '(a roundTo: b) = c' to: 'b = c');
		add: (tr from: '(a truncateTo: b) = c' to: 'a = c');
		add: (tr from: '(a truncateTo: b) = c' to: 'b = c').!

initializeSpecialFunctionRules

	| tr |
	tr _ TranslationRule.	"abbreviation"
	RestructureRules
		add: (tr from: '(a @ b) = c' to: 'a = c x');
		add: (tr from: '(a @ b) = c' to: 'b = c y');
		add: (tr from: 'a degreesToRadians = b' to: 'a = b radiansToDegrees');
		add: (tr from: 'a radiansToDegrees = b' to: 'a = b degreesToRadians');
		add: (tr from: 'a asPoint = b' to: 'a = b x').!

initializeTestingRules

	| tr |
	tr _ TranslationRule.	"abbreviation"
	RestructureRules
		add: (tr from: 'a even = b' to: 'a = (b ifTrue: [0] ifFalse: [1])');
		add: (tr from: 'a odd = b' to: 'a = (b ifTrue: [1] ifFalse: [0])');
		add: (tr from: 'a negative = b' to: 'a = (b ifTrue: [-1] ifFalse: [0])');
		add: (tr from: 'a positive = b' to: 'a = (b ifTrue: [1] ifFalse: [-1])');
		add: (tr from: 'a strictlyPositive = b' to: 'a = (b ifTrue: [1] ifFalse: [0])');
		add: (tr from: 'a sign = b' to:  'a = b').!

initializeTrigFunctionRules

	| tr |
	tr _ TranslationRule.	"abbreviation"
	RestructureRules
		add: (tr from: 'a arcCos = b' to: 'a = b cos');
		add: (tr from: 'a cos = b' to: 'a = b arcCos');
		add: (tr from: 'a arcSin = b' to: 'a = b sin');
		add: (tr from: 'a sin = b' to: 'a = b arcSin');
		add: (tr from: 'a arcTan = b' to: 'a = b tan');
		add: (tr from: 'a tan = b' to: 'a = b arcTan').!

initializeUnaryFunctionRules

	| tr |
	tr _ TranslationRule.	"abbreviation"
	RestructureRules
		add: (tr from: 'a abs = b abs' to: 'a = b abs');
		add: (tr from: 'a abs = b' to: 'a = b abs');
		add: (tr from: 'a negated = b negated' to: 'a = b');
		add: (tr from: 'a negated = b' to: 'a = b negated');
		add: (tr from: 'a reciprocal = b' to: 'a = b reciprocal');
		add: (tr from: 'a sqrt = b' to: 'a = b squared');
		add: (tr from: 'a squared = b' to: 'a = b sqrt');
		add: (tr from: 'a ceiling = b' to: 'a = b');
		add: (tr from: 'a floor = b' to: 'a = b');
		add: (tr from: 'a rounded = b' to: 'a = b');
		add: (tr from: 'a truncated = b' to: 'a = b').! !

!EquationTranslator class methodsFor: 'accessing'!

reorderRules

	^ReorderRules!

restructureRules

	^RestructureRules! !

!EquationTranslator class methodsFor: 'translating'!

methodsFor: equationString
	"Answer an array of assignment statement strings that represent the various inversions of the given equation. For example, the methods for 'a = (b + c)' are 'a _ b + c', 'b _ a - c', and 'c _ a - b'. The top level expression must be an '=' expression. Note that due to Smalltalk's left-to-right evaluation order, the top level expression of 'a = b + c' is the '+' expression, NOT the '=' expression; use parenthesis if necessary."

	^(super new)
		setEquationString: equationString;
		computeMethods! !


StringHolder subclass: #ConstraintDefiner
	instanceVariableNames: 'client view '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Things-Support'!


!ConstraintDefiner methodsFor: 'initialize-release'!

client: clientObject
	"Register a client object. This client will be updated with the prototype of the newly defined constraint when the user does 'accept'. My initial text is derived from the constraint currently held by the client. The client may be any object the understands the messages #baseConstraint, #baseConstraint:, #baseStrength, and #baseStrength:."

	client _ clientObject.
	contents _
		clientObject baseStrength, '\' withCRs,
		clientObject baseConstraint definitionString.!

view: aView
	"Set my view to the given view."

	view _ aView.! !

!ConstraintDefiner methodsFor: 'operation'!

buildConstraint: defString methods: methodStrings

	| parseTree strength varNames paths full root constraint |
	parseTree _  (EquationParser parse: ('dummy ', defString) readStream)
				block statements first.
	"get strength (the receiver name)"
	strength _ parseTree receiver name asSymbol.
	"get constraint variable names (the message keywords, minus colons)"
	varNames _ parseTree selector key keywords
					collect: [: n | (n copyFrom: 1 to: n size - 1) asSymbol].
	"get paths (the message arguments)"
	paths _ parseTree arguments collect:
		[: arg |
		 full _ arg name asSymbol path.
		 root _ full first.
		 Reference on: root path: (full copyFrom: 2 to: full size)].
	constraint _ Constraint symbols: varNames methodStrings: methodStrings.
	constraint partlyBind: paths asArray.
	^Array with: constraint with: strength!

contents: aString

	| pieces constraintDef methodDefs constraintAndStrength |
	pieces _ self splitIntoPieces: aString.
	(pieces size > 1)
		ifTrue:
			[constraintDef _ pieces first.
			 methodDefs _ pieces copyFrom: 2 to: pieces size.
			 constraintAndStrength _
				self buildConstraint: constraintDef methods: methodDefs.
			 client baseConstraint: (constraintAndStrength at: 1).
			 client baseStrength: (constraintAndStrength at: 2)]
		ifFalse: [client baseConstraint: nil].

	(view notNil) ifTrue:
		[view model updateCaches.
		 view displaySafe: [view displayView]].!

open
	"Open a view for this ConstraintDefiner. This call does not return."

	| constraintDefinerView topView |
	constraintDefinerView _ StringHolderView container: self.
	topView _ SpecialSystemView new.
	topView borderWidth: 1.
	topView model: constraintDefinerView model.
	topView addSubView: constraintDefinerView.
	topView label: 'Constraint Definer'.
	topView minimumSize: 100@50.
	topView icon: (Icon constantNamed: #default).
	topView controller open.!

splitIntoPieces: aString
	"Answer a collection of pieces for the given string. The pieces of the input string are separated by blank lines."

	| newLine pieces sourceStream pieceStream lastCharWasNewLine ch hasContent |
	newLine _ Character cr.
	pieces _ OrderedCollection new: 10.
	sourceStream _ aString readStream.
	[sourceStream atEnd] whileFalse:
		[pieceStream _ (String new: 100) writeStream.
		 lastCharWasNewLine _ false.
		 hasContent _ false.
		 [(sourceStream atEnd not) and:
		   [(lastCharWasNewLine & ((ch _ sourceStream next) = newLine)) not]]
			whileTrue:
				[pieceStream nextPut: ch.
				 (ch isSeparator) ifFalse: [hasContent _ true].
				 lastCharWasNewLine _ (ch = newLine)].
		 (hasContent) ifTrue: [pieces addLast: pieceStream contents]].
	^pieces! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ConstraintDefiner class
	instanceVariableNames: ''!


!ConstraintDefiner class methodsFor: 'instance creation'!

openOn: clientObject view: aView
	"Open a new ConstraintDefiner for the given client object. The client should understand the messages #baseConstraint, #baseConstraint:, #baseStrength, and #baseStrength:. The view, if non-nil, is updated after the constraint is changed."

	(self new)
		client: clientObject;
		view: aView;
		open! !

Object subclass: #ThingData
	instanceVariableNames: 'allConstraints determinedBy usedBy walkStrength stay mark '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Things'!
ThingData comment:
'I store the planner data that must be attached to each constrained part of a Thing. Currently this data is specific to the DeltaBlue algorithm, but it could be extended to support other planners.

Instance variables:
	walkStrength...	the Walkabout strength of my part <Strength>
	stayFlag...		true if my part will not change <Boolean>
	allConstraints...	all the constraints that reference my part {Constraint}
	determinedBy...	the constraint that currently determines
					my part''s value or nil if there isn''t one <Constraint>
	usedBy...			constraints that currently use my part
					as an input {Constraint}
	ancestors...		references to all the ThingDatas used to compute
					my part {ThingData}
'!


!ThingData methodsFor: 'initialize-release'!

destroy

	allConstraints _ nil.
	determinedBy _ nil.
	usedBy _ nil.
	walkStrength _ nil.
	stay _ nil.
	mark _ nil.!

initialize

	allConstraints _ Array new.
	determinedBy _ nil.
	usedBy _ Array new.
	walkStrength _ Strength absoluteWeakest.
	stay _ true.
	mark _ 0.! !

!ThingData methodsFor: 'access'!

addConstraint: aConstraint
	"Add the given constraint to the set of constraints that refer to me."

	(allConstraints includes: aConstraint) ifFalse:
		[allConstraints _ allConstraints copyWith: aConstraint].!

addUsedBy: aConstraint
	"Add the given constraint to the set of constraints that use me as an input in the current dataflow."

	(usedBy includes: aConstraint) ifFalse:
		[usedBy _ usedBy copyWith: aConstraint].!

constraints
	"Answer the set of constraints that refer to me."

	^allConstraints!

determinedBy
	"Answer the constraint that determines me in the current dataflow."

	^determinedBy!

determinedBy: aConstraint
	"Set the given constraint to be the one that determines me in the current data flow."

	determinedBy _ aConstraint.!

mark
	"Answer my mark value."

	^mark!

mark: markValue
	"Set my mark value."

	mark _ markValue.!

removeConstraint: aConstraint
	"Remove the given constraint from the set of constraints that refer to me."

	allConstraints _ allConstraints copyWithout: aConstraint.!

removeUsedBy: aConstraint
	"Remove the given constraint from the set of constraints that use me as an input in the current dataflow."

	usedBy _ usedBy copyWithout: aConstraint.!

stay
	"Answer my stay value."

	^stay!

stay: aBoolean
	"Set my stay value."

	stay _ aBoolean.!

usedBy
	"Answer the set of constraints that use me as an input in the current dataflow."

	^usedBy!

walkStrength
	"Answer my walkabout strength in the current dataflow."

	^walkStrength!

walkStrength: aStrength
	"Set my walkabout strength in the current dataflow."

	walkStrength _ aStrength.!

ws
	"Shorthand for 'walkStrength' to make module 'isPossiblexxx' methods more readable."

	^walkStrength! !

!ThingData methodsFor: 'module compiler'!

ancestors
	"Answer the ThingDatas of all variables on which my variable depends (i.e. all upstream variables), including myself."

	| processed ancestors todo c |
	processed _ IdentitySet new: 20.	"processed constraints"
	ancestors _ OrderedCollection new: 100.
	ancestors add: self.
	todo _ OrderedCollection new: 100.
	todo add: self.
	[todo isEmpty] whileFalse:
		[c _ todo removeFirst determinedBy.
		 (c notNil and: [(processed includes: c) not]) ifTrue:
			[processed add: c.
			 c whichMethod inDatasIn: c thingDatas do:
				[: in |
				 todo add: in.
				 ancestors add: in]]].
	^ancestors!

initExternal: varEntry

	determinedBy _ nil.
	usedBy _ Array new.
	walkStrength _ WalkEquation external: varEntry.
	self stay: false.!

initInternal

	determinedBy _ nil.
	usedBy _ Array new.
	walkStrength _ Strength absoluteWeakest.
	self stay: true.! !

!ThingData methodsFor: 'printing'!

longPrintOn: aStream

	self shortPrintOn: aStream.
	aStream nextPutAll: 'Referenced by: '.
	(allConstraints isEmpty)
		ifTrue: [aStream nextPutAll: 'nobody']
		ifFalse:
			[allConstraints do:
				[: c | aStream cr; tab. c shortPrintOn: aStream]].
	aStream cr; nextPutAll: 'Determined by: '.
	(determinedBy isNil)
		ifTrue: [aStream nextPutAll: 'nobody']
		ifFalse: [aStream cr; tab. determinedBy shortPrintOn: aStream].
	aStream cr; nextPutAll: 'Used by: '.
	(usedBy isEmpty)
		ifTrue: [aStream nextPutAll: 'nobody']
		ifFalse:
			[usedBy do:
				[: c | aStream cr; tab. c shortPrintOn: aStream]].
	aStream cr.!

printOn: aStream

	(Sensor leftShiftDown)
		ifTrue: [self longPrintOn: aStream]
		ifFalse: [self shortPrintOn: aStream].!

shortPrintOn: aStream

	aStream nextPutAll: 'TD(', self asOop printString, ', '.
	aStream nextPutAll: walkStrength printString, ', '.
	aStream nextPutAll: (self stay ifTrue: ['stay'] ifFalse: ['not stay']).
	aStream nextPutAll: ')'.
	aStream cr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ThingData class
	instanceVariableNames: ''!


!ThingData class methodsFor: 'instance creation'!

new

	^super new initialize! !

View subclass: #SceneView
	instanceVariableNames: 'scrollOffset enclosingRect backgroundForm scratchForm visibleForeground selectedForeground '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Framework'!
SceneView comment:
'This class is used to display a Scene. The picture may be scrolled by adjusting ''scrollOffset''. The default controller for SceneView is SceneController.

SceneViews encapsulate the notion of a changing foreground and a fixed background during interactive updates. During an interaction (such as dragging), some glyphs may not change location or appearance. These are part of the "background". All remaining glyphs ("foreground" glyphs) are painted against this unchanging backdrop during the interaction.

Instance Variables:
	scrollOffset			the current scroll offset of this view
	enclosingRect 		a rectangle large enough to contain all the objects in the scene, plus a small border (this is a cache that must be recomputed when glyphs are moved, added, or removed from the scene)

The following instance variables are only meaningful after ''computeBackground'' has been sent:
	backgroundForm		a <Form> containing the fixed background
	visibleForeground		glyphs that are changing but not selected during an interaction
	selectedForeground	selected glyphs that are changing during an interaction'!


!SceneView methodsFor: 'initialize-release'!

initialize

	super initialize.
	scrollOffset _ 0@0.
	enclosingRect _ nil.! !

!SceneView methodsFor: 'label access'!

newLabel: aString
	"Change my label to be the given string."

	self topView deEmphasize.
	self topView newLabel: aString.
	self topView emphasize.! !

!SceneView methodsFor: 'displaying'!

computeBackground
	"Compute the backgroundForm and the two lists, visibleForeground and selectedForeground. These are used by the 'displayFeedback' and 'displayFeedbackWithBox:width:' operations."

	| viewExtent viewOrigin clipBox |
	viewExtent _ self enclosingRectangle rounded extent max: self insetDisplayBox extent.
	backgroundForm _ Form extent: viewExtent depth: 32. backgroundForm fillWhite.
	scratchForm _ Form extent: viewExtent depth: 32. scratchForm fillWhite.
	viewOrigin _ self viewOrigin.
	clipBox _ backgroundForm computeBoundingBox.
	self displayBorderOn: backgroundForm at: viewOrigin clippingBox: clipBox.

	visibleForeground _ OrderedCollection new: 100.
	model visibleGlyphs do:
		[: g |
		 (model isChanging: g)
			ifTrue: [visibleForeground add: g]
			ifFalse: [g displayOn: backgroundForm at: viewOrigin clippingBox: clipBox]].

	selectedForeground _ OrderedCollection new: 100.
	model selected do:
		[: g |
		 (model isChanging: g)
			ifTrue: [selectedForeground add: g]
			ifFalse: [g highlightOn: backgroundForm at: viewOrigin clippingBox: clipBox]].!

displayBorderOn: aDisplayMedium at: aPoint clippingBox: clipBox
	"Draw a boundary line that encloses all glyphs in the scene."

	| borderBox |
	borderBox _ (aPoint + enclosingRect origin) extent:
					(enclosingRect extent max: clipBox extent).
	borderBox _ borderBox insetOriginBy: 4@4 cornerBy: 4@4.
	aDisplayMedium
		border: borderBox
		widthRectangle: (1@1 corner: 1@1)
		fillColor: (Color gray)
		clippingBox: clipBox.

	"display cross hairs at origin"
	aDisplayMedium black: (aPoint + (2@4) extent: 5@1).
	aDisplayMedium black: (aPoint + (4@2) extent: 1@5).!

displayFeedback
	"Update my display during a user interaction. The client must have called 'computeBackgroundWhileChanging:' to prepare for this operation."

	self displayFeedbackWithBox: nil width: nil.!

displayFeedbackWithBox: aRectangle width: w
	"Update my display during a user interaction. The client must have called 'computeBackgroundWhileChanging:' to prepare for this operation. If it is not nil, the given rectangle (in model coordinates) is drawn with the given border width as additional feedback."

	| viewOrigin clipBox |
	viewOrigin _ self viewOrigin.
	clipBox _ backgroundForm computeBoundingBox.
	backgroundForm displayOn: scratchForm at: 0@0.
	visibleForeground do:
		[: g | g displayOn: scratchForm at: viewOrigin clippingBox: clipBox].
	selectedForeground do:
		[: g | g highlightOn: scratchForm at: viewOrigin clippingBox: clipBox].
	(aRectangle notNil) ifTrue:
		[scratchForm
			border: (aRectangle translateBy: viewOrigin)
			widthRectangle: (w@w corner: w@w)
			fillColor: (Color black)
			clippingBox: clipBox].
	scratchForm
		displayOn: Display
		at: self insetDisplayBox origin + scrollOffset
		clippingBox: self insetDisplayBox.!

displayScene
	"Display the scene."

	self computeBackground.
	self displayFeedback.!

displayView
	"This method is called by the system when the top view is framed or moved."

	"adjust offset in case the view has been resized"
	self scrollOffset: scrollOffset.
	self displayScene.! !

!SceneView methodsFor: 'controller access'!

defaultControllerClass

	^SceneController! !

!SceneView methodsFor: 'scrolling'!

scrollOffset
	"Answer my scrolling offset."

	^scrollOffset!

scrollOffset: aPoint
	"Set my scroll offset after first limiting it to lie within the envelope of permissible values."

	| limits |
	limits _ self scrollOffsetLimits.
	scrollOffset _ (aPoint max: limits origin) min: limits corner.!

scrollOffsetLimits
	"Answer the envelope of possible offset values (a possibly empty rectangle in the upper-left quadrant of the Cartesian plane)."

	| extent |
	extent _ (self enclosingRectangle extent - self insetDisplayBox extent) max: 0@0.
	^(0@0 - extent) corner: 0@0! !

!SceneView methodsFor: 'coordinates'!

computeEnclosingRectangle
	"Compute a rectangle capable of enclosing all glyphs in this view. The rectangle's corners are computed and then expanded to allow room for a border. This method should be called any time glyphs are added, removed or moved."

	| min max b |
	min _ 6@6.
	max _ 6@6.
	model allGlyphs do:
		[: g |
		 b _ g boundingBox.
		 min _ min min: b origin.
		 max _ max max: b corner].
	enclosingRect _ (min - (6@6)) corner: (max + (6@6)).!

displayToModelPoint: aDisplayPoint
	"Converts the given point in Display coordinates to the corresponding point in model coordinates."

	^enclosingRect origin + (aDisplayPoint - self insetDisplayBox origin) - scrollOffset!

enclosingRectangle
	"Answer a rectangle capable of enclosing all glyphs in this view. This rectangle is expensive to compute, so it is cached in 'enclosingRect'."

	(enclosingRect isNil) ifTrue: [self computeEnclosingRectangle].
	^enclosingRect!

modelToDisplayPoint: aModelPoint
	"Converts the given point in model coordinates to the corresponding point in Display coordinates (the inverse of 'displayToModelPoint:')."

	^self insetDisplayBox origin + (aModelPoint - enclosingRect origin) + scrollOffset!

viewOrigin
	"Answer the origin of the view's coordinate system relative to 0@0."

	^(0@0) - enclosingRect origin! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SceneView class
	instanceVariableNames: ''!


!SceneView class methodsFor: 'instance creation'!

on: aScene
	"Create a new view on the given Scene."

	^self new model: aScene!

openOn: aScene
	"Open a new view on the given Scene."

	self
		openWithSubview: (self on: aScene)
		label: 'Scene'.!

openWithSubview: aView label: labelString
	"Open a StandardSystemView with the given label and the given view as a subview."

	| topView |
	topView _ SpecialSystemView new.
	topView
		model: nil;
		label: labelString;
		minimumSize: 60@60.
	topView
		borderWidth: 1;
		addSubView: aView.
	topView controller open.!

openWithSubview: aView label: labelString fromHolder: aPartHolder zoomFrom: fromRect to: toRect
	"Open a SpecialSystemView with the given label and the given view as a subview zooming open from the given rectangle."

	| topView controller |
	controller _ SpecialSystemController new.
	controller
		fromHolder: aPartHolder;
		fromFrame: fromRect.
	topView _ SpecialSystemView new.
	topView
		model: nil;
		label: labelString;
		minimumSize: 60@60.
	topView
		borderWidth: 1;
		controller: controller;
		addSubView: aView.
	((fromRect notNil) & (toRect notNil))
		ifTrue:
			[Display zoom: fromRect to: toRect duration: 260.
			 topView window: (0@0 extent: toRect extent) viewport: toRect.
			 topView controller openDisplayAt: toRect center]
		ifFalse: [topView controller open].! !

Parser subclass: #EquationParser
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Equations'!


!EquationParser methodsFor: 'public access'!

editor
	"I am never called from an interactive editor."

	^nil!

encoder
	"Answer my encoder."

	^encoder!

parse: sourceStream
	"Parse the given source stream and answer the resulting parse tree. The source stream contents must represent a syntactically correct Smalltalk method definition such as:
	foo
		a _ b.
		c _ 55 * a + b.
That is, there must be a method header followed by a series of statements."

	| meth |
	failBlock _ [].
	self init: sourceStream notifying: nil failBlock: failBlock.
	cue _ CompilationCue new initializeWithSource: stream context: nil
        receiver: Object class: Object environment: (Environment new initialize) requestor: nil.
	encoder _ EquationEncoder new init: cue notifying: self.
	meth _ self method: false context: nil.
	"break cycles & mitigate refct overflow"
	failBlock _ parseNode _ nil.
	encoder release.
	^meth!

parse: sourceStream in: aClass
	"Parse the given source stream for the given class and answer the resulting parse tree. The source stream contents must represent a syntactically correct Smalltalk method definition such as:
	foo
		a _ b.
		c _ 55 * a + b.
That is, there must be a method header followed by a series of statements."

	| meth |
	failBlock _ [self error: 'Module Compiler Error'].
	self init: sourceStream notifying: nil failBlock: failBlock.
	cue _ CompilationCue new initializeWithSource: stream context: nil
        receiver: Object class: aClass environment: (Environment new initialize) requestor: nil.
	encoder _ EquationEncoder new init: cue notifying: self.
	meth _ self method: false context: nil.
	"break cycles & mitigate refct overflow"
	failBlock _ parseNode _ nil.
	encoder release.
	^meth!

parse: sourceStream withEncoder: anEncoder
	"Parse the given source stream using the given encoder and answer the resulting parse tree. The source stream contents must represent a syntactically correct Smalltalk method definition such as:
	foo
		a _ b.
		c _ 55 * a + b.
That is, there must be a method header followed by a series of statements."

	| meth |
	failBlock _ [self error: 'Module Compiler Error'].
	self init: sourceStream notifying: nil failBlock: failBlock.
	encoder _ anEncoder.
	meth _ self method: false context: nil.
	"break cycles & mitigate refct overflow"
	failBlock _ parseNode _ nil.
	^meth! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EquationParser class
	instanceVariableNames: ''!


!EquationParser class methodsFor: 'parsing'!

parse: aStream
	"Parse the given source stream and answer the resulting parse tree."

	^(super new) parse: aStream!

parse: aStream in: aClass
	"Parse the given source stream for the given class and answer the resulting parse tree."

	^(super new) parse: aStream in: aClass!

parse: aStream withEncoder: anEncoder
	"Parse the given stream using the supplied encoder and answer the resulting parse tree."

	^(super new) parse: aStream withEncoder: anEncoder! !

BitBltDisplayScanner subclass: #QuickPrint
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Support'!
QuickPrint comment:
'This class supports fast character string display. It is significantly faster than using a Paragraph for the same purpose.'!

!QuickPrint methodsFor: 'Squeak compatibility'!

clipRect: aRect
	bitBlt clipRect: aRect!

clipRect
	^bitBlt clipRect! !

!QuickPrint methodsFor: 'displaying'!

drawString: aString
	"Draw the given string."

	| dt |
	destX _ bitBlt clipX.
	destY _ bitBlt clipY.
	dt _ DisplayText text: aString asText.
	dt foregroundColor: Color black backgroundColor: Color white.
	dt displayOn: bitBlt destForm at: (destX @ destY) clippingBox: self clipRect rule: Form over fillColor: Color white. !

stringWidth: aString
	"Answer the width of the given string."

	| dt |
	dt _ DisplayText text: aString asText.
	^dt computeBoundingBox width.! !

!QuickPrint methodsFor: 'positioning'!

downBy: offset
	"Move the top border of my clipping box down by the given amount."

	| clipBox |
	clipBox _ self clipRect.
	clipBox := clipBox top: ((clipBox top + offset) min: clipBox bottom).
	self clipRect: clipBox.!

rightBy: offset
	"Move the left border of my clipping box right by the given amount."

	| clipBox |
	clipBox _ self clipRect.
	clipBox := clipBox left: ((clipBox left + offset) min: clipBox right).
	self clipRect: clipBox.! !

!QuickPrint methodsFor: 'private'!

newOn: aForm box: aRectangle
	"Initialize myself."

	kern := 0.
	bitBlt := BitBlt asGrafPort toForm: aForm.
	textStyle _ TextStyle default.
	font _ textStyle fontAt: 1.
	destForm _ aForm.
	halftoneForm _ Color black.
	bitBlt combinationRule: Form over.
	self clipRect: aRectangle.
	bitBlt sourceY: 0.
	"sourceX is set when selecting the character from the font strike bitmap"
	self setStopConditions.!

setStopConditions
	"Set default stop conditions for the font."

	spaceWidth _ font widthOf: Character space. 
	bitBlt sourceForm: font glyphs.
	xTable _ font xTable.
	bitBlt height: font height.
	stopConditions _ DefaultStopConditions copy.
	stopConditions at: CR asInteger + 1 put: #cr.
	stopConditions at: 10 + 1 put: #cr.
	stopConditions at: EndOfRun put: #endOfRun.
	stopConditions at: CrossedX put: #crossedX.
	stopConditions at: Ctrls asInteger + 1 put: #onePixelSpace.
	stopConditions at: CtrlS asInteger + 1 put: #onePixelBackspace.
	stopConditions at: Ctrlz asInteger + 1 put: #characterNotInFont.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

QuickPrint class
	instanceVariableNames: ''!


!QuickPrint class methodsFor: 'instance creation'!

newOn: aForm box: aRectangle
	"Create an instance to print on the given form in the given rectangle."

	^(super new) newOn: aForm box: aRectangle! !

!QuickPrint class methodsFor: 'queries'!

lineHeight
	"Answer the height of the font used by QuickPrint."

	^TextStyle defaultFont height!

width: aString
	"Answer the width of the printed representation of the given string in pixels."

	| scanner |
	scanner _ QuickPrint
		newOn: Display
		box: (0@0 corner: 0@0).
	^scanner stringWidth: aString! !

!QuickPrint class methodsFor: 'example'!

example
	"This will quickly print all the numbers from 1 to 100 on the display and then answer the width and height of the string 'hello world'."
	"QuickPrint example"

	| scanner |
	scanner _ QuickPrint
		newOn: Display
		box: (20@70 corner: 80@90).
	1 to: 100 do: [: i | scanner drawString: i printString].
	^(QuickPrint width: 'hello world')@(QuickPrint lineHeight)! !

Object subclass: #ShortestPaths
	instanceVariableNames: 'vertexCount vertexTable transitionList distances toDo '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Layout'!


!ShortestPaths methodsFor: 'all'!

computeDistances: aMatrix
	"Initialize the distance matrix and various constants."
	"Note: If using Floyd's algorithm, aMatrix should be copied since 'distances' is modified by the algorithm."

	distances _ aMatrix.
	^self dijkstra!

dijkstra
	"Compute the least-cost array by using Dijkstra's algorithm to compute the least cost paths from each vertex in turn."

	| costs v |
	self dijkstraSetup.
	costs _ Array new: vertexCount.
	v _ 1.
	[v <= vertexCount] whileTrue:
		[costs at: v put: (self dijkstraComputeRow: v).
		 v _ v + 1].
	^Matrix new setRows: costs!

dijkstraComputeRow: vertex
	"Compute one row of the cost matrix using Dijkstra's algorithm."

	| costRow element v vCost transitions count i nextV |
	self dijkstraRowSetupFor: vertex.
	costRow _ Array new: vertexCount.
	[toDo size == 0] whileFalse:
		[element _ toDo removeMin.
		 v _ element label.
		 vCost _ element cost.
		 costRow at: v put: vCost.
		 vCost _ vCost + 1.
		 transitions _ transitionList at: v.
		 count _ transitions size.
		 i _ 1.
		 [i <= count] whileTrue:
			[nextV _ vertexTable at: (transitions at: i).
			 (vCost < nextV cost) ifTrue:
				[nextV cost: vCost.
				 toDo relocate: nextV].
			 i _ i + 1]].
	costRow at: vertex put: 0.
	^costRow!

dijkstraRowSetupFor: vertex
	"Initialize the set of unvisited vertices ('toDo') for finding the shortest paths to all other vertices from the given vertex."

	| transitions count i v |
	(vertexTable at: vertex) cost: 0.
	toDo initializeWithVertices: vertexTable except: vertex cost: 100000.
	transitions _ transitionList at: vertex.
	count _ transitions size.
	i _ 1.
	[i <= count] whileTrue:
		[v _ vertexTable at: (transitions at: i).
		 v cost: 1.
		 toDo relocate: v.
		 i _ i + 1].!

dijkstraSetup
	"Initialize the transitionsList and vertexTable for Dijkstra's algorithm."

	| i dists edges j |
	vertexCount _ distances rowCount.
	transitionList _ Array new: vertexCount.
	vertexTable _ Array new: vertexCount.
	i _ 1.
	[i <= vertexCount] whileTrue:
		[dists _ distances row: i.
		 edges _ OrderedCollection new: vertexCount.
		 j _ 1.
		 [j <= vertexCount] whileTrue:
			[((dists at: j) == 1) ifTrue: [edges add: j].
			 j _ j + 1].
		 transitionList at: i put: edges asArray.
		 vertexTable at: i put: (LayoutGlyph label: i).
		 i _ i + 1].
	toDo _ PriorityQueue new: vertexCount.!

floyd
	"Compute the transitive closure of the distance function using Floyd's algorithm."

	| matrixSize row newDist k i j |
	matrixSize _ distances rowCount.
	k _ 0.
	[k < matrixSize] whileTrue:
		[k _ k + 1.
		 i _ 0.
		 [i < matrixSize] whileTrue:
			[i _ i + 1.
			 row _ distances row: i.
			 j _ 0.
			 [j < matrixSize] whileTrue:
				[j _ j + 1.
				 "distances from i to j via k"
				 newDist _ (row at: k) + (distances row: k col: j).
				 (newDist < (row at: j)) ifTrue:
					[row at: j put: newDist]]]].
	^distances! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ShortestPaths class
	instanceVariableNames: ''!


!ShortestPaths class methodsFor: 'computing'!

computeDistances: initialDistanceMatrix
	"Given an initial distance matrix, answer the shortest path cost matrix for the graph. The distance matrix has d(i,j) = 1 if there is a direct path from i to j in the graph, d(i,j) > 1 if there is no direct path from i to j in the graph, and d(i,i) = 0 for all i."

	^self new computeDistances: initialDistanceMatrix! !

!ShortestPaths class methodsFor: 'examples'!

example1
	"Answers the shortest path matrix for a 3 vertex chain."
	"ShortestPaths example1"

	^ShortestPaths computeDistances:
		((Matrix rows: 3 columns: 3)
			fill: 1000;
			row: 1 col: 1 put: 0;
			row: 2 col: 2 put: 0;
			row: 3 col: 3 put: 0;
			row: 1 col: 2 put: 1;
			row: 2 col: 1 put: 1;
			row: 2 col: 3 put: 1;
			row: 3 col: 2 put: 1)!

example2: vertexCount
	"Answers the time required to compute the shortest paths matrix for an N vertex ring."
	"ShortestPaths example2: 80"
	"Here are some figures for various values of N using different algorithms:

		N = 5, 10, 20, 40, 80, 160
		20 92 400 1660 7329 32226 -- dijkstra, final implementation
		31 143 512 2122 9236 40642 -- dijkstra, backrefs
		31 103 482 2070 9809 50399 -- dijkstra, better locate
		71 133 636 2777 13284  66410 -- dijkstra, original
		21 82 594 4520 35936 275817 -- floyd
		20 134 1014 7472 58271 <missing> -- old floyd
		41 430 3065 23114 183219 <missing> -- john
	These figures were collected on a Mac SE with an Irwin 25 MHz accellerator. They provide a glimpse into the complex process of optimizing an algorithm and how effective such optimization can be. 'john' was my original naive solution to problem. Floyd is an implementation of Floyd's algorithm and Dijkstra is an implementation of Dijkstra's algorithm.
	Finally, a few tests on the extreme's of Dijkstra's algorithm:
		N = 5, 10, 20, 40, 80, 160
		21  82 174 676 2788 10895 -- graph with no edges
		21 123 584 3536 24272 175285 -- fully connected graph"

	| m |
	m _ Matrix rows: vertexCount columns: vertexCount.
	m fill: 1000.
	1 to: vertexCount do: [: i | m row: i col: i put: 0].
	1 to: vertexCount-1 do:
		[: i |
		 m row: i col: i+1 put: 1.
		 m row: i+1 col: i put: 1].
	m row: 1 col: vertexCount put: 1.
	m row: vertexCount col: 1 put: 1.
	^Time millisecondsToRun: [ShortestPaths computeDistances: m]! !

Object subclass: #BluePlanner
	instanceVariableNames: 'thingDatas sortedConstraints '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII'!
BluePlanner comment:
'I embody a simple, non-incremental constraint planning algorithm known as Blue.'!


!BluePlanner methodsFor: 'initialize-release'!

on: aThing
	"Initialize myself for satisfying the constraints on the given Thing."
	"Note: constraint satisfaction could be done faster if we used one BluePlanner for each constraint partition. The partitions could be maintained incrementally. Food for thought..."

	| allConstraints |
	thingDatas _ IdentitySet new: 40.
	aThing allThingsDo:
		[: thing | thingDatas addAll: thing thingDatas].
	allConstraints _ IdentitySet new: 40.
	thingDatas do:
		[: thingData | allConstraints addAll: thingData constraints].
	sortedConstraints _
		(SortedCollection new: 200)
			sortBlock: [: i : j | i isStrongerThan: j].
	sortedConstraints addAll: allConstraints.! !

!BluePlanner methodsFor: 'planning'!

plan
	"Figure out how to satisfy the constraints and answer a Plan."

	| currentMark constraintCount plan nextC m |
	sortedConstraints do: [: c | c prepareForPlanning].
	currentMark _ Time millisecondClockValue.
	constraintCount _ sortedConstraints size.
	plan _ Plan new: constraintCount * 2.
	nextC _ 1.
	[nextC <= constraintCount] whileTrue:
		[| c | c _ sortedConstraints at: nextC.
		 m _ c attemptSatisfaction: currentMark.
		 (m notNil)
			ifTrue:
				[(c doesSomething) ifTrue: [plan addLast: m].
				 nextC _ 1]
			ifFalse:
				[nextC _ nextC + 1]].
	^plan! !

Object subclass: #AbstractMethod
	instanceVariableNames: 'codeString bindings '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Constraints'!
AbstractMethod comment:
'A Method is the unit of computation for a constraint. Executing the method enforces the constraint using some the constraint''s variables as inputs and computing other variables as outputs. The input and output variable sets may not intersect but either set may be empty.

Instance variables:
	codeString...	string that can be used to compile this method <String>
	bindings...	a string indicating the mapping of constraint variables
				to my inputs and outputs. In this string, ''i'' indicates an
				input, ''o'' indicates and output, and ''x'' indicates a
				constraint variable unused by this method. <String>
	inDatas...	a cache of the ThingDatas for my inputs {ThingData}
	outDatas...	a cache of the ThingDatas of my outputs {ThingData}
'!


!AbstractMethod methodsFor: 'access'!

bindings
	"Answer my binding array."

	^bindings!

bindings: anArrayOfCharacters	
	"Set my binding array."

	bindings _ anArrayOfCharacters.!

codeString
	"Answer my code string."

	^codeString!

codeString: aString
	"Set my code string."

	codeString _ aString.! !

!AbstractMethod methodsFor: 'DeltaBlue'!

execute: refList
	"Execute myself to enforce my constraint. refList contains all the References for my constraint."

	self subclassResponsibility!

inDatasIn: thingDatas do: aBlock
	"Evaluate the given block for each of my input ThingDatas."

	| i |
	i _ bindings size.
	[i > 0] whileTrue:
		[((bindings at: i) == $i) ifTrue:
			[aBlock value: (thingDatas at: i)].
		 i _ i - 1].!

inputsAreStayIn: thingDatas
	"Answer true if all my inputs are stay or if I have no inputs."

	| i |
	i _ bindings size.
	[i > 0] whileTrue:
		[((bindings at: i) == $i) ifTrue:
			[((thingDatas at: i) stay) ifFalse:
				[^false]].
		 i _ i - 1].
	^true!

inputsIn: thingDatas known: currentMark
	"Answer true if all my inputs have been determined (i.e. marked with the given mark) or if I have no inputs."

	| i |
	i _ bindings size.
	[i > 0] whileTrue:
		[((bindings at: i) == $i) ifTrue:
			[((thingDatas at: i) mark == currentMark) ifFalse:
				[^false]].
		 i _ i - 1].
	^true!

isPossibleMethodGiven: constraintStrength
	"Answer true if I am a possible method given the current walkabout strengths of my variables. Normal (non-Module) methods are always possible."

	^true!

outDatasIn: thingDatas do: aBlock
	"Evaluate the given block for each of my output ThingDatas."

	| i |
	i _ bindings size.
	[i > 0] whileTrue:
		[((bindings at: i) == $o) ifTrue:
			[aBlock value: (thingDatas at: i)].
		 i _ i - 1].!

outputsAreStayIn: thingDatas
	"Answer true if all my outputs are stay or if I have no outputs."

	| i |
	i _ bindings size.
	[i > 0] whileTrue:
		[((bindings at: i) == $o) ifTrue:
			[((thingDatas at: i) stay) ifFalse:
				[^false]].
		 i _ i - 1].
	^true!

outputsIn: thingDatas notKnown: currentMark
	"Answer true only if none of my outputs have been determined."

	| i |
	i _ bindings size.
	[i > 0] whileTrue:
		[((bindings at: i) == $o) ifTrue:
			[((thingDatas at: i) mark == currentMark) ifTrue:
				[^false]].
		 i _ i - 1].
	^true!

strongestOutStrengthIn: thingDatas

	| maxOutStrength i |
	maxOutStrength _ Strength absoluteWeakest.
	i _ bindings size.
	[i > 0] whileTrue:
		[((bindings at: i) == $o) ifTrue:
			[maxOutStrength _
				maxOutStrength strongest:  (thingDatas at: i) walkStrength].
		 i _ i - 1].
	^maxOutStrength!

updateOutputsIn: thingDatas for: myConstraint stay: stayFlag
	"Update the walkabout strengths and stay flags for all my outputs and answer the list of output ThingDatas."

	| outs i out thisOut outStrengths |
	outs _ #().	"default return value"
	i _ bindings size.
	[i > 0] whileTrue:
		[((bindings at: i) == $o) ifTrue:
			[out _ thingDatas at: i.
			 (thisOut isNil) ifTrue:
				[thisOut _ 1. 	"do this initialization on demand and once at most"
				 outs _ OrderedCollection new: 10.
				 outStrengths _ myConstraint strengthsFor: self].
			 outs add: out.
			 out walkStrength: (outStrengths at: thisOut).
			 out stay: stayFlag.
			 thisOut _ thisOut + 1].
		 i _ i - 1].
	^outs! !

!AbstractMethod methodsFor: 'cloning'!

cloneWith: cloneDictionary for: aConstraint
	"Make a clone of myself for the given constraint using the mapping given by cloneDictionary. The default is to NOT copy myself, since non-Module methods can be shared."

	^self! !

!AbstractMethod methodsFor: 'printing'!

printOn: aStream

	aStream cr; nextPutAll: 'Method('.
	aStream nextPutAll: codeString.
	aStream nextPutAll: ')'.! !

Object subclass: #Thing
	instanceVariableNames: 'parents constraints thingDatas '
	classVariableNames: 'DefaultIcons '
	poolDictionaries: ''
	category: 'ThingLabII-Things'!
Thing comment:
'A Thing has two functions:
	First, it is the grouping mechanism for the user-interface.
	Second, a Thing is a constrainable object to the planner.

New kinds of Things are created one of three ways:
	(A) New empty Things are created by subclassing Thing.
	(B) New Things can be created from existing Things by adding and
		removing parts.
	(C) New Things can be "compiled" from old Things. The old
		Thing is then the "construction view" for the new Thing, and
		the new Thing is the "use view" for the old.

A Thing must never replace its instance variables (parts), as this could leave dangling references in constraints. Compound parts are updated by recursive copying.

Each kind of Thing is implemented using a normal Smalltalk class and a prototype instance is stored in the class. The prototype is cloned to get new instances of that kind of thing (i.e. this is a prototype based system, rather than a class based one).

When a new part is added to a prototype, its class is updated by adding a named instance variable for the part and by adding access methods to get and change the value of the part. (Detail: Because adding new instance variables to a class is slow, extra instance variables are kept around. These are labeled unused1, unused2, etc.) If there are instances of the class besides the prototype, the class cannot be changed. Instead, a copy of the class and prototype are made and the new class is changed.

Things rely on knowing and controlling their instance variable layout. Please do not subclass a Thing or, if you must, do not add any instance variables or you will get unexpected results.

Instance variables:
	parents...	the parents of this Thing. There can be
				multiple parents because of merging. {Thing}
	constraints...	the constraints owned by this Thing. Used to
				clone constraints along with a Thing. {Constraint}
	thingData...	data structure for planning (up to one entry per sub-part)
				{name->ThingData}

Class instance variables:
	thingName...		text name given by the user <String>
	partIcon...		icon for display in the parts bin <Form>
	explainText...	text description for the user <String>
	partNamesAndIndices...
					an array of (<Symbol>,<SmallInteger>) pairs
					used to keep track of the allocation and naming
					of instance variables to hold parts
	externalParts...	sub-parts to be visible when this Thing is
					compiled {Thing}
	useView...		the class of the useView if this Thing was compiled
	prototype...		an instance that is the prototype for this type
					<some subclass of Thing>
'!


!Thing methodsFor: 'public-part add/remove'!

addPartsNamed: nameList toHold: partsList
	"Add a collection of new parts with the given names for the objects in partsList. Compile get and put access methods for the new parts. Answer true if I had to become a new class in order to do this. partsList may contain Strings or Symbols."

	| changedType partNameStrings slot |
	(self isStructureModifiable) ifFalse:
		[^nil error: 'Sorry, my structure cannot be modified'].

	"make a new class for me if necessary"
	BusyCursor begin.
	changedType _ false.
	(self isUnencumbered) ifFalse:
		[changedType _ true.
		 self becomeUnencumbered].

	"allocate and initialize instance variables"
	BusyCursor inc.
	partNameStrings _ nameList collect: [: n | n asString].
	partNameStrings with: partsList do:
		[: partName : part |
		 BusyCursor inc.
		 "allocate a new instance variable"
		 slot _ self findEmptyInstVar.
		 self class renameInstVarAt: (slot - self class instOffset) as: partName.
		 self class partNamesAndIndices add: (Array
			with: partName asSymbol
			with: slot).

		 "put the new part into the new slot and make me its parent"
		 self instVarAt: slot put: part.
		 (part isThing) ifTrue: [part addParent: self]].

	"build the part access methods"
	BusyCursor inc.
	self class
		compileAccessMethodsFor: partsList
		named: nameList.

	BusyCursor end.
	^changedType!

addThing: aThing 
	"Add a part variable with a made up name like 'numberPrinter5' and put aThing into it. This method must handle Thing names that include spaces, digits, and/or capital first letters. Answer true if I had to become a new class to accomplish this."

	| partName partNum |
	partName _ aThing name asString copyUpTo: $ .
	(partName isEmpty) ifTrue: [partName _ 'part'].
	partName at: 1 put: (partName at: 1) asLowercase.
	[(partName at: partName size) isDigit] whileTrue:
		[partName _ partName copyFrom: 1 to: partName size - 1].
	(partName isEmpty) ifTrue: [partName _ 'part'].
	partNum _ self findEmptyInstVar - self class instOffset.
	^self
		addPartsNamed: (Array with: (partName, partNum printString))
		toHold: (Array with: aThing)!

removePartNamed: partName
	"Remove and destroy this part and its access methods. You may only remove parts from the top-level Thing."

	| instIndex partToRemove changedType allThingDatas |
	(self isStructureModifiable) ifFalse:
		[^self error: 'Sorry, my structure cannot be modified'].
	(parents isEmpty) ifFalse:
		[^self error: 'You may only remove top-level parts'].

	instIndex _
		(self class partNamesAndIndices
			detect: [: pair | pair first = partName asSymbol]
			ifNone: [^self error: partName, ' is not one of my parts']) last.

	BusyCursor begin.
	partToRemove _ self perform: partName asSymbol.
	changedType _ false.
	(self isUnencumbered) ifFalse: 
		[changedType _ true.
		 self becomeUnencumbered].

	"removing a non-Thing part:"
	(partToRemove isThing) ifFalse:
		[self removeConstraintsForPart: partName.
		 partToRemove release].

	"removing a Thing part:"
	(partToRemove isThing) ifTrue:
		["extract the part from all external merges"
		 BusyCursor inc.
		 self isolate: self->partName
			within: self->partName.

		 "remove all constraints attached to the part"
		 BusyCursor inc.
		 allThingDatas _ Set new.
		 partToRemove allThingDatasInto: allThingDatas.
		 allThingDatas do: 
			[: thingData | 
			 BusyCursor inc.
			 thingData constraints copy do: [: c | c removeConstraint]].

		 "sanity check: did we get 'em all?"
		 allThingDatas _ Set new.
		 partToRemove allThingDatasInto: allThingDatas.
		 (allThingDatas isEmpty)
			ifFalse: [self error: 'ThingLabII Internal Error'].

		"nil out the part instance variable and destroy the part"
		BusyCursor inc.
		partToRemove destroy].

	"remove the part's inst var and access methods from the class"
	BusyCursor inc.
	self instVarAt: instIndex put: nil.
	self class removePartNamed: partName asSymbol.

	BusyCursor end.
	^changedType! !

!Thing methodsFor: 'public-merging'!

extractMergedPart: partRef
	"Extract the part with the given reference from the merge it is in. Answer true if I had to create a new class in order to do this. The extracted part retains all internal merges and its internally owned constraints."

	| changedType |
	"sanity checks"
	((partRef topParent == self topParent) and:
	 [(partRef value isThing) and:
	 [partRef value parents size > 1]]) ifFalse:
		[^self error: 'attempt to unmerge parts that are not merged or that I do not own'].
	(self isStructureModifiable) ifFalse:
		[^self error: 'you cannot modify the structure of this Thing'].

	BusyCursor begin.
	changedType _ false.
	(self isUnencumbered) ifFalse: 
		[changedType _ true.
		 self becomeUnencumbered].

	self extractFromMerge: partRef.

	BusyCursor end.
	^changedType!

extractPart: partRef
	"Extract the top-most owner of this part from all merges. For example, if the given reference is for the TextThing part of a NumberPrinter, the NumberPrinter and all its sub-parts will be extracted from all merges."

	| changedType topRef |
	(self isStructureModifiable) ifFalse:
		[^self error: 'Sorry, my structure cannot be modified'].
	(parents isEmpty) ifFalse:
		[^self error: 'You may only remove top-level parts'].
	(partRef value isThing) ifFalse:
		[^false].		"can only extract Thing parts"
	(partRef topParent ~~ self) ifTrue:
		[^self error: 'Part is not owned by me'].

	BusyCursor begin.
	changedType _ false.
	(self isUnencumbered) ifFalse: 
		[changedType _ true.
		 self becomeUnencumbered].

	"extract the part from all merges"
	topRef _ partRef copyFromTopParent.
	self isolate: topRef within: topRef.
	BusyCursor inc.

	BusyCursor end.
	^changedType!

mergePart: part1 withPart: part2 
	"Merge two of my sub-parts. The sub-parts must be Things. Answer true if I had to become unencumbered (i.e. change my class) in order to do the merge."

	| changedType |
	"sanity checks"
	(self isStructureModifiable) ifFalse:
		[^self error: 'you cannot modify the structure of this Thing'].
	((part1 isThing) & (part2 isThing)) ifFalse:
		[self error: 'you may only merge Things'].
	((part1 topParent == self topParent) &
	 (part2 topParent == self topParent)) ifFalse:
		[^self error: 'parts may be merged only if they have a common ancestor'].

	(part1 == part2) ifTrue:
		[^false]. 	"the given parts are already merged"

	BusyCursor begin.
	changedType _ false.
	(self isUnencumbered) ifFalse: 
		[changedType _ true.
		 self becomeUnencumbered].

	BusyCursor inc.
	(self privateMerge: part1 into: part2) ifFalse:
		[Display reverse; reverse].

	BusyCursor end.
	^changedType! !

!Thing methodsFor: 'public-cloning/destruction'!

clone
	"Answer a clone of myself. Cloning Things is done in two passes. In pass 1, we recursively copy the old Thing's part-whole structure, being careful to maintain the same graph structure for shared parts (sharing occurs when parts of the old Thing have been merged). During this first pass we also build a dictionary that maps parts in the old Thing to their corresponding parts in the new Thing. In pass 2, all constraints owned by the old Thing are cloned and and added to the new Thing, after first updating their references to point to the new Thing's parts."

	| cloneDictionary myClone constraintsToClone |
	cloneDictionary _ IdentityDictionary new: 200.
	myClone _ self clonePass1: cloneDictionary.
	myClone clonePass2: cloneDictionary.
	^myClone!

destroy
	"Destroy myself (this instance only, not its class). Destruction helps avoid circular garbage. Warning: be sure not to destroy the prototype for a class of Things unless you know what you are doing."

	| part |
	(constraints notNil) ifTrue:
		[constraints do: [: constraint | constraint destroy]].
	self partIndicesDo:
		[: i |
		 part _ self instVarAt: i.
		 (part notNil & part isThing) ifTrue: [part destroy].
		 (part notNil & part isThing not) ifTrue: [part release].
		 self instVarAt: i put: nil].
	(thingDatas notNil) ifTrue:
		[thingDatas do: [: thingData | thingData destroy]].
	parents _ nil.
	constraints _ nil.
	thingDatas _ nil.!

destroyAndRemoveClass
	"Attempt to destroy myself and my class and answer true if successful. In other words, entirely delete all evidence of myself from the system. This can only happen if I am the only instance. This message is sent to the prototype Thing for a class of Things. "

	(self class allInstances size == 1) ifFalse: [^false].
	self destroy.
	self class destroy.
	^true! !

!Thing methodsFor: 'public-testing'!

canMerge: thingOne with: thingTwo
	"Answer true if I can merge these two parts. The parts can be merged only if they both have the same topParent as me, both are Things of the same class, and they are not already merged."

	^(thingOne topParent == self topParent) and:
	[(thingTwo topParent == self topParent) and:
	[(thingOne isThing & thingTwo isThing) and:
	[(thingOne class == thingTwo class) and:
	[(thingOne ~~ thingTwo)]]]]!

isStructureModifiable
	"Answer true if it is possible to modify my structure, even if doing so entails creating a new class. This is overridden by PrimitiveThing to prevent primitive Things from being modified."

	^true!

isThing
	"Answer true if I am a Thing."

	^true!

isUnencumbered
	"Answer true if I am unencumbered and thus can be freely modified. This is true if I am the only instance of my class (i.e. the prototype) and if I have no construction or use views. If I AM encumbered then you can make a new, equivalent, class using the 'becomeUnencumbered' message, and modify the prototype of the new class."

	^(self class allInstances size = 1) and:
	[(self class useView isNil) and:
	[self class constructionView isNil]]!

isUseView
	"Answer true if I was compiled from another Thing."

	^self class constructionView notNil! !

!Thing methodsFor: 'public-references'!

-> aPathSymbol
	"Answer a Reference to the part of me with the given path. The path is a possibly compound symbol such as '#a.node.lastValue'."

	^Reference on: self path: aPathSymbol asSymbol path!

partAt: aPath

	| part |
	part _ self.
	aPath path do:
		[: partName |
		 part _ part perform: partName].
	^part!

referenceToYourself
	"Answer a Reference to myself."

	| aParent |
	aParent _ parents first.
	^aParent->(aParent firstPartNameFor: self)! !

!Thing methodsFor: 'public-stay constraints'!

defaultStay: path
	"Add a default stay constraint to the given part of me. Answer the constraint."

	^self addConstraint:
		(StayConstraint
			ref: self->path
			strength: #default)!

preferStay: path
	"Add a preferred stay constraint to the given part of me. Answer the constraint."

	^self addConstraint:
		(StayConstraint
			ref: self->path
			strength: #preferred)!

requireStay: path
	"Add a preferred stay constraint to the given part of me. Answer the constraint."

	^self addConstraint:
		(StayConstraint
			ref: self->path
			strength: #required)!

strongDefaultStay: path
	"Add a default stay constraint to the given part of me. Answer the constraint."

	^self addConstraint:
		(StayConstraint
			ref: self->path
			strength: #strongDefault)!

stronglyPreferStay: path
	"Add a strongly preferred stay constraint to the given part of me. Answer the constraint."

	^self addConstraint:
		(StayConstraint
			ref: self->path
			strength: #strongPreferred)!

weakDefaultStay: path
	"Add a weak default stay constraint to the given part of me. Answer the constraint."

	^self addConstraint:
		(StayConstraint
			ref: self->path
			strength: #weakDefault)! !

!Thing methodsFor: 'public-equals constraints'!

default: pathOne equals: pathTwo
	"Add and answer a default equality constraint between the given parts of me."

	^self addConstraint:
		(EqualityConstraint
			ref: self->pathOne
			ref: self->pathTwo
			strength: #default)!

prefer: pathOne equals: pathTwo
	"Add and answer a preferred equality constraint between the given parts of me."

	^self addConstraint:
		(EqualityConstraint
			ref: self->pathOne
			ref: self->pathTwo
			strength: #preferred)!

require: pathOne equals: pathTwo
	"Add and answer a required equality constraint between the given parts of me."

	^self addConstraint:
		(EqualityConstraint
			ref: self->pathOne
			ref: self->pathTwo
			strength: #required)!

stronglyPrefer: pathOne equals: pathTwo
	"Add and answer a strongly preferred equality constraint between the given parts of me."

	^self addConstraint:
		(EqualityConstraint
			ref: self->pathOne
			ref: self->pathTwo
			strength: #strongPreferred)! !

!Thing methodsFor: 'public-other constraints'!

methods: methodList where: bindingsList strength: aSymbol
	"Create and add a constraint of the given strength constructed from the given set of methods. Answer the constraint constructed. See require:where: for a description of the bindingList."

	| variableNames pathList refs |
	variableNames _ (bindingsList collect: [: pair | pair first]) asArray.
	pathList _ (bindingsList collect: [: pair | pair last]) asArray.
	refs _ pathList collect: [: path | self->path].
	^self addConstraint:
		(Constraint
			symbols: variableNames
			methodStrings: methodList
			refs: refs
			strength: aSymbol)!

offset: pathOne by: offset from: pathTwo
	"Add a strongly preferred offset constraint to make the part with pathTwo be equal to the part with pathOne plus the given offset."

	^self addConstraint:
		(OffsetConstraint
			ref: self->pathTwo
			ref: self->pathOne
			strength: #strongPreferred
			offset: offset)!

offset: pathOne by: offset from: pathTwo strength: aSymbol
	"Add an offset constraint to make the part with pathTwo be equal to the part with pathOne plus the given offset."

	^self addConstraint:
		(OffsetConstraint
			ref: self->pathTwo
			ref: self->pathOne
			strength: aSymbol
			offset: offset)!

prefer: anEquation where: bindingsList
	"Create and add a preferred constraint constructed from the given equation (a String). Answer the constraint constructed. See require:where: for a description of the bindingList argument."

	| variableNames pathList refs |
	variableNames _ (bindingsList collect: [: pair | pair first]) asArray.
	pathList _ (bindingsList collect: [: pair | pair last]) asArray.
	refs _ pathList collect: [: path | self->path].
	^self addConstraint:
		(Constraint
			symbols: variableNames
			equation: anEquation
			refs: refs
			strength: #preferred)!

require: anEquation where: bindingsList
	"Create and add a required constraint constructed from the given equation (a String). Answer the constraint constructed. bindingsList is an ordered list of (variableName, part) pairs such as #((x1 a.location.x) (x2 b.location.x)). In each pair, variableName is a variable in the equation and part is a path for the part of me to which the variable should be bound."

	| variableNames pathList refs |
	variableNames _ (bindingsList collect: [: pair | pair first]) asArray.
	pathList _ (bindingsList collect: [: pair | pair last]) asArray.
	refs _ pathList collect: [: path | self->path].
	^self addConstraint:
		(Constraint
			symbols: variableNames
			equation: anEquation
			refs: refs
			strength: #required)!

stronglyPrefer: anEquation where: bindingsList
	"Create and add a strongly preferred constraint constructed from the given equation (a String). Answer the constraint constructed. See require:where: for a description of the bindingList argument."

	| variableNames pathList refs |
	variableNames _ (bindingsList collect: [: pair | pair first]) asArray.
	pathList _ (bindingsList collect: [: pair | pair last]) asArray.
	refs _ pathList collect: [: path | self->path].
	^self addConstraint:
		(Constraint
			symbols: variableNames
			equation: anEquation
			refs: refs
			strength: #strongPreferred)!

stronglyPreferEdit: path
	"Add a strongly preferred edit constraint to the given part of me. Answer the constraint."

	^self addConstraint:
		(EditConstraint
			ref: self->path
			strength: #strongPreferred)! !

!Thing methodsFor: 'public-changes'!

set: pathSymbol to: aValue
	"Assign the given value to the subpart of this Thing with the given path using a strength of #preferred."

	self set: pathSymbol to: aValue strength: #preferred.!

set: pathSymbol to: aValue strength: strengthSymbol
	"Assign the given value to the the subpart of this Thing with the given path using the given strength."

	| ref editConstraint |
	ref _ self->pathSymbol.
	(ref thingData isNil or: [ref thingData determinedBy isNil])
		ifTrue:
			["easy case: no constraint need be overridden"
			 ref value: aValue.
		 	 DeltaBluePlanner propagateFrom: ref thingData]
		ifFalse:
			["must attempt to override other constraints on the part"
			 editConstraint _ EditConstraint ref: ref strength: strengthSymbol.
			 editConstraint addConstraint.
			 (editConstraint isSatisfied) ifTrue:
				[ref value: aValue.
				 DeltaBluePlanner propagateFrom: ref thingData].
			 editConstraint removeConstraint; destroy].!

setAll: paths to: values
	"Assign the given values to the subparts of this Thing with the given paths using a strength of #preferred."

	self setAll: paths to: values strength: #preferred.!

setAll: paths to: values strength: strengthSymbol
	"Assign the given values to the subparts of this Thing with the given paths using the given strength."

	| refs editConstraints thisRef thisConstraint okay |
	"sanity check"
	(paths size = values size) ifFalse:
		[^self error: 'paths and values must be same size'].

	"build edit constraints"
	refs _ Array new: paths size.
	editConstraints _ Array new: paths size.
	1 to: paths size do:
		[: i |
		 thisRef _ self->(paths at: i).
		 refs at: i put: thisRef.
		 thisConstraint _ EditConstraint ref: thisRef strength: strengthSymbol.
		 editConstraints at: i put: thisConstraint].

	"add all the edit constraints"
	okay _ true.		"true iff all edit constraints are satisfied"
	editConstraints do:
		[: c |
		 c addConstraint.
		 (c isSatisfied) ifFalse: [okay _ false]].

	(okay) ifTrue:
		["do the assignments only if all the edit constraints are satisfied"
		 1 to: refs size do:
			[: i |
			 thisRef _ (refs at: i).
			 thisRef value: (values at: i).
			 DeltaBluePlanner propagateFrom: thisRef thingData]].

	"remove all the edit constraints"
	editConstraints do:
		[: c | c removeConstraint; destroy].! !

!Thing methodsFor: 'history'!

advanceHistory
	"If this thing keeps previous states, then tick its 'clock' to advance the states one step. Things that don't keep history do nothing."!

keepsHistory
	"Some Things keep one or more previous states of some of their variables. Such Things should answer true to this message and should also implement the 'advanceHistory' message."

	^false! !

!Thing methodsFor: 'UI-parts bin'!

explainText

	^self class explainText!

explainText: aString

	self class explainText: aString.!

icon

	^self class partIcon!

icon: aForm

	self class partIcon: aForm.!

name

	^self class name!

name: newName

	(Smalltalk includesKey: newName asSymbol) ifFalse:
		[self class rename: newName].! !

!Thing methodsFor: 'UI-glyph access'!

glyphsComment
	"Many primitive Things obey the basic protocol for glyphs. That is, they may be displayed, selected, and moved. A Thing often makes all the glyphs of its component parts available for all these operations. However, sometimes a Thing may hide some of the glyphs of its components or some aspect of those glyphs, such as the ability to select them. Thus, there are different messages for collecting the glyphs of Thing for various purposes. A Thing may override the default behavior (which is to return all the glyphs of its sub-parts) to control the visibility of its sub-part's glyphs for different operations. The three categories of glyphs are:

	1. visible glyphs -- glyphs that are visible in the display
	2. selectable glyphs -- glyphs that can be selected and moved
	3. input glyphs -- glyphs that respond to keyboard and/or mouse events

These categories are orthogonal, so it is possible to have visible glyphs that cannot be selected and moved or glyphs that can be selected but are not visible (such as the end points of a PlainLine). One could extend this set of classes if necessary; these are just the categories that have been useful so far.

Note: If a Thing is visible, it must respond to glyph protocol. If a Thing is selectable, it must also respond to the 'location' message. If a Thing is an input glyph, it must also respond to the 'wantsKeystrokes' and 'wantsMouse' messages, and if it answers 'true' to one of these messages, it must support the corresponding keyboard or mouse prototcol."!

inputGlyphs
	"Answer the set of my glyphs that are candidates for mouse and/or keyboard input."

	| inputGlyphs |
	inputGlyphs _ OrderedCollection new.
	self inputGlyphsInto: inputGlyphs.
	^self removeDuplicates: inputGlyphs!

inputGlyphsInto: aSet
	"Add all my possible input Thing parts to aSet."

	self thingPartsDo:
		[: p | p inputGlyphsInto: aSet].!

removeDuplicates: aCollection
	"Answer a copy of the given collection without duplicates. The order of the collection is maintained."

	| result |
	result _ aCollection species new: aCollection size.
	aCollection do:
		[: element |
		 (result includes: element) ifFalse: [result add: element]].
	^result!

selectableGlyphs
	"Answer the set of my glyphs that are to be selectable and moveable."

	| selectableGlyphs |
	selectableGlyphs _ OrderedCollection new.
	self selectableGlyphsInto: selectableGlyphs.
	^self removeDuplicates: selectableGlyphs!

selectableGlyphsInto: aSet
	"Add all my selectable Thing parts to aSet."

	self thingPartsDo:
		[: p | p selectableGlyphsInto: aSet].!

visibleGlyphs 
	"Answer the set of my glyphs that are to be visible in the display."

	| glyphs |
	glyphs _ OrderedCollection new.
	self visibleGlyphsInto: glyphs.
	^self removeDuplicates: glyphs!

visibleGlyphsInto: aSet
	"Add all my visible Thing parts to aSet."

	self thingPartsDo:
		[: p | p visibleGlyphsInto: aSet].! !

!Thing methodsFor: 'UI-glyph protocol'!

boundingBox
	"Answer my bounding box."

	^self subclassResponsibility!

containsPoint: aPoint
	"More complex subclasses may refine this method."

	^self boundingBox containsPoint: aPoint!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox 
	"This is the generic Thing display method. Subclasses of Thing may implement more specialized display methods. This method displays all the parts of the Thing."

	self thingPartsDo:
		[: part |
		 part
			displayOn: aDisplayMedium
			at: aDisplayPoint
			clippingBox: clipBox].!

glyphDependsOn
	"Answer a collection of Things whose values affect my display appearance (i.e. my glyph). By default, my display appearance does not depend on anything."

	^Array new!

highlightOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox 
	"This is the default Thing highlighted display method. It draws a box around the Thing. Subclasses may refine."

	aDisplayMedium
		border: ((self boundingBox translateBy: aDisplayPoint)
					insetOriginBy: -2 cornerBy: -2)
		widthRectangle: (1@1 corner: 1@1)
		fillColor: (Color black)
		clippingBox: clipBox.!

intersects: aRectOrThing
	"Answer true if I intersect the given object, which may be either a Rectangle or another Thing."

	(aRectOrThing isMemberOf: Rectangle)
		ifTrue:
			[^aRectOrThing intersects: self boundingBox]
		ifFalse:
			[^aRectOrThing boundingBox intersects: self boundingBox].!

location
	"Answer a PointThing that is my location. This must be implemented by any Thing that may be a selectable glyph."

	self subclassResponsibility! !

!Thing methodsFor: 'UI-keyboard'!

handleKeystroke: aCharacter view: aView
	"Accept the given character. The default behavior is to do nothing."!

keystrokeConstraints
	"Answer a list of constraints that should be added before I accept keyboard input."

	^self subclassResponsibility!

wantsKeystrokes
	"Answer true if I want to get keyboard input. Subclasses may refine this method."

	^false! !

!Thing methodsFor: 'UI-mouse'!

handleMouseDown: mousePoint view: aView
	"The mouse button has been pressed. mousePoint is in local coordinates. The default behavior is to do nothing."!

handleMouseMove: mousePoint view: aView
	"The message is sent repeatedly while the mouse button is pressed. mousePoint is in local coordinates. The default behavior is to do nothing."!

handleMouseUp: mousePoint view: aView
	"The mouse button has gone up. mousePoint is in local coordinates. The default behavior is to do nothing."!

mouseComment

	"Mouse event handling: When mouse input is initiated (with option-mouse button), the following sequence of events occurs:
	1. mouseConstraints is sent to the Thing to get a list of constraints to be added before processing mouse events. The constraints are added and, if they can all be satisfied, processing proceeds. If any of these constraints cannot be satisfied, all the constraints are removed and mouse input is aborted.
	2. handleMouseDown:view: is sent to the Thing (exactly once)
	3. handleMouseMove:view: is sent to the Thing repeatedly while the mouse is down (at least once)
	4. handleMouseUp:view: is sent to the Thing (exactly once)
	5. the constraints are removed.
All of the handleMouseXXX: messages have an argument which is the mouse position in Thing coordinates."!

mouseConstraints
	"Answer a list of constraints that should be added before processing mouse events."

	^self subclassResponsibility!

wantsMouse
	"Answer true if I want to be informed of mouse activity. The default behavior is to answer false."

	^false! !

!Thing methodsFor: 'initialize-merge'!

initialize
	"Initialize my Thing-related fields."

	parents _ Array new.
	constraints _ Array new.
	thingDatas _ Dictionary new.!

merge: pathOne with: pathTwo
	"Merge the two sub-parts of me with the given paths."
	"WARNING: This is meant only for use in initializing new PrimitiveThings, so sanity checks are skipped."

	^self privateMerge: (self partAt: pathOne) into: (self partAt: pathTwo)! !

!Thing methodsFor: 'parents access'!

addParent: aThing
	"Add the given Thing to my list of parents."
	"Details: The instance variable 'parents' is an array of Things. Due to merges, a Thing may have several parents. Each parent appears only once in the parents array (since we do not allow merges between the immediate children of a Thing, it should never be requested to have the same parent appear more than once anyhow)."

	(parents includes: aThing) ifFalse:
		[parents _ parents copyWith: aThing].!

allPartNamesFor: anObject
	"Answer all the parts names for the given object in this Thing. (Due to merges, there may be more than one). Raise an error if anObject is not one of my parts."

	| names |
	names _ OrderedCollection new: 10.
	self partsAndNamesDo:
		[: part : name |
		 (part == anObject) ifTrue: [names add: name]].

	(names isEmpty) ifTrue:
		[^self error:
		 'ThingLab Internal Error: the given object is not one of my parts'].

	^names!

allTopParentPaths
	"Answer a collection of all paths from my top-most parent to me. A path is an OrderedCollection of Symbols. If I have no parents, answer a collection containing one path, the empty path."

	| allPaths pathsToParent thisPath |
	(parents isEmpty) ifTrue:	"no parents, so answer includes just the empty path"
		[^OrderedCollection with: OrderedCollection new].

	allPaths _ OrderedCollection new.
	parents do:
		[: parent |
		 pathsToParent _ parent allTopParentPaths.
		 (parent allPartNamesFor: self) do:
			[: nameInParent |
			 pathsToParent do:
				[: path |
				 thisPath _ path copy addLast: nameInParent; yourself.
				 allPaths add: thisPath]]].
	^allPaths!

firstPartNameFor: anObject
	"Answer the name of the first part containing the given object. Raise an error if anObject is not one of my parts."

	self partsAndNamesDo:
		[: part : name |
		 (part == anObject) ifTrue: [^name]].

	^nil error: 'ThingLab Internal Error: the given object is not one of my parts'!

parents
	"Answer my parents array. See the comment at addParent: for a description of the structure of this array."

	^parents!

removeParent: aThing
	"Remove aThing from my list of parents."

	parents _ parents copyWithout: aThing.!

topParent
	"Answer my top-most parent. If I have no parents, answer myself."

	parents isEmpty
		ifTrue: [^self]
		ifFalse: [^parents first topParent].! !

!Thing methodsFor: 'thingdata access'!

allThingDatasInto: aSet
	"Add to aSet all thingDatas attached me and to my subparts."

	| myThingData |
	myThingData _ self thingDataForYourself.
	(myThingData notNil) ifTrue: [aSet add: myThingData].
	aSet addAll: thingDatas.
	self allThingsDo:
		[: part |
		 (part thingDatas notNil) ifTrue:
			[aSet addAll: part thingDatas]].!

cleanUpThingDataFor: partName 
	"Remove the ThingData for this part of me if and only if it is no longer used by any constraint. This is complicated if the part is merged because there may be pointers to its ThingData in the thingData Dictionaries of its other parents."

	| thingData part |
	thingData _ self thingDataFor: partName.
	(thingData isNil or: [thingData constraints size > 0]) ifTrue:
		[^self].	"thingData is already gone or is still in use"

	part _ self perform: partName asSymbol.
	(part isThing) ifTrue:
		[part parents do:
			[: parent |
			 (parent allPartNamesFor: part) do:
				[: nameInParent |
				 parent localRemoveThingDataFor: nameInParent]]].

	self localRemoveThingDataFor: partName.!

localRemoveThingDataFor: partName
	"Remove and destroy the local ThingData record, if any, for the part with the given name."

	| thingData |
	thingData _ thingDatas removeKey: partName asSymbol ifAbsent: [nil].
	(thingData notNil) ifTrue: [thingData destroy].!

localThingDataFor: partSymbol
	"Answer the ThingData entry for this part of me from my local dictionary or nil if there isn't one."

	^thingDatas at: partSymbol ifAbsent: [nil]!

strengthFor: partName
	"Answer the walkabout strength for this part of me. If there is no thingData for the given part, answer (Strength absoluteWeakest)."

	| thingData |
	thingData _ self thingDataFor: partName.
	(thingData isNil)
		ifTrue: [^Strength absoluteWeakest]
		ifFalse: [^thingData walkStrength].!

thingDataFor: partName 
	"Answer the ThingData for this part of me. If there isn't one locally, look for one among the part's other parents, in case the part participates in a merge. If we find one, make a local pointer to it for faster access in the future."

	| partSymbol part thingData |
	partSymbol _ partName asSymbol.

	"look for a ThingData locally and answer it if we find one"
	thingData _ self localThingDataFor: partSymbol.
	(thingData notNil) ifTrue: [^thingData].

	"if the part isn't a Thing then I am its only parent (only Things can be merged) so it has no ThingData"
	part _ self perform: partSymbol.
	(part isThing) ifFalse: [^nil].	"no ThingData found"
 
	"otherwise, look for a thingData in some other parent of the (Thing) part"
	part parents do:
		[: parent |
		 (parent allPartNamesFor: part) do:
			[: nameInParent |
			 thingData _ parent localThingDataFor: nameInParent.
			 "if we find a ThingData, cache a pointer to it locally and answer it"
			 (thingData notNil) ifTrue:
				[thingDatas at: partSymbol put: thingData.
			 	 ^thingData]]].

	 ^nil		"no ThingData found"!

thingDataForYourself
	"Answer a ThingData for me, if there is one."

	| aParent |
	(parents isEmpty) ifTrue: [^nil].	"no parents"
	aParent _ parents first.
	^aParent thingDataFor: (aParent firstPartNameFor: self)!

thingDataOrAllocateFor: partName
	"Answer the ThingData structure for this part of me. If there isn't one locally, search among all the part's immediate parents to find one. If we find one, make a local pointer to it. If we don't find one, allocate a new ThingData locally."

	| thingData |
	thingData _ self thingDataFor: partName.

	"if we there is currently no ThingData for this part, allocate one"
	(thingData isNil) ifTrue:
		[thingData _ ThingData new].

	"store a pointer to the thingData locally and answer it"
	thingDatas at: partName asSymbol put: thingData.
	^thingData!

thingDatas
	"Answer my ThingData dictionary. The entries of this dictionary map the part names (Symbols) of my constrained parts to ThingData objects."

	^thingDatas! !

!Thing methodsFor: 'constraints'!

addConstraint: aConstraint
	"Add the given constraint to the set of constraints that I own and satisfy it. Answer the constraint."

	constraints _ constraints copyWith: aConstraint.
	aConstraint addConstraint.
	^aConstraint!

constraints
	"Answer the set of constraints that I own."

	^constraints!

constraints: newConstraints

	constraints _ newConstraints.!

removeConstraint: aConstraint
	"Remove the given constraint from the data flow and from the set of constraints that I own."

	aConstraint removeConstraint.
	constraints _ constraints copyWithout: aConstraint.! !

!Thing methodsFor: 'enumerating'!

allThingsDo: aBlock
	"Evaluate aBlock on me and each of my Thing subparts, recursively."

	self thingPartsDo: [: p | p allThingsDo: aBlock].
	aBlock value: self.!

partIndicesDo: aBlock
	"Do aBlock for each of my part variable indices."

	self class partNamesAndIndices do:
		[: nameAndIndex |
		 aBlock value: (nameAndIndex at: 2)].!

partsAndNamesDo: aBlock
	"Do aBlock for each of my parts and its name."

	| name part |
	self class partNamesAndIndices do:
		[: nameAndIndex |
		 name _ (nameAndIndex at: 1).
		 part _ self instVarAt: (nameAndIndex at: 2).
		 aBlock value: part value: name].!

thingPartsAndNamesDo: aBlock
	"Do aBlock for each of my Thing parts and its name."

	| name part |
	self class partNamesAndIndices do:
		[: nameAndIndex |
		 name _ (nameAndIndex at: 1).
		 part _ self instVarAt: (nameAndIndex at: 2).
		 (part isThing) ifTrue: [aBlock value: part value: name]].!

thingPartsDo: aBlock
	"Do aBlock for each of my Thing parts."

	| part |
	self class partNamesAndIndices do:
		[: nameAndIndex |
		 part _ self instVarAt: (nameAndIndex at: 2).
		 (part isThing) ifTrue: [aBlock value: part]].! !

!Thing methodsFor: 'modification'!

allocateNewInstVars
	"Allocate a gaggle of new instance variables for my class. The variables will be given names such as 'unused13'."

	| oldInstVarCount increment newVars |
	oldInstVarCount _ self class instVarNames size.
	increment _ oldInstVarCount min: 64.
	newVars _ ''.
	oldInstVarCount + 1 to: oldInstVarCount + increment do:
		[: i | newVars _ newVars, 'unused' , i printString, ' '].

	"By luck it turns out that the addInstVarName: message works with a string containing multiple instance variables."
	self class addInstVarName: newVars.!

becomeUnencumbered
	"This method clones the class of this Thing to create an identical, but unused, class and prototype. This is used when we wish to modify classes that have existing instances. NOTE: The class of the receiver of this message changes as a side effect!!"

	| newName newThingClass cloneDict myClone newPrototype part |
	"sanity checks"
	(parents size == 0) ifFalse:
		[^self error: 'ThingLab Internal Error --
this Thing is supposed to be a prototype;
it should not have parents'].

	"make a copy of my class, give it a new class name and a new parts bin name, and classify it in the Smalltalk system dictionary."
	newName _ self class successorName asSymbol.
	(Smalltalk includesKey: newName) ifTrue:
		[^self error: 'The class name ''', newName, ''' is already used.'].
	newThingClass _ self class copy.
	newThingClass organization: self class organization deepCopy.
	newThingClass smashName: newName.
	Smalltalk at: newName put: newThingClass.
	SystemOrganization
		classify: newName
		under: 'Things-Built' asSymbol.
	newThingClass initializeByCopying: self class.

	"create a prototype instance for the new class, and then make a copy of myself to become the prototype for the new class. This is a four step process:
		1. create an instance of the new class
		2. clone my structure and values (using clonePass1:)
		3. copy the clone's variables to the instance (thus making it the equivalent of my clone but having the new class)
		4. clone my constraints to the class instance (using clonePass2:)"

	"clone my structure and values"
	cloneDict _ IdentityDictionary new: 200.
	myClone _ self clonePass1: cloneDict.

	"make a thing of the new class and copy the clone's top parts into it"
	newPrototype _ newThingClass basicNew initialize.
	1 to: self class instSize do: [: index |
		part _ myClone instVarAt: index.
		newPrototype instVarAt: index put: part.
		(part isThing) ifTrue:
			["I will the parent after the 'become:' coming up"
			 part removeParent: myClone.
			 part addParent: self]].

	"copy the constraints to the new thing"
	newPrototype constraints: (NeedToClone with: self constraints).
	cloneDict at: self put: self.	"this is because of the 'become:' coming up"
	newPrototype clonePass2: cloneDict.

	"fix up the prototypes for life after the 'become:'"
	newThingClass prototype: self.
	self class prototype: newPrototype.

	"finally, I become the new prototype, and he becomes me"
	self become: newPrototype.!

findEmptyInstVar
	"Answer the index of an unused instance variable in my class. Use one of the pre-allocated instance variables if possible, otherwise allocate some more and try again."

	| partsSet allInstVars |
	partsSet _ Set new: 40.
	self class partNamesAndIndices do:
		[: entry | partsSet add: entry first asString].
	allInstVars _ self class instVarNames.
	1 to: allInstVars size do:
		[: i |
		 (partsSet includes: (allInstVars at: i))
			ifFalse: [^i + self class instOffset]].		"found a free inst var"

	"allocate some new instance variables and try again"
	self allocateNewInstVars.
	^self findEmptyInstVar! !

!Thing methodsFor: 'cloning'!

clonePass1: cloneDictionary 
	"Recursively clone myself and each of my parts, recording all clones in the given clone dictionary. If I am already in the clone dictionary, then answer a pointer to my clone, rather than copying myself again; this will preserve the acyclic structure of the sub-part graph. This operation copies the part-whole structure of a Thing and establishes its parent pointers but it does not copy the constraints or ThingData dictionaries."

	| myClone oldPart newPart |
	myClone _ cloneDictionary at: self ifAbsent: [nil].
	(myClone notNil) ifTrue: [^myClone].	"I've already been cloned"

	myClone _ self shallowCopy initialize.
	myClone constraints: (NeedToClone with: constraints).
	self partIndicesDo:
		[: i |
		 oldPart _ self instVarAt: i.
		 (oldPart isThing)
			ifTrue:
				[newPart _ oldPart clonePass1: cloneDictionary.
		 		 newPart addParent: myClone]
			ifFalse: [newPart _ oldPart copy].
		 myClone instVarAt: i put: newPart].
	cloneDictionary at: self put: myClone.
	^myClone!

clonePass2: cloneDictionary
	"Clone my constraints. This method executes in the context of the newly forming clone. Because there may be multiple paths to a part and we don't wish to clone a set of constraints multiple times, the NeedToClone class is used to mark constraints that have not yet been cloned. If we encounter a part who's constraints instance variable is not marked with a 'NeedToClone' then we need not look at its sub-parts."

	| newC |
	(constraints isMemberOf: NeedToClone) ifTrue:
		[constraints _ constraints data collect:
			[: c |
			 newC _ c cloneUsing: cloneDictionary.
			 newC addConstraint.
			 newC].
		 self thingPartsDo: [: p | p clonePass2: cloneDictionary]].! !

!Thing methodsFor: 'merging'!

change: thingOne to: thingTwo
	"Replace all my references to thingOne with references to thingTwo."

	self partIndicesDo:
		[: i |
		 ((self instVarAt: i) == thingOne) ifTrue:
			[self instVarAt: i put: thingTwo]].!

conflictsBetween: partOne and: partTwo
	"We intend to merge the given parts. Look for required-constraint conflicts between the parts themselves and all the corresponding parts of their sub-part trees and answer true if a conflict is discovered. The parts are assumed to be Things of the same class."
	"NOTE: We do NOT check for potential cycle conflicts."

	^(self
		thingData: partOne thingDataForYourself
		conflictsWith: partTwo thingDataForYourself) or:
	  [self subPartConflictsBetween: partOne and: partTwo]!

externalConstraintsFor: aThing
	"Answer the set of constraints pointing to but not owned by aThing and/or its subparts."

	| ownedConstraints allConstraints thingData |
	ownedConstraints _ IdentitySet new.
	allConstraints _ IdentitySet new.
	aThing allThingsDo:
		[: otherThing |
		 ownedConstraints addAll: otherThing constraints.
		 otherThing thingDatas do:
			[: thingDataa |
			 allConstraints addAll: thingDataa constraints]].

	"add top-level constraints to allConstraints"
	thingData _ aThing thingDataForYourself.
	(thingData notNil) ifTrue:
		[allConstraints addAll: thingData constraints].

	"external constraints = allConstraints - ownedConstraints"
	^allConstraints select: [: c | (ownedConstraints includes: c) not]!

privateMerge: partOne into: partTwo
	"Merge partOne with partTwo and answer true if the operation succeeds. The parts must share a common ancestor. After the merge, partOne will be discarded."

	"Here is an outline the merge operation:
	1. A check is made of all thingDatas for corresponding pairs
	   of sub-parts to be sure that no required constraint conflicts
	   would be caused by the merge.
	2. Constraints external (i.e. not owned by any sub-part)
	   to both part trees are collected and temporarily removed.
	3. The pointers to partOne in its parent are pointed to partTwo.
	4. The parents of partOne are added to partTwo.
	5. partOne is destroyed (but not its subparts, which may still be in use!!)
	6. The constraints collected in step 2 are re-added."

	| removedConstraints |
	"step 1"
	(self conflictsBetween: partOne and: partTwo) ifTrue:
		[^false].	"merging failed"

	"step 2"
	removedConstraints _ IdentitySet new.
	removedConstraints addAll: (self externalConstraintsFor: partOne).
	removedConstraints addAll: (self externalConstraintsFor: partTwo).
	removedConstraints do:
		[: constraint |
		 constraint removeConstraint].

	"steps 3 and 4"
	(partOne parents copy) do:
		[: parent |
		 parent change: partOne to: partTwo.
		 partTwo addParent: parent.
		 partOne removeParent: parent].

	"step 5"
	"protect subparts from destruction; they may still be in use"
	partOne partIndicesDo: [: i | partOne instVarAt: i put: nil].
	partOne destroy.

	"step 6"
	removedConstraints do:
		[: constraint | constraint addConstraint].

	"merging was successful"
	^true!

subPartConflictsBetween: thingOne and: thingTwo
	"Check for required-constraint conflicts between the corresponding sub-parts of thingOne and thingTwo and answer true if a conflict is discovered. thingOne and thingTwo are assumed to be Things of the same class."

	thingOne partsAndNamesDo:
		[: part : name |
		 (self
			thingData: (thingOne thingDataFor: name)
			conflictsWith: (thingTwo thingDataFor: name)) ifTrue:
				[^true].
		 (part isThing) ifTrue:
			[(self
				subPartConflictsBetween: part
				and: (thingTwo perform: name)) ifTrue:
					[^true]]].

	"no conflicts found"
	^false!

thingData: thingDataOne conflictsWith: thingDataTwo
	"Answer true if a required-constraint conflict exists between the given ThingDatas for parts we propose to merge."

	"no conflicts if one part is unconstrained"
	(thingDataOne isNil | thingDataTwo isNil) ifTrue: [^false].

	"is there a required constraint conflict?"
	((thingDataOne walkStrength == Strength required) &
	 (thingDataTwo walkStrength == Strength required)) ifTrue: [^true].

	"no conflicts"
	^false! !

!Thing methodsFor: 'unmerging/removing'!

extractFromMerge: thingRef
	"The part pointed to by thingRef will be extracted from the merge that it is in. This method only unmerges at the level of thingRef; it does not unmerge merged sub-parts."
	"Details: When unmerging, we must separate the constraints attached to what used to be the single, merged part. After the unmerge, some of these constraints will continue to point to the old part, some will point to the new part, and some will point to both parts. This process is implemented by removing all the constraints that touch the merged part and reinstating them after the unmerge. Because the constraints have built-in references, they will be reinstated in their correct locations."

	| parent oldPart removedConstraints cloneDict newPart |
	parent _ thingRef finalVariable.
	oldPart _ thingRef value.

	"remove all constraints for the merge and remember them"
	removedConstraints _
		parent removeConstraintsForPart: thingRef part.

	"clone a copy of the old part to become the new part"
	"(the clone will get copies of all constraints owned by the part)"
	BusyCursor inc.
	newPart _ oldPart clone.

	"insert newPart into its parent and fix the parents of both parts"
	BusyCursor inc.
	parent change: oldPart to: newPart.
	oldPart removeParent: parent.
	newPart addParent: parent.

	"reinstate the constraints"
	removedConstraints do:
		[: c |
		 BusyCursor inc.
		 c addConstraint].!

isolate: thingRef within: rootRef
	"Isolate the sub-parts tree for the Thing pointed to by thingRef from all merges external to rootRef. Used when removing a part that might be merged with some other parts."

	| top thing internalRef externalRef |
	thingRef refresh.
	top _ thingRef topParent.
	thing _ thingRef value.

	"look for an external reference to me"
	 externalRef _ nil.
	 (thing allTopParentPaths) do:
		[: path |
		 (rootRef isPrefixOf: path) ifFalse:
			[externalRef _ (Reference on: top path: path)]].

	"if there was an external reference then, extract myself from the merge"
	 (externalRef notNil) ifTrue:
		[self extractFromMerge: thingRef].

	"do the same for my sub-parts"
	thing thingPartsAndNamesDo:
		[: part : partName |
		 self
			isolate: (thingRef, (Array with: partName))
			within: rootRef].!

removeConstraintsForPart: partName
	"Remove all constraints for the part of me with the given name and all its sub-parts and add the removed constraints to the given set."

	| allConstraints thingData part |
	allConstraints _ IdentitySet new.

	"collect top-level constraints"
	thingData _ self thingDataFor: partName.
	(thingData notNil) ifTrue:
		[allConstraints addAll: thingData constraints].

	"collect sub-part constraints"
	part _ self perform: partName asSymbol.
	(part isThing) ifTrue:
		[part allThingsDo:
			[: subPart |
			 subPart thingDatas do:
				[: thingDataa |
				 allConstraints addAll: thingDataa constraints]]].

	"remove the collected constraints"
	allConstraints do:
		[: c |
		 BusyCursor inc.
		 c removeConstraint].

	^allConstraints! !

!Thing methodsFor: 'printing'!

definitionString
	"Answer a string containing my definition for the Thing definer."

	| out |
	out _ (String new: 200) writeStream.
	out nextPutAll: self name; cr.
	self partsAndNamesDo:
		[: part : name |
		 out tab; nextPutAll: name, ': '.
		 out nextPutAll: part class name; cr].
	^out contents!

longPrintOn: aStream

	aStream nextPutAll: '('.
	self shortPrintOn: aStream.
	self partsAndNamesDo:
		[: part : partName |
		 aStream space.
		 aStream nextPutAll: partName.
		 aStream nextPut: $:.
		 ((self thingDataFor: partName) notNil) ifTrue:
			[aStream nextPut: $:].
		 part printOn: aStream].
	aStream nextPutAll: ')'.!

printOn: aStream

	(Sensor leftShiftDown)
		ifTrue: [self longPrintOn: aStream]
		ifFalse: [self shortPrintOn: aStream].!

shortPrintOn: aStream

	aStream nextPutAll: self class name, '(', self hash printString, ')'.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Thing class
	instanceVariableNames: 'partIcon explainText partNamesAndIndices externalParts useView prototype '!


!Thing class methodsFor: 'class initialization'!

initialize
	"Thing initialize"

	"DefaultIcons holds default PartsBin icons (gizmos)."
	DefaultIcons _ OrderedCollection new.
	DefaultIcons add: (Form
		extent: 16@16
		fromArray: #(6112 10256 18448 18400 19012 19018 19066 522 634 586 580 2016 2576 5128 10756 16380)
		offset: 0@0).
	DefaultIcons add: (Form
		extent: 16@16
		fromArray: #(24582 40953 40953 25158 576 576 1504 1824 2160 3024 7688 4344 10116 15372 16634 32766)
		offset: 0@0).
	DefaultIcons add: (Form
		extent: 16@16
		fromArray: #(8 24604 61474 51228 17416 9212 32766 49155 38229 32769 32769 32769 38937 42021 26598 6168)
		offset: 0@0).
	DefaultIcons add: (Form
		extent: 16@16
		fromArray: #(32766 49155 37137 43689 37137 49155 32766 20490 20490 20490 20490 20490 21034 36185 33089 32318)
		offset: 0@0).
	DefaultIcons add: (Form
		extent: 16@16
		fromArray: #(1160 2740 4546 992 3640 7148 4644 15342 10570 14670 320 320 320 16254 24579 16382)
		offset: 0@0).
	DefaultIcons add: (Form
		extent: 16@16
		fromArray: #(0 0 0 0 0 0 0 56 124 7422 16129 32725 32929 43711 32992 65408)
		offset: 0@0).

	DefaultIcons _ DefaultIcons asArray.! !

!Thing class methodsFor: 'defining'!

defineNewThing
	"Create a new subclass of Thing for a new type of Thing. Give the new Thing a name like 'Thing45'. Answer the prototype instance of the new Thing."

	^self defineNewThingNamed: ('Thing', ThingLabII uniqueNumber printString)!

defineNewThingNamed: newThingName
	"Create a new subclass of Thing for a new type of Thing. Give the new Thing the given name. Answer the prototype instance of the new Thing's class."

	| className newThingClass |
	className _ ((Smalltalk includesKey: newThingName)
		ifTrue: [newThingName, 'v', ThingLabII uniqueNumber printString]
		ifFalse: [newThingName]) asSymbol.

	BusyCursor begin.
	newThingClass _ Thing
		subclass: className
		instanceVariableNames: 'unused1 unused2 unused3 unused4 unused5 unused6 unused7 unused8 unused9 unused10 unused11 unused12 unused13 unused14 unused15 unused16'
		classVariableNames: ''
		poolDictionaries: ''
		category: 'Things-Built'.

	BusyCursor inc.
	newThingClass initializeBuiltThing.

	BusyCursor end.
	^newThingClass prototype!

defineNewThingNamed: newThingName withParts: nameList toHold: partsList
	"Create a new subclass of Thing for a new type of Thing with the given parts. Give the new Thing the given name. Answer the prototype instance of the new Thing's class."

	| className newThingClass parts proto |
	className _ ((Smalltalk includesKey: newThingName asSymbol)
		ifTrue: [newThingName, 'v', ThingLabII uniqueNumber printString]
		ifFalse: [newThingName]) asSymbol.

	parts _ (String new: 100) writeStream.
	nameList do: [: part | parts nextPutAll: part; space].
	newThingClass _ Thing
		subclass: className
		instanceVariableNames: parts contents
		classVariableNames: ''
		poolDictionaries: ''
		category: 'Things-Built'.

	newThingClass initializeBuiltThing.
	proto _ newThingClass prototype.
	proto addPartsNamed: nameList toHold: partsList.
	^newThingClass prototype!

defineNewThingWithParts: nameList toHold: partsList
	"Create a new subclass of Thing for a new type of Thing with the given parts. Answer the prototype instance of the new Thing's class."

	^self
		defineNewThingNamed: ('Thing', ThingLabII uniqueNumber printString)
		withParts: nameList
		toHold: partsList! !

!Thing class methodsFor: 'instance creation'!

cloneFor: aThing
	"Answer a copy of my prototype to be used as a sub-part of aThing (i.e. aThing will be made a parent of the copy). This method is 'syntactic sugar' for building the structure of primitive Things."

	^(self prototype clone) addParent: aThing!

new
	"Answer a copy of my prototype."

	^self prototype clone! !

!Thing class methodsFor: 'access'!

basicPrototype
	"Answer the contents of my prototype field. Do not create a new prototype."

	^prototype!

constructionView
	"Answer the class of the Thing that was compiled to create me. Non-module Things have no construction view, so answer nil. This method is overridden in ModuleThing class."

	^nil!

constructionView: aThingClass
	"Set the class of the Thing that was compiled to create me."

	self subclassResponsibility!

explainText
	"Answer my explanation."

	^explainText!

explainText: aString
	"Set my explanation."

	explainText _ aString.!

externalParts
	"Answer my set of external parts."

	^externalParts!

externalParts: collectionOfPartNames
	"Set my set of external parts. These are the parts that will be visible to the outside world after compiling me into a module."

	externalParts _ collectionOfPartNames.!

partIcon
	"Answer my part icon for the parts bin."

	^partIcon!

partIcon: aForm
	"Set my part icon for the parts bin."

	partIcon _ aForm.!

prototype
	"Answer my prototype. This is the actual prototype, NOT a copy."

	(prototype isNil) ifTrue: [prototype _ self basicNew initialize].
	^prototype!

useView
	"Answer class of the module Thing compiled from me or nil if I have never been compiled."

	^useView!

useView: aClass
	"Set the class of the Thing that was compiled from me."

	useView _ aClass.! !

!Thing class methodsFor: 'private-initialize-destroy'!

aDefaultIcon
	"Answer one of the default icons at random."

	^DefaultIcons at:
		((Random new next * DefaultIcons size) truncated + 1)!

destroy
	"Eliminate any possibility of circular data structures and remove myself (a class) from the system."

	partIcon _ nil.
	explainText _ nil.
	partNamesAndIndices _ nil.
	externalParts _ nil.
	useView _ nil.
	prototype _ nil.
	self removeFromSystem.!

initializeBuiltThing
	"Initialize the class for a newly defined Thing."

	partIcon _ self aDefaultIcon deepCopy.
	explainText _ 'This Thing was constructed by the user.'.
	partNamesAndIndices _ OrderedCollection new.
	externalParts _ OrderedCollection new.
	useView _ nil.
	prototype _ self basicNew initialize.!

initializeByCopying: aThingClass
	"Initialize this Thing subclass by copying its fields from the given class. Used when creating an unencumbered class."

 	partIcon _ aThingClass partIcon deepCopy.
	explainText _ aThingClass explainText deepCopy.
	partNamesAndIndices _ aThingClass partNamesAndIndices deepCopy.
	externalParts _ aThingClass externalParts deepCopy.
	useView _ nil.
	prototype _ nil.!

initializePartsList
	"Initialize the 'partsNamesAndIndices' class instance variable based on my instance variable names."

	| allInstVarNames |
	allInstVarNames _ self allInstVarNames.
	partNamesAndIndices _ OrderedCollection new: allInstVarNames size.
	(self instOffset + 1) to: allInstVarNames size do:
		[: i |
		 partNamesAndIndices addLast:
			(Array
				with: (allInstVarNames at: i) asSymbol
				with: i)].!

initializePrimitive
	"Initialize the class for a primitive Thing."

	partIcon _ self aDefaultIcon.
	explainText _ 'This is a Primitive Thing.'.
	self initializePartsList.
	externalParts _ OrderedCollection new.
	useView _ nil.
	prototype _ self basicNew initialize.
	prototype
		initializeStructure;
		initializeValues;		"initialize values so constraints don't fail"
		initializeConstraints;
		initializeValues.		"reassert values after adding constraints"!

prototype: aThing
	"Private!! Register my prototype. Used by becomeUnencumberedClass."

	prototype _ aThing.!

successorName
	"Create a new, unique name for this class that is similar but not identical to the current name."

	| rs count str |
	rs _ ReadStream on: self name asString.
	rs setToEnd; skip: -1.
	[(rs position > 1) & (rs peek isDigit)]
		whileTrue: [rs skip: -1].
	((rs position > 1) & (rs peek = $v))
		ifTrue: 
			[count _ rs position.
			 rs reset.
			 str _ rs next: count]
		ifFalse: [str _ rs contents].
	str _ str, 'v', ThingLabII uniqueNumber printString.
	^str asSymbol!

vaporize
	"Delete this thing and its class."
	"Warning: Use with caution!!!!"

	prototype destroyAndRemoveClass.! !

!Thing class methodsFor: 'private-parts'!

instOffset
	"This is the number of internal (i.e. non-part) instance variables every Thing has. This offset must be added to change local inst var indices into indices for the object as a whole."

	^3!

partNamesAndIndices
	"Answer a collection of (name, instVarIndex) pairs for my parts."

	^partNamesAndIndices!

removeInstVarNamed: nameString 
	"Rename the instance the the given part to 'unusedNNN'."

	| instVars |
	instVars _ self instVarNames.
	1 to: instVars size do:
		[: i |
		 (nameString = (instVars at: i)) ifTrue: 
			[^self
				renameInstVarAt: i
				as: 'unused', i printString]].
	self error: 'ThingLabII Internal Error -- could not find instVar with given name'.!

removePartNamed: partSymbol
	"Remove the part with the given name and its access methods."

	"remove the part as an instance variable and also remove its records in partNamesAndIndices and externalParts"
	self removeInstVarNamed: partSymbol asString.
	partNamesAndIndices _
		partNamesAndIndices select:
			[: entry | entry first ~= partSymbol].
	externalParts remove: partSymbol ifAbsent: [].

	"remove the get and put methods"
	self removeSelector: partSymbol.
	self removeSelector: ('prim', partSymbol, ':') asSymbol.!

renameInstVarAt: index as: nameString
	"Rename the instance variable with the given index in this class."

	self instVarNames at: index put: nameString.! !

!Thing class methodsFor: 'private-compiling'!

compileAccessMethodsFor: thingsOrObjects named: partNames
	"Compile access methods for the given parts. The two arguments should be sequenceable collections of the same size. thingsOrObjects are prototypes for the parts (either Things or normal Smalltalk objects) and partNames are the names for these parts."

	| cue encoder |
	cue _ CompilationCue new initializeWithSource: nil context: nil
        receiver: Object class: Object environment: (Environment new initialize) requestor: nil.
	encoder _ (EncoderForSistaV1 new) init: cue notifying: nil.
	partNames with: thingsOrObjects do:
		[: partName : thingOrObject |
		 BusyCursor inc.
		 self compileGetMethodFor: partName asString encoder: encoder.
		 BusyCursor inc.
		 thingOrObject isThing
			"ifTrue:
				[self
					compileThingPutMethodFor: partName asString
					asA: thingOrObject
					encoder: encoder]"
			ifFalse:
				[self
					compileNonThingPutMethodFor: partName asString
					encoder: encoder]].!

compileGetMethodFor: partName encoder: anEncoder
	"Compile the get access method for the part with the given name. The method will take the form:

		XXX
			^XXX"

	| selector returnNode block methodNode |
	selector _ partName asSymbol.
	returnNode _ ReturnNode new expr: (anEncoder encodeVariable: partName).
	block _ BlockNode new
		statements: (OrderedCollection with: returnNode)
		returns: true.
	methodNode _ MethodNode new
		selector: selector
		arguments: #()
		precedence: selector precedence
		temporaries: #()
		block: block
		encoder: anEncoder
		primitive: 0.
	self addSelector: selector withMethod: (methodNode generate).
	self organization classify: selector under: #access.!

compileNonThingPutMethodFor: partName encoder: anEncoder
	"Compile the put method for the part with the given name. The part is assumed to contain a normal Smalltalk object, not a Thing. The method will take the form:

		primXXX: arg
			XXX _ arg"

	| selector arg assignment block methodNode |
	selector _ ('prim', partName, ':') asSymbol.
	arg _ anEncoder autoBind: 'arg'.
	assignment _ AssignmentNode new
		variable: (anEncoder encodeVariable: partName)
		value: arg
		from: anEncoder.
	block _ BlockNode new
		statements: (OrderedCollection with: assignment)
		returns: false.
	block returnSelfIfNoOther.	"add '^self'"
	methodNode _ MethodNode new
		selector: selector
		arguments: (Array with: arg)
		precedence: selector precedence
		temporaries: #()
		block: block
		encoder: anEncoder
		primitive: 0.
	self addSelector: selector withMethod: methodNode generate.
	self organization classify: selector under: #access.!

compileThingPutMethodFor: partName asA: aThing encoder: anEncoder
	"Compile the put method for the part with the given name. The part is assumed to contain a Thing like the given example. The method will take the form:

		primXXX: arg
			XXX primYY: arg YY.
			XXX primZZ: arg ZZ"

	| selector arg rcvr statements s m1 block methodNode |
	selector _ ('prim', partName, ':') asSymbol.
	arg _ anEncoder autoBind: 'arg'.
	rcvr _ anEncoder encodeVariable: partName.
	statements _
		aThing class partNamesAndIndices collect: 
			[: entry | 
			 s _ entry first asSymbol.
			 m1 _ MessageNode new
				receiver: arg
				selector: s
				arguments: #()
				precedence: s precedence
				from: anEncoder.
			 s _ ('prim', entry first, ':') asSymbol.
			 MessageNode new
				receiver: rcvr
				selector: s
				arguments: (Array with: m1)
				precedence: s precedence
				from: anEncoder].
	block _ BlockNode new
		statements: statements
		returns: false.
	block returnSelfIfNoOther.	"add '^self'"
	methodNode _ MethodNode new
		selector: selector
		arguments: (Array with: arg)
		precedence: selector precedence
		temporaries: #()
		block: block
		encoder: anEncoder
		primitive: 0.
	self addSelector: selector withMethod: methodNode generate.
	self organization classify: selector under: #access.! !


Object subclass: #DeltaBluePlanner
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII'!
DeltaBluePlanner comment:
'I embody the DeltaBlue algorithm given in "The DeltaBlue Algorithm: An Incremental Constraint Hierarchy Solver" by Bjorn N. Freeman-Benson and John Maloney.
'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DeltaBluePlanner class
	instanceVariableNames: 'currentMark '!


!DeltaBluePlanner class methodsFor: 'add/remove'!

incrementalAdd: aConstraint
	"Entry point for adding a constraint. Add the given constraint and incrementally update the dataflow graph."

	(aConstraint isSatisfied) ifFalse:
		[self chooseNewMark.
		 self privateAddConstraint: aConstraint].!

incrementalRemove: aConstraint
	"Entry point for removing a constraint. Remove the given constraint and incrementally update the dataflow graph."

	(aConstraint isSatisfied) ifTrue:
		[self chooseNewMark.
		 self privateRemoveConstraint: aConstraint unmarkedOnly: false].! !

!DeltaBluePlanner class methodsFor: 'planning'!

extractPlanFromChangingThingDatas: thingDatas
	"Extract a plan for the constraints on the given set of changing (i.e. non-stay) thingDatas. If optimizeStays is true, it is assumed that all variables marked 'stay' were computed as the constraints were added. Since these variables will not change, they (and any variables upstream of them) will not be recomputed by the plan. If optimizeStays is false, all variables will be recomputed by the plan."
	"Two pass implementation:
	  1. Build a plan potentially containing redundant constraints. Clear
	     marks on all constraints as they are added to the plan.
	  2. Filter out duplicate constraints by using marks."

	| plan todo filteredPlan |
	plan _ Plan new: 1000.
	todo _ OrderedCollection new: 1000.
	thingDatas do:
		[: td || c |
		 todo add: td.
		 c _ td determinedBy.
		 (c notNil) ifTrue:
			 [(c shouldUseGiven: true) ifTrue:
				[plan addLast: c.
				 c clearCommitted]]].

	[todo isEmpty] whileFalse:
		[ | td | td _ todo removeFirst.
		 td usedBy do:
			[: c |
			 (c shouldUseGiven: true) ifTrue:
				[plan addLast: c.
				 c clearCommitted].
			 c outDatasDo: [: out | todo add: out]]].

	filteredPlan _ Plan new: (plan size * 2) + 2.	"avoid growing"
	plan reverseDo:
		[: c |
		 (c isCommitted not) ifTrue:
			[filteredPlan addFirst: c].
		 c setCommitted].
	plan _ todo _ nil.
	^filteredPlan!

extractPlanFromThing: aThing 
	"Extract the current solution for the given Thing's constraints as a Plan."
	"Details: There are two ways to extract a dataflow from the current DeltaBlue plan: top-down and bottom-up. Bottom-up starts with the terminal nodes and works 'upstream' in the dataflow graph. Top-down starts at all the source nodes and works down. This method implements bottom-up."

	| allThingDatas |
	allThingDatas _ IdentitySet new: 100.
	aThing allThingsDo:
		[: thing | allThingDatas addAll: thing thingDatas].
	^self extractPlanFromThingDatas: allThingDatas optimizeStays: true!

extractPlanFromThingDatas: thingDatas optimizeStays: optimizeStays
	"Extract a plan for the constraints on the given set of thingDatas. If optimizeStays is true, it is assumed that all variables marked 'stay' were computed as the constraints were added. Since these variables will not change, they (and any variables upstream of them) will not be recomputed by the plan. If optimizeStays is false, all variables will be recomputed by the plan."

	| hotConstraints plan hotC |
	currentMark _ Time millisecondClockValue.
	hotConstraints _ OrderedCollection new: 200.
	plan _ Plan new: 100.
	thingDatas do:
		[: thingData |
		 (thingData constraints size > 0) ifTrue:
		 	[(thingData determinedBy isNil) ifTrue:
				[thingData mark: currentMark].
			 thingData constraints do:
				[: c |
				 (c isSatisfied)
					ifTrue: [c clearCommitted]
					ifFalse: [c setCommitted].
				 ((c isSatisfied) and:
				  [c inputsKnown: currentMark]) ifTrue:
					[hotConstraints addFirst: c]]]].

	[hotConstraints isEmpty] whileFalse:
		[hotC _ hotConstraints removeFirst.
		 ((hotC isCommitted not) and:
		  [hotC inputsKnown: currentMark]) ifTrue:
			[(hotC shouldUseGiven: optimizeStays) ifTrue:
				[plan addLast: hotC].
			 hotC setCommitted.
			 hotC outDatasDo:
				[: out |
				 out mark: currentMark.
				 out usedBy do:
					[: c |
					 (c isCommitted) ifFalse:
						[hotConstraints addLast: c]]]]].
	^plan! !

!DeltaBluePlanner class methodsFor: 'value propagation'!

propagateFrom: aThingData
	"The variable associated with the given ThingData has changed. Propagate new values downstream."

	| todo |
	(aThingData isNil) ifTrue: [^self].	"no constraints since ThingData is nil"

	todo _ OrderedCollection new: 100.
	todo add: aThingData.
	[todo isEmpty] whileFalse:
		[(todo removeFirst usedBy) do:
			[: constraint |
			 constraint execute.
			 constraint whichMethod
				outDatasIn: constraint thingDatas
				do: [: out | todo add: out]]].! !

!DeltaBluePlanner class methodsFor: 'private'!

addPropagateFrom: aConstraint execFlag: execFlag
	"Recompute the walkabout strengths and stay flags of all variables downstream of the given constraint. If execFlag is true, also recompute the actual values of all downstream variables whose stay flag is true. If the propagation succeeds without finding a cycle, answer true. If a cycle is detected, undo the propagation and answer false."

	| bindings thingDatas refs outs savedDBData i out cycleFound entry varIndex |
	"save output variable state to allow restoring"
	bindings _ aConstraint whichMethod bindings.
	thingDatas _ aConstraint thingDatas.
	refs _ aConstraint variables.
	outs _ OrderedCollection new: 12.
	savedDBData _ OrderedCollection new: 12.
	i _ bindings size.
	[i > 0] whileTrue:
		[((bindings at: i) == $o) ifTrue:
			[out _ thingDatas at: i.
			 outs add: out.
			 savedDBData add:
				(Array
					with: i
					with: ((refs at: i) value)
					with: out stay
					with: out walkStrength)].
		 i _ i - 1].

	"calculate and propagate new values"
	aConstraint calculateDeltaBlueData: execFlag.
	cycleFound _ self
		propagateFrom: outs
		watchFor: (aConstraint inDatas)
		execFlag: execFlag.

	"cycle found: must restore all values to their previous states"
	cycleFound ifTrue:
		[i _ savedDBData size.
		 [i > 0] whileTrue:
			[entry _ savedDBData at: i.
			 varIndex _ entry at: 1.
			 out _ thingDatas at: varIndex.
			 (refs at: varIndex) value: (entry at: 2).
			 out stay: (entry at: 3).
			 out walkStrength: (entry at: 4).
			 i _ i - 1].
		 self propagateFrom: outs watchFor: nil execFlag: execFlag].

	^cycleFound not!

chooseNewMark
	"Select a new mark value."

	currentMark _ Time millisecondClockValue.
	(currentMark == 0) ifTrue: [currentMark _ 1].
		"zero always means unmarked"!

privateAddConstraint: aConstraint
	"Attempt to add the given constraint. If successful, resatisfy any overridden constraints. The markValue is not reset to avoid getting into an infinite loop alternately satisfying and unsatisfying a cycle of constaints."

	| overridden c |
	overridden _ OrderedCollection new: 50.
	self satisfy: aConstraint overriddenInto: overridden.
	[overridden isEmpty] whileFalse:
		[c _ overridden removeFirst.
		 self satisfy: c overriddenInto: overridden].!

privateRemoveConstraint: aConstraint unmarkedOnly: unmarkedFlag
	"Remove the given constraint and incrementally update the dataflow graph."

	| outVars oldMark hotConstraints multiOutConstraints |
	"Take note of variables to propagate from. If this is part of a retract operation, we propagate only from the unmarked (downstream) outputs. Otherwise, we propagate from all outputs."
	outVars _ OrderedCollection new: 12.
	aConstraint outDatasDo:
		[: out |
		 unmarkedFlag
			ifTrue:
				[(out mark ~~ currentMark) ifTrue:
					[outVars add: out]]
			ifFalse:
				[outVars add: out]].

	"If this is a retract operation, choose a temporary mark, remembering the old one."
	unmarkedFlag ifTrue:
		[oldMark _ currentMark.
		 self chooseNewMark].

	"NOTE: unsatisfy sets whichMethod to nil"
	aConstraint unsatisfy.

	"propagate DeltaBlue data and collect the affected constraints, sorted in order of decreasing strength"
	hotConstraints _ (SortedCollection new: 200)
		sortBlock: [: i : j | i isStrongerThan: j].
	multiOutConstraints _ OrderedCollection new: 100.
	self
		removePropagateFrom: outVars
		unsatisfiedInto: hotConstraints
		multiOutsInto: multiOutConstraints.

	"consider currently unsatisfied constraints for possible resatisfaction (except the one we are removing!!)"
	hotConstraints do:
		[: c |
		 (c ~~ aConstraint) ifTrue:
			[self incrementalAdd: c]].

	"re-add constraints with multiple outputs"
	multiOutConstraints do:
		[: c |
		 (c ~~ aConstraint) ifTrue:
			[c addToGraph.
			 self incrementalAdd: c]].

	"restore old mark (which might have been messed up by re-adding constraints"
	unmarkedFlag ifTrue: [currentMark _ oldMark].!

propagateFrom: vars watchFor: cycleVars execFlag: execFlag
	"Recompute the walkabout strengths and stay flags of all variables downstream of the given variables. If execFlag is true, compute the values of variables whose stay flag is true. If cycleVars is not nil and any of the variables in cycleVars is encountered, stop and answer true. Otherwise, answer false."

	| todo outs i outVar |
	todo _ vars copy.
	[todo isEmpty] whileFalse:
		[(todo removeFirst usedBy) do:
			[: constraint |
			 outs _ constraint calculateDeltaBlueData: execFlag.
			 i _ outs size.
			 [i > 0] whileTrue:
				[outVar _ outs at: i.
				 ((cycleVars notNil) and:
				  [cycleVars includes: outVar]) ifTrue:
					[^true	"cycle found"].
				 todo add: outVar.
				 i _ i - 1]]].
	^false	"no cycle found"!

removePropagateFrom: vars unsatisfiedInto: hotConstraints multiOutsInto: multiOuts
	"Recompute the walkabout strengths and stay flags of all variables downstream of the given set of variables, collecting all unsatisfied downstream constraints into hotConstraints and all multiple output constraints into multiOuts."

	| todo |
	todo _ OrderedCollection new: 100.
	vars do:
		[: var |
		 var walkStrength: Strength absoluteWeakest.
		 var stay: true.
		 todo add: var].

	[todo isEmpty] whileFalse:
		[| var | var _ todo removeFirst.
		 var constraints do:
			[: c |
			 (c isSatisfied) ifFalse:
				[hotConstraints add: c]].
		 var usedBy do:
			[: c |
			 (c hasMultipleOutputs)
				ifTrue:
					[self incrementalRemove: c.
					 c removeFromGraph.
					 multiOuts add: c]
				ifFalse:
					[todo add: ((c calculateDeltaBlueData: false) at: 1)]]].!

retract: aConstraint
	"Retract the given constraint because it is being overridden by another constraint. If the constraint has only one output, no recomputation of DeltaBlue information is necessary and it can simply be unsatisfied. If the constraint has more than one output, retracting it is more expensive as we must resatisfying constraints downstream of its unmarked outputs. This is necessary because before the constraint can be reconsidered for satisfaction we must know the walkabout strengths of its variables in its absence."

	| method |
	method _ aConstraint whichMethod.
	(method isNil) ifTrue: [^self].	"constraint is already retracted"
	((aConstraint hasMultipleOutputs) and:
	 [(method bindings select: [: b | b == $o]) size > 1])
		ifTrue:	"retracting is expensive if there's more than one output"
			[self privateRemoveConstraint: aConstraint unmarkedOnly: true]
		ifFalse:	"otherwise, retracting is cheap"
			[aConstraint unsatisfy].!

satisfy: aConstraint overriddenInto: overridden
	"Attempt to find a method to satisfy the given constraint without creating a cycle. If successful, add the constraint and put all overridden constraints in the given collection."

	| methods foundMethod bindings thingDatas i td oldC |
	(aConstraint isSatisfied) ifTrue: [^self].		"already satisfied"

	methods _ aConstraint selectMethodsGiven: currentMark.
	foundMethod _ false.
	[methods isEmpty | foundMethod] whileFalse:
		[aConstraint whichMethod: (methods removeFirst).
		 foundMethod _
			self addPropagateFrom: aConstraint execFlag: true].

	foundMethod
		ifTrue:
			["constraint satisfaction succeeded"
			 bindings _ aConstraint whichMethod bindings.
			 thingDatas _ aConstraint thingDatas.
			 i _ bindings size.
			 [i > 0] whileTrue:
				[td _ thingDatas at: i.
				 ((bindings at: i) == $i) ifTrue:
					[td addUsedBy: aConstraint].
				 ((bindings at: i) == $o) ifTrue:
					[td mark: currentMark.
					 oldC _ td determinedBy.
					 (oldC notNil) ifTrue:
					 	[overridden add: oldC.
						 self retract: oldC].
					 td determinedBy: aConstraint].
				 i _ i - 1]]
		ifFalse:
			["constraint satisfaction failed"
			 aConstraint whichMethod: nil.
			 (aConstraint isRequired) ifTrue:
				[self notify:
				  ('Could not find a way to satisfy a required constraint.\',
				   'The constraint will be left unsatisfied. Please proceed.')
					withCRs]].! !

Object subclass: #DebugConstraintRecord
	instanceVariableNames: 'constraint glyph varGlyphs solutions '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Debugger'!
DebugConstraintRecord comment:
'Each partition of the constraint graph being debugged contains a collection of three-tuples (DebugConstraintRecords) of the form:

	constraint		-- the actual constraint object <Constraint>
	glyph 			-- a glyph for the constraint <ConstraintGlyph>
	solutions			-- a collection of constraint methods, one per solution {Method}

Each tuple in a partition has the same number of solutions. The i-th solution for a partition is found by taking the i-th element of each tuple''s solutions collection. The first solution is always the current solution. The remaining solutions are the possible solutions. (The current solution should be among them unless there is a bug in the constraint solver!!).
'!


!DebugConstraintRecord methodsFor: 'accessing'!

constraint

	^constraint!

constraint: aConstraint

	constraint _ aConstraint.!

glyph

	^glyph!

glyph: aConstraintGlyph

	glyph _ aConstraintGlyph.!

solutions

	^solutions!

solutions: aCollectionOfMethods

	solutions _ aCollectionOfMethods.!

varGlyphs

	^varGlyphs!

varGlyphs: aCollectionOfVariableGlyphs

	varGlyphs _ aCollectionOfVariableGlyphs.! !

!DebugConstraintRecord methodsFor: 'operations'!

centerConstraint: graphCenter
	"Place my constraint glyph at the center of its operands. If the constraint has only one operand, place it on the side of the operand farthest from the center of the graph."

	| outVec |
	(varGlyphs size = 1)
		ifTrue:
			[outVec _ ((varGlyphs at: 1) location - graphCenter) unitVector.
			 glyph location: varGlyphs first location + (outVec * 35.0) rounded]
		ifFalse:
			 [| sum | sum _ varGlyphs
						inject: 0@0
						into: [: summ : varGlyph | summ + varGlyph location].
			 glyph location: sum // varGlyphs size].!

updateCurrentSolution
	"Update the current solution for my constraint."

	solutions at: 1 put: constraint whichMethod.!

updateGlyph: solutionIndex
	"Update the constraint glyph for the given solution."

	| method inVars outVars unusedVars |
	method _ solutions at: solutionIndex.
	(method isNil)
		ifTrue: [glyph ins: #() outs: #() unused: varGlyphs]
		ifFalse:
			[inVars _ OrderedCollection new.
			 outVars _ OrderedCollection new.
			 unusedVars _ varGlyphs asOrderedCollection.
			 varGlyphs with: method bindings do:
				[: var : binding |
				 (binding == $i) ifTrue:
					[inVars add: var. unusedVars remove: var].
				 (binding == $o) ifTrue:
					[outVars add: var. unusedVars remove: var]].
			glyph ins: inVars outs: outVars unused: unusedVars].! !

Object subclass: #ModuleVarTableEntry
	instanceVariableNames: 'thingData name type reference value tempFlag constFlag constAncestors '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Module Compiler'!
ModuleVarTableEntry comment:
'I am used to represent a constrained variable during Module compilation. As analysis proceeds, I am classified as one of:
	external		-- part of an external part
	internal		-- a non-external variable
	temporary	-- an internal variable than does not hold
					state between constraint satisfaction passes
	constant		-- an internal variable whose value is constant

Temporary and constant variables do not require space in the finished module.'!


!ModuleVarTableEntry methodsFor: 'initialize-release'!

on: aReference
	"Initialize a new variable table entry for the given Reference."

	thingData _ aReference thingData.
	name _ 'v', thingData asOop printString.
	type _ #internal.			"assume internal until declared external"
	reference _ aReference.
	value _ aReference value.

	"the following are used only during variable use analysis:"
	tempFlag _ true.			"assume temporary until shown otherwise"
	constFlag _ true.			"assume constant until shown otherwise"
	constAncestors _ nil.		"used to detect constants"! !

!ModuleVarTableEntry methodsFor: 'access'!

name

	^name!

name: aName

	name _ aName.!

reference
	"Anwer my reference."

	^reference!

thingData

	^thingData!

value

	^value! !

!ModuleVarTableEntry methodsFor: 'operations'!

classify
	"Decide the type of this variable. This method assumes that we have already recorded the status of this variable for all possible solutions. A variable may be:
		#external -- an external part
		#virtual -- a virtual, external part (#virtual implies #external)
		#internal -- invisible but holds state
		#temporary -- does NOT hold state state
		#constant -- stay flag is true for every flow, with the same ancestors"

	(self isExternal not) ifTrue:
		[constFlag & ((value isKindOf: Number) | (value isMemberOf: String))
			ifTrue: [type _ #constant]
			ifFalse: [tempFlag ifTrue: [type _ #temporary]]].
	constFlag _ constAncestors _ nil.
	tempFlag _ nil.

	"Note: non-external, non-constant, non-temporary variables are #internal"!

makeExternal: aReference
	"Make this an external variable for the part with the given top-level reference."

	type _ #external.
	reference _ aReference.
	tempFlag _ nil. 		"not relevant for external variables"
	constFlag _ nil.		"ditto"
	constAncestors _ nil.	"ditto"!

makeVirtual
	"Make this entry be a virtual external variable."

	(self isExternal) ifFalse:
		[self error: 'Only external variables may be virtual parts!!'].
	type _ #virtual.!

recordCurrentStatus
	"Record the status of this variable in the current solution. This information will later be used to classify the variable; see 'classify' for further details."

	(self isExternal not) ifTrue:
		[constFlag ifTrue:
			[((thingData stay) and:
			  [self sameAncestors: thingData ancestors]) ifFalse:
				[constFlag _ false]].
		 tempFlag ifTrue:
			[((thingData determinedBy notNil) and:
			   [thingData usedBy isEmpty not]) ifFalse:
				[tempFlag _ false]]].! !

!ModuleVarTableEntry methodsFor: 'queries'!

isConstant
	"Answer true if I am a constant in all solutions."

	^type == #constant!

isExternal
	"Answer true if I am an external part. (Note: #virtual implies #external)."

	^(type == #external) | (type == #virtual)!

isInternal
	"Answer true if I am an internal part."

	^type == #internal!

isOutput
	"Answer true if I am an external output variable in the current solution."

	^(self isExternal) and:
	  [thingData determinedBy notNil]!

isTemporary
	"Answer true if I am used as a temporary in all solutions."

	^type == #temporary!

isVirtual
	"Answer true if I am a virtual external part."

	^type == #virtual! !

!ModuleVarTableEntry methodsFor: 'code generation'!

getCodeStringOn: aStream
	"Append to the given stream a code string to get the value of my variable."

	(self isExternal) ifTrue:
		[(reference fullPath) do:
			[: part | aStream nextPutAll: part; space].
		 aStream skip: -1].
	(self isConstant) ifTrue: [^value storeOn: aStream].
	(self isInternal | self isTemporary) ifTrue: [^name].!

literalTreeForUsing: anEncoder
	"I am a constant. Use the given encoder to build and answer a parse tree for my value's storeString."

	| tree |
	(self isConstant) ifFalse: [self error: 'Module Compiler Error'].
	tree _ EquationParser
		parse: ('Doit ', value storeString) readStream
		withEncoder: anEncoder.
	^tree block statements first!

putCodeStringOn: aStream
	"Append to the given stream a code string to set the value of my variable."

	(self isExternal) ifTrue:
		[(reference finalVarPath) do:
			[: part | aStream nextPutAll: part; space].
		 aStream nextPutAll: 'prim'.
		 aStream nextPutAll: reference part.
		 aStream nextPutAll: ': '].
	(self isInternal | self isTemporary) ifTrue: [aStream nextPutAll: name, ' _ '].
	(self isConstant) ifTrue:
		["can't change a constant; we must have mis-categorized this variable"
		 self error: 'ThingLabII Implementation Error'].!

strengthCodeStringOn: aStream
	"Append to the given stream a code string to get the walkabout strength for my variable."

	(self isExternal)
		ifTrue:
			[aStream nextPut: $(.
			 (reference finalVarPath) do:
				[: part | aStream nextPutAll: part; space].
			 aStream nextPutAll: 'strengthFor: #'.
			 aStream nextPutAll: reference part.
			 aStream nextPut: $).
			 ^aStream contents]
	ifFalse:
		[self error: 'ThingLabII Implementation Error'].!

thingDataCodeStringOn: aStream
	"Append to the given stream a code string to get the ThingData for my variable."

	(self isExternal)
		ifTrue:
			[aStream nextPut: $(.
			 (reference finalVarPath) do:
				[: part | aStream nextPutAll: part; space].
			 aStream nextPutAll: 'thingDataFor: #'.
			 aStream nextPutAll: reference part.
			 aStream nextPut: $).
			 ^aStream contents]
	ifFalse:
		[self error: 'ThingLabII Implementation Error'].! !

!ModuleVarTableEntry methodsFor: 'printing'!

printOn: aStream

	aStream nextPutAll: name.! !

!ModuleVarTableEntry methodsFor: 'private'!

sameAncestors: ancestors
	"If no ancestors are currently recorded for me, remember this set and answer true. Otherwise, compare the previously recorded ancestors to the given set of ancestors and return true iff they are the same."

	(constAncestors isNil)
		ifTrue:
			[constAncestors _ ancestors.
			 ^true]
		ifFalse:
			[^self set: constAncestors equals: ancestors].!

set: setA equals: setB
	"Answer true if setA contains exactly the same elements as setB."

	(setA size ~= setB size) ifTrue: [^false].
	setA do: [: elementA | (setB includes: elementA) ifFalse: [^false]].
	setB do: [: elementB | (setA includes: elementB) ifFalse: [^false]].
	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModuleVarTableEntry class
	instanceVariableNames: ''!


!ModuleVarTableEntry class methodsFor: 'instance creation'!

on: aReference
	"Create a new instance of me for the referenced variable."

	^(super new) on: aReference! !

Object subclass: #ThingPerf
	instanceVariableNames: 'partsList thing '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Things-Support'!


!ThingPerf methodsFor: 'public'!

doTests: n
	"Do performance tests, printing the results in the Transcript."
	"ThingPerf new doTests: 10"

	| t editConstraint plan bluePlanner |
	t _ Time millisecondsToRun: [self buildThing: n].
	self report: ('Building ', n printString, ' node Thing: ') time: t.

	t _ Time millisecondsToRun: [self addConstraints].
	self report: 'Adding Equality Constraints: ' time: t.

	editConstraint _
		EditConstraint
			ref: thing->#n1.value
			strength: #preferred.
	"warm up Reference caches"
	editConstraint addConstraint; removeConstraint.

	t _ Time millisecondsToRun: [editConstraint addConstraint].
	self report: 'Add constraint (case 1): ' time: t.
	t _ Time millisecondsToRun: [thing set: #n1.value to: 1 strength: #preferred].
	self report: 'Setting first node: (case 1a): ' time: t.
	t _ Time millisecondsToRun:
		[thing
			set: ('n', n printString, '.value') asSymbol
			to: 1 strength: #preferred].
	self report: 'Setting last node: (case 1b): ' time: t.
	t _ Time millisecondsToRun:
		[plan _ DeltaBluePlanner extractPlanFromThing: thing].
	self report: 'Make Plan (case 1): ' time: t.
	t _ Time millisecondsToRun: [plan execute].
	self report: 'Execute Plan (case 1): ' time: t.
	t _ Time millisecondsToRun:
		[bluePlanner _ BluePlanner new on: thing].
	self report: 'Make Blue Planner (case 1): ' time: t.
	t _ Time millisecondsToRun:
		[plan _ bluePlanner plan].
	self report: 'Blue Planning Time (case 1): ' time: t.
	t _ Time millisecondsToRun: [editConstraint removeConstraint].
	self report: 'Remove constraint (case 1): ' time: t.
	editConstraint destroy.

	editConstraint _
		EditConstraint
			ref: thing->#n1.value
			strength: #weakDefault.
	"warm up Reference caches"
	editConstraint addConstraint; removeConstraint.
	Transcript cr.

	t _ Time millisecondsToRun: [editConstraint addConstraint].
	self report: 'Add constraint (case 2): ' time: t.
	t _ Time millisecondsToRun: [thing set: #n1.value to: 1 strength: #weakDefault].
	self report: 'Setting first node: (case 2a): ' time: t.
	t _ Time millisecondsToRun:
		[thing
			set: ('n', n printString, '.value') asSymbol
			to: 1 strength: #weakDefault].
	self report: 'Setting last node: (case 2b): ' time: t.
	t _ Time millisecondsToRun:
		[plan _ DeltaBluePlanner extractPlanFromThing: thing].
	self report: 'Make Plan (case 2): ' time: t.
	t _ Time millisecondsToRun: [plan execute].
	self report: 'Execute Plan (case 2): ' time: t.
	t _ Time millisecondsToRun:
		[bluePlanner _ BluePlanner new on: thing].
	self report: 'Make Blue Planner (case 2): ' time: t.
	t _ Time millisecondsToRun:
		[plan _ bluePlanner plan].
	self report: 'Blue Planning Time (case 2): ' time: t.
	t _ Time millisecondsToRun: [editConstraint removeConstraint].
	self report: 'Remove constraint (case 2): ' time: t.
	editConstraint destroy.

	t _ Time millisecondsToRun: [thing destroyAndRemoveClass].
	self report: 'Destroying Thing: ' time: t.
	Transcript cr.! !

!ThingPerf methodsFor: 'private'!

addConstraints

	| p1 p2 |
	1 to: (partsList size - 1) do:
		[: i |
		 p1 _ (partsList at: i), '.value'.
		 p2 _ (partsList at: i + 1), '.value'.
		 thing require: p1 equals: p2].
	thing defaultStay: (partsList last, '.value').!

buildThing: numberOfNodes

	partsList _ (1 to: numberOfNodes) collect:
		[: i | ('n', i printString) asSymbol].
	thing _ Thing defineNewThingNamed: #PerfTestThing.
	thing
		addPartsNamed: partsList
		toHold: ((1 to: numberOfNodes) collect: [: i | Node new]).!

partitionTest: numberOfNodes
	"Measure performance of the partitioning algorithm."
	"ThingPerf new partitionTest: 10"

	| t partitions |
	t _ Time millisecondsToRun: [self buildThing: numberOfNodes].
	self report: ('Building ', numberOfNodes printString, ' node Thing: ') time: t.

	t _ Time millisecondsToRun: [self addConstraints].
	self report: 'Adding Equality Constraints: ' time: t.

	t _ Time millisecondsToRun: [partitions _ Partitioner partition: thing].

	self report: 'Partitioning took: ' time: t.
	Transcript show: 'Partitions: ', (partitions collect: [: p | p size]) printString.
	Transcript cr; cr.

	t _ Time millisecondsToRun: [thing destroyAndRemoveClass].
	self report: 'Destroying Thing: ' time: t.!

report: string time: time

	Transcript show: string, time printString, ' milliseconds'; cr.! !

Encoder subclass: #EquationEncoder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Equations'!

!EquationEncoder methodsFor: 'squeak compat'!

supportsFullBlocks
	^false! !

!EquationEncoder methodsFor: 'encoding'!

encodeVariable: name
	"If the given variable is not already in my scopeTable, just make it a new temp."

	^scopeTable
		at: name
		ifAbsent: 
			[self lookupInPools: name 
				 ifFound: [: assoc | ^self global: assoc name: name].
			 ^self reallyBindTemp: name]! !

View subclass: #ModuleCompilerView
	instanceVariableNames: 'state '
	classVariableNames: 'BlackAndWhites Icons Locations '
	poolDictionaries: ''
	category: 'ThingLabII-Module Compiler'!


!ModuleCompilerView methodsFor: 'state control'!

incrementState

	state _ state + 1.
	self displayView.!

initializeState

	state _ 1.
	self borderWidth: 0.
	self insideColor: nil.! !

!ModuleCompilerView methodsFor: 'displaying'!

displayView

	| displayBox tempForm colors |
	displayBox _ self insetDisplayBox.
	tempForm _ Form extent: displayBox extent depth: 32. tempForm fillWhite.
	colors _ BlackAndWhites at: state.
	colors with: Locations do:
		[: color : loc | 
		 (Icons at: (loc at: 1))
			displayOn: tempForm
			at: ((loc at: 2)@(loc at: 3))
			clippingBox: (tempForm boundingBox)
			rule: (Form paint)
			fillColor: (Form perform: color)].
	tempForm displayOn: Display at: displayBox topLeft.! !

!ModuleCompilerView methodsFor: 'termination'!

closeAndRemove

	self topView controller close.
	ScheduledControllers unschedule: self topView controller.
	ScheduledControllers activeController flushDisplayBits.
	ScheduledControllers activeController view display.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModuleCompilerView class
	instanceVariableNames: ''!


!ModuleCompilerView class methodsFor: 'class initialization'!

initialize
	"ModuleCompilerView initialize"

	self initializeBlackAndWhites.
	self initializeLocations.
	self initializeIcons.!

initializeBlackAndWhites

	BlackAndWhites _ #(
		(black black white white gray gray white gray white white gray gray)
		(black black black white black gray white gray white white gray gray)
		(black black black black black black white gray white white gray gray)
		(black black black black black black black black white white gray gray)
		(black black black black black black black black black white black gray)
		(black black black black black black black black black black black black)).!

initializeIcons

	Icons _ Dictionary new.
	Icons at: #allVars put: (Form
		extent: 47@54
		fromArray: #(0 0 0 0 0 0 16383 65535 65528 16383 65535 65528 12288 0 24 12288 0 24 12288 0 24 12799 65535 65304 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12799 65535 65304 12288 0 24 12288 0 24 12799 65535 65304 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12799 65535 65304 12288 0 24 12288 0 24 12799 65535 65304 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12544 0 280 12799 65535 65304 12288 0 24 12288 0 24 12288 0 24 16383 65535 65528 16383 65535 65528 0 0 0 0 0 0)
		offset: 0@0).
	Icons at: #someVars put: (Form
		extent: 45@52
		fromArray: #(0 0 0 32767 65535 65520 32767 65535 65520 24576 0 48 24576 0 48 24576 0 48 25599 65535 65072 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25599 65535 65072 24576 0 48 24576 0 48 25599 65535 65072 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25599 65535 65072 24576 0 48 24576 0 48 25599 65535 65072 25429 21845 22064 25258 43690 43568 25429 21845 22064 25258 43690 43568 25429 21845 22064 25258 43690 43568 25429 21845 22064 25258 43690 43568 25429 21845 22064 25258 43690 43568 25599 65535 65072 24576 0 48 24576 0 48 24576 0 48 32767 65535 65520 32767 65535 65520 0 0 0)
		offset: 0@0).
	Icons at: #fewVars put: (Form
		extent: 45@38
		fromArray: #(0 0 0 32767 65535 65520 32767 65535 65520 24576 0 48 24576 0 48 24576 0 48 25599 65535 65072 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25599 65535 65072 24576 0 48 24576 0 48 25599 65535 65072 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25599 65535 65072 24576 0 48 24576 0 48 24576 0 48 32767 65535 65520 32767 65535 65520 0 0 0)
		offset: 0@0).
	Icons at: #allCons put: (Form
		extent: 51@55
		fromArray: #(0 0 0 0 0 0 0 0 0 7 49152 0 0 24 12288 0 0 48 6144 0 0 32 2048 0 0 64 1024 0 248 64 1024 0 774 192 1024 0 1539 832 1024 0 1025 1088 1024 0 2048 38944 2048 0 2048 41008 6144 0 2048 49176 12288 0 2048 32783 49152 0 2048 32776 8192 0 1025 16 8192 0 1539 16 4096 0 774 16 2048 0 248 16 2048 0 16 32 1272 0 16 32 1798 0 16 32 1539 0 8 112 1025 0 8 142 2048 32768 8 257 51200 32768 4 512 14336 32768 4 1024 2048 32768 31 2048 2048 32768 96 61440 1025 0 192 24576 1539 0 128 8192 1798 0 256 4096 2296 0 256 4096 2048 0 256 4096 4096 0 256 4096 4096 0 256 4096 4096 0 128 8192 8192 0 192 24576 8192 0 96 49152 16384 0 31 1 61440 0 0 6 3072 0 0 12 1536 0 0 8 512 0 0 16 256 0 0 16 256 0 0 16 256 0 0 16 256 0 0 16 256 0 0 8 512 0 0 12 1536 0 0 6 3072 0 0 1 61440 0 0 0 0 0 0 0 0 0)
		offset: 0@0).
	Icons at: #someCons put: (Form
		extent: 50@54
		fromArray: #(0 0 0 0 0 15 32768 0 0 48 24576 0 0 96 12288 0 0 64 4096 0 0 128 2048 0 496 128 2048 0 1548 384 2048 0 3078 1664 2048 0 2050 2176 2048 0 4097 12352 4096 0 4097 16480 12288 0 4097 32816 24576 0 4097 31 32768 0 4097 16 16384 0 2050 32 16384 0 3078 32 8192 0 1548 32 4096 0 496 32 4096 0 32 64 2544 0 32 64 3596 0 32 64 3078 0 16 224 2050 0 16 284 4097 0 16 515 36865 0 8 1024 28673 0 8 2048 4097 0 62 4096 4097 0 213 57344 2050 0 426 49152 3078 0 341 16384 3596 0 682 40960 4592 0 853 24576 4096 0 682 40960 8192 0 853 24576 8192 0 682 40960 8192 0 341 16384 16384 0 426 49152 16384 0 213 32768 32768 0 62 3 57344 0 0 13 22528 0 0 26 44032 0 0 21 21504 0 0 42 43520 0 0 53 22016 0 0 42 43520 0 0 53 22016 0 0 42 43520 0 0 21 21504 0 0 26 44032 0 0 13 22528 0 0 3 57344 0 0 0 0 0 0 0 0 0)
		offset: 0@0).
	Icons at: #fewCons put: (Form
		extent: 49@34
		fromArray: #(0 0 0 0 0 31 0 0 0 96 49152 0 0 192 24576 0 0 128 8192 0 0 256 4096 0 992 256 4096 0 3096 768 4096 0 6156 3328 4096 0 4100 4352 4096 0 8194 24704 8192 0 8194 32960 24576 0 8195 96 49152 0 8194 31 0 0 8194 0 32768 0 4100 0 32768 0 6156 0 16384 0 3088 0 8192 0 992 0 8192 0 0 0 5088 0 0 0 7192 0 0 0 6156 0 0 0 4100 0 0 0 8194 0 0 0 8194 0 0 0 8194 0 0 0 8194 0 0 0 8194 0 0 0 4100 0 0 0 6156 0 0 0 3096 0 0 0 992 0 0 0 0 0 0 0 0 0)
		offset: 0@0).
	Icons at: #optimize put: (Form
		extent: 45@52
		fromArray: #(0 0 0 32767 65535 65520 32767 65535 65520 24576 0 48 24576 0 48 24576 0 48 25599 65535 65072 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25599 65535 65072 24576 0 48 24576 0 48 25599 65535 65072 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25088 0 560 25592 0 32304 25599 65535 65072 25086 1 64560 25087 7 64560 25599 65535 65072 25439 62847 63024 25263 64255 59952 25431 65535 22064 25259 65534 43568 25429 32765 22064 25258 65530 43568 25429 65533 22064 25259 65535 43568 25439 65023 54832 25279 64255 59952 25599 65535 65072 25087 32775 63536 25086 3 63536 25084 0 63536 32767 65535 65520 32767 65535 65520 0 0 0)
		offset: 0@0).
	Icons at: #arrow put: (Form
		extent: 28@19
		fromArray: #(0 0 0 49152 0 57344 0 61440 0 63488 0 64512 0 65024 32767 65280 32767 65408 32767 65408 32767 65280 0 65024 0 64512 0 63488 0 61440 0 57344 0 49152 0 0 0 0)
		offset: 0@0).!

initializeLocations
	"ModuleCompilerView initializeLocations."

	Locations _ #(
		(allVars 10 10)
		(allCons 10 70)
		(arrow 65 30)
		(arrow 65 85)
		(someVars 100 10)
		(someCons 100 70)
		(arrow 155 60)
		(optimize 190 40)
		(arrow 245 35)
		(arrow 245 80)
		(fewVars 280 27)
		(fewCons 280 73)).! !

!ModuleCompilerView class methodsFor: 'instance creation'!

new

	^super new initializeState!

open
	"Create and open a new instance of me. Answer the new instance."

	| extent topView inView |
	extent _ 350@140.
	topView _
		SpecialSystemView
			model: nil
			label: ' Compiling a Module '
			minimumSize: extent.
	topView addSubView: (inView _ ModuleCompilerView new).
	topView window: (0@0 extent: extent)
		viewport: (0@0 extent: extent).
	topView align: topView viewport center with: (Display boundingBox center + (0@8)).
	topView translateBy:
		(topView displayBox amountToTranslateWithin: Display boundingBox).
	ScheduledControllers schedulePassive: topView controller.
	ScheduledControllers activeController flushDisplayBits.
	topView display.
	^inView! !


Model subclass: #Explanation
	instanceVariableNames: 'thing '
	classVariableNames: 'Frame '
	poolDictionaries: ''
	category: 'ThingLabII-UI-Support'!
Explanation comment:
'I am used as the model for CodeViews on Thing explanations. I support the basic text editing operations (cut, copy, paste, etc) and also the do it, print it, and inspect operations.'!


!Explanation methodsFor: 'initialization'!

thing: aThing
	"Set my Thing."

	thing _ aThing.! !

!Explanation methodsFor: 'adaptor'!

explainText
	"Answer my Thing's explanation string as a Text object."

	^thing explainText asText!

explainText: newExplanation
	"Store the new explanation as a string in my Thing."

	^thing explainText: newExplanation asString! !

!Explanation methodsFor: 'text menu'!

textMenu
	"Answer a menu of generic text actions."

	^ActionMenu
		labels: 'again\undo\copy\cut\paste\do it\print it\inspect\accept\cancel' withCRs
		lines: #(2 5 8)
		selectors: #(again undo copySelection cut paste doIt printIt inspectIt accept cancel)! !

!Explanation methodsFor: 'doIt support'!

doItContext
	"Answer the context in which a text selection can be evaluated."

	^nil!

doItReceiver
	"Answer the object that should be informed of the result of evaluating a text selection."

	^nil!

doItValue: ignored
	"I don't do anything with the value of a doIt."! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Explanation class
	instanceVariableNames: ''!


!Explanation class methodsFor: 'instance creation'!

on: aThing
	"Answer a new Explanation object for the given Thing."

	^(super new) thing: aThing!

openOn: aThing
	"Open a CodeView on an Explanation for the given Thing."

	self openOn: aThing zoomingFrom: nil.!

openOn: aThing zoomingFrom: fromRect
	"Open a CodeView on an Explanation for the given Thing, zooming open from the given rectangle if it isn't nil."

	| textView controller topView zoomFromRect |
	textView _ CodeView
		on: (self on: aThing)
		aspect: #explainText
		change: #explainText:
		menu: #textMenu
		initialSelection: nil.
	textView
		controller: ExplanationController new;
		borderWidth: 1.
	controller _ (SpecialSystemController new) fromHolder: self.
	topView _ SpecialSystemView
		model: nil
		label: 'Explanation of ', aThing name
		minimumSize: 160@50.
	topView
		borderWidth: 1;
		controller: controller;
		addSubView: textView.
	(fromRect notNil)
		ifTrue: [zoomFromRect _ fromRect]
		ifFalse:
			[(Frame isNil)
				ifTrue: [zoomFromRect _
							Display boundingBox center extent: 0@0]
				ifFalse: [zoomFromRect _ Frame center extent: 0@0]].
	(Frame notNil)
		ifTrue:
			[controller fromFrame: zoomFromRect.
			 Display zoom: zoomFromRect to: Frame duration: 260.
			 topView window: (0@0 extent: Frame extent) viewport: Frame.
			 topView controller openDisplayAt: Frame center]
		ifFalse: [topView controller open].! !

!Explanation class methodsFor: 'accessing'!

lastFrame: aDisplayRect

	Frame _ aDisplayRect.! !

OrderedCollection variableSubclass: #Plan
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII'!
Plan comment:
'A Plan is an ordered list of constraints to execute to make the current constraint graph consistent.'!


!Plan methodsFor: 'interpretation'!

execute
	"Execute my constraints in order."

	self do: [: c | c execute].! !

Object subclass: #ModuleDisjunction
	instanceVariableNames: 'constEquations knownValue '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Module Compiler'!
ModuleDisjunction comment:
'I represent a disjunction (OR) of terms. ThingData

Each term has the form:
	aStrength <= aWalkEquation

I store my terms as an OrderedCollection of Arrays of the form:
	(aStrength, aWalkEquation)

Some of my terms can be evaluated at compile time. Any term that evaluates to ''false'' may be removed, as a false term cannot make the overall disjunction be true. On the other hand, any term that evaluates to ''true'' makes the entire disjunction evaluate to true, regardless of the other terms. A conjunction with no terms is false. (Such a conjunction probably had ''false'' terms that were removed during simplification.)

Instance variables:
	constEquations...		an OrderedCollection of pairs: (strength, walkEqn)
	knownValue...			caches the simplified value of this disjunction
						(true or false) if it is known at this time or
						nil if it cannot be determined at this time.'!


!ModuleDisjunction methodsFor: 'initialize-release'!

initialize

	constEquations _ OrderedCollection new.
	knownValue _ nil.! !

!ModuleDisjunction methodsFor: 'operations'!

addTermsTo: anEquation
	"Append all my terms to the given equation."

	constEquations do:
		[: term |
		 anEquation strength: (term at: 1) weakerOrEq: (term at: 2)].!

hasOnlyOneTerm
	"Answer true if this equation has only a single term."

	^constEquations size == 1!

isFalse
	"Answer true if this set of equations can be evaluated to false at this time."

	(knownValue isNil) ifTrue: [self simplify].
	^knownValue == false!

isTrue
	"Answer true if this set of equations can be evaluated to true at this time."

	(knownValue isNil) ifTrue: [self simplify].
	^knownValue == true!

strength: aStrength weakerOrEq: strengthOrWalkEquation
	"Add an equation of the form:
		strength <= walkEquation
	strengthOrWalkEquation is a Strength or a WalkEquation. If it is a strength, it is converted into a WalkEquation. aStrength is a Strength constant."

	| eqn |
	eqn _ (strengthOrWalkEquation isMemberOf: Strength)
		ifTrue: [WalkEquation constant: strengthOrWalkEquation asSymbol]
		ifFalse: [strengthOrWalkEquation].
	constEquations add: (Array with: aStrength with: eqn).
	knownValue _ nil.! !

!ModuleDisjunction methodsFor: 'printing'!

printLeft: left right: right on: aStream

	left printOn: aStream.
	aStream nextPutAll: ' .le. '.
	right printOn: aStream.
	aStream cr.!

printOn: aStream

	aStream nextPutAll: 'OR('.
	constEquations do:
		[: eqn | self printLeft: (eqn at: 1) right: (eqn at: 2) on: aStream].
	aStream nextPutAll: ')'.! !

!ModuleDisjunction methodsFor: 'code generation'!

codeLeft: left right: right on: aStream
	"Used by storeOn: to store a single term of a boolean strength equation. left may be a Strength or a ModuleVarTableEntry."

	aStream nextPut: $(.
	(left isMemberOf: ModuleVarTableEntry)
		ifTrue: [left strengthCodeStringOn: aStream]
		ifFalse: [left storeOn: aStream].
	aStream nextPutAll: ' leq: '; cr; tab; tab.
	(right isMemberOf: ModuleVarTableEntry)
		ifTrue: [right strengthCodeStringOn: aStream]
		ifFalse: [right storeOn: aStream].
	aStream nextPut: $).!

storeOn: aStream
	"Append to aStream code to be compiled to evalute myself at run-time."

	(self isTrue) ifTrue: [^aStream nextPutAll: 'true'].
	(self isFalse) ifTrue: [^aStream nextPutAll: 'false'].
	aStream nextPut: $(.
	constEquations do:
		[: eqn |
		 aStream tab.
		 self codeLeft: (eqn at: 1) right: (eqn at: 2) on: aStream.
		 aStream nextPutAll: ' | '].
	(constEquations isEmpty) ifFalse:
		[aStream skip: -2].
	aStream nextPut: $).! !

!ModuleDisjunction methodsFor: 'private'!

emptyCheck
	"See if I have no terms and, if so, set my knownValue based on this."
	"An empty disjunction (OR) is false because the false constant terms were filtered out."

	(constEquations isEmpty)
		ifTrue: [knownValue _ false].!

keepTermLeft: left right: right
	"This method is used in simplifying module boolean equations. Answer true if the given term should be kept. Set the known value of the equation if possible. Assume that left side is a constant and that the right side has a constant part."
	"Since this equation is a disjunction (OR), we can remove all false constant terms.  A true constant term makes the entire disjunction true."

	(left stronger: right constant)
		ifTrue: [^false]	"term is false, don't keep it"
		ifFalse:
			[(right vars isEmpty)
				ifTrue:
					["term is true, keep it and set known value"
					 knownValue _ true.
					 ^true]
				ifFalse:
					["term value is not known, keep it"
					 ^true]].!

simplify
	"Simplify this equation by removing constant terms and setting its known value if possible. A constant term is one for which either:
	a. the left and right sides are both constants and the left side
	    is NOT STRONGER than the right side (the term is true), or
	b. the left side is a constant and is STRONGER than the
	    constant part of the right hand side (the term is false)."

	| newEquations left right |
	knownValue _ nil.		"assume value cannot be determined"
	newEquations _ constEquations species new.
	constEquations do:
		[: eqn |
		 left _ (eqn at: 1).
		 right _ (eqn at: 2).
		 right simplify.
		 (right constant notNil)
			ifTrue:	"right hand side has a constant part"
				[(self keepTermLeft: left right: right)
					ifTrue: [newEquations add: eqn]]
			ifFalse:	"right hand side has no constant part"
				["term value not known, keep it"
				 newEquations add: eqn]].

	constEquations _ newEquations.
	self emptyCheck.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModuleDisjunction class
	instanceVariableNames: ''!


!ModuleDisjunction class methodsFor: 'instance creation'!

new

	^(super new) initialize! !

Object subclass: #HistoryQueue
	instanceVariableNames: 'values next '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Things-Support'!
HistoryQueue comment:
'I am a simple fixed-length queue that remembers the last <size> elements added to me. The last N elements (where N <= size) may be enumerated from oldest to most recent. The entire queue may be filled with a given value by the clearTo: operation.

Instance variables:
	values		-- an <Array> of element values
	next		-- index of the next location to store an element
'!


!HistoryQueue methodsFor: 'all'!

add: aValue
	"Add the given value to the end of the queue."

	values at: next put: aValue.
	(next = values size)
		ifTrue: [next _ 1]
		ifFalse: [next _ next + 1].!

clearTo: aValue

	values _ Array new: (values size) withAll: aValue.
	next _ 1.!

initialize: size

	values _ Array new: size.
	next _ 1.!

last: count do: aBlock
	"Evaluate the given block for the last 'count' values, from least to most recent. If 'count' is larger than my size, raise an error."

	| size i |
	size _ values size.
	(count > size) ifTrue: [^self error: 'Queue too small'].
	i _ ((next - 1 - count) \\ size) + 1.
	(count = size) ifTrue:
		[aBlock value: (values at: next).
		 i _ (next = size) ifTrue: [1] ifFalse: [next + 1]].
	[i ~= next] whileTrue:
		[aBlock value: (values at: i).
		 (i = size)
			ifTrue: [i _ 1]
			ifFalse: [i _ i + 1]].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HistoryQueue class
	instanceVariableNames: ''!


!HistoryQueue class methodsFor: 'instance creation'!

new

	^self new: 10!

new: size

	^self basicNew initialize: size! !

Object subclass: #ThingLabII
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII'!
ThingLabII comment:
'ThingLab II was written by John Maloney and Bjorn N. Freeman-Benson under the guidance of Professor Alan Borning. We would like to acknowledge and thank some of the many other people who have contributed ideas and suggestions for ThingLab II (alphabetically):

	Yu-Ying Chow
	Robert Duisberg
	Theresa Farrah
	Bjorn N. Freeman-Benson
	Robert Henry
	Axel Kramer
	Frank Ludolph
	John Maloney
	Scott Wallace
	Mike Woolf

For a complete introduction and overview of the ThingLabII system, please read the ThingLab II Programmer''s Manual that has not yet been written.

The ThingLabII class is the "anchor" point for the ThingLabII system. Here is where global data such as the current constraint satisfaction planner is kept.'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ThingLabII class
	instanceVariableNames: 'lastUniqueNumber editStrength '!


!ThingLabII class methodsFor: 'class initialization'!

initialize
	"ThingLabII initialize."

	"The first unique number will be 1."
	lastUniqueNumber _ 0.

	"Default edit strength is 'preferred'."
	editStrength _ #preferred.! !

!ThingLabII class methodsFor: 'access'!

editStrength
	"The strength for user editing and manipulation of things with the mouse."

	^editStrength!

editStrength: aSymbol
	"Set the strength for user editing."

	editStrength _ aSymbol.! !

!ThingLabII class methodsFor: 'unique number generation'!

uniqueNumber
	"A generator for unique number for Thing and Module names."

	^lastUniqueNumber _ lastUniqueNumber + 1! !

!ThingLabII class methodsFor: 'prototype maintainance'!

allPartsOf: aPrototype in: initializedClasses
	"Answer true if the classes for all Thing parts of the given prototype are in the given collection."

	aPrototype thingPartsDo:
		[: part |
		 (initializedClasses includes: part class) ifFalse: [^false]].
	^true!

collectPrimitives
	"Answer a collection of prototypes for all primitive Things."

	| primitivePrototypes |
	"Construct a list of all Things that currently exist."
	primitivePrototypes _ IdentitySet new.
	SystemOrganization categories do:
		[: category |
		 (('things*' match: category) and:
		   [('things-built' match: category) not]) ifTrue:
			[(SystemOrganization listAtCategoryNamed: category asSymbol) do:
				[: className |
				 primitivePrototypes add: (Smalltalk at: className) prototype]]].
	^primitivePrototypes asOrderedCollection!

updatePrimitives
	"Updates all the primitive Things in the system. Expensive!! This is used after changing the constraints for a primitive Thing to cause prototypes containing this Thing to be updated with new instances having the new prototypes. User-defined Things are not affected."
	"Note: This algorithm assumes that structure of prototypes (i.e. what parts they have and what types those parts are) has not been changed. If prototype structure has been changed, running this algorithm a second time will take care of matters."
	"ThingLabII updatePrimitives"

	| allProtos initializedClasses proto |
	allProtos _ self collectPrimitives.
	initializedClasses _ IdentitySet new.
	[allProtos isEmpty] whileFalse:
		[proto _ allProtos detect: [: p | self allPartsOf: p in: initializedClasses].
		 Transcript show: 'Initializing ', proto class printString; cr.
		 proto class initialize.
		 allProtos remove: proto.
		 initializedClasses add: proto class.
		 proto destroy.
		 proto _ nil].
	Transcript show: 'Updating Parts Bins'; cr.
	PartsBin updateAllBins	.
	Transcript show: 'All Primitives Updated'; cr.! !

!ThingLabII class methodsFor: 'filing out'!

fileOutCategoriesMatching: patternString on: aStream
	"File out on the given stream all methods in protocol categories matching the given pattern string. Both classes and metaclasses are examined."

	| class metaClass |
	Transcript cr; show: '*** Filing out ThingLabII System Changes ***'; cr; cr.
	(SystemOrganization elements) do:
		[: className |
		 class _ Smalltalk at: className asSymbol.
		 metaClass _ class class.
		 class organization categories do:
			[: categoryName |
			 (patternString match: categoryName) ifTrue:
				[self
					fileOutClass: class
					category: categoryName
					on: aStream]].
		 metaClass organization categories do:
			[: categoryName |
			 (patternString match: categoryName) ifTrue:
				[self
					fileOutClass: metaClass
					category: categoryName
					on: aStream]]].!

fileOutClass: aClass category: category on: aStream
	"File out the given category of the given class on the given stream."

	Transcript show: aClass printString, '>>', category; cr.
	aClass
		fileOutCategory: category
		on: aStream
		moveSource: false
		toFile: 0.!

fileOutClassesOn: aStream
	"File out on the given stream all classes in categories matching 'thinglab*'."
	"WARNING: The order of class initializations will need to be fixed by hand."

	| classNames classList |
	Transcript cr; show: '*** Filing out ThingLabII classes ***'; cr.
	classNames _ OrderedCollection new: 100.
	SystemOrganization categories do:
		[: categoryName |
		 ('thinglab*' match: categoryName) ifTrue:
			[Transcript show: 'Classes in: ', categoryName; cr.
			 classNames addAll:
				(SystemOrganization listAtCategoryNamed: categoryName)]].
	classList _ ChangeSet superclassOrder:
				(classNames collect: [: className | Smalltalk at: className]).
	classList do:
		[: aClass |
		 aStream cr; cr.
		 aClass fileOutOn: aStream].!

fileOutPostludeOn: aStream
	"File out some final stuff on the given stream."

	aStream cr; cr; nextPutAll:
'"*************** Class and System Initialization ***************"!!

	"Put class initializations here (NOTE: verify these and check ordering):"!!
	ArrowHead initialize!!
	BusyCursor initialize!!
	EquationTranslator initialize!!
	Strength initialize!!
	ThingLabII initialize!!
	Thing initialize!!
	PrimitiveThing initialize!!
	ModuleCompilerView initialize!!
	ThingLabIIControlPanel initialize!!
	PartsBin initialize!!

	"Initialize the ScreenController yellow button menu:"!!
	ScreenController initialize!!
	ScreenController allInstancesDo: [: c | c initializeYellowButtonMenu]!!

"Th-th-that''s all, Folks..."!!'.!

fileOutPreludeOn: aStream with: nameString
	"File out the time and copyright notice."

	aStream nextPutAll:
		'"', nameString, ' of ', Time dateAndTimeNow printString, '"!!'; cr; cr.
	aStream nextPutAll:
'"Copyright (c) 1989 and 1990, Regents of the University of Washington.
Permission is granted to use or reproduce this program for research
and development purposes only. For information regarding the use of this
program in a commercial product, contact:

	Office of Technology Transfer
	University of Washington
	4225 Roosevelt Way NE, Suite 301
	Seattle, WA  98105

ThingLab II was written between 1988 and 1990 by John Maloney and
Bjorn N. Freeman-Benson with the guidance of Alan Borning."!!'; cr.!

fileOutPrimitiveThingsOn: aStream
	"Files out all the primitive Things in the system on the given stream. The primitives are filed out in the correct order."
	"ThingLabII fileOutPrimitiveThingsOn: (FileStream newFileNamed: 'Things.st')"

	| allProtos filedOutClasses proto |
	Transcript cr; show: '*** Filing out ThingLabII Primitive Things ***'; cr.
	self fileOutPreludeOn: aStream with: 'ThingLabII Primitive Things'.
	allProtos _ self collectPrimitives.
	filedOutClasses _ IdentitySet new.
	[allProtos isEmpty] whileFalse:
		[proto _ allProtos detect:
			[: p |
			 ((p class superclass == PrimitiveThing) or:
				[filedOutClasses includes: p class superclass]) and:
			  [self allPartsOf: p in: filedOutClasses]].
		 (proto isNil) ifTrue:
			[self error: 'Circular dependency among Primitive things'].
		 proto class fileOutOn: aStream.
		 aStream cr.
		 allProtos remove: proto.
		 filedOutClasses add: proto class].
	aStream cr; close.
	Transcript cr; cr; show: '*** Primitive Things Filed Out ***'; cr; cr.!

fileOutSystemOn: aStream
	"File out the ThingLabII system on the given stream. This includes all classes and all changes to system classes. It does not include the primitive Things. You may need to adjust the order of the 'initialize' messages listed in fileOutPostludeOn:. You will definitely need to remove the class initialization messages sprinkled throughout the file."
	"ThingLabII fileOutSystemOn: (FileStream newFileNamed: 'ThingLabII.st')"

	self fileOutPreludeOn: aStream with: 'ThingLabII System'.
	self fileOutCategoriesMatching: 'thinglab*' on: aStream.
	self fileOutClassesOn: aStream.
	self fileOutPostludeOn: aStream.
	aStream cr; close.
	Transcript cr; cr; show: '***ThingLabII System Filed Out***'; cr; cr.! !


Object subclass: #Reference
	instanceVariableNames: 'root path part putSymbol finalVarCache '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII'!
Reference comment:
'A reference is used to point to some part or sub-part of a Thing. It consists of a root Thing and a path. The path is the sequence of parts to traverse, starting from the Thing, to get to the referenced part.

Instance variables:
	variable			the Thing from which the path starts <Thing>
	path			an array of part names that goes from the root
					to one part above the final destination {Symbol}
	part				the final path element <Symbol>
	putSymbol		the selector to send to the destination Thing to
					set its value <Symbol>. This is expensive to
					compute, so it is cached.
	finalVarCache	the final Thing in the path. It is to the final variable
					that the get and put messages are sent. The final
					variable is expensive to compute, so it is cached.
'!


!Reference methodsFor: 'initialize-release'!

destroy
	"Break circular dependencies."

	root _ nil.
	path _ nil.
	part _ nil.
	putSymbol _ nil.
	finalVarCache _ nil.!

on: aThing path: thePath
	"Initialize myself to point to the part of aThing accessed by the given sequence of selectors (thePath). thePath may contain Symbols or Strings."

	root _ aThing.
	path _ (thePath copyFrom: 1 to: (thePath size - 1)) asArray.
	part _ thePath last asSymbol.
	putSymbol _ nil.		"computed on demand"
	finalVarCache _ nil.	"computed on demand"! !

!Reference methodsFor: 'access'!

finalVariable
	"Follow the path and answer the object found at the end. This is the immediate parent of the variable I reference."

	(finalVarCache isNil) ifTrue:
		[finalVarCache _
			path inject: root
			into: [: v : p | v perform: p]].
	^finalVarCache!

finalVarPath

	^path!

fullPath

	^path copyWith: part!

part

	^part!

root

	^root!

root: aThing
	"Set my root Thing. Used during module compilation."

	root _ aThing.
	finalVarCache _ nil.	"flush cache"! !

!Reference methodsFor: 'target access'!

cleanUpThingData
	"Remove the thingData for the object I point to if it has no more constraints."

	(self finalVariable) cleanUpThingDataFor: part.!

thingData
	"Answer the ThingData for the object I reference or nil if one doesn't currently exist."

	^(self finalVariable) thingDataFor: part!

thingDataOrAllocate
	"Answer a ThingData for the object I reference, allocating a new one if one doesn't currently exist."

	^(self finalVariable) thingDataOrAllocateFor: part!

value
	"Answer the value of the object that I reference."

	^(self finalVariable) perform: part!

value: anObject
	"Set the value of the object that I reference."

	^(self finalVariable)
		perform: self putSymbol
		with: anObject! !

!Reference methodsFor: 'testing'!

= aReference

	(aReference isMemberOf: Reference) ifFalse: [^false].
	^(root == aReference root) and:
		[self fullPath = aReference fullPath]!

isPrefixOf: aPath 
	"Answer true I am a prefix of aPath."

	(aPath size < (path size + 1)) ifTrue: [^false].
	1 to: path size do:
		[: i |
		 ((aPath at: i) = (path at: i))
			ifFalse: [^false]].
	^(aPath at: (path size + 1)) = part! !

!Reference methodsFor: 'functions'!

, aSymbolArray 
	"Create a new Reference that is a copy of myself extending my path by aSymbolArray. For example,

	ref1, #(d e f)

will create a new reference with the path such as 'a.b.c.d.e.f' given that ref1's path was 'a.b.c'."

	^Reference
		on: root
		path: (self fullPath, aSymbolArray)!

copyFromTopParent
	"Create a new reference that refers to the same part that I do, but it goes from the top-most parent."

	^Reference
		on: root topParent
		path: (root allTopParentPaths first, self fullPath)!

putSymbol
	"Answer the putSymbol for the object I reference. The put symbol is computed the first time it is needed, then cached for future use."

	(putSymbol isNil)
		ifTrue: [putSymbol _ ('prim', part, ':') asSymbol].
	^putSymbol!

refresh
	"Purge my finalVar cache. This is used when the structure of a Thing is changed during merging or unmerging or when the root is changed."

	finalVarCache _ nil.!

topParent
	"Answer the top-most parent of my root Thing."

	^root topParent! !

!Reference methodsFor: 'cloning'!

cloneUsing: cloneDictionary
	"Make a clone of myself using the mapping given by cloneDictionary."

	| myClone |
	myClone _ self shallowCopy.
	myClone root: (cloneDictionary at: root).
	^myClone! !

!Reference methodsFor: 'printing'!

longName

	| s |
	s _ (String new: 100) writeStream.
	self fullPath do:
		[: partName |
		 s nextPutAll: partName.
		 s nextPut: $..].
	s skip: -1.
	^s contents!

longPrintOn: aStream

	(root isThing)
		ifTrue: [root shortPrintOn: aStream]
		ifFalse: [root printOn: aStream].
	aStream nextPut: $..
	path do: [: p | p printOn: aStream. aStream nextPut: $.].
	part printOn: aStream.!

printOn: aStream
	"Usually we show more information when the shift key is held down but in this case we show less. This is to reduce verbiage when printing constraints and methods and also to help you see more clearly when different constraints refer to the same variable."

	(Sensor leftShiftDown)
		ifTrue: [self shortPrintOn: aStream]
		ifFalse: [self longPrintOn: aStream].!

shortPrintOn: aStream

	self finalVariable shortPrintOn: aStream.
	aStream nextPutAll: '.', part.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Reference class
	instanceVariableNames: ''!


!Reference class methodsFor: 'instance creation'!

on: aThing path: anArrayOfSymbols
	"Answer a Reference for the part of aThing with the given path."

	^(self new) on: aThing path: anArrayOfSymbols! !

Object subclass: #Constraint
	instanceVariableNames: 'strength symbols variables thingDatas methods inverseMethods whichMethod flags '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Constraints'!
Constraint comment:
'I represent a system-maintainable relationship, or "constraint", between a set of variables. I contain a set of methods that can be executed to enforce the constraint. If I am satisfied in the current data flow graph, the method used to enforce, or "satisfy", this constraint is stored in whichMethod. If I am not satisfied, whichMethod will be nil.

Note: Constraints must only be applied to the leaves of the Thing data hierarchy because there is currently no support for constraints at different levels (such as one constraint on a Point and another on its X part).

Instance variables:

	variables...		references to the variables to which this
					constraint applies {Reference}
	strength...		the strength of this constraint <Strength>
	methods...		a collection of methods that can be used to
					enforce this constraint {Method}
	whichMethod...	the method currently used to enforce this constraint
					or nil if this constraint is not satisfied <Method>'!


!Constraint methodsFor: 'initialize-release'!

bind: refs strength: aSymbol
	"Bind myself to the given set of references with the given strength."

	self isBound
		ifTrue: [self notify: 'This constraint is already bound!!'].
	self variables: refs.
	strength _ Strength of: aSymbol.!

destroy

	strength _ nil.
	symbols _ nil.
	variables _ nil.
	thingDatas _ nil.
	methods _ nil.
	inverseMethods _ nil.
	whichMethod _ nil.
	flags _ nil.!

initializeFlags
	"Set a multiple output flag if this constraint has at least one method with multiple outputs. Clear other flags."
	"WARNING: This method assumes that 'methods' has already been initialized."

	flags _ 0.
	methods do:
		[: m |
		 ((m bindings select: [: b | b == $o]) size > 1) ifTrue:
			[flags _ flags bitOr: 2r100]].!

symbols: symbolList methods: methodList
	"Initialize myself with the given methods. I am initialially unbound."

	strength _ #unbound.
	symbols _ symbolList.
	variables _ Array new: symbolList size.
	thingDatas _ Array new: symbolList size.
	self methods: methodList asArray.
	whichMethod _ nil.
	self initializeFlags.! !

!Constraint methodsFor: 'DeltaBlue-public'!

addConstraint
	"Add this constraint to the constraint graph and attempt to satisfy it."

	self variables: variables.	"make sure thingDatas cache is up to date"
	self addToGraph.
	DeltaBluePlanner incrementalAdd: self.!

removeConstraint
	"Remove the constraint from the constraint graph, possible causing other constraints to be satisfied."

	DeltaBluePlanner incrementalRemove: self.
	self removeFromGraph.
	variables do: [: var | var cleanUpThingData].! !

!Constraint methodsFor: 'DeltaBlue-private'!

addToGraph
	"Add myself to the constraint graph as an unsatisfied constraint."

	thingDatas do:
		[: td |
		 td addConstraint: self.
		 (td determinedBy == self) ifTrue:
			[td determinedBy: nil].
		 td removeUsedBy: self].
	whichMethod _ nil.!

calculateDeltaBlueData: execFlag
	"Calculate the walkabout strength, the stay flag, and (if execFlag is true) the real data values for the current outputs of this constraint. Answer a collection of ThingDatas for the outputs."

	| stayFlag |
	"assume: whichMethod has been set"
	"My outputs are stay if either:
		I am a stay constraint OR
		I am not an input constraint such as a mouse constraint and
		 all the inputs of my selected method are stay."
	stayFlag _
		self isStay or:
	 	 [(self isInput not) and:
	 	  [whichMethod inputsAreStayIn: thingDatas]].
	(execFlag & stayFlag) ifTrue:
		[whichMethod execute: variables].
	^whichMethod updateOutputsIn: thingDatas for: self stay: stayFlag!

execute
	"Execute my selected method, if any."

	(whichMethod notNil) ifTrue:
		[whichMethod execute: variables].!

hasMultipleOutputs
	"Answer true if this constraint has at least one method that has multiple outputs."

	^0 ~= (flags bitAnd: 2r100)!

inputsKnown: currentMark
	"Answer true if all the inputs of my selected method have the given mark."

	^whichMethod inputsIn: thingDatas known: currentMark!

removeFromGraph
	"Remove myself from the constraint graph."

	thingDatas do:
		[: td |
		 td removeConstraint: self.
		 (td determinedBy == self) ifTrue:
			[td determinedBy: nil].
		 td removeUsedBy: self].
	whichMethod _ nil.!

satisfyWith: aMethod
	"Satisfy myself using the given method."

	| bindings i last td |
	whichMethod _ aMethod.
	bindings _ whichMethod bindings.
	i _ 1.
	last _ bindings size.
	[i <= last] whileTrue:
		[td _ thingDatas at: i.
		 ((bindings at: i) == $i) ifTrue:
			[td addUsedBy: self].
		 ((bindings at: i) == $o) ifTrue:
			[td determinedBy: self].
		 i _ i + 1].!

selectMethodsGiven: currentMark
	"Answer a collection of my methods that change the weakest of my variables and do not change any previously determined (i.e. marked) variable. Answer nil if there is no such method."

	| minOutStrength possibleMethods strongestOut bestMethods |
	minOutStrength _ Strength absoluteStrongest.
	possibleMethods _ OrderedCollection new: 20.
	methods do:
		[: method |
		 ((method outputsIn: thingDatas notKnown: currentMark) and:
		  [method isPossibleMethodGiven: strength]) ifTrue:
		 	[strongestOut _ method strongestOutStrengthIn: thingDatas.
			 possibleMethods addFirst:
				(Array with: method with: strongestOut).
			 (strongestOut weaker: minOutStrength) ifTrue:
				[minOutStrength _ strongestOut]]].

	"if this constraint is not stronger than some possible set of outputs, leave it unsatisfied"
	(self strength weaker: minOutStrength) ifTrue:
		[^#()].

	"collect and answer the methods that change the weakest set of outputs"
	bestMethods _ OrderedCollection new: 20.
	possibleMethods do:
		[: methodAndStrength |
		 ((methodAndStrength at: 2) sameAs: minOutStrength) ifTrue:
			[bestMethods add: (methodAndStrength at: 1)]].

	^bestMethods!

strengthsFor: aMethod
	"Answer the walkabout strengths to be assigned to the outputs of the given method. The walkabout strength is the strength required to override the weakest upstream constraint determining the value of a given variable. The computation is complicated by the fact that some of my methods may not have inverses."

	| outStrengths bindings i outStrength strongestOutOfInverse |
	bindings _ aMethod bindings.
	outStrengths _ OrderedCollection new: bindings size * 2.
	i _ bindings size.
	[i > 0] whileTrue:
		[((bindings at: i) == $o) ifTrue:
			[outStrength _ self strength.
			 (inverseMethods at: i) do:
				[: inverse |
				 strongestOutOfInverse _
					(methods at: inverse) strongestOutStrengthIn: thingDatas.
				 outStrength _
					outStrength weakest: strongestOutOfInverse].
			outStrengths addLast: outStrength].
		 i _ i - 1].
	^outStrengths!

unsatisfy
	"Unsatisfy myself. Remove myself from the usedBy and determinedBy fields of my argument thingDatas and set whichMethod to nil. This is a noop if I am already unsatisfied."

	| bindings i td |
	(whichMethod notNil) ifTrue:
		[bindings _ whichMethod bindings.
		 i _ thingDatas size.
		 [i > 0] whileTrue:
			[td _ thingDatas at: i.
			 (td determinedBy == self) ifTrue:
				[td determinedBy: nil].
			 ((bindings at: i) == $i) ifTrue:
				[td removeUsedBy: self].
			 i _ i - 1].
		 whichMethod _ nil].! !

!Constraint methodsFor: 'Blue-private'!

attemptSatisfaction: currentMark
	"Consider myself for possible satisfaction. If I can be satisfied, answer the chosen method. Otherwise, answer nil. The outcome of considering a constraint for satisfaction may be:
	1. it is established that the constraint can never be satisfied,
	2. the constraint can be satisfied with some method, or
	3. we don't know the values of enough variables to choose a method to satisfy the constraint at this time"

	| possible chosen |
	(self shouldConsider not | self isCommitted) ifTrue:
		[^nil].	"this constraint is already committed or is not ready for consideration"

	possible _ false.	"assume false until shown otherwise"
	methods reverseDo:
		[: m |
		 (m outputsIn: thingDatas notKnown: currentMark) ifTrue:
			[possible _ true.	"a possible method"
			 (m inputsIn: thingDatas known: currentMark) ifTrue:
				[chosen _ m]]].
	(possible) ifFalse:
		["this constraint can never be satisfied"
		 self setCommitted.
		 ^nil].
	(chosen notNil)
		 ifTrue:
			["satisfy this constraint using the chosen method"
			 self reconsiderConstraintsOnOutputsOf: chosen mark: currentMark.
		 	 self setCommitted.
			 ^chosen]
		ifFalse:
			["don't consider this constraint until another var is known"
			 self clearConsider.
			 ^nil].!

clearCommitted
	"Clear my committed flag."

	flags _ flags bitAnd: (2r010 bitInvert)!

clearConsider
	"Clear my consider flag."

	flags _ flags bitAnd: (2r001 bitInvert)!

isCommitted
	"Answer true if my committed flag is set."

	^0 ~~ (flags bitAnd: 2r010)!

prepareForPlanning
	"Prepare for planning using the Blue planner. No constraints are committed yet. Only constraints with no inputs are worthy of initial consideration."

	self clearCommitted.
	self clearConsider.
	methods do:
		[: m |
		 (m bindings includes: $i) ifFalse:
			["give this constraint initial consideration only if it has a method with zero inputs"
			 self setConsider.
			 ^self]].!

reconsiderConstraintsOnOutputsOf: aMethod mark: currentMark
	"Mark for possible reconsideration all constraints on the output variables of the given method."

	aMethod outDatasIn: thingDatas do:
		[: out |
		 out mark: currentMark.
		 out constraints do:
			[: c | c setConsider]].!

setCommitted
	"Set my committed flag."

	flags _ flags bitOr: 2r010.!

setConsider
	"Set my consider flag."

	flags _ flags bitOr: 2r001.!

shouldConsider
	"Answer true if my consider flag is set."

	^0 ~~ (flags bitAnd: 2r001)! !

!Constraint methodsFor: 'access'!

inDatas
	"Answer the ThingDatas for the inputs of my currently selected method."

	| inDatas |
	inDatas _ OrderedCollection new: thingDatas size * 2.
	whichMethod inDatasIn: thingDatas do:
		[: in | inDatas add: in].
	^inDatas!

methods
	"Answer my complete set of methods."

	^methods!

methods: methodArray
	"Set my set of methods and record their inverses. The inverseMethods array contains, for each variable of this constraint, an array of indices for the methods that have that variable as an input."

	methods _ methodArray.
	inverseMethods _ (1 to: variables size) collect:
		[: inputIndex |
		 (1 to: methods size) select:
			[: methodIndex |
			 ((methods at: methodIndex) bindings at: inputIndex) == $i]].!

outDatas
	"Answer the ThingDatas for the outputs of my currently selected method."

	| outDatas |
	outDatas _ OrderedCollection new: thingDatas size * 2.
	whichMethod outDatasIn: thingDatas do:
		[: out | outDatas add: out].
	^outDatas!

outDatasDo: aBlock
	"Evaluate the given block for all outputs of my currently selected method."

	whichMethod outDatasIn: thingDatas do: aBlock.!

strength
	"Answer my strength."

	^strength!

strength: aStrength
	"Set my strength."

	strength _ aStrength.!

symbols
	"Answer a collection of symbolic names for my arguments. Each symbol in this collection is used to refer to the variable at the same location in the variables list."

	^symbols!

thingDatas
	"Answer the cache of ThingDatas for my variables."

	^thingDatas!

variables
	"Answer my variables (a collection of References)."

	^variables!

variables: arrayOfReferences
	"Set my variables and compute the thingDatas cache."

	variables _ arrayOfReferences.
	thingDatas _ variables collect: [: ref | ref refresh; thingDataOrAllocate].!

whichMethod
	"Answer the method that I use to satisfy myself in the current solution. This is nil if I am not currently satisfied."

	^whichMethod!

whichMethod: aMethod
	"Set the method that I use to satisfy myself in the current solution."

	whichMethod _ aMethod.! !

!Constraint methodsFor: 'applying'!

add: aStrengthSymbol on: r1 on: r2
	"Add a copy of this constraint to the given references with the given strength. The receiver must be an unbound constraint."

	^((self clone)
		bind: (Array with: r1 with: r2)
		strength: aStrengthSymbol)
			addConstraint!

add: aStrengthSymbol on: r1 on: r2 on: r3
	"Add a copy of this constraint to the given references with the given strength. The receiver must be an unbound constraint."

	^((self clone)
		bind: (Array with: r1 with: r2 with: r3)
		strength: aStrengthSymbol)
			addConstraint! !

!Constraint methodsFor: 'queries'!

doesSomething
	"Some constraints, such as Stay and Edit constraints, are used only to control the planning process and have no actual code to execute. Answer false if I am such a constraint, otherwise answer true (the default behavior)."

	^true!

isBound
	"Answer true if I am bound to my arguments."

	^strength ~~ #unbound!

isInput
	"Normal constraints are not input constraints. An input constraint is one that depends on external state, such as the mouse, the keyboard, or a clock."

	^false!

isRequired
	"Answer true if this constraint is a required constraint."

	^strength sameAs: (Strength required)!

isSatisfied
	"Answer true if this constraint is satisfied in the current solution."

	^whichMethod notNil!

isStay
	"Normal constraints are not stay constraints. Stay constraints are a subclass."

	^false!

isStrongerThan: aConstraint
	"Answer true if I am stronger than the given constraint."

	^self strength stronger: aConstraint strength!

shouldUseGiven: stayOptimizationFlag
	"Answer true if this constraint should be added to the plan."

	^(self doesSomething) and:		"use this constraint if it does something AND"
		[(stayOptimizationFlag not) or:			"(we aren't optimizing stays OR"
		[(whichMethod outputsAreStayIn: thingDatas) not]]	" the outputs are not all stay)"! !

!Constraint methodsFor: 'set constraints'!

partlyBind: incompleteRefs
	"To be used for Set Constraints. Partly bind myself to the given set of incomplete references. The references are incomplete because their root Things have not yet been filled in. The constraint will remain unbound but it will contain the given incomplete references. Warning: these references will not get copied by the clone operation."

	self isBound
		ifTrue: [self notify: 'This constraint is already bound!!'].
	variables _ incompleteRefs.
	thingDatas _ Array new: variables size.! !

!Constraint methodsFor: 'cloning'!

clone
	"Answer a copy of this constraint."

	^self cloneUsing: IdentityDictionary new!

cloneMethods: cloneDictionary 
	"Update my methods using the mapping given by cloneDictionary."

	| newMethods newMethod |
	newMethods _ methods collect:
		[: m |
		 newMethod _ m cloneWith: cloneDictionary for: self.
		 (whichMethod == m) ifTrue: [whichMethod _ newMethod].
		 newMethod].
	(newMethods ~= methods) ifTrue:
		[methods _ newMethods].!

cloneUsing: cloneDictionary 
	"Make a clone of myself using the mapping given by cloneDictionary."

	| myClone |
	myClone _ self shallowCopy.
	myClone cloneVariables: cloneDictionary.
	myClone cloneMethods: cloneDictionary.
	^myClone!

cloneVariables: cloneDictionary 
	"Update my variables using the mapping given by cloneDictionary."

	self isBound
		ifTrue:
			[self variables:
				(variables collect:
					[: ref | ref cloneUsing: cloneDictionary])]
		ifFalse:
			[variables _ Array new: variables size].! !

!Constraint methodsFor: 'printing'!

definitionString
	"Answer a string containing my definition for the constraint definer."

	| out |
	out _ (String new: 200) writeStream.
	symbols with: variables do:
		[: sym : var |
		 out tab; nextPutAll: sym, ': '.
		 (var root isThing)
			ifTrue: [out nextPutAll: 'THING']
			ifFalse: [var root printOn: out].
		 out nextPutAll: '.', var longName.
		 out cr].
	out cr.
	methods do:
		[: method |
		 out nextPutAll: method codeString; cr; cr].
	^out contents!

longPrintOn: aStream

	| bindings |
	aStream nextPut: $(.
	self shortPrintOn: aStream.
	aStream cr; nextPutAll: self strength printString, ', '.
	aStream nextPutAll:
		((self isSatisfied) ifTrue: ['SAT'] ifFalse: ['NOT SAT']).
	bindings _ (self isSatisfied)
		ifTrue: [whichMethod bindings]
		ifFalse: [String new: variables size withAll: $X].
	variables with: bindings do: [: v : binding |
		aStream cr; tab.
		aStream nextPut: binding; space.
		v printOn: aStream.
		(v thingData isNil)
			ifTrue: [aStream nextPutAll: ' nil']
			ifFalse:
				[aStream nextPutAll:
					' TD(', v thingData asOop printString, ') '.
				 v thingData walkStrength printOn: aStream]].
	aStream nextPut: $).!

printOn: aStream

	(Sensor leftShiftDown)
		ifTrue: [self longPrintOn: aStream]
		ifFalse: [self shortPrintOn: aStream].!

shortPrintOn: aStream

	aStream nextPutAll: self class name, '(', self asOop printString, ')'.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Constraint class
	instanceVariableNames: ''!


!Constraint class methodsFor: 'instance creation'!

symbols: symbols equation: equation
	"Similar to symbols:equation:refs:strength: but the constraint is not bound to references at this time."

	| methodList |
	methodList _ (EquationTranslator methodsFor: equation) collect:
		[: m | Method symbols: symbols methodString: m].
	^(super new)
		symbols: symbols
		methods: methodList!

symbols: symbols equation: equation refs: refs strength: strength
	"Create and initialize a new constraint using the given Smalltalk expression as an equation. The equation should be of the form '(expr1) = (expr2)'. For example, the following builds a Sum constraint with methods to solve for any one variable in terms of the remaining two:
	Constraint
		symbols: #(a b c)
		equation: 'c = (a + b)'
		refs: (Array
			with: aThing->#a.value
			with: aThing->#b.value
			with: aThing->#c.value
		strength: #required"

	| methodList |
	methodList _ (EquationTranslator methodsFor: equation) collect:
		[: m | Method symbols: symbols methodString: m].
	^((super new)
		symbols: symbols
		methods: methodList)
			bind: refs strength: strength!

symbols: symbolList methods: methodList
	"Answer a new instance with the given methods. The instance is initially unbound."

	^(super new)
		symbols: symbolList
		methods: methodList!

symbols: symbols methodStrings: methodStrings
	"Similar to symbols:methodStrings:refs:strength: but the constraint is not bound to references at this time."

	| methodList |
	methodList _ methodStrings collect:
		[: m | Method symbols: symbols methodString: m].
	^(super new)
		symbols: symbols
		methods: methodList!

symbols: symbols methodStrings: methodStrings refs: refs strength: strength
	"Create and initialize a new constraint using the given method strings. The expressions in methodStrings are compiled to produce the actual method bodies for the constraint. For example, the following builds a one-way constraint that computes the magnitude of a vector:
	Constraint
		symbols: #(magnitude vector)
		methodStrings: #('magnitude _ (vector dotProduct: vector) sqrt')
		refs: (Array
			with: aThing->#tension
			with: aThing->#forceVector)
		strength: #required"

	| methodList |
	methodList _ methodStrings collect:
		[: m | Method symbols: symbols methodString: m].
	^((super new)
		symbols: symbols
		methods: methodList)
			bind: refs strength: strength! !

Controller subclass: #GestureController
	instanceVariableNames: 'startTime '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Framework'!
GestureController comment:
'This class supports simple multiple-click and drag gestures. It uses the passage of time to determine the difference between a click, double-click, or drag gesture.'!


!GestureController methodsFor: 'control defaults'!

controlActivity
	"Process user activity. This consists of either red button gestures or yellow button menu activity. Any other activity is handled by my superclass. Examples of gestures are: click, double-click, drag, and sweep (a special kind of drag). See the 'gestures' category for the full list."

	(sensor yellowButtonPressed) ifTrue: [^self menuActivity].
	(sensor redButtonPressed) ifTrue: [^self possibleClickAt: sensor cursorPoint].
	super controlActivity.!

isControlActive
	"Let the super view handle blue button activity."

	^self viewHasCursor & sensor blueButtonPressed not! !

!GestureController methodsFor: 'gestures'!

clickAt: aPoint
	"Perform action for a red button click at the given point. The default is to do vanilla red button activity."

	self redButtonActivity.!

doubleClickAt: aPoint
	"Perform action for a red button double-click at the given point. The default is to do vanilla red button activity."

	self redButtonActivity.!

dragAt: aPoint
	"Perform action for a red button drag starting at the given point. The default is to do vanilla red button activity."

	self redButtonActivity.!

redButtonActivity
	"If the subclass does not override a gesture messages, it is sent this message to perform vanilla red button activity. This default method does nothing."!

sweepAt: aPoint
	"Perform action for a red button sweep starting at the given point. (A sweep is a diagonal down-and-right drag, used by some applications to sweep out an area for group selection.) The default is to do vanilla red button activity."

	self redButtonActivity.! !

!GestureController methodsFor: 'menu support'!

menuActivity
	"If the yellow button is pressed, this message is sent to the controller to handle the application menu. It is up to subclasses to override this message. This default method does nothing."! !

!GestureController methodsFor: 'private-timer'!

resetTimer
	"Reset our timer by remembering the current value of the millisecond clock."

	startTime _ Time millisecondClockValue.!

timeOut: timeOutInMilliseconds
	"Compute the timer value by subtracting the time at which the timer was last reset from the current millisecond clock value. Answer true if the result is greater than timeOutInMilliseconds."

	| timerVal |
	timerVal _ Time millisecondClockValue - startTime.
	^(timerVal > timeOutInMilliseconds)! !

!GestureController methodsFor: 'private-gestures'!

dragOrSweepAt: aPoint
	"The button was held down too long for it to be a click so it is either a drag or a sweep. It is considered a sweep if the mouse has moved in definite downward-and-right manner between the time the button was depressed and now. (Note that the constants in this method may need to be changed if the timeout in possibleClickAt: is changed.)"

	| delta |
	delta _ sensor cursorPoint - aPoint.
	((delta x > 1) & (delta y > 1))
		ifTrue: [self sweepAt: aPoint]
		ifFalse: [self dragAt: aPoint].!

possibleClickAt: aPoint
	"Invoked when the red button is first depressed. If the button is released before the timeout period has elapsed, then there is at least one click and we must look for a second click. Otherwise, the gesture is a drag or sweep." 

	self resetTimer.
	[(self timeOut: 150) not & sensor redButtonPressed]
		whileTrue: ["wait for timeout or button up"].
	(sensor redButtonPressed not)	"has the button gone up?"
		ifTrue: [self possibleDoubleClickAt: aPoint]
		ifFalse: [self dragOrSweepAt: aPoint].!

possibleDoubleClickAt: aPoint
	"Invoked after the first click (i.e. the button is up). If the button is depressed again before the timeout period has elapsed, then the gesture is a double click. Otherwise, the gesture is a single click. A single click is recorded immediately. Thus, a double click causes the sequence of messages: 'clickAt:' and 'doubleClickAt:' to be sent."

	self resetTimer.
	[(self timeOut: 260) not & sensor redButtonPressed not]
		whileTrue: ["wait for timeout or button down"].
	(sensor redButtonPressed)	"has the button gone down?"
		ifTrue: [self doubleClickAt: aPoint]
		ifFalse: [self clickAt: aPoint].! !

SceneView subclass: #BasicThingView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!
BasicThingView comment:
'A BasicThingView is used to display a Thing under construction. A ThingAdaptor is the model and a ThingConstructorController is the controller. When the user edits or moves some part of the thing under construction, this class computes the parts of the display that stay the same so that only the parts that are changing need be redisplayed. This class is also responsible for accepting new Things when they are are dragging into it from a PartsBin.'!


!BasicThingView methodsFor: 'controller access'!

defaultControllerClass

	^BasicThingController! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BasicThingView class
	instanceVariableNames: ''!


!BasicThingView class methodsFor: 'instance creation'!

on: aThing
	"Create a new view on the given Thing."

	^self new model: (ThingAdaptor on: aThing)!

openOn: aThing
	"Open a view on the given Thing."

	self
		openWithSubview: (self on: aThing)
		label: (aThing name).!

openOn: aThing from: aPartHolder zoomingFrom: fromRect to: openFrame
	"Open a view on the given Thing zooming from fromRect to openFrame. Remember that this view was opened from the given partHolder."

	self
		openWithSubview: (self on: aThing)
		label: (aThing name)
		fromHolder: aPartHolder
		zoomFrom: fromRect 
		to: openFrame.! !

AbstractMethod subclass: #Method
	instanceVariableNames: 'block '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Constraints'!
Method comment:
'I represent a normal (i.e. non-module) method.
Instance variables are (in addition to those inherited):

	block...	block to execute to enforce the constraint <BlockContext>

'!


!Method methodsFor: 'initialize-release'!

block: aBlock
	"Set my code block. Used to initialize special constraints."

	block _ aBlock.!

destroy
	"Break potential cycles."

	block _ nil.
	super destroy.!

symbols: symbols methodString: methodString
	"Initialize a method by compiling the given string considering the given collection of symbols to represent the parameters of the method (i.e. its inputs and outputs). A given variable may not be both an input and an output. Note: Free variables in the methodString will be handled as they are for any block, however the user is given a warning, since free variables in a constraint methods are unusual and may indicate a programmer error."

	| insOutsTemps ins outs temps |
	insOutsTemps _ self extractInsOutsAndTemps: methodString using: symbols.
	ins _ insOutsTemps at: 1.
	outs _ insOutsTemps at: 2.
	temps _ insOutsTemps at: 3.
	self checkIns: ins outs: outs temps: temps all: symbols.
	codeString _ methodString.
	bindings _ self makeBindingArrayForIns: ins outs: outs varVector: symbols.
	block _ Compiler
			evaluate:
				((self blockPrefixForIns: ins temps: temps args: symbols),
				 methodString,
				 (self blockPostfixForOuts: outs allNames: symbols))
			for: nil
			logged: false.
	(temps size > 0) ifTrue: [block fixTemps].! !

!Method methodsFor: 'DeltaBlue'!

execute: refList
	"Execute myself to enforce my constraint. refList contains all the References for my constraint."

	block value: refList.! !

!Method methodsFor: 'private'!

blockPostfixForOuts: outNames allNames: allNames
	"Answer a string to be used as the postfix when creating a block for this method. All output temporary variables are stored via their References in the argument array and the block is terminated."

	| stream |
	"make a stream and add separator to terminate user's method string"
	stream _ WriteStream on: (String new).
	stream nextPutAll: '.'; cr.

	"build the expression postfix, creating assignments for all outputs"
	1 to: allNames size do:
		[: index |
		 (outNames includes: (allNames at: index)) ifTrue:
			[stream tab; nextPutAll: '(vars at: '.
			 stream nextPutAll: index printString, ') value: '.
			 stream nextPutAll: (allNames at: index), '.'; cr]].

	"nil out all temps, to avoid keeping pointers to garbage"
	allNames do:
		[: name |
		 stream tab; nextPutAll: name, ' _ nil.'; cr].
	stream tab; nextPutAll: ']'; cr.

	^stream contents!

blockPrefixForIns: inNames temps: tempNames args: argNames
	"Answer a string to be used as the prefix when creating a block for a method with the given input names. All constraint variables are declared as temporaries, in addition to the temporary variables from the method string. Input variable temporaries are initialized from the argument vector."

	| stream |
	stream _ WriteStream on: (String new).

	"build the expression prefix, making all the variables look like temps"
	stream nextPutAll: '| '.
	argNames do: [: v | stream nextPutAll: v; space].
	tempNames do: [: v | stream nextPutAll: v; space].
	stream nextPutAll: '|'; cr.

	"build the block header and input assignments"
	stream tab; nextPutAll: '[: vars |'; cr.
	1 to: argNames size do:
		[: index |
		 (inNames includes: (argNames at: index)) ifTrue:
			[stream tab; nextPutAll: (argNames at: index), ' _ (vars at: '.
			stream nextPutAll: index printString.
			stream nextPutAll: ') value.'; cr]].

	stream tab.
	^stream contents!

checkIns: inNames outs: outNames temps: tempNames all: allNames
	"Notify the user and answer nil if the input and output arg lists are not disjoint. Warn the user if the method code has free variables (these will be made into temporaries)."

	outNames do:
		[: v |
		 ((inNames includes: v) and:
		  [allNames includes: v]) ifTrue:
			[self error: v asString, ' cannot be both input and output!!']].

	tempNames do:
		[: v |
		 Transcript show:
			'Warning: ''', v, ''' is assumed to be a temporary.'; cr].!

extractInsOutsAndTemps: methodString using: allNames
	"Extract the input, output and temporary variable names from the Smalltalk expression represented by the given string. A temporary variable is one that is neither an input, an output, or a global. Answer an array containing the three lists (ins, outs, temps)."

	| parseTree ins outs temps |
	parseTree _ EquationParser parse: ('DoIt ', methodString) readStream.
	ins _ parseTree referenced.
	outs _ parseTree assignedTo.
	temps _ parseTree allVariables select:
		[: v | ((allNames includes: v) not) &
			  ((Smalltalk includesKey: v) not)].
	^Array with: ins with: outs with: temps!

makeBindingArrayForIns: inNames outs: outNames varVector: constraintArgs
	"Compute and answer the bindings array for the given sets of variable names. The bindings array contains for each symbol in the constraint arguments vector:
		$i if the variable is an input
		$o if the variable is an output
		$x if the variable is not referenced by this method"

	^(constraintArgs collect:
		[: varName |
		 (inNames includes: varName)
			ifTrue: [$i]
			ifFalse:
				[(outNames includes: varName)
					ifTrue: [$o]
					ifFalse: [$x]]]) asArray! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Method class
	instanceVariableNames: ''!


!Method class methodsFor: 'instance creation'!

symbols: symbols methodString: methodString
	"Answer a new, initialized instance."

	^(super new)
		symbols: symbols methodString: methodString! !

Object subclass: #ClippingRectangle
	instanceVariableNames: 'xMin xMax yMin yMax u0 u1 '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Support'!
ClippingRectangle comment:
'I support line clipping using the standard algorithm (see, e.g., Foley and vanDam''s book on interactive graphics). If I have zero area (because my height or width is zero) then I will report that no lines intersect me.'!


!ClippingRectangle methodsFor: 'clipping'!

clipFrom: beginPoint to: endPoint
	"Clip the line (beginPoint, endPoint) and answer an array of three elements, (drawFlag, clippedBegin, clippedEnd). If the first element of the answer is false, the line is completely outside the clipping rectangle, and need not be displayed. If the first element of answer is true, the second two elements are the beginning and ending points of the clipped line."

	| beginX beginY dx dy clippedBegin clippedEnd |
	self noArea ifTrue: ["line rejected" ^Array with: false with: nil with: nil].
	u0 _ 0.0.
	u1 _ 1.0.
	beginX _ beginPoint x.
	beginY _ beginPoint y.
	dx _ endPoint x - beginX.
	dy _ endPoint y - beginY.

	((self clip: (beginX - xMin) delta: dx negated) and:
	 [(self clip: (xMax - beginX) delta: dx) and:
	 [(self clip: (beginY - yMin) delta: dy negated) and:
	 [(self clip: (yMax - beginY) delta: dy)]]])
		ifFalse: ["line rejected" ^Array with: false with: nil with: nil].

	"If we haven't rejected the line by now, some of it must lie within the clipping rectangle. If u0 or u1 are within the open interval (0..1), use them to compute the new line segment start and/or point."
	dx _ dx asFloat.
	dy _ dy asFloat.
	(u0 > 0.0)
		ifTrue: [clippedBegin _ beginPoint +
				((dx asFloat * u0)@(dy asFloat * u0)) rounded]
		ifFalse: [clippedBegin _ beginPoint].
	(u1 < 1.0)
		ifTrue: [clippedEnd _ beginPoint +
				((dx asFloat * u1)@(dy asFloat * u1)) rounded]
		ifFalse: [clippedEnd _ endPoint].
	^Array with: true with: clippedBegin with: clippedEnd!

noArea
	"Answer true if either my width or my height are zero."

	^(xMin == xMax) | (yMin == yMax)! !

!ClippingRectangle methodsFor: 'private'!

clip: e delta: d

	| r |
	"Case 1: line parallel to boundary"
	(d = 0) ifTrue: [^e >= 0].		"accept if e is on boundary or inside"

	r _ e asFloat / d asFloat.		"the normalized intersection with the boundary"
	"Case 2: line from outside to inside"
	(d < 0) ifTrue:
		[(r > u1) ifTrue: [^false].		"reject"
		 u0 _ u0 max: r.				"update u0 and accept"
		 ^true].
	"Case 3: line from inside to outside"
	(d > 0) ifTrue:
		[(r < u0) ifTrue: [^false].		"reject"
		 u1 _ u1 min: r.				"update u1 and accept"
		 ^true].!

clipOrigin: origin corner: corner
	"This is the initialization message. corner should be >= origin, but if it isn't you will simply get an empty clipping rectangle."

	xMin _ origin x.
	yMin _ origin y.
	xMax _ xMin max: corner x.
	yMax _ yMin max: corner y.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClippingRectangle class
	instanceVariableNames: ''!


!ClippingRectangle class methodsFor: 'instance creation'!

from: aRectangle

	^(self new)
		clipOrigin: aRectangle origin corner: aRectangle corner!

origin: point1 corner: point2

	^(self new)
		clipOrigin: point1 corner: point2!

origin: point1 extent: extent

	^(self new)
		clipOrigin: point1 corner: (point1 + extent)! !

!ClippingRectangle class methodsFor: 'example'!

example1
	"ClippingRectangle example1"

	| r ans |
	r _ ClippingRectangle origin: 0@0 corner: 20@20.
	ans _ r clipFrom: -5@-5 to: 32@32.
	^(ans first)
		ifFalse: ['REJECTED']
		ifTrue: [(ans at: 2) printString,
				' -> ', (ans at: 3) printString]!

example2
	"ClippingRectangle example2"

	| r lines ans |
	r _ ClippingRectangle origin: 0@0 corner: 20@20.
	lines _ (OrderedCollection new)
		"these should be accepted and possibly clipped"
		add: (Array with: 5@5 with: 32@32);
		add: (Array with: -5@-5 with: 12@12);
		add: (Array with: 32@32 with: -5@-5);
		add: (Array with: 5@5 with: 12@12);

		"these should be rejected"
		add: (Array with: -5@-5 with: -5@132);
		add: (Array with: -5@-5 with: -112@-112);
		add: (Array with: 32@32 with: 70@90);
		add: (Array with: 32@5 with: 70@5);
		add: (Array with: -5@5 with: -1@5);
		add: (Array with: -5@-5 with: -1@12);
		yourself.
	^lines collect: [: l |
		ans _ r clipFrom: (l at: 1) to: (l at: 2).
		(l at: 1) printString, ' -> ', (l at: 2) printString, ' ==> ',
			((ans first)
				ifFalse: ['REJECTED']
				ifTrue: [(ans at: 2) printString, ' -> ', (ans at: 3) printString])]! !

Object subclass: #BusyCursor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Support'!
BusyCursor comment:
'This is a single-instance class implemented in the class protocol that implements animated busy cursors. Several variations are supported.'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BusyCursor class
	instanceVariableNames: 'current cursors oldCursor '!


!BusyCursor class methodsFor: 'class initialization'!

initialize
	"BusyCursor initialize."

	self initialize1.!

initialize1
	"Spinning smiley face."
	"BusyCursor initialize1."

	current _ 1.
	cursors _ Array new: 8.
	cursors at: 1 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 16388 19556 35938 32770 32770 36882 38962 20452 18372 8200 6192 1984)
	offset: 0@0).
	cursors at: 8 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 16772 16772 32786 32786 38930 38962 32882 16612 18372 8200 6192 1984)
	offset: 0@0).
	cursors at: 7 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 16580 19556 35890 32818 32818 32818 35890 19556 16580 8200 6192 1984)
	offset: 0@0).
	cursors at: 6 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 17348 16612 32882 38962 38930 32786 32786 16772 16772 8200 6192 1984)
	offset: 0@0).
	cursors at: 5 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 18372 20452 38962 36882 32770 32770 35938 19556 16388 8200 6192 1984)
	offset: 0@0).
	cursors at: 4 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 18372 19972 39938 38962 36914 36866 36866 16772 16772 8200 6192 1984)
	offset: 0@0).
	cursors at: 3 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 17924 19556 39010 38914 38914 38914 39010 19556 17924 8200 6192 1984)
	offset: 0@0).
	cursors at: 2 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 17156 17156 36866 36866 36914 38962 39938 19972 18372 8200 6192 1984)
	offset: 0@0).
	self example: 40.!

initialize2
	"Spinning slice of pie."
	"BusyCursor initialize2."

	current _ 1.
	cursors _ Array new: 8.
	cursors at: 1 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6640 8696 16892 16892 33278 33278 33278 32770 32770 16388 16388 8200 6192 1984)
	offset: 0@0).
	cursors at: 2 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 16412 16444 32894 33022 33278 33022 32894 16444 16412 8200 6192 1984)
	offset: 0@0).
	cursors at: 3 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 16388 16388 32770 32770 33278 33278 33278 16892 16892 8696 6640 1984)
	offset: 0@0).
	cursors at: 4 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 16388 16388 32770 32770 33026 33666 34754 20452 24564 16376 8176 1984)
	offset: 0@0).
	cursors at: 5 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 16388 16388 32770 32770 65282 65282 65282 32516 32516 16136 7984 1984)
	offset: 0@0).
	cursors at: 6 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 6192 8200 28676 30724 64514 65026 65282 65026 64514 30724 28676 8200 6192 1984)
	offset: 0@0).
	cursors at: 7 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 7984 16136 32516 32516 65282 65282 65282 32770 32770 16388 16388 8200 6192 1984)
	offset: 0@0).
	cursors at: 8 put: (Cursor
	extent: 16@16
	fromArray: #( 0 1984 8176 16376 24564 20452 34754 33666 33026 32770 32770 16388 16388 8200 6192 1984)
	offset: 0@0).
	self example: 40.!

initialize3
	"Beanie with spinning propeller."
	"BusyCursor initialize3."

	current _ 1.
	cursors _ Array new: 6.
	"horizontal"
	cursors at: 1 put: (Cursor
		extent: 16@16
		fromArray: #(0 0 14 32766 29056 384 384 384 8184 30702 52275 38937 65535 0 0 0)
		offset: 0@0).
	"uphill"
	cursors at: 2 put: (Cursor
		extent: 16@16
		fromArray: #(0 14 62 480 1920 32128 29056 384 8184 30702 52275 38937 65535 0 0 0)
		offset: 0@0).
	"steep uphill"
	cursors at: 3 put: (Cursor
		extent: 16@16
		fromArray: #(112 112 64 128 384 896 3968 3968 8184 30702 52275 38937 65535 0 0 0)
		offset: 0@0).
	"vertical"
	cursors at: 4 put: (Cursor
		extent: 16@16
		fromArray: #(0 0 384 384 384 384 384 384 8184 30702 52659 39321 65535 0 0 0)
		offset: 0@0).
	"steep downhill"
	cursors at: 5 put: (Cursor
		extent: 16@16
		fromArray: #(7168 7168 1536 768 384 448 496 496 8184 30702 52275 38937 65535 0 0 0)
		offset: 0@0).
	"downhill"
	cursors at: 6 put: (Cursor
		extent: 16@16
		fromArray: #(0 0 31744 30592 494 446 384 384 8184 30702 52275 38937 65535 0 0 0)
		offset: 0@0).
	self example: 40.!

initialize4
	"Spinning propeller."
	"BusyCursor initialize4."

	current _ 1.
	cursors _ Array new: 8.
	"horizontal"
	cursors at: 1 put: (Cursor
		extent: 16@16
		fromArray: #(0 0 0 0 0 0 0 956 32764 31616 0 0 0 0 0 0)
		offset: 0@0).
	"slantUp1"
	cursors at: 2 put: (Cursor
		extent: 16@16
		fromArray: #(0 0 0 0 0 12 60 1008 896 8064 30720 24576 0 0 0 0)
		offset: 0@0).
	"slantUp2"
	cursors at: 3 put: (Cursor
		extent: 16@16
		fromArray: #(0 0 0 12 28 56 112 896 896 896 7168 14336 28672 24576 0 0)
		offset: 0@0).
	"slantUp3"
	cursors at: 4 put: (Cursor
		extent: 16@16
		fromArray: #(0 0 96 96 192 192 128 896 896 896 512 1536 1536 3072 3072 0)
		offset: 0@0).
	"vertical"
	cursors at: 5 put: (Cursor
		extent: 16@16
		fromArray: #(0 0 768 768 768 768 256 896 896 896 256 384 384 384 384 0)
		offset: 0@0).
	"slantDown1"
	cursors at: 6 put: (Cursor
		extent: 16@16
		fromArray: #(0 0 3072 3072 1536 1536 512 896 896 896 128 192 192 96 96 0)
		offset: 0@0).
	"slantDown2"
	cursors at: 7 put: (Cursor
		extent: 16@16
		fromArray: #(0 0 0 24576 28672 14336 7168 896 896 896 112 56 28 12 0 0)
		offset: 0@0).
	"slantDown3"
	cursors at: 8 put: (Cursor
		extent: 16@16
		fromArray: #(0 0 0 0 0 24576 30720 8064 896 1008 60 12 0 0 0 0)
		offset: 0@0).
	self example: 40.! !

!BusyCursor class methodsFor: 'busy cursor'!

begin
	"Start showing the BusyCursor."
	oldCursor _ Cursor currentCursor.
	(cursors at: current) show!

dec
	"Decrement the BusyCursor."
	current _ current - 1.
	current < 1 ifTrue: [current _ cursors size].
	(cursors at: current) show!

end
	"End showing the BusyCursor."
	oldCursor show!

inc
	"Increment the BusyCursor."
	current _ current + 1.
	current > cursors size ifTrue: [current _ 1].
	(cursors at: current) show! !

!BusyCursor class methodsFor: 'example'!

example: aTime
	"BusyCursor example: 40."

	self begin.
	1 to: 20 do: [:i | self inc. (Delay forMilliseconds: aTime) wait].
	1 to: 20 do: [:i | self dec. (Delay forMilliseconds: aTime) wait].
	self end! !


Object subclass: #ModuleSolution
	instanceVariableNames: 'methods plan isPossibleEquation outWalkEqns dependencies '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Module Compiler'!
ModuleSolution comment:
'I record information about one solution during the Module compilation process. I will eventually become one method of a Module constraint.'!


!ModuleSolution methodsFor: 'initialize-release'!

methods: methodList
	"Initialize myself."

	methods _ methodList.
	plan _ nil.				"filled in later"
	isPossibleEquation _ nil.	"filled in later"
	outWalkEqns _ nil.		"filled in later"
	dependencies _ nil.		"filled in later"! !

!ModuleSolution methodsFor: 'access'!

dependencies: aModuleDependency
	"Record my input/output dependencies."

	dependencies _ aModuleDependency.!

isPossibleEquation: aModuleAND
	"Record my strength check equation."

	isPossibleEquation _ aModuleAND.!

methods
	"Answer the list of methods that comprise this solution."

	^methods!

outWalkEqns: eqnList
	"Record the walkabout strength equations for my outputs. These are in the same order as my dependencies list."

	outWalkEqns _ eqnList.!

plan: aPlan
	"Record my plan. The order of methods in the plan is different from the order in my 'methods' instance variable; the methods in the plan correspond to the order of constraints in the partition's constraint list whereas the order of methods in the plan is the correct execution order. The plan also omits null methods from stay and edit constraints."

	plan _ aPlan.! !

!ModuleSolution methodsFor: 'method gen'!

methodFor: module namePrefix: prefix constraints: constraints externalVars: externalVars varTable: varTable
	"Compile the check, execute, and propagate methods for this solution and install them in module's class. Name them using given prefix string. Answer a new ModuleMethod for this solution."

	| codeString |
	codeString _ self codeStringAndVarsFor: constraints varTable: varTable.
	self
		compileExecuteIn: module class
		prefix: prefix
		codeString: codeString
		varTable: varTable.
	self compileIsPossibleIn: module class prefix: prefix.
	self compilePropagateIn: module class prefix: prefix.
	^ModuleMethod
		module: module
		codeString: codeString
		bindings: (self buildBindingArray: externalVars)
		isPossible: prefix, 'isPossible'
		execute: prefix, 'execute'
		propagate: prefix, 'propagate'! !

!ModuleSolution methodsFor: 'private-method gen'!

appendStatementsOf: methodTree to: aStream
	"Append the statements of the given method parse tree to the given stream. Omit the final '^self' statement."

	| statements s |
	"get method statements and remove final '^self'"
	statements _ methodTree block statements.
	statements _ statements copyFrom: 1 to: (statements size - 1).
	"add statements to aStream"
	statements do:
		[: statement |
		 s _ statement printString.
		 s _ s copyFrom: 2 to: (s size - 1).	"remove {} brackets"
		 aStream tab; nextPutAll: s; nextPut: $.; cr].!

buildBindingArray: constraintArgs
	"Construct the bindings array for this solution for use in a ModuleMethod, using the given vector of external variables. The bindings array contains for each variable in the constraint arguments vector:
		$i if the variable is an input
		$o if the variable is an output
		$x if the variable is not referenced by this method"

	| outVars inVars bindings |
	outVars _ Set new: 8.
	inVars _ Set new: 8.
	dependencies do:
		[: d |
		 outVars add: d outVar.	
		 inVars addAll: d dependsOn].
	bindings _ constraintArgs collect:
		[: var |
		 (outVars includes: var)
			ifTrue: [$o]
			ifFalse: [(inVars includes: var)
				ifTrue: [$i]
				ifFalse: [$x]]].
	^bindings asArray!

codeStringAndVarsFor: constraints varTable: varTable
	"Answer the code string and the referenced variable list for this solution. The code string is derived by concatenating all the statements of the non-nil methods of this solution in order."
	"Details: The varible references in each method are renamed by using the reference and symbol vectors of its constraint and the varMap dictionary to map all the constraint argument names to their corresponding variable names in this context. We also inline expand all constant references at this time."

	| stream varMap constraint parser tree |
	stream _ (String new: 1000) writeStream.
	varMap _ IdentityDictionary new: varTable size.
	varTable do: [: v | varMap at: v thingData put: v].
	plan do:
		[: method |
		 constraint _ constraints detect: [: c | c methods includes: method].
		 parser _ EquationParser new.
		 tree _ parser parse: ('DoIt ', method codeString) readStream.
		 tree _ self
			remapVars: tree
			for: constraint
			varMap: varMap
			encoder: parser encoder.
		 self appendStatementsOf: tree to: stream].
	^stream contents!

remapVars: parseTree for: constraint varMap: varMap encoder: encoder
	"Remap the variable reference in the given parseTree to use the local name and expand constant references. varMap is a dictionary mapping thingDatas to ModuleVarTableEntries."
	"Details: First we construct a dictionary mapping the constraint's symbolic variable names to local names or constant expressions. Then we apply this mapping to the given parse tree."

	| mappingDict varEntry newName |
	mappingDict _ Dictionary new.
	constraint variables with: constraint symbols do:
		[: var : symbol |
		 varEntry _ varMap at: var thingData.
		 mappingDict at: symbol put:
			((varEntry isConstant)
				ifTrue: [varEntry literalTreeForUsing: encoder]
				ifFalse: [encoder autoBind: varEntry name])].
	^parseTree transformBy:	"apply the mapping"
		[: node |
		 (node isMemberOf: VariableNode)
			ifTrue: [mappingDict at: (node name asSymbol) ifAbsent: [node]]
			ifFalse: [node]]! !

!ModuleSolution methodsFor: 'private-compilation'!

ancestorsAndStayCodeOn: aStream
	"Append onto the given stream code to propagate ancestors and stay values for this solution."

	| fixed nonFixed |
	aStream cr; cr; tab; nextPutAll: '| ins |'; cr.
	fixed _ dependencies select: [: entry | entry stay & entry dependsOn isEmpty].
	nonFixed _ dependencies select: [: entry | (fixed includes: entry) not].

	"output code to compute the DeltaBlue data for the outputs determined by stay constraints"
	fixed do:
		[: entry |
		 aStream tab.
		 entry outVar thingDataCodeStringOn: aStream.
		 aStream tab; tab; nextPutAll: 'walkStrength: ', entry strengthString, ';'; cr.
		 aStream tab; tab; nextPutAll: 'stay: true;'; cr.
		 aStream tab; tab; nextPutAll: 'ancestors: #().'; cr].

	"output code to compute the ancestor and stay data for the outputs NOT determined by stay constraints"
	(nonFixed isEmpty) ifFalse:
		[nonFixed do:
			[: entry |
			 aStream tab; nextPutAll: 'ins _ OrderedCollection new.'; cr.
			 entry dependsOn do:
				[: v |
				 aStream tab; nextPutAll: 'ins add: '.
				 v thingDataCodeStringOn: aStream.
				 aStream nextPut: $.; cr].
			 aStream tab; nextPutAll: 'self propagateFrom: ins to: '.
			 entry outVar thingDataCodeStringOn: aStream.
			 aStream nextPut: $.; cr]].!

compile: aString in: moduleClass dontExpand: dontExpand
	"Compile the given method string in the given class. Variables in the collection dontExpand will not be expanded in line."

	| methodNode selector |
	methodNode _ EquationParser parse: aString readStream in: moduleClass.
	selector _ methodNode selector.
	self optimize: (methodNode block statements) dontExpand: dontExpand.
	methodNode block returnSelfIfNoOther.	"add '^self'"
	moduleClass addSelector: selector withMethod: (methodNode generate).
	moduleClass organization classify: selector under: 'module methods' asSymbol.!

compileExecuteIn: moduleClass prefix: prefix codeString: codeString varTable: varTable
	"Compile the 'xxxExecute' method in the given class."

	| s internals |
	s _ (String new: 1000) writeStream.
	s nextPutAll: prefix, 'execute'.
	s cr; cr.
	self putPrefixOn: s varTable: varTable.
	s nextPutAll: codeString.
	self putPostfixOn: s.
	internals _ (varTable select: [: v | v isInternal]) collect: [: v | v name].
	self
		compile: (s contents)
		in: moduleClass
		dontExpand: internals asSet.!

compileIsPossibleIn: moduleClass prefix: prefix
	"Compile the 'xxxIsPossible' method in the given class."

	| s |
	s _ (String new: 1000) writeStream.
	s nextPutAll: prefix, 'isPossible'.
	s cr; cr; tab; nextPut: $^; cr.
	isPossibleEquation storeOn: s.
	self compile: (s contents)
		in: moduleClass
		dontExpand: #().!

compilePropagateIn: moduleClass prefix: prefix
	"Compile the 'xxxPropagate' method in the given class."

	| s temp |
	s _ (String new: 1000) writeStream.
	s nextPutAll: prefix, 'propagate'.
	s cr; cr.
	self ancestorsAndStayCodeOn: s.
	s cr.

	"generate code for the walkabout strength computations for all outputs not completely determined by stay constraints"
	dependencies with: outWalkEqns do:
		[: entry : eqn |
		 (entry stay not) ifTrue:
			[s tab.
			 (entry outVar) thingDataCodeStringOn: s.
			 s nextPutAll: ' walkStrength: '; cr; tab; tab.
			 eqn storeOn: s.
			 s nextPut: $.; cr]].

	"compile the 'isPossible' method"
	self compile: (s contents)
		in: moduleClass
		dontExpand: #().!

putPostfixOn: aStream
	"Answer a string to be used as the postfix when compiling my method. Statements are created to store the values of all outputs temporaries in their final destinations."

	| outVar |
	dependencies do:
		[: d |
		 ((d stay) & (d dependsOn isEmpty)) ifFalse:	"not just a stay constraint"
			[outVar _ d outVar.
			 aStream tab.
			 outVar putCodeStringOn: aStream.
			 aStream nextPutAll: outVar name.
			 aStream nextPut: $.; cr]].!

putPrefixOn: aStream varTable: varTable
	"Append to the given stream a prefix to be used when compiling my execute method. Assignments statements are created to fetch the value of all variables into temporary variables. Unnecessary assignments statements are later removed during code optimization."

	varTable do:
		[: var |
		(var isExternal) ifTrue:
			[aStream tab; nextPutAll: var name, ' _ '.
			 var getCodeStringOn: aStream.
			 aStream nextPut: $.; cr]].! !

!ModuleSolution methodsFor: 'private-optimization'!

detectInlineCandidateIn: statements dontExpand: dontExpand
	"Find a candidate assignement statement for inline expansion from the given list of statements. Answer the index of the candidate statement or nil if we don't find one."

	| node v |
	1 to: statements size do:
		[: index |
		 node _ statements at: index.
		 (node isMemberOf: AssignmentNode) ifTrue:
			[v _ node variable name.
		  	 (((dontExpand includes: v) not) and:
			  [(self var: v isNotAssignedToAfter: index in: statements) and:
		 	  [(self var: v usageCountAfter: index in: statements) <= 1]])
					ifTrue: [^index]]].
	^nil!

detectUnneededCandidateIn: statements
	"Select a candidate unnecessary assignement statement from the given list of statements. Answer the index of the candidate statement or nil if we don't find one."

	| node var |
	1 to: statements size do:
		[: index |
		 node _ statements at: index.
		 ((node isMemberOf: AssignmentNode) and:
		  [node variable isTemp]) ifTrue:
			[var _ node variable name.
		  	 ((self var: var usageCountAfter: index in: statements) = 0)
				ifTrue: [^index]]].
	^nil!

optimize: statements dontExpand: dontExpand
	"Do inline expansions on the given OrderedCollection of statements. The statement list is modified in place."
	"Algorithm:
	 Repeat until nothing more can be done:
		find an assignment statement s of the form 'v _ expr' such that
			v is not in dontExpand AND
			v is used at most once in the remaining statements AND
			v is not assigned to in the remaining statements
		remove s from the statements list
		replace references to v with expr
Also, remove assignments to temporary variables that are never referenced in subsequent statements."

	| index s |
	[true] whileTrue:
		[index _	self detectInlineCandidateIn: statements dontExpand: dontExpand.
		 (index isNil) ifTrue: [^self]. 	"nothing more to do"
		 s _ statements removeAtIndex: index.
		 self replace: (s variable name) with: (s value) in: statements after: index].

	"remove unneeded assignments to temporary variables"
	[true] whileTrue:
		[index _	self detectUnneededCandidateIn: statements.
		 (index isNil) ifTrue: [^self]. 	"nothing more to do"
		 s _ statements removeAtIndex: index].!

replace: var with: expr in: statements after: index
	"Replace the given variable with the given expression in the statements following index in the given list."

	| old new |
	index to: statements size do:
		[: i |
		 old _ statements at: i.
		 new _ old transformBy:
			[: node |
			 ((node isMemberOf: VariableNode) and:
			   [node name = var])
				ifTrue: [expr transformBy: [: n | n] "copies expr tree"]
				ifFalse: [node]].
		 statements at: i put: new].!

var: var isNotAssignedToAfter: index in: statements
	"Answer true if the given variable is not assigned to after the statement with the given index in the given list of statements."

	| s |
	(index + 1) to: statements size do:
		[: i |
		 (statements at: i) apply:
			[: node |
			 ((node isMemberOf: AssignmentNode) and:
			   [node variable name = var]) ifTrue:
				[^false].
			 true	"apply this block to the entire tree"]].

	^true!

var: var usageCountAfter: index in: statements
	"Answer the number of times that the given variable is referenced after the statement with the given index in the given list of statements."

	| count |
	count _ 0.
	(index + 1) to: statements size do:
		[: i |
		 (statements at: i) apply:
			[: node |
			 ((node isMemberOf: VariableNode) and:
			   [node name = var]) ifTrue:
				[count _ count + 1].
			 true	"apply this block to the entire tree"]].
	^count! !

!ModuleSolution methodsFor: 'printing'!

printOn: aStream

	aStream cr; nextPutAll: 'ModuleSolution['.
	methods do:
		[: m |
		 (m isNil) ifTrue: [aStream cr].
		 m printOn: aStream].
	aStream nextPutAll: ']'.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModuleSolution class
	instanceVariableNames: ''!


!ModuleSolution class methodsFor: 'instance creation'!

on: methodList
	"Answer a new instance for the given solution."

	^self new methods: methodList! !

AbstractMethod subclass: #OffsetMethod
	instanceVariableNames: 'offset '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Constraints-Special'!


!OffsetMethod methodsFor: 'initialize-release'!

offset: aNumber

	offset _ aNumber.! !

!OffsetMethod methodsFor: 'DeltaBlue'!

execute: refList
	"Execute myself to enforce my constraint. refList contains all the References for my constraint."
	"Details: If my first reference is the output, then compute it by adding the offset to the value of the first reference. If my first reference is the input, do the inverse operation (subtracting the offset)."

	(bindings first == $i)
		ifTrue: [(refList at: 2) value: ((refList at: 1) value + offset)]
		ifFalse: [(refList at: 1) value: ((refList at: 2) value - offset)].! !


ActionMenu subclass: #ThingLabCustomMenu
	instanceVariableNames: 'items lastLine '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Framework'!

ThingLabCustomMenu comment:
'I am used to build menus on-the-fly. I maintain lists of menu items, actions (usually symbols to be sent as messages), and menu section dividing lines to which my clients may append new entries and lines by sending me the messages:

	add: aString action: anAction
	addLine

After the menu is constructed, it may be invoked with one of the following messages:

	invoke: initialSelection
	invoke

I am a subclass of ActionMenu, so I inherit a number of instance variables. The ones I am particularly concerned with are:

	items _ an OrderedCollection of strings to appear in the menu
	selectors _ an OrderedCollection of Symbols to be used as message selectors
	lineArray _ an OrderedCollection of line positions
	lastLine _ used to keep track of the last line to avoid making duplicate entries in lineArray'!


!ThingLabCustomMenu methodsFor: 'initialize-release'!

initialize

	items _ OrderedCollection new.
	selectors _ OrderedCollection new.
	lineArray _ OrderedCollection new.
	lastLine _ 0.! !

!ThingLabCustomMenu methodsFor: 'construction'!

add: aString action: aSymbol
	"Add the given string as the next menu item. If it is selected, the given action (usually but not necessarily a symbol) will be returned to the client."

	items addLast: aString.
	selectors addLast: aSymbol.!

addLine
	"Append a line to the menu after the last entry. Suppress duplicate lines."

	(lastLine ~= items size)
		ifTrue:
			[lastLine _ items size.
			 lineArray addLast: lastLine].! !

!ThingLabCustomMenu methodsFor: 'invocation'!

invoke
	"Invoke the menu with no initial selection."

	^self invoke: nil!

invoke: initialSelection
	"Invoke the menu with the given initial selection (i.e. one of my 'action' symbols). Answer the 'action' selector associated with the menu item chosen by the user or nil if none is chosen."

	| itemIndex |
	self build.
	(initialSelection notNil)
		ifTrue: [self preSelect: initialSelection].
	itemIndex _ self startUp.
	(itemIndex = 0)
		ifTrue: [^nil]
		ifFalse: [^selectors at: itemIndex].! !

!ThingLabCustomMenu methodsFor: 'private'!

build
	"Turn myself into an invokable ActionMenu."

	| stream itemIndex |
	stream _ WriteStream on: (String new).
	items do: [: item | stream nextPutAll: item; cr].
	(items isEmpty)
		ifFalse: [stream skip: -1]. 	"remove last cr"
	self labels: stream contents font: (TextStyle default fontAt: 1) lines: lineArray.!

preSelect: action
	"Pre-select and highlight the menu item associated with the given action."

	| i |
	i _ selectors indexOf: action ifAbsent: [^self].
	self reset.
	marker _ marker 
		align: marker topLeft 
		with: (marker left)@(frame inside top + (marker height * (i - 1))).
	selection _ i.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ThingLabCustomMenu class
	instanceVariableNames: ''!


!ThingLabCustomMenu class methodsFor: 'instance creation'!

new

	^(super new) initialize! !

!ThingLabCustomMenu class methodsFor: 'example'!

example
	"ThingLabCustomMenu example"

	| menu |
	menu _ ThingLabCustomMenu new.
	menu add: 'apples' action: #apples.
	menu add: 'oranges' action: #oranges.
	menu add: 'peaches' action: #peaches.
	menu add: 'pears' action: #pears.
	^menu invoke: #peaches! !

Thing subclass: #ModuleThing
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Things'!
ModuleThing comment:
'I am an abstract class for compiled ThingLabII Things. These Things are known as Modules. Do NOT EVER subclass a subclass of ModuleThing. Very bad!!  Even worse than for Things.

My protocol is fairly simple because most of the work is done at compile time.
'!


!ModuleThing methodsFor: 'public-testing'!

isStructureModifiable
	"Modules cannot be further modified."

	^false! !

!ModuleThing methodsFor: 'cloning'!

clonePass1: cloneDictionary
	"ModuleThings must clone their internal parts as well as their normal parts."

	| myClone oldPart newPart |
	myClone _ super clonePass1: cloneDictionary.
	"clone my internal parts"
	(super class instOffset + 1) to: (self class instOffset) do:
		[: i |
		 oldPart _ self instVarAt: i.
		 newPart _ oldPart cloneUsing: cloneDictionary.
		 myClone instVarAt: i put: newPart].
	"redundant, but good documentation:"
	cloneDictionary at: self put: myClone.
	^myClone! !

!ModuleThing methodsFor: 'DeltaBlue'!

propagateFrom: inDatas to: outData
	"Used by ModuleMethods to propagate stay values from the given inputs to the given output."

	outData stay:
		((inDatas isEmpty) or:
		  [(inDatas detect: [: var | var stay not] ifNone: [nil]) isNil]).! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModuleThing class
	instanceVariableNames: 'constructionView '!


!ModuleThing class methodsFor: 'initialize and destroy'!

destroy
	"Eliminate useView/constructionView circularities before destroying this class."

	(constructionView notNil) ifTrue:
		[constructionView useView: nil].
	constructionView _ nil.
	super destroy.!

initializeForSourceClass: sourceThingClass internalPartCount: internalPartCount
	"Initialize a new ModuleThing class created from the given source class."

	| instVarNames |
	partIcon _ sourceThingClass partIcon deepCopy.
	explainText _ 'This is a compiled Module. It was compiled from ', sourceThingClass name, '.'.
	externalParts _ OrderedCollection new.
	instVarNames _ self instVarNames.
	partNamesAndIndices _ OrderedCollection new: instVarNames size.
	1 to: instVarNames size do:
		[: i |
		 (i > internalPartCount) ifTrue:
		 	[partNamesAndIndices addLast:
				(Array
					with: (instVarNames at: i) asSymbol
					with: (self instOffset + i))]].
	useView _ nil.
	constructionView _ sourceThingClass.
	prototype _ self basicNew initialize.! !

!ModuleThing class methodsFor: 'access'!

constructionView
	"Answer the class of the Thing that was compiled to create me."

	^constructionView!

constructionView: aThingClass
	"Set the class of the Thing that was compiled to create me."

	constructionView _ aThingClass.! !

!ModuleThing class methodsFor: 'private-compiling'!

compileInstOffsetMethodAs: size
	"Compile the instOffset method for this class of the form:

		instOffset
			^NNN
	where NNN is the number of internal variable plus the instOffset for normal Things."

	| sel encoder returnNode block methodNode |
	sel _ #instOffset.
	encoder _ (Encoder new) init: self class context: nil notifying: self.
	returnNode _ ReturnNode new expr: (encoder encodeLiteral: size).
	block _ BlockNode new
		statements: (OrderedCollection with: returnNode)
		returns: true.
	methodNode _ MethodNode new
		selector: sel
		arguments: #()
		precedence: sel precedence
		temporaries: #()
		block: block
		encoder: encoder
		primitive: 0.
	self class addSelector: sel withMethod: (methodNode generate).
	self class organization classify: sel under: 'inst var access' asSymbol.! !

StandardSystemController subclass: #SpecialSystemController
	instanceVariableNames: 'fromFrame fromHolder '
	classVariableNames: 'BlueButtonMenu '
	poolDictionaries: ''
	category: 'ThingLabII-UI-Support'!


!SpecialSystemController methodsFor: 'accessing'!

fromFrame

	^fromFrame!

fromFrame: aRectangle

	fromFrame _ aRectangle!

fromHolder

	^fromHolder!

fromHolder: aPartHolder

	fromHolder _ aPartHolder! !

!SpecialSystemController methodsFor: 'queries'!

isVisible

	^status ~= #closed! !

!SpecialSystemController methodsFor: 'menu messages'!

blueButtonActivity
	"Use special menu if collapsed. Otherwise, use my custom blueButtonMenu, which omits 'collapse'."

	| selector i |
	view isCollapsed
		ifTrue: [^super blueButtonActivity].

	(BlueButtonMenu isNil) ifTrue:
		[BlueButtonMenu _ ActionMenu
			labels: ' under \ move \ frame \ close ' withCRs
			lines: #(3)
			selectors: #(under move reframe close)].
	i _ BlueButtonMenu startUp.
	(i > 0) ifTrue: [self perform: (BlueButtonMenu selectorAt: i)].!

close
	"Do zooming animation and remember the current view display box on close. In order to do the animation, fromFrame must be non-nil and in order to remember the display box fromHolder must be non-nil."

	"model changeRequest ifFalse: [^self].
	status _ #closed.
	view erase.
	(fromHolder notNil)
		ifTrue: [fromHolder lastFrame: (view displayBox)].
	(fromFrame notNil)
		ifTrue: [Display zoom: view displayBox to: fromFrame duration: 260]."
	super close.!

controlActivity

	(sensor blueButtonPressed and: [self viewHasCursor])
		ifTrue: [^self blueButtonActivity].
	(sensor redButtonPressed and:
	  [view labelDisplayBox containsPoint: sensor cursorPoint])
		ifTrue: [^self redButtonActivity].
	self controlToNextLevel.!

redButtonActivity
	"Give access to menus when the mouse (red button) goes down in the label part of my view. If the mouse is in the text box, act as though the yellow button were pressed (the application menu, by convention) otherwise, act as though the blue button were pressed (the view menu, by convention)."

	| p |
	p _ sensor cursorPoint.
	(view labelDisplayBox containsPoint: p)
		ifTrue:
			[((view labelTextDisplayBox containsPoint: p) and:
			   [view firstSubView notNil])
				ifTrue:
					[(view firstSubView controller respondsTo: #menuActivity) ifTrue:
						[view firstSubView controller menuActivity].
					  (view firstSubView controller respondsTo: #yellowButtonActivity) ifTrue:
						[view firstSubView controller yellowButtonActivity]]
				ifFalse: [self blueButtonActivity]]
		ifFalse: [].! !

BasicThingView subclass: #MultiThingView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!


!MultiThingView methodsFor: 'controller access'!

defaultControllerClass

	^MultiThingController! !

!MultiThingView methodsFor: 'operations'!

acceptCopies: thingHolders at: offsets withRespectTo: ignored
	"Insert copies of the given Things."

	thingHolders do:
		[: thingHolder | model addGlyph: (thingHolder cargo clone)].
	self displayView.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MultiThingView class
	instanceVariableNames: ''!


!MultiThingView class methodsFor: 'instance creation'!

on: aMultiThingAdaptor
	"Answer a new view on the given object."

	^(self new) model: aMultiThingAdaptor!

open
	"Open an empty view."

	self
		openWithSubview: (self new model: MultiThingAdaptor new)
		label: 'MultiThing View'.! !

Constraint subclass: #OffsetConstraint
	instanceVariableNames: ''
	classVariableNames: 'SharedMethods '
	poolDictionaries: ''
	category: 'ThingLabII-Constraints-Special'!
OffsetConstraint comment:
'I am used to relate two variables by a fixed offset.'!


!OffsetConstraint methodsFor: 'initialize-release'!

ref: ref1 ref: ref2 strength: aSymbol offset: offset
	"Initialize myself with the given references, strength, and offset."

	strength _ Strength of: aSymbol.
	symbols _ #(v1 v2).
	self variables: (Array with: ref1 with: ref2).
	self methods: (self getMethodsFor: offset).
	whichMethod _ nil.
	self initializeFlags.! !

!OffsetConstraint methodsFor: 'private'!

getMethodsFor: offset
	"To save space, we maintain a Dictionary of shared methods for offsets in the range [-25..25]. Answer the methods array from this Dictionary or a newly created one."

	| offsetMethods |
	(SharedMethods isNil) ifTrue:
		[SharedMethods _ Dictionary new: 100].
	((offset isInteger) & (offset >= -25) & (offset <= 25))
		ifTrue:			"cached methods"
			[offsetMethods _ SharedMethods
				at: offset
				ifAbsent: [self makeMethodsFor: offset].
			 SharedMethods at: offset put: offsetMethods]
		ifFalse:			"non-integer or unusual size offset"
			[offsetMethods _ self makeMethodsFor: offset].
	^offsetMethods!

makeMethodsFor: offset
	"Construct and answer a pair of OffsetMethods for the given offset."

	^Array
		with: ((OffsetMethod new)
			codeString: 'v2 _ v1 + ', offset printString;
			offset: offset;
			bindings: 'io')
		with: ((OffsetMethod new)
			codeString: 'v1 _ v2 - ', offset printString;
			offset: offset;
			bindings: 'oi')! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OffsetConstraint class
	instanceVariableNames: ''!


!OffsetConstraint class methodsFor: 'instance creation'!

from: ref1 to: ref2 require: aNumber
	"Create an OffsetConstraint on the referenced variable. For example:

	OffsetConstraint
		from: point1->#x
		to: point2->#x
		require: 25."

	^(super new) ref: ref1 ref: ref2 strength: #required offset: aNumber!

ref: ref1 ref: ref2 strength: strength offset: aNumber
	"Create an OffsetConstraint on the referenced variable. For example:

	OffsetConstraint
		ref: point1->#x
		ref: point2->#x
		strength: #preferred
		offset: 25."

	^(super new) ref: ref1 ref: ref2 strength: strength offset: aNumber! !

BasicThingView subclass: #ThingConstructorView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!


!ThingConstructorView methodsFor: 'controller access'!

defaultControllerClass

	^ThingConstructorController! !

!ThingConstructorView methodsFor: 'operations'!

acceptCopies: thingHolders at: offsets withRespectTo: ignored
	"Insert copies of the given Things and allow the user to connect up their inserters."

	| newPart |
	 (model thing isStructureModifiable)
		ifFalse: [^self flash].

	thingHolders do:
		[: thingHolder |
		 self displaySafe: [controller insertThing: (thingHolder cargo)]].! !

Object subclass: #MultiSolver
	instanceVariableNames: 'constraints externalVars modeTable modeStrength methods satisfied determined solutions variables transitions '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Module Compiler'!
MultiSolver comment:
'I am used by the ModuleCompiler and the Thing debugger to enumerate the possible solutions to a set of constraints. There are various options to control which possibilities are presented. One may get all possible solutions, only those without cycles, or only those that without cycles that have unique input/output modes.'!


!MultiSolver methodsFor: 'initialization'!

constraints: constraintList
	"Initialize myself with the constraints of the given collection."

	| sorter |
	"sort constraints in order of decreasing strength"
	sorter _ (SortedCollection new: 100)
				sortBlock: [: i : j | i strength stronger: j strength].
	sorter addAll: constraintList.
	constraints _ sorter asOrderedCollection.

	"re-order the constraints in constraintList to match constraints"
	constraintList removeAll.	"empties constraintList"
	constraintList addAll: constraints.
	sorter release.
	self buildVariableDictionary.
	externalVars _ IdentitySet new.
	modeTable _ modeStrength _ nil.!

constraints: constraintList externalVars: extVarList
	"Initialize myself with the given constraints and external variables."

	self constraints: constraintList.
	externalVars _ IdentitySet new: extVarList size.
	externalVars addAll: extVarList.
	modeTable _ Dictionary new.
	modeStrength _ Dictionary new.! !

!MultiSolver methodsFor: 'public'!

allSolutions
	"Answer all the solutions, even those that contain cycles."

	^solutions!

computeSolutions
	"Compute and remember all legal solutions to my set of constraints."

	methods _ OrderedCollection new: constraints size.
	satisfied _ IdentitySet new: (constraints size * 4).
	determined _ IdentitySet new: 30.
	solutions _ OrderedCollection new: 100.
	self possibleNextMethods do:
		[: m | self solutionsUsing: m].!

nonCyclicSolutions
	"Answer all non-cyclic solutions. This can take some time if there are a large number of solutions."

	^solutions select: [: s | (self hasCycle: s) not]!

uniqueModeSolutions
	"Answer a set of non-cyclic solutions that handle mutually exclusive input/output modes over the external variables. This can only be done if I know what the external variables are (i.e. if my modeTable is not nil)."

	| solutionSet |
	(modeTable isNil) ifTrue:
		[^self error: 'The external variables were not defined.'
		 "use the constraints:externalVars: initialization message"].

	solutionSet _ OrderedCollection new: modeTable size.
	modeTable do: [: solution | solutionSet add: solution].
	^solutionSet! !

!MultiSolver methodsFor: 'private-find solutions'!

couldUse: aMethod for: theConstraint
	"Answer true if the given constraint is stronger than all unsatisfied constraints that could potentially determine the given method's outputs. If any of the method's outputs are external variables, we can't be sure that it is strong enough. We assume that the given method is possible -- that is, that none of its outputs is already determined by another constraint."

	| maxOutStrength |
	maxOutStrength _ Strength absoluteWeakest.
	aMethod outDatasIn: theConstraint thingDatas do:
		[: outVar |	"examine all output vars of the method"
		 (externalVars includes: outVar) ifTrue: [^false].
		 outVar constraints do:
			[: c |	"examine all unsatisfied constraints except theConstraint"
			 ((c ~~ theConstraint) and:
			  [(satisfied includes: c) not]) ifTrue:
				[maxOutStrength _
					maxOutStrength strongest: c strength]]].

	^theConstraint strength stronger: maxOutStrength!

modeVector
	"Answer a mode vector for the current solution. A mode vector is a string of 'i' and 'o' characters (e.g. 'iio') that indicates whether each var in externalVars is an input or output."
	"Details: v is output if it is in determined OR if it is an output of the last method (if that method isn't nil). We have to check the last method outputs because the last method's outputs are not recorded in determined to save cost of copying determined (for backtracking). This is a messy efficiency hack that saves about 12%; it would be cleaner to to update and restore 'determined' even when processing the last method."

	| lastMethodOuts modeVector i |
	lastMethodOuts _ IdentitySet new.
	(methods last notNil) ifTrue:
		[methods last outDatasIn: (constraints last thingDatas) do:
			[: out | lastMethodOuts add: out]].

	modeVector _ String new: externalVars size.
	i _ 1.
	externalVars do:
		[: v |
		 ((determined includes: v) or:
		  [lastMethodOuts includes: v])
			ifTrue: [modeVector at: i put: $o]
			ifFalse: [modeVector at: i put: $i].
		 i _ i + 1].
	^modeVector!

nilAllowedFor: theConstraint possibleMethods: possibleMethods
	"Consider the given set of possible methods for the given constraint and answer true if the nil method is allowed. If the constraint is required or if it can be satisfied without interferring with any stronger constraint, the nil method is not allowed."

	"If the constraint is required, nil is not allowed."
	(theConstraint isRequired) ifTrue: [^false].

	"
Look for a method that could be used to satisfy the given constraint without interferring with a stronger constraint. If we find one, don't allow nil as a possible method."
	possibleMethods do:
		[: m |
		 (self couldUse: m for: theConstraint) ifTrue: [^false]].

	^true	"nil method is okay"!

outputsOf: aMethod notDeterminedFor: aConstraint
	"Answer true if none of the outputs of the given method has been determined."

	aMethod outDatasIn: aConstraint thingDatas do:
		[: outVar |
		 (determined includes: outVar) ifTrue: [^false]].
	^true	"none of the outputs has been determined"!

possibleNextMethods
	"Answer a collection of possible methods for solving the next constraint. A nil in this collection means that the constraint need not be satisfied."

	| c possibleMethods |
	c _ constraints at: (methods size + 1).
	possibleMethods _ c methods select:
		[: m | self outputsOf: m notDeterminedFor: c].

	^(self nilAllowedFor: c possibleMethods: possibleMethods)
		ifTrue: [possibleMethods copyWith: nil]
		ifFalse: [possibleMethods]!

recordSolution: aSolution
	"Record the given solution in the mode table, if there is one."

	| modeVec oldCost costOfThisSolution |
	solutions add: aSolution.
	(modeTable notNil) ifTrue:
		[modeVec _ self modeVector.
		 oldCost _ modeStrength
			at: modeVec
			ifAbsent: [Strength absoluteStrongest].
		 costOfThisSolution _
			self strengthOfStrongestUnsatisfiedConstraint: aSolution.
		 ((costOfThisSolution weaker: oldCost) and:
		   [(self hasCycle: aSolution) not]) ifTrue:
			[modeTable at: modeVec put: aSolution.
			 modeStrength at: modeVec put: costOfThisSolution]].!

solutionsUsing: aMethod
	"Solve the current constraint using the given method then find all legal solutions reachable from this state. We use a recursive, depth-first enumeration technique."
	"Details: The list of currently determined constraints must be saved and then restored when we are done to allow proper backtracking. However, this list need only be copied if we are going to change it (i.e. the current constraint is satisfied and it is not the last constraint), so the copy is done lazily."

	| currentConstraint savedDetermined |
	currentConstraint _ constraints at: (methods size + 1).

	"save state and solve the current constraint with the given method"
	savedDetermined _ determined.		"make a copy later if necessary"
	methods addLast: aMethod.
	satisfied add: currentConstraint.

	(methods size = constraints size)
		ifTrue:
			["record a finished solution"
			 self recordSolution: methods copy]
		ifFalse: 
			[(aMethod notNil) ifTrue:
				["make a copy of determined before changing it"
				 savedDetermined _ determined copy.
				 aMethod outDatasIn: currentConstraint thingDatas do:
					[: outVar | determined add: outVar]].
			 "enumerate solutions from here"
			 self possibleNextMethods do:
				[: m | self solutionsUsing: m]].

	"restore state"
	satisfied remove: currentConstraint.
	methods removeLast.
	determined _ savedDetermined.!

strengthOfStrongestUnsatisfiedConstraint: aSolution
	"Answer the strength of the strongest unsatisfied constraint in the given solution or a Strength absoluteWeakest if all the constraints are satisfied."

	constraints with: aSolution do:
		[: constraint : method |
		 (method isNil) ifTrue: [^constraint strength]].
	^Strength absoluteWeakest! !

!MultiSolver methodsFor: 'private-cycle detector'!

buildVariableDictionary
	"Construct the variables map, a dictionary that maps each variable to its own row index. Also initializes the transition matrix."

	| var |
	variables _ IdentityDictionary new: 16.
	constraints do:
		[: c |
		 (c variables) do:
			[: ref |
			 var _ ref thingData.
			 (variables includesKey: var) ifFalse:
				[variables at: var put: (variables size + 1)]]].

	transitions _ (1 to: variables size) collect:
		[: i |	 Array new: variables size withAll: false].!

hasCycle: methodList
	"Answer true if the given collection of methods contains a cycle."
	"Details: This is implemented by finding the transitive closure of the directed graph formed by the methods of methodList. If any variable is its own ancestor in the transitive closure then there is a cycle in the solution. We use a boolean matrix representation to compute the transitive closure. The element [i,j] of this matrix is true if the value of variable i depends directly or indirectly on the value of variable j in the dataflow given by the method list."

	| status |
	self initializeTransitionMatrix: methodList.
	status _ #progress.
	[status == #progress] whileTrue:
		[status _ self propagateAncestors.
		 (status == #cycleDetected) ifTrue:
			[^true]].		"cycle detected"

	^false	"no cycle detected"!

initializeTransitionMatrix: methodList
	"Initialize the transition matrix for the given list of methods. The entry at [i,j] in this matrix is true if variable j is an ancestor of variable i."

	| matrixSize i row j m thingDatas |
	"first, clear transition matrix"
	matrixSize _ transitions size.
	i _ matrixSize.
	[i > 0] whileTrue:
		[row _ transitions at: i.
		 j _ matrixSize.
		 [j > 0] whileTrue:
			[row at: j put: false.
			 j _ j - 1].
		 i _ i - 1].

	"now, register initial ancestors based on the methods"
	i _ methodList size.
	[i > 0] whileTrue:
		[m _ methodList at: i.
		 (m notNil) ifTrue:
			[thingDatas _ (constraints at: i) thingDatas.
			 m outDatasIn: thingDatas do:
				[: out |
				 row _ transitions at: (variables at: out).
				 m inDatasIn: thingDatas do:
					[: in | row at: (variables at: in) put: true]]].
		 i _ i - 1].!

propagateAncestors
	"Make one pass over the transition matrix propagating the ancestors relation. Answer one of:
		#done -- if no progress was made
		#progress -- if progress was made but no cycle was detected
		#cycleDetected -- if a cycle was detected."

	| matrixSize progress i descendent row |
	matrixSize _ transitions size.
	progress _ false.
	i _ 1.
	[i <= matrixSize] whileTrue:
		[descendent _ 1.
		 [descendent <= matrixSize] whileTrue:
			[row _ transitions at: descendent.
			 (row at: i) ifTrue:
				[(self propagateFrom: i to: descendent) ifTrue:
					[progress _ true.
				 	 (row at: descendent) ifTrue:
						[^#cycleDetected]]].
			 descendent _ descendent + 1].
		 i _ i + 1].

	progress
		ifTrue: [^#progress]
		ifFalse: [^#done].!

propagateFrom: sourceVar to: descendentVar
	"OR the ancestors of sourceVar (its row) into descendentVar's row. Answer true if descendentVar's row changed."

	| source dest changed i sourceSize |
	source _ transitions at: sourceVar.
	dest _ transitions at: descendentVar.
	changed _ false.
	i _ 1.
	sourceSize _ source size.
	[i <= sourceSize] whileTrue:
		[((dest at: i) not and: [source at: i]) ifTrue:
			[dest at: i put: true.
			 changed _ true].
		 i _ i + 1].
	^changed! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MultiSolver class
	instanceVariableNames: ''!


!MultiSolver class methodsFor: 'instance creation'!

on: constraintList
	"Answer a new instance for the given set of constraints. Do not compute the solutions until asked to do so."

	^(self new)
		constraints: constraintList! !

!MultiSolver class methodsFor: 'queries'!

allSolutionsFor: constraintList
	"Answer all solutions to the given set of constraints, including those that are cyclic."

	^(self on: constraintList)
		computeSolutions;
		allSolutions!

solutionsFor: constraintList
	"Answer a collection of non-cyclic solutions to the given list of constraints."

	^(self on: constraintList)
		computeSolutions;
		nonCyclicSolutions!

solutionsFor: constraintList externalVars: extVarList
	"Answer a collection of cycle-free solutions to the given set of constraints but only include one solutions for each input/output 'mode' of the set of externally visible variables. For example, if a, b, and c are the external variables then the modes are (in, in, in), (in, in, out), (in, out, in), and five more."

	^((self new)
		constraints: constraintList externalVars: extVarList;
		computeSolutions)
			uniqueModeSolutions! !

SceneView subclass: #ThingDebugView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Debugger'!


!ThingDebugView methodsFor: 'controller access'!

defaultControllerClass

	^ThingDebugController! !

!ThingDebugView methodsFor: 'displaying'!

computeBackground
	"Compute the backgroundForm and the two lists, visibleForeground and selectedForeground. These are used by the 'displayFeedback' and 'displayFeedbackWithBox:width:' operations."

	super computeBackground.
	self
		displaySolutionInfoOn: backgroundForm
		at: (self viewOrigin)
		clippingBox: (backgroundForm computeBoundingBox).!

displaySolutionInfoOn: aDisplayMedium at: aPoint clippingBox: clipBox
	"Display information about the number of solutions and partitions and whether there is a cycle in the currently selected solution."

	| infoBox printer |
	infoBox _ ((10@10 extent: 200@80) translateBy: aPoint)
				intersect: clipBox.
	aDisplayMedium border: infoBox width: 1.
	printer _
		QuickPrint newOn: aDisplayMedium
		box: (infoBox topLeft + (40@4) corner: infoBox bottomRight).
	printer drawString:
		'Partition ', model partitionIndex printString,
		' of ', model partitionCount printString.
	printer downBy: 20.
	(model solutionIndex = 0)
		ifTrue:
			[printer drawString: 'Current solution']
		ifFalse:
			[printer drawString:
				'Alternative ', model solutionIndex printString,
				' of ', model solutionCount printString].
	printer downBy: 20.
 	(model solutionHasCycle) ifTrue:
		[printer drawString: 'Cycle Detected!!'].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ThingDebugView class
	instanceVariableNames: ''!


!ThingDebugView class methodsFor: 'instance creation'!

openOn: aThing
	"Open a new ThingDebugView on the given Thing."

	self
		openWithSubview:
			((ThingDebugView new) model: (ThingDebug on: aThing))
		label: 'Debugger on ', aThing name.! !

Constraint subclass: #EqualityConstraint
	instanceVariableNames: ''
	classVariableNames: 'SharedMethods '
	poolDictionaries: ''
	category: 'ThingLabII-Constraints-Special'!
EqualityConstraint comment:
'I am used to constrain two variable to contain the same value.'!


!EqualityConstraint methodsFor: 'initialize-release'!

ref: ref1 ref: ref2 strength: aSymbol
	"Initialize myself with the given strength between the two referenced parts."

	strength _ Strength of: aSymbol.
	symbols _ #(a b).
	self variables: (Array with: ref1 with: ref2).
	"initialize methods list shared by all instances"
	(SharedMethods isNil) ifTrue:
		[SharedMethods _ Array
			with: ((Method new)
				codeString: 'a _ b';
				block: [: vars | (vars at: 1) value: (vars at: 2) value.];
				bindings: 'oi')
			with: ((Method new)
				codeString: 'b _ a';
				block: [: vars | (vars at: 2) value: (vars at: 1) value.];
				bindings: 'io')].
	self methods: SharedMethods.
	whichMethod _ nil.
	self initializeFlags.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EqualityConstraint class
	instanceVariableNames: ''!


!EqualityConstraint class methodsFor: 'instance creation'!

ref: ref1 ref: ref2 strength: strength
	"Create a new equality constraint with the given strength equating the values referenced by ref1 and ref2. For example:

	EqualityConstraint
		ref: aThing->line.p1.y
		ref: aThing->line.p2.y
		strength: #required."

	^(super new) ref: ref1 ref: ref2 strength: strength!

require: ref1 equals: ref2
	"Install a required EqualityConstraint between the given references."

	(self ref: ref1 ref: ref2 strength: #required) addConstraint.! !

Thing subclass: #PrimitiveThing
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Things'!
PrimitiveThing comment:
'I am an abstract class for primitive Things. Primitive Things cannot be structurally changed.'!


!PrimitiveThing methodsFor: 'initialize-release'!

initializeConstraints
	"Override this method to add constraints when initializing the prototype of a PrimitiveThing. This method is called after the structure of the Thing is initialized. By default, no constraints are added."!

initializeStructure
	"Override this method to initialize the part-whole structure when initializing the prototype of a PrimitiveThing. By default, no Thing subparts are created."!

initializeValues
	"Override this method to initialize part values when initializing the prototype of a PrimitiveThing. This method is called after the structure of the Thing is initialized and constraints have been added. By default, no initial values are provided."! !

!PrimitiveThing methodsFor: 'public-testing'!

isStructureModifiable
	"Primitive Things cannot be modified."

	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimitiveThing class
	instanceVariableNames: ''!


!PrimitiveThing class methodsFor: 'class initialization'!

initialize
	"Initialize this PrimitiveThing."

	self initializePrimitive.! !

!PrimitiveThing class methodsFor: 'private-initialize-destroy'!

vaporize
	"Make this a noop, to avoid accidentally deleting primitive Things."! !


AbstractMethod subclass: #ModuleMethod
	instanceVariableNames: 'module isPossibleSel executeSel propagateSel '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Constraints'!
ModuleMethod comment:
'I represent methods for compiled ModuleThings. I have a pointer to the ModuleThing instance and a bunch of selectors to perform various operations on that ModuleThing in order to plan for and perform constraint satisfaction.

Instance variables (in addition to those inherited):

	owner...			my ModuleThing
	executeSel...		selector to compute the values of my outputs
 	checkSel...		selector to compute if I am an appropriate method
	walkSel...		selector to compute the walkabout strengths of my outputs
	ancestorSel...		selector to compute the ancestors of my outputs
'!


!ModuleMethod methodsFor: 'initialize-release'!

destroy
	"Break potential cycles."

	module _ nil.
	super destroy.!

module: owningModule codeString: aString bindings: bindingArray isPossible: isPossibleSelector execute: executeSelector propagate: propagateSelector
	"Initialize myself."

	module _ owningModule.
	codeString _ aString.
	bindings _ bindingArray.
	isPossibleSel _ isPossibleSelector asSymbol.
	executeSel _ executeSelector asSymbol.
	propagateSel _ propagateSelector asSymbol.! !

!ModuleMethod methodsFor: 'DeltaBlue'!

execute: refList
	"Execute myself to enforce my constraint. Do this by executing the method compiled for that purpose. refList is ignored."

	module perform: executeSel.!

isPossibleMethodGiven: constraintStrength
	"Answer true if I am a possible method given the current walkabout strengths of my variables. Compute the answer by executing the method compiled for that purpose."

	^module perform: isPossibleSel!

updateOutputsIn: thingDatas for: myConstraint stay: stayFlag
	"Update the walkabout strengths and stay flags for all my outputs and answer the output ThingDatas. Do this by executing the method compiled for that purpose."

	module perform: propagateSel.
	^myConstraint outDatas! !

!ModuleMethod methodsFor: 'cloning'!

cloneWith: cloneDictionary for: ignored
	"Make a clone of myself using the mapping given by cloneDictionary."

	| myClone |
	myClone _ self shallowCopy.
	myClone module: (cloneDictionary at: module).
	^myClone!

module: aModuleThing
	"Used in cloning."

	module _ aModuleThing.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModuleMethod class
	instanceVariableNames: ''!


!ModuleMethod class methodsFor: 'instance creation'!

module: owningModule codeString: aString bindings: bindingArray isPossible: isPossibleSelector execute: executeSelector propagate: propagateSelector
	"Answer a new, initialized instance."

	^self new
		module: owningModule
		codeString: aString
		bindings: bindingArray
		isPossible: isPossibleSelector
		execute: executeSelector
		propagate: propagateSelector! !

BasicThingView subclass: #ThingModuleView
	instanceVariableNames: 'constructorView '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!


!ThingModuleView methodsFor: 'initialize-release'!

initialize

	super initialize.
	constructorView _ nil.! !

!ThingModuleView methodsFor: 'controller access'!

defaultControllerClass

	^ThingModuleController! !

!ThingModuleView methodsFor: 'access'!

constructorView

	^constructorView!

constructorView: aView

	constructorView _ aView.!

model: aThingAdaptor

	super model: aThingAdaptor.
	model clearSelection.
	model thing class externalParts do:
		[: part | model select: (model thing perform: part)].! !

!ThingModuleView methodsFor: 'displaying'!

computeBackground
	"Compute the backgroundForm and the two lists, visibleForeground and selectedForeground. These are used by the 'displayFeedback' and 'displayFeedbackWithBox:width:' operations."

	| viewExtent viewOrigin clipBox |
	viewExtent _ enclosingRect extent max: self insetDisplayBox extent.
	backgroundForm _ Form extent: viewExtent depth: 32. backgroundForm fillWhite.
	scratchForm _ Form extent: viewExtent depth: 32. scratchForm fillWhite.
	viewOrigin _ self viewOrigin.
	clipBox _ backgroundForm computeBoundingBox.

	"draw and gray-out the internal glyphs"
	self internalGlyphsDo:
		[: glyph |
		 glyph
			displayOn: backgroundForm
			at: viewOrigin clippingBox: clipBox].
	backgroundForm fill: clipBox rule: Form erase fillColor: Color gray.

	"draw the border and external glyphs"
	self displayBorderOn: backgroundForm at: viewOrigin clippingBox: clipBox.
	self externalGlyphsDo:
		[: glyph |
		 glyph
			displayOn: backgroundForm
			at: viewOrigin clippingBox: clipBox].

	"nothing is changing"
	visibleForeground _ OrderedCollection new.
	selectedForeground _ OrderedCollection new.!

externalGlyphsDo: aBlock

	(model visibleGlyphs) do:
		[: g |
		 (model selected includes: g) ifTrue:
			[aBlock value: g]].!

internalGlyphsDo: aBlock

	(model visibleGlyphs) do:
		[: g |
		 ((model selected includes: g) not) ifTrue:
			[aBlock value: g]].! !

GestureController subclass: #SceneController
	instanceVariableNames: 'myMenu lastMenuItem doneFlag '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Framework'!
SceneController comment:
'This is the controller class for SceneViews. It supports gestures for scrolling, click-selection, and area selection of scene glyphs.'!


!SceneController methodsFor: 'initialize-release'!

initialize

	super initialize.
	myMenu _ ThingLabCustomMenu new.
	lastMenuItem _ nil.
	doneFlag _ false.! !

!SceneController methodsFor: 'control defaults'!

controlActivity
	"Process user mouse and keyboard activity."

	(sensor keyboardPressed) ifTrue: [^self readKeyboard].
	(sensor yellowButtonPressed) ifTrue: [^self menuActivity].
	(sensor redButtonPressed) ifTrue: [^super possibleClickAt: sensor cursorPoint].!

isControlActive

	^self viewHasCursor
		& sensor blueButtonPressed not
		& self done not!

isControlWanted

	^self viewHasCursor & sensor blueButtonPressed not! !

!SceneController methodsFor: 'access'!

done
	"Should I give up control?"

	^doneFlag!

done: aBoolean
	"A flag is maintained to allow me to gracefully give up control (see isControlActive and isControlWanted) when switching between View/Controller pairs within the same top view."

	doneFlag _ aBoolean.! !

!SceneController methodsFor: 'gestures'!

clickAt: aPoint
	"If the mouse is clicked over a glyph that wants mouse input and we are in 'operate' mode, pass the mouse to it. Otherwise, select the glyph under aPoint. If the shift key is depressed, the glyph's inclusion in the selection is toggled: that is, it is added to the selection if it is not currently selected and removed from the selection if it is currently selected."

	"first, try to process mouse input for the glyph at aPoint"
	(self processMouseAt: aPoint) ifTrue: [^self].

	"if that fails, do select operation"
	self selectAt: aPoint toggleFlag: (sensor leftShiftDown).
	view displayScene.!

doubleClickAt: aPoint
	"Handle a double-click action by selecting everything."

	self selectAll.
	sensor waitNoButton.!

dragAt: aPoint
	"Handle a drag action. If aPoint is over a glyph that is interested in mouse actions, let that glyph handle the mouse. Otherwise, move or scroll depending on whether or not the given point is over a selectable glyph or not."

	| glyph |
	"first, try to process mouse input for the glyph at aPoint"
	(self processMouseAt: aPoint) ifTrue: [^self].

	"if that fails, handle the normal move-or-scroll situation"
	glyph _ self glyphAt: aPoint.
	(glyph notNil)
		ifTrue:
			["if the glyph is not in the selection, select it"
			 (model selected includes: glyph) ifFalse:
				[self selectAt: aPoint toggleFlag: (sensor leftShiftDown)].
			 view displayScene.
			 self moveAt: aPoint]
		ifFalse: [self scrollAt: aPoint].!

processMouseAt: aPoint
	"If the given point is over a glyph that is interested in mouse actions, let that glyph handle the mouse and answer true. Otherwise, answer false."

	| mouseGlyph |
	mouseGlyph _ self mouseGlyphAt: aPoint.
	(mouseGlyph notNil)
		ifTrue: [self passMouseTo: mouseGlyph. ^true]
		ifFalse: [^false].!

sweepAt: aPoint
	"First, try to pass the mouse to any glyphs under aPoint that want it. If there aren't any mouse input glyphs by there is a selectable glyph under aPoint, then select it and drag the selected glyphs. Otherwise, handle the sweep gesture by doing an area-select. If the shift key is down, then toggle select all enclosed glyphs. Otherwise, clear the selection first."

	"first, try to process mouse input for the glyph at aPoint"
	(self processMouseAt: aPoint) ifTrue: [^self].

	"if that fails, handle the normal move-or-area-select situation"
	((self glyphAt: aPoint) notNil)	"check for a drag situation"
		ifTrue: [self dragAt: aPoint]
		ifFalse:
			[self
				selectAreaAt: aPoint
				toggleFlag: (sensor leftShiftDown)].! !

!SceneController methodsFor: 'menu handling'!

argument
	"Answer the argument for unary operation from the model's selection. There must be exactly one object selected. If so, answer it. Otherwise, answer nil."

	(model selected size == 1)
		ifTrue: [^model selected asOrderedCollection first]
		ifFalse: [^nil].!

menuActivity
	"Present the yellow button menu and determine which menu item, if any, the user selected. If an item was selected, then send that message to the object designated as the menu message receiver. Remember the menu item across menu invocations."

	| menu item |
	menu _ self yellowButtonMenu: (sensor leftShiftDown).
	(menu isNil) ifTrue: [^self].

	item _ menu invoke: lastMenuItem.
	lastMenuItem _ item.
	(item notNil) ifTrue: [self perform: item].!

yellowButtonMenu: debugging
	"Answer my yellow-button menu, constructed by sending myself the message 'addMenuItems: debugging.' Items are appended to the ThingLabCustomMenu myMenu; this allows subclasses to augment the menu provided  by their superclass without the maintainance headache of copying the menu creation code into the subclass."

	myMenu _ ThingLabCustomMenu new.
	self addMenuItems: debugging.
	^myMenu! !

!SceneController methodsFor: 'menu operations'!

addMenuItems: debugging
	"Answer my yellow-button menu given the current selection and possibly some other view or controller state. The goal is to present in the menu only those possibilities which are legal commands at this juncture. If debugging is true, present a additional options which might be useful to implementors and other gurus."

	myMenu add: ' scroll ' action: #scroll.
	myMenu add: ' area ' action: #selectArea.
	myMenu addLine.
	myMenu add: ' all ' action: #selectAll.
	(model selected size > 0) ifTrue:
		[myMenu add: ' none ' action: #clearSelection].
	myMenu addLine.!

clearSelection
	"Unselect everything."

	model clearSelection.
	view displayScene.!

scroll
	"Wait for the mouse button to be pressed, then scroll."

	Cursor webLink showWhile: [sensor waitButton].
	self scrollAt: sensor cursorPoint.!

selectAll
	"Select all selectable glyphs."

	model clearSelection.
	model selectableGlyphs do: [: g | model select: g].
	view displayScene.!

selectArea
	"Select everything in a rectangular area specified using the mouse. If the shift key is down, toggle select everything in the area."

	Cursor origin showWhile: [sensor waitButton].
	self selectAreaAt: (sensor cursorPoint) toggleFlag: (sensor leftShiftDown).! !

!SceneController methodsFor: 'direct manipulation'!

adjustedPoint: aPoint
	"Answer a point (in view coordinates) that is as close to aPoint (in screen coordinates) as possible."

	| borderBox adjustedPoint |
	borderBox _ view insetDisplayBox insetBy: 5.
	adjustedPoint _ aPoint copy.
	(aPoint x < borderBox left) ifTrue: [adjustedPoint x: borderBox left].
	(aPoint x > borderBox right) ifTrue: [adjustedPoint x: borderBox right].
	(aPoint y < borderBox top) ifTrue: [adjustedPoint y: borderBox top].
	(aPoint y > borderBox bottom) ifTrue: [adjustedPoint y: borderBox bottom].	
	^view displayToModelPoint: adjustedPoint!

adjustOffsetForSelArea: aPoint
	"If aPoint (in screen coordinates) is outside my inset display box, try to scroll the view in that direction."

	| box pX pY left right top bottom new |
	box _ view insetDisplayBox.
	(box containsPoint: aPoint) ifTrue: [^self].
	pX _ aPoint x.
	pY _ aPoint y.
	left _ box left.
	right _ box right.
	top _ box top.
	bottom _ box bottom.
	new _ view scrollOffset.
	(pX < left) ifTrue: [new x: (new x + left - pX)].
	(pX > right) ifTrue: [new x: (new x + right - pX)].
	(pY < top) ifTrue: [new y: (new y + top - pY)].
	(pY > bottom) ifTrue: [new y: (new y + bottom - pY)].
	view scrollOffset: new.!

glyphAt: aPoint
	"Answer the selectable glyph at aPoint or nil if there isn't one."

	| adjustedPoint pointX pointY box |
	adjustedPoint _ view displayToModelPoint: aPoint.
	pointX _ adjustedPoint x.
	pointY _ adjustedPoint y.
	model selectableGlyphs do:
		[: glyph |
		 box _ glyph boundingBox.
		 (box top <= pointY) ifTrue:
			[(box bottom >= pointY) ifTrue:
				[(box left <= pointX) ifTrue:
					[(box right >= pointX) ifTrue:
						[(glyph containsPoint: adjustedPoint) ifTrue:
							[^glyph]]]]]].
	^nil		"no glyph found"!

moveAt: aPoint
	"Drag all selected glyphs."

	| movingParts relativePositions point oldPoint |
	movingParts _ model selected asOrderedCollection.
	model moveToFront: movingParts.
	relativePositions _ movingParts collect: [: p | p location - aPoint].
	view computeBackground.
	[sensor redButtonPressed] whileTrue:
		[point _ sensor cursorPoint.
		 (oldPoint ~= sensor cursorPoint) ifTrue:
			[movingParts
				with: relativePositions
				do: [: p : relPos | p location: (relPos + point)].
			 view displayFeedback]].
	view computeEnclosingRectangle.
	view displayView.!

scrollAt: aPoint
	"As the user moves the cursor, change the offset of my model to scroll the view."

	| limits relOffset hotRect ratio lastPoint newPoint |
	limits _ view scrollOffsetLimits.
	Cursor webLink showWhile:
		[view computeBackground.
		 relOffset _
			(view scrollOffset * -40) / (limits extent max: (1@1)).
		 hotRect _ (aPoint + relOffset - (40@40)) extent: 40@40.
		 ratio _ limits extent / hotRect extent.
		 lastPoint _ -1@-1.
		 [sensor redButtonPressed] whileTrue:
		 	[newPoint _ sensor cursorPoint.
			 (newPoint ~= lastPoint) ifTrue:
				[view scrollOffset:
					(ratio * (newPoint - hotRect corner)) rounded.
			 	 view displayFeedback.
				 lastPoint _ newPoint]]].!

selectAreaAt: aPoint toggleFlag: toggleFlag
	"As the user moves the cursor, draw a selection rectangle, scrolling if the mouse leaves my view. When the red button is released, select all selectable glyphs inside the selection rectangle."

	| origin corner selectionRect viewBox done newPoint lastPoint |
	toggleFlag ifFalse: [model clearSelection].
	origin _ self adjustedPoint: aPoint.
	selectionRect _ origin extent: 0@0.
	view computeBackground.
	viewBox _ view insetDisplayBox.
	lastPoint _ -1@-1.
	done _ false. 	"do the loop at least once"
	[done] whileFalse:
	 	[newPoint _ sensor cursorPoint.
		 ((newPoint ~= lastPoint) or: [(viewBox containsPoint: newPoint) not]) ifTrue:
			[self adjustOffsetForSelArea: newPoint.
			 corner _ self adjustedPoint: newPoint.
			 selectionRect _ Rectangle
				origin: (origin min: corner)
				extent: ((origin - corner) abs).
			 view displayFeedbackWithBox: selectionRect width: 1.
			 lastPoint _ newPoint].
		 done _ sensor anyButtonPressed not].

	model selectableGlyphs do:
		[: p |
		 (p intersects: selectionRect)
			ifTrue:
				[toggleFlag
					ifTrue: [model toggleSelect: p]
					ifFalse: [model select: p]]].
	view displayScene.!

selectAt: aPoint toggleFlag: toggleFlag
	"Select the glyph at aPoint. If toggleFlag is true, add/remove the glyph to/from the selection. Otherwise add the glyph. If aPoint is not over any glyph then clear the selection."

	| glyph |
	glyph _ self glyphAt: aPoint.
	(glyph notNil)
		ifTrue:
			[((model selected includes: glyph) not & toggleFlag not)
				ifTrue: [model clearSelection].
			 toggleFlag
				ifTrue: [model toggleSelect: glyph]
				ifFalse: [model select: glyph]]
		ifFalse: [model clearSelection].! !

!SceneController methodsFor: 'keyboard'!

readKeyboard
	"Keystrokes are sent to all selected Things that are interested in keyboard input."

	| interested char |
	interested _ model selected select:
		[: thing |
		 (thing wantsKeystrokes) and: [model inputGlyphs includes: thing]].

	[sensor keyboardPressed] whileTrue:
		[self resetTimer.
		 char _ sensor keyboard.
		 interested do:
			[: thing | thing handleKeystroke: char view: view].
		 [(self timeOut: 100) | sensor keyboardPressed] whileFalse:
			["wait a bit in case there is another character"]].
	view displayScene.! !

!SceneController methodsFor: 'mouse'!

adjustedCursorPoint
	"Answer the cursor point in adjusted view coordinates."

	^view displayToModelPoint: sensor cursorPoint!

mouseGlyphAt: aPoint
	"Answer the mouse glyph at aPoint or nil if there isn't one."

	| adjustedPoint |
	adjustedPoint _ view displayToModelPoint: aPoint.
	model inputGlyphs reverseDo:
		[: g |
		 ((g wantsMouse) and:
		   [g containsPoint: adjustedPoint]) ifTrue:
			[^g]].

	^nil	"no mouse input glyph found"!

passMouseTo: aGlyph
	"Allow the given glyph to handle a mouse interaction. It is assumed that the glyph wants the mouse."

	aGlyph handleMouseDown: self adjustedCursorPoint view: view.
	aGlyph handleMouseMove: self adjustedCursorPoint view: view.		"do at least once"
	[sensor anyButtonPressed] whileTrue:
		[aGlyph handleMouseMove: self adjustedCursorPoint view: view].
	aGlyph handleMouseUp: self adjustedCursorPoint view: view.
	view displayScene.! !

Constraint subclass: #YMouseConstraint
	instanceVariableNames: 'yOffset '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Constraints-Special'!
YMouseConstraint comment:
'I am used to relate a variable to the current y-coordinate of the mouse. I contain an offset to normalize the coordinate system to one convenient for the target variable. I have only one method with no inputs and one output.'!


!YMouseConstraint methodsFor: 'initialize-release'!

ref: ref strength: aSymbol offset: aNumber
	"Initialize myself with the given reference, strength, and y-offset."

	strength _ Strength of: aSymbol.
	symbols _ #(y).
	self variables: (Array with: ref).
	self methods: (Array with:
		((Method new)
			codeString: '"mouseY"';
			block:
				[: vars |
				 (vars at: 1) value: (Sensor cursorPoint y + yOffset).];
			bindings: 'o')).
	whichMethod _ nil.
	self initializeFlags.
	yOffset _ aNumber.! !

!YMouseConstraint methodsFor: 'queries'!

isInput
	"I depend on the state of the mouse."

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

YMouseConstraint class
	instanceVariableNames: ''!


!YMouseConstraint class methodsFor: 'instance creation'!

ref: ref strength: strength offset: yOffset
	"Create a YMouse constraint on the referenced variable. For example:

	YMouseConstraint
		ref: myPoint->#y
		strength: #preferred
		offset: (Sensor cursorPoint y)."

	^(super new) ref: ref strength: strength offset: yOffset! !

Constraint subclass: #XMouseConstraint
	instanceVariableNames: 'xOffset '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Constraints-Special'!
XMouseConstraint comment:
'I am used to relate a variable to the current x-coordinate of the mouse. I contain an offset to normalize the coordinate system to one convenient for the target variable. I have only one method with no inputs and one output.'!


!XMouseConstraint methodsFor: 'initialize-release'!

ref: ref strength: aSymbol offset: aNumber
	"Initialize myself with the given reference, strength, and x-offset."

	strength _ Strength of: aSymbol.
	symbols _ #(x).
	self variables: (Array with: ref).
	self methods: (Array with:
		((Method new)
			codeString: '"mouseX"';
			block:
				[: vars |
				 (vars at: 1) value: (Sensor cursorPoint x + xOffset).];
			bindings: 'o')).
	whichMethod _ nil.
	self initializeFlags.
	xOffset _ aNumber.! !

!XMouseConstraint methodsFor: 'queries'!

isInput
	"I depend on the state of the mouse."

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XMouseConstraint class
	instanceVariableNames: ''!


!XMouseConstraint class methodsFor: 'instance creation'!

ref: ref strength: strength offset: aNumber
	"Create an XMouse constraint on the referenced variable. For example:

	XMouseConstraint
		ref: myPoint->#x
		strength: #preferred
		offset: (Sensor cursorPoint x)."

	^(super new) ref: ref strength: strength offset: aNumber! !

Controller subclass: #ThingLabIIControlPanel
	instanceVariableNames: 'bigLabelSwitch gridXview gridYview editPreferredSwitch '
	classVariableNames: 'BigLabelFlag Where '
	poolDictionaries: ''
	category: 'ThingLabII-UI-Support'!


!ThingLabIIControlPanel methodsFor: 'initialize-release'!

addEditLevelSwitches: topView
	"Add switches to control the strength of user edits."

	| toggle labelView preferredSWView editRequiredSwitch requiredSWView |
	toggle _ Model new.
	labelView _ (FormView new)
				model: 'Edit Strength:' asParagraph asForm;
				borderWidth: 0;
				controller: NoController new.
	editPreferredSwitch _ (ThingLabII editStrength == #preferred)
			ifTrue: [OneOnSwitch newOn]
			ifFalse: [OneOnSwitch newOff].
	editRequiredSwitch _ (ThingLabII editStrength == #preferred)
			ifTrue: [OneOnSwitch newOff]
			ifFalse: [OneOnSwitch newOn].
	editPreferredSwitch connection: toggle.
	editRequiredSwitch connection: toggle.
	preferredSWView _ (SwitchView new)
			model: editPreferredSwitch;
			label: 'preferred' asParagraph centered;
			borderWidth: 1.
	requiredSWView _ (SwitchView new)
			model: editRequiredSwitch;
			label: 'required' asParagraph centered;
			borderWidth: 1.
	topView
		addSubView: labelView align: 0@0 with: 15@58;
		addSubView: preferredSWView align: 0@0 with: 107@60;
		addSubView: requiredSWView align: 0@0 with: 168@60.!

addGridSettings: topView
	"Add controls to set the PartBin grid."

	| gridXLabel gridYLabel |
	gridXLabel _ (FormView new)
		model: 'Parts Bin GridX:' asParagraph asForm;
		borderWidth: 0;
		controller: NoController new.
	gridXview _ (StringHolderView new)
		model: ((StringHolder new) contents: (PartsBin gridX printString));
		window: (0@0 extent: 32@19);
		borderWidth: 1.
	gridYLabel _ (FormView new)
		model: 'GridY:' asParagraph asForm;
		borderWidth: 0;
		controller: NoController new.
	gridYview _ (StringHolderView new)
		model: ((StringHolder new) contents: (PartsBin gridY printString));
		window: (0@0 extent: 32@19);
		borderWidth: 1.
	topView
		addSubView: gridXLabel align: 0@0 with: 15@95;
		addSubView: gridXview align: 0@0 with: 105@95;
		addSubView: gridYLabel align: 0@0 with: 145@95;
		addSubView: gridYview align: 0@0 with: 185@95.!

addLabelSizeSwitches: topView
	"Add switches to control the size of the labels for Thinglab windows."

	| toggle labelView bigSWView smallSwitch smallSWView |
	toggle _ Model new.
	labelView _ (FormView new)
				model: 'Label Size:' asParagraph asForm;
				borderWidth: 0;
				controller: NoController new.
	bigLabelSwitch _ (BigLabelFlag)
			ifTrue: [OneOnSwitch newOn]
			ifFalse: [OneOnSwitch newOff].
	bigLabelSwitch connection: toggle.
	bigSWView _ (SwitchView new)
			model: bigLabelSwitch;
			label: 'big' asParagraph centered;
			borderWidth: 1.
	smallSwitch _ (BigLabelFlag)
			ifTrue: [OneOnSwitch newOff]
			ifFalse: [OneOnSwitch newOn].
	smallSwitch connection: toggle.
	smallSWView _ (SwitchView new)
			model: smallSwitch;
			label: 'small' asParagraph centered;
			borderWidth: 1.
	topView
		addSubView: labelView align: 0@0 with: 15@23;
		addSubView: bigSWView align: 0@0 with: 107@25;
		addSubView: smallSWView align: 0@0 with: 133@25.!

addMenu: topView
	"Adds an invisible sub-view whose controller is myself. This allows me to support the 'the application menu is available from the center of the top view's label' scheme, which tries to send the #menuActivity message to the first subview. This method should be executed first to ensure that this is the first sub-view."

	| firstSubview |
	firstSubview _ (FormView new)
		model: (Form extent: 0@0);
		borderWidth: 0;
		controller: self.
	topView
		addSubView: firstSubview align: 0@0 with: 0@0.!

buildInside: aTopView
	"Set up my controls within the given view."

	self addMenu: aTopView.	"this should be done first"
	self addGridSettings: aTopView.
	self addEditLevelSwitches: aTopView.
	self addLabelSizeSwitches: aTopView.!

release

	super release.
	gridXview release.
	gridYview release.
	bigLabelSwitch release.
	editPreferredSwitch release.
	gridXview _ nil.
	gridYview _ nil.
	bigLabelSwitch _ nil.
	editPreferredSwitch _ nil.! !

!ThingLabIIControlPanel methodsFor: 'menu messages'!

applySettings
	"Apply the currently displayed settings."

	BigLabelFlag _ bigLabelSwitch isOn.
	(editPreferredSwitch isOn)
		ifTrue: [ThingLabII editStrength: #preferred]
		ifFalse: [ThingLabII editStrength: #required].
	gridXview controller accept.
	gridYview controller accept.
	PartsBin gridX: (gridXview getContents asString asNumber).
	PartsBin gridY: (gridYview getContents asString asNumber).!

cancelSettings
	"Undo changes to the currently displayed settings. This is done by removing all subview and rebuilding them, resetting the settings of the controls in the process."

	| topView |
	topView _ view topView.
	topView deEmphasize.
	topView removeSubViews.
	self buildInside: topView.
	topView displaySubViews.
	topView emphasize.!

menuActivity
	"Handle my menu."

	| action |
	action _ (PopUpMenu labels: 'done\apply\cancel' withCRs) startUp.
	(action == 1) ifTrue: [self applySettings. view topView controller close].
	(action == 2) ifTrue: [self applySettings].
	(action == 3) ifTrue: [self cancelSettings].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ThingLabIIControlPanel class
	instanceVariableNames: ''!


!ThingLabIIControlPanel class methodsFor: 'class initialization'!

initialize
	"Reset the initial location of the control panel."
	"ThingLabIIControlPanel initialize"

	Where _ 140@100.
	BigLabelFlag _ true.! !

!ThingLabIIControlPanel class methodsFor: 'instance creation'!

open
	"ThingLabIIControlPanel open"

	| panelRect controller topView |
	panelRect _ 0@0 extent: 235@135.
	controller _ (SpecialSystemController new) fromHolder: self.
	topView _ SpecialSystemView new.
	topView label: 'ThingLabII Control Panel';
		minimumSize: panelRect extent;
		maximumSize: panelRect extent;
		window: panelRect viewport: panelRect;
		controller: controller.
	self new buildInside: topView.
	controller openDisplayAt: Where.! !

!ThingLabIIControlPanel class methodsFor: 'accessing'!

bigLabelFlag

	^BigLabelFlag!

lastFrame: aRectangle
	"Record the last position of the control panel so we can open it there next time."

	Where _ aRectangle center.! !


SceneController subclass: #ThingModuleController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!


!ThingModuleController methodsFor: 'menu operations'!

addMenuItems: debugging

	super addMenuItems: debugging.
	myMenu add: ' compile ' action: #compile.
	myMenu add: ' cancel ' action: #cancel.!

cancel
	"Go back to the ConstructionView from whence I came..."

	| externalParts topView |
	"remember the external parts"
	externalParts _ 
		(model selected) collect:
			[: part | (part allTopParentPaths first) first].
	(model thing class) externalParts: externalParts asOrderedCollection.

	(view constructorView isNil)
		ifTrue: [view flash]
		ifFalse:
			[topView _ view topView.
			 "remove my view"
			 topView removeSubViews.
			 "allow old controller to resume"
			 view constructorView controller done: false.
			 "reinstate old view and display it"
			 topView addSubView: view constructorView.
			 view constructorView scrollOffset: view scrollOffset.
			 topView displaySubViews.
			 self done: true.	"relinquish control"].!

compile
	"Compile my model into a module, making the currently selected parts external. The module is given a new name such as 'Module43'."

	| thingClass externalParts module constructorView topView |
	thingClass _ model thing class.
	externalParts _ 
		(model selected) collect:
			[: part | (part allTopParentPaths first) first].
	thingClass externalParts: externalParts asOrderedCollection.
	module _ ModuleCompiler compileThing: (model thing).

	"Return to the constructor view, but on the module"
	constructorView _ view constructorView.
	constructorView controller done: false.
	topView _ view topView.
	topView removeSubViews.
	topView addSubView: constructorView.
	constructorView controller viewThing: module.
	self done: true.	"relinquish control"! !

CodeController subclass: #ExplanationController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Support'!
ExplanationController comment:
'I am a controller for CodeViews on Explanations. I have a special implementation of accept that closes my top view.'!


!ExplanationController methodsFor: 'menu messages'!

accept
	"Accept the changes, if there are any, and close this explanation view."

	(self textHasChanged)
		ifTrue: [view accept: self text from: self].
	view topView controller close.!

menuActivity

	self yellowButtonActivity.! !

Model subclass: #Scene
	instanceVariableNames: 'glyphs selected '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Framework'!
Scene comment:
'A Scene is a two-dimensional diagram or picture composed of displayable objects called glyphs. Each glyph must respond to the basic protocol for Glyphs (see class Glyph). A scene also maintains a list of selected glyphs and can enumerate various kinds of the glyphs: visible, selectable, and input-accepting.

Scenes maintain a list of selected glyphs.
'!


!Scene methodsFor: 'initialize-release'!

initialize

	glyphs _ OrderedCollection new.
	selected _ Set new.! !

!Scene methodsFor: 'glyphs access'!

allGlyphs
	"Answer the set of all glyphs. By default, this is just the visible glyphs."

	^self visibleGlyphs!

inputGlyphs
	"Answer the set of glyphs that accept input."

	^glyphs select: [: g | g wantsMouse | g wantsKeystrokes]!

selectableGlyphs
	"Answer the set of glyphs that are selectable. By default, this is just the visible glyphs."

	^self visibleGlyphs!

visibleGlyphs
	"Answer the set of glyphs that are visible."

	^glyphs! !

!Scene methodsFor: 'glyphs'!

addGlyph: aGlyph

	glyphs addLast: aGlyph!

isChanging: aGlyph
	"Answer true if the give glyph is undergoing changes that could effect how it is displayed. For example, this would be 'true' for glyphs being dragged with the mouse. By default, all glyphs are unchanging."

	^selected includes: aGlyph!

moveToFront: glyphsList
	"Move the glyphs in the collection glyphsList to the back of my glyph collection so that they will be displayed last and hence appear in front of any overlapping glyphs."

	| temp |
	glyphsList do: [: g |
		temp _ glyphs remove: g ifAbsent: [nil].
		(temp notNil) ifTrue: [glyphs addLast: temp]].!

removeGlyph: aGlyph

	glyphs remove: aGlyph ifAbsent: [].
	selected remove: aGlyph ifAbsent: [].! !

!Scene methodsFor: 'selections'!

clearSelection

	selected _ selected species new.!

deselect: aGlyph

	selected remove: aGlyph ifAbsent: [].!

select: aGlyph

	selected add: aGlyph.!

selected

	^selected!

toggleSelect: aGlyph
	"Toggle the selection of aGlyph. That is, if aGlyph is currently selected, deselect it; if it is not selected, select it."

	(selected includes: aGlyph)
		ifTrue: [self deselect: aGlyph]
		ifFalse: [self select: aGlyph]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Scene class
	instanceVariableNames: ''!


!Scene class methodsFor: 'instance creation'!

new

	^self basicNew initialize! !

Controller subclass: #IntroPicture
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Support'!
IntroPicture comment:
'I support startup pictures. The picture will also appear after you snapshot. The startup picture is typically stored in a file such as ''ThingLabII.form''. I go away when the user presses any mouse button.'!


!IntroPicture methodsFor: 'control defaults'!

isControlActive
	"Hack, hack!! Seize control and don't give it up until the user clicks any mouse button."

	sensor waitClickButton.
	view topView controller close.
	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntroPicture class
	instanceVariableNames: ''!


!IntroPicture class methodsFor: 'instance creation'!

openOn: aForm 
	"Display the ThingLabII intro picture."
	"IntroPicture openOn: (Form readFrom: 'ThingLabII.form')"

	| formView topView extent scratchForm |
	extent _ 354@332.
	Display boundingBox height - 30 < extent y
		ifTrue: [extent _ 318@294].
	scratchForm _ Form extent: extent depth: 32. scratchForm fillWhite.
	aForm
		displayOn: scratchForm
		at: ((extent - aForm boundingBox extent) // 2).
	formView _ FormView new model: scratchForm.
	formView controller: self new.

	topView _
		SpecialSystemView
			model: nil
			label: ' Welcome to ThingLabII '
			minimumSize: extent.
	topView addSubView: formView.
	topView window: (0@0 extent: extent)
		viewport: (0@0 extent: extent).
	topView controller openDisplayAt:
		(Display boundingBox center + (0@8)).! !

StandardSystemView subclass: #SpecialSystemView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Support'!

!SpecialSystemView class methodsFor: 'Squeak compatibility'!
model: aModel label: aString minimumSize: aPoint
	^self new model: aModel;
				label: aString;
				minimumSize: aPoint;
				yourself! !

!SpecialSystemView methodsFor: 'controller access'!

defaultControllerClass

	^SpecialSystemController! !

!SpecialSystemView methodsFor: 'queries'!

isVisible

	^(controller notNil) and: [controller isVisible]! !

!SpecialSystemView methodsFor: 'custom labels'!

displayLabel
	"Customized label display for that special look-n-feel."

	self isCollapsed ifTrue: [^self].
	isLabelComplemented _ false.
	"draw my label"
	(self labelForm)
		displayOn: Display
		at: self labelDisplayBox topLeft
		clippingBox: self labelDisplayBox.!

displayView
	"Display my label."

	self displayLabel!

expandLabelFrame
	"Make my label frame fill the entire width of my display box. Assume that labelFrame topLeft has already been computed."

	labelFrame region: ((labelFrame region withRight: self displayBox width)
		withBottom:
			((labelText notNil)
				ifTrue: [labelText boundingBox height]
				ifFalse: [TextStyle default lineGrid])).!

label: aString 
	"Set aString to be my label. There are two label sizes: one for real computers and the other for small Macintoshes (toy computers)."

	self label: aString big: (ThingLabIIControlPanel bigLabelFlag).
	self expandLabelFrame.
	self setLabelRegion. "So that labelFrame border rect is replaced by a number" !

label: aString big: bigFlag
	"Set aString to be my label. Use big text if bigFlag is true, otherwise use small text."

	| style |
	(aString == nil)
		ifTrue: 
			[labelText _ nil.
			 labelFrame region: (0@0 extent: 0@0)]
		ifFalse:
			[bigFlag
				ifTrue:
					[style _ TextStyle default]
				ifFalse:
					[style _ TextStyle default].
			 labelText _ Paragraph withText: aString asText style: style.
			 labelFrame region:
				(0@0 extent: labelText boundingBox extent)].

	(iconView notNil & iconText isNil)
		ifTrue: [iconView text: self label asText].!

labelForm
	"A customized label display for that special look-n-feel."

	| form textBox textPlace leftEdge rightEdge |
	form _ Form extent: labelFrame extent depth: 32. form fillWhite.

	"draw the label text"
	textBox _ self labelTextBox.
	textPlace _ form boundingBox center -
				(textBox center - textBox topLeft).
	(labelText notNil) ifTrue:
		[labelText
			displayOn: form
			at: textPlace + (4@1)
			clippingBox: textBox].

	"draw decorative fringes"
	leftEdge _ textPlace x - 12.
	rightEdge _ textPlace x + textBox width.

	"left side fringe"
	form fill: (0@0 corner: leftEdge@form height) fillColor: Color lightGray.
	form fill: ((leftEdge@0) extent: 12@form height) fillColor: Color white.
	form fill: ((leftEdge@0) extent: 4@form height) fillColor: Color black.
	form fill: ((leftEdge + 6@0) extent: 2@form height) fillColor: Color black.
	form fill: ((leftEdge + 11@0) extent: 1@form height) fillColor: Color black.

	"right side fringe"
	form fill: (rightEdge@0 corner: form extent) fillColor: Color lightGray.
	form fill: ((rightEdge@0) extent: 12@form height) fillColor: Color white.
	form fill: ((rightEdge@0) extent: 1@form height) fillColor: Color black.
	form fill: ((rightEdge + 4@0) extent: 2@form height) fillColor: Color black.
	form fill: ((rightEdge + 8@0) extent: 4@form height) fillColor: Color black.

	"draw the border over everything else"
	form
		border: form boundingBox
		widthRectangle: ((1@1) corner: (1@0)) rule: (Form over) fillColor: (Color black).
	^form!

labelTextBox
	"Answer the rectangle containing just the text part of my label. This rectangle is in the coordinate system whose origin is the top-left corner of my label."

	| textWidth |
	(labelText isNil)
		ifTrue: [textWidth _ 8]
		ifFalse: [textWidth _ labelText boundingBox width + 8].
	^(0@1 corner: labelFrame extent) insetBy:
		((1 max: ((labelFrame width - textWidth) // 2)) @ 0)!

labelTextDisplayBox.
	"Answer the rectangle containing just the text part of my label in the Display coordinate system."

	^self labelTextBox translateBy: self labelDisplayBox origin!

reverseLabel
	"Reverse my label."

	Display reverse: (self labelTextDisplayBox).!

window: newWind viewport: newViewport
	"Intercept this message to allow me to re-compute my label frame when the view is re-sized."

	super window: newWind viewport: newViewport.
	self expandLabelFrame.! !

Object subclass: #ModuleCompiler
	instanceVariableNames: 'oldThing workThing newThing partitions internalVarCount '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Module Compiler'!
ModuleCompiler comment:
'This is is the top-level of the Module compiler that converts a Thing and a list of external parts into a ModuleThing and a set of ModuleConstraints.'!


!ModuleCompiler methodsFor: 'compiling'!

compileThing: aThing
	"This is the entry point of the ModuleCompiler. The module compiler manipulates a working copy of the original Thing to construct the new Module."

	| showOffView |
	oldThing _ aThing.
	workThing _ aThing clone.
	showOffView _ ModuleCompilerView open.	BusyCursor begin.
	self createPartitions.						BusyCursor inc.
	self removeExternalPartConstraints.		BusyCursor inc.
	showOffView incrementState.				BusyCursor inc.
	self declareExternalVariables.				BusyCursor inc.
	self removePrivateAndEmptyPartitions.		BusyCursor inc.
	showOffView incrementState.				BusyCursor inc.
	partitions do:
		[: partition |
		 partition computeSolutions.			BusyCursor inc.
		 partition analyzeSolutions.			BusyCursor inc].
	showOffView incrementState.				BusyCursor inc.
	self numberPartitions.				BusyCursor inc.
	self allocateInternalVariables.				BusyCursor inc.
	showOffView incrementState.				BusyCursor inc.
	self constructNewClass.					BusyCursor inc.
	self initializePrototype.					BusyCursor inc.
	showOffView incrementState.				BusyCursor inc.
	self buildAndAddConstraints.				BusyCursor inc.
	workThing destroy.						BusyCursor inc.
	showOffView closeAndRemove.				BusyCursor end.
	^newThing! !

!ModuleCompiler methodsFor: 'private'!

addConstrainedPartPathsFor: aPart from: pathSoFar into: paths
	"Recursively collect full paths for all constrained subparts of aPart into the given collection of paths. The path to this point is pathSoFar."

	(aPart isThing) ifTrue:
		[aPart partsAndNamesDo:
			[: part : partName |
			 ((aPart thingDataFor: partName) notNil) ifTrue:
				[paths add: (pathSoFar copyWith: partName asSymbol)].
			 self
				addConstrainedPartPathsFor: part
				from: (pathSoFar copyWith: partName asSymbol)
				into: paths]].!

allocateInternalVariables
	"Allocate internal variable names to the partitions. Internal variables are given names like 'internal1'."

	internalVarCount _ 0.
	partitions do:
		[: partition |
		 internalVarCount _
			partition allocateInternalVariables: internalVarCount].!

buildAndAddConstraints
	"Construct module constraints for all partitions and add them to newThing."

	| constraint |
	partitions do:
		[: p |
		 constraint _ p compileFor: newThing.
		 "allocate thingDatas before adding the constraint; the module methods assume they are there"
		 constraint variables do: [: v | v thingDataOrAllocate].
		 newThing addConstraint: constraint].!

constructNewClass
	"Build a new class for the module. This class will be a subclass of ModuleThing and will have instance variables for the external parts and the internal variables. Access methods must be compiled for the external parts."

	| instVarStream moduleName newClass externalThings |
	"build a list of instance variables for the new Module's class"
	instVarStream _ WriteStream on: String new.
	1 to: internalVarCount do:
		[: n | instVarStream nextPutAll: 'internal', n printString; space].
	oldThing class externalParts do: 
		[: var | instVarStream nextPutAll: var; space].

	"build the new Module's class"
	moduleName _ 'Module', ThingLabII uniqueNumber printString.
	newClass _ ModuleThing
		subclass: moduleName asSymbol
		instanceVariableNames: instVarStream contents
		classVariableNames: ''
		poolDictionaries: ''
		category: 'Things-Built'.

	"initialize the modules' class instance variables"
	newClass
		initializeForSourceClass: oldThing class
		internalPartCount: internalVarCount.
	newThing _ newClass prototype.

	"set up use/construction links"
	oldThing class useView: newClass.
	newThing class constructionView: oldThing class.

	"build custom access methods for the external parts"
	externalThings _ oldThing class externalParts collect:
		[: name | oldThing perform: name asSymbol].
	newThing class
		compileAccessMethodsFor: externalThings
		named: (oldThing class externalParts).

	"compile the instance offset class method for the new class"
	newClass compileInstOffsetMethodAs: ModuleThing instOffset + internalVarCount.!

createPartitions
	"Partition the constraints of workThing, creating a ModulePartition for each connected set of constraints."

	partitions _ (Partitioner partition: workThing) collect:
		[: partitionConstraints |
		 ModulePartition on: partitionConstraints].!

declareExternalVariables
	"Construct a set of references for the constrained subparts of the external parts of workThing. The references must contain paths starting with external part names. Use this set of references to declare the external variables for each partition."

	| paths part externalRefs |
	paths _ OrderedCollection new: 40.
	(workThing class externalParts) do:
		[: partName |
		 ((workThing thingDataFor: partName) notNil) ifTrue:
			[paths add: (Array with: partName)].
		 part _ workThing perform: partName.
		 self
			addConstrainedPartPathsFor: part
			from: (Array with: partName)
			into: paths].
	externalRefs _ paths collect:
		[: path | Reference on: workThing path: path].

	"identify the external variables in each partition"
	partitions do:
		[: partition |
		 partition declareExternalVars: externalRefs].!

initializePrototype
	"Initialize the external parts of the prototype with clones of the corresponding parts from workThing. Also initialize the internal variables."

	| tempThing extParts partRef allThingDatas cloneDictionary clone partName index |
	tempThing _ oldThing clone.
	"first, make sure external parts are not entangled with any doomed internal parts. this is done by isolating the non-external parts from merges and removing their constraints. we must also remove the top-level constraints from tempThing."
	extParts _ (tempThing class externalParts) asSet.
	tempThing thingPartsAndNamesDo:
		[: part : name |
		 (extParts includes: name) ifFalse:
			["isolate the part"
			 partRef _ part referenceToYourself.
			 part isolate: partRef within: partRef.
			 "remove all constraints attached to the part"
			 allThingDatas _ Set new.
			 part allThingDatasInto: allThingDatas.
			 allThingDatas do: 
				[: thingData | 
				 BusyCursor inc.
				 thingData constraints do: [: c | c removeConstraint]]]].

	tempThing constraints copy do: [: c | c destroy].
	tempThing constraints: tempThing constraints species new.

	"now, copy the external parts to the new module prototype. this is done using the cloning operation but moving the parts and changing the clone dictionary midway through."
	cloneDictionary _ IdentityDictionary new: 200.
	clone _ tempThing clonePass1: cloneDictionary.
	"move the newly copied external parts to their new home"
	newThing class partNamesAndIndices do:
		[: partAndIndex || part |
		 partName _ partAndIndex at: 1.
		 index _ partAndIndex at: 2.
		 part _ clone perform: partName.
		 newThing instVarAt: index put: part.
		 part removeParent: clone.
		 part addParent: newThing].
	"fix all references by changing old references to tempThing to go to newThing, using pass2 of the cloning operation."
	cloneDictionary at: tempThing put: newThing.
	clone clonePass2: cloneDictionary.

	partitions do: [: p | p initializeInternalVarsFor: newThing].
	tempThing destroy.!

numberPartitions
	"Assign a unique number to each partition."

	| nextId |
	nextId _ 0.
	partitions do:
		[: partition |
		 partition setID: (nextId _ nextId + 1)].!

removeExternalPartConstraints
	"Remove constraints owned by the external parts from all partitions."

	| externalConstraints part |
	"first, collect the constraints owned by external parts"
	externalConstraints _ IdentitySet new: 20.
	workThing class externalParts do:
		[: partName |
		 part _ workThing perform: partName.
		 (part isThing) ifTrue:
			[part allThingsDo:
				[: thing | externalConstraints addAll: thing constraints]]].

	"remove the external constraints from all partitions"
	partitions do:
		[: partition |
		 partition removeExternalPartConstraints: externalConstraints].

	"release the external constraints"
	externalConstraints do: [: c | c removeConstraint; destroy].!

removePrivateAndEmptyPartitions
	"Filter out partitions with no external variables since these partitions cannot be seen from outside the module. Filter out partitions which have no constraints because they required no further processing."

	partitions _ partitions select:
		[: p | (p hasExternalVars) and: [p isEmpty not]].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ModuleCompiler class
	instanceVariableNames: ''!


!ModuleCompiler class methodsFor: 'compiling'!

compileThing: aThing
	"Create a new instance of me and use it to compile the given thing into a Module."

	^self new compileThing: aThing! !

Constraint subclass: #EditConstraint
	instanceVariableNames: ''
	classVariableNames: 'SharedMethods '
	poolDictionaries: ''
	category: 'ThingLabII-Constraints-Special'!
EditConstraint comment:
'I am used to mark variable that the user wishes to edit. I have only one method with no inputs and one output. My method does nothing.'!


!EditConstraint methodsFor: 'initialize-release'!

ref: ref strength: aSymbol 
	"Initialize myself with the given reference and strength."

	strength _ Strength of: aSymbol.
	symbols _ #(a).
	self variables: (Array with: ref).
	"initialize methods list shared by all instances"
	(SharedMethods isNil) ifTrue:
		[SharedMethods _ Array with:
			((Method new)
				codeString: '"edit"';
				block: [: vars | "I do nothing"];
				bindings: 'o')].
	self methods: SharedMethods.
	whichMethod _ nil.
	self initializeFlags.! !

!EditConstraint methodsFor: 'queries'!

doesSomething
	"Edit constraints have no effect other than to control the planning process."

	^false!

isInput
	"Normal constraints are not input constraints. An input constraint is one that depends on external state, such as the mouse, the keyboard, or a clock."

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EditConstraint class
	instanceVariableNames: ''!


!EditConstraint class methodsFor: 'instance creation'!

ref: ref
	"Answer a new instance of me on the referenced variable with the current edit strength."

	^self ref: ref strength: ThingLabII editStrength!

ref: ref strength: strength
	"Create a new edit constraint on the referenced variable. For example:

	EditConstraint
		ref: aThing->#node.value
		strength: #preferred."

	^(super new) ref: ref strength: strength! !

Scene subclass: #ThingDebug
	instanceVariableNames: 'thing variables partitions currentPartition solvers solutionIndex '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Debugger'!


!ThingDebug methodsFor: 'initialize-release'!

buildButtons
	"Construct buttons for navigating through the partitions and solutions."

	| leftArrowForm rightArrowForm |
	leftArrowForm _ (Form
		extent: 10@9
		fromArray: #(3072 7168 15360 32704 65472 32704 15360 7168 3072)
		offset: 0@0).
	rightArrowForm _ leftArrowForm rotateBy: 2.
	self addGlyph: ((ButtonGlyph at: 21@20 form: leftArrowForm)
					 action: [: v | self previousPartition]).
	self addGlyph: ((ButtonGlyph at: 38@20 form: rightArrowForm)
					 action: [: v | self nextPartition]).
	self addGlyph: ((ButtonGlyph at: 21@34 form: leftArrowForm)
					 action: [: v | self previousAlternative]).
	self addGlyph: ((ButtonGlyph at: 38@34 form: rightArrowForm)
					 action: [: v | self nextAlternative]).!

buildPartitions
	"Build ThingDebug of data structures for the partitions of my Thing."

	| partitionRecord constraintRecord |
	partitions _ (Partitioner partition: thing) collect:
		[: partition |
		 partitionRecord _ DebugPartitionRecord new.
		 partitionRecord
			solver: (MultiSolver on: partition);
		 	constraintRecords: (partition collect:
				[: constraint |
				 constraintRecord _ DebugConstraintRecord new.
				 constraintRecord
					constraint: constraint;
				 	glyph: (ConstraintGlyph named: (self strengthString: constraint));
					solutions: (OrderedCollection with: constraint whichMethod)]).
		 partitionRecord].!

buildVariableTable
	"Build a dictionary of all constrained variables. The dictionary maps ThingDatas to VariableGlyphs. The information is extracted from the partitions, which must already have been built."

	| constraint glyph |
	variables _ IdentityDictionary new.
	partitions do:
		[: partition |
		 partition constraintRecords do:
			[: cRec |
			 cRec constraint variables do:
				[: v |
				 (variables includesKey: v thingData) ifFalse:
				 	[glyph _ VariableGlyph
								named: (v longName)
								at:  (self nextPlace).
					 variables at: v thingData put: glyph]].
			 cRec varGlyphs:
				(cRec constraint variables collect:
					[: v | variables at: v thingData])]].!

on: aThing
	"Initialize a new instance of me on the given Thing and build the partitions and variables table."

	super initialize.
	thing _ aThing.
	currentPartition _ 1.
	self buildButtons.
	self buildPartitions.
	self buildVariableTable.
	partitions do:
		[: partition |
		 partition solution: 0.
		 partition centerConstraints].
	self firstPartition.! !

!ThingDebug methodsFor: 'glyphs'!

isChanging: aGlyph
	"Answer true if the following glyph is changing. This is the case if the glyph is selected or if it is a ConstraintGlyph and one of its associated variables is selected."

	(selected includes: aGlyph) ifTrue: [^true].
	(aGlyph isMemberOf: ConstraintGlyph) ifTrue:
		[aGlyph allVarGlyphs do:
			[: var |
			 (selected includes: var) ifTrue: [^true]]].
	^false!

selectableGlyphs

	^glyphs select: [: g | (g isMemberOf: ButtonGlyph) not]! !

!ThingDebug methodsFor: 'partitions'!

firstPartition
	"Display the first partition."

	currentPartition _ 1.
	self updateGlyphs.!

nextPartition
	"Display the next partition. Wrap around at the end of the list of partitions."

	currentPartition _ (currentPartition \\ partitions size) + 1.
	self updateGlyphs.!

partitionCount
	"Answer the total number of constraint partitions for my Thing."

	^partitions size!

partitionIndex
	"Answer the index of the current partition."

	^currentPartition!

previousPartition
	"Display the previous partition. Wrap around at the beginning of the list of partitions."

	currentPartition _ ((currentPartition - 2) \\ partitions size) + 1.
	self updateGlyphs.! !

!ThingDebug methodsFor: 'solutions'!

currentSolution
	"Display solution zero, the current solution, for the current partition."

	(partitions at: currentPartition) solution: 0.!

nextAlternative
	"Display the next alternative solution for this partition. Wrap around at the end of the solutions list. If the alternative solutions have not yet been computed for this partition, compute them now."

	| partition |
	(self solutionCount = 0) ifTrue:
		[Cursor execute showWhile: [self computeAllSolutions]].
	partition _ partitions at: currentPartition.
	partition solution:
		((partition solution + 1) \\ (partition solutionCount + 1)).!

previousAlternative
	"Display the next previous solution for this partition. Wrap around at the beginning of the solutions list. If the alternative solutions have not yet been computed for this partition, compute them now."

	| partition |
	(self solutionCount = 0) ifTrue:
		[Cursor execute showWhile: [self computeAllSolutions]].
	partition _ partitions at: currentPartition.
	partition solution:
		((partition solution - 1) \\ (partition solutionCount + 1)).!

solutionCount
	"Answer the number of possible solutions for this partition."

	^(partitions at: currentPartition) solutionCount!

solutionHasCycle
	"Answer true if the current solution has a cycle."

	^(partitions at: currentPartition) solutionHasCycle!

solutionIndex
	"Answer the index of the displayed solution for the current partition. Zero means the current solution."

	^(partitions at: currentPartition) solution! !

!ThingDebug methodsFor: 'operations'!

animateOn: aView
	"Animate the layout algorithm."

	(partitions at: currentPartition) animateOn: aView.!

centerConstraints
	"Center all constraints between their operands."

	(partitions at: currentPartition) centerConstraints.!

rebuildFromThing
	"Completely rebuild my data structures from my Thing. This is useful when the structure of the underlying Thing has been changed but the user wants to keep using the same ThingDebugView."

	self on: thing.!

toggleConstraintLabels
	"Toggle the visibility of the constraint labels of the current partition."

	(partitions at: currentPartition) toggleLabels.!

toggleVariableLabels
	"Toggle the visibility of all variable labels."

	(variables asOrderedCollection first labelIsHidden)
		ifTrue: [variables do: [: v | v showLabel]]
		ifFalse: [variables do: [: v | v hideLabel]].!

updateCurrentSolutions
	"Update the current solution of each partition."

	partitions do:
		[: partition |
		 partition updateCurrentSolution].! !

!ThingDebug methodsFor: 'private'!

computeAllSolutions
	"This can be very expensive for large partitions!! Find and record all the possible solutions for this partition so that the user may browse through them."

	(partitions at: currentPartition) findAllSolutions.!

nextPlace

	|  random x y |
	random _ Random new.
	x _ (random next * 200) rounded.
	y _ (random next * 200) rounded.
	^(60@40) + (x@y)!

strengthString: aConstraint
	"Answer an abbreviation of the constraint's strength."

	| sym |
	sym _ aConstraint strength asSymbol.
	(sym == #required) ifTrue: [^'R'].
	(sym == #strongPreferred) ifTrue: [^'sP'].
	(sym == #preferred) ifTrue: [^'P'].
	(sym == #strongDefault) ifTrue: [^'sD'].
	(sym == #default) ifTrue: [^'D'].
	(sym == #weakDefault) ifTrue: [^'wD'].
	^'(', sym, ')'!

updateGlyphs
	"Update my glyphs after changing partitions."

	| partition varGlyphs |
	(partitions isEmpty) ifTrue: [^self].
	partition _ partitions at: currentPartition.

	glyphs _ glyphs select:
		[: g | ((g isMemberOf: VariableGlyph) | (g isMemberOf: ConstraintGlyph)) not].
	self clearSelection.

	varGlyphs _ IdentitySet new: 20.
	partition constraintRecords do:
		[: cRec |
		 glyphs add: cRec glyph.
		 varGlyphs addAll: cRec varGlyphs].
	glyphs addAll: varGlyphs.

	(partition neverLaidOut) ifTrue: [partition initialLayout].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ThingDebug class
	instanceVariableNames: ''!


!ThingDebug class methodsFor: 'instance creation'!

on: aThing
	"Create a new instance on the given Thing."

	^(super new) on: aThing! !

Constraint subclass: #StayConstraint
	instanceVariableNames: ''
	classVariableNames: 'SharedMethods '
	poolDictionaries: ''
	category: 'ThingLabII-Constraints-Special'!
StayConstraint comment:
'I am used to mark variables should, with some level of preference, stay the same. I have only one method with no inputs and one output. My method does nothing. Planners may use the fact that, if I am satisfied, my output will not change to perform stay optimization.'!


!StayConstraint methodsFor: 'initialize-release'!

ref: ref strength: aSymbol 
	"Initialize myself with the given reference and strength."

	strength _ Strength of: aSymbol.
	symbols _ #(a).
	self variables: (Array with: ref).
	"initialize methods list shared by all instances"
	(SharedMethods isNil) ifTrue:
		[SharedMethods _ Array with:
			((Method new)
				codeString: '"stay"';
				block: [: vars | "I do nothing"];
				bindings: 'o')].
	self methods: SharedMethods.
	whichMethod _ nil.
	self initializeFlags.! !

!StayConstraint methodsFor: 'queries'!

doesSomething
	"Stay constraints have no effect other than to control the planning process."

	^false!

isStay
	"I am a stay constraint."

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StayConstraint class
	instanceVariableNames: ''!


!StayConstraint class methodsFor: 'instance creation'!

ref: ref strength: strength
	"Create a new stay constraint on the referenced variable. For example:

	StayConstraint
		ref: aThing->#midpoint.y
		strength: #default."

	^(super new) ref: ref strength: strength! !

Object subclass: #Glyph
	instanceVariableNames: 'location '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Framework'!
Glyph comment:
'This is an abstract class that defines the protocol used by components of a Scene to permit them to be laid out, displayed, and selected. Subclasses must implement the methods specified as ''subclassResponsibility'' (which are currently only displayOn:at:clippingBox: and boundingBox, but don''t trust this comment!!).'!


!Glyph methodsFor: 'initialize-release'!

initialize
	"Initialize myself with default values. Subclasses should do 'super initialize' when overriding this method to ensure that instance variables owned by their superclass are properly initialized."

	location _ 0@0.! !

!Glyph methodsFor: 'accessing'!

location

	^location!

location: aPoint

	location _ aPoint.! !

!Glyph methodsFor: 'glyph protocol'!

boundingBox
	"Answer a Rectangle that completely surrounds all visible parts of me."

	^self subclassResponsibility!

containsPoint: aPoint
	"More complex subclasses may refine this method."

	^self boundingBox containsPoint: aPoint!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox 
	"Draw myself. The default is to do nothing. Visible glyphs supply a more specialized behavior for this method."!

glyphsComment
	"This protocol describes the basic operations on graphical objects known as 'glyphs'. A glyph may be displayed, selected, and moved. The three categories of glyphs are:

	1. visible glyphs -- glyphs that are visible in the display
	2. selectable glyphs -- glyphs that can be selected and moved
	3. input glyphs -- glyphs that respond to keyboard and/or mouse events

These categories are orthogonal, so it is possible to have visible glyphs that cannot be selected and moved or glyphs that can be selected but are not visible.

All glyphs must respond to basic glyph protocol:
	boundingBox -- Essential!!
	displayOn:at:clippingBox:
	boundingBox
	initialize
The only essential message is boundingBox; default behavior is provided for the other messages, although since the default displayOn:at:clippingBox: behavior is to do nothing, a glyph that does not override this default will be invisible.

For a glyph to be considered an input glyph, it must also answer true to one of:
	wantsKeystrokes
	wantsMouse
and it must support the corresponding keyboard and/or mouse prototcol."!

highlightOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox 
	"This is the default highlighted glyph display method, which merely draws a box around itself. Subclasses may refine this."

	aDisplayMedium
		border: ((self boundingBox translateBy: aDisplayPoint)
					insetOriginBy: -2@-2 cornerBy: -2@-2)
		widthRectangle: (1@1 corner: 1@1)
		fillColor: (Color black)
		clippingBox: clipBox.!

intersects: aRectOrGlyph
	"Answer true if I interesect with the given object, which may be either a Rectangle or a Glyph."

	(aRectOrGlyph isMemberOf: Rectangle)
		ifTrue:
			[^aRectOrGlyph intersects: self boundingBox]
		ifFalse:
			[^aRectOrGlyph boundingBox intersects: self boundingBox].! !

!Glyph methodsFor: 'keyboard'!

handleKeystroke: aCharacter view: aView
	"Accept the given character. The default behavior is to do nothing."!

wantsKeystrokes
	"Answer true if I want to get keyboard input. The default behavior is to answer false."

	^false! !

!Glyph methodsFor: 'mouse'!

handleMouseDown: mousePoint view: aView
	"The mouse button has been pressed. mousePoint is in local coordinates. The default behavior is to do nothing."!

handleMouseMove: mousePoint view: aView
	"The message is sent repeatedly while the mouse button is pressed. mousePoint is in local coordinates. The default behavior is to do nothing."!

handleMouseUp: mousePoint view: aView
	"The mouse button has gone up. mousePoint is in local coordinates. The default behavior is to do nothing."!

mouseComment

	"When mouse input is initiated, the following sequence of events occurs:
	1. handleMouseDown:view: is sent to the glyph (exactly once)
	2. handleMouseMove: is sent to the glyph repeatedly while the mouse is down (at least once)
	3. handleMouseUp: is sent to the glyph (exactly once)

All of these messages have two arguments: 1) the current mouse position in local coordinates and 2) the view in which this Glyph appears."!

wantsMouse
	"Answer true if I want to be informed of mouse activity. The default behavior is to answer false."

	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Glyph class
	instanceVariableNames: ''!


!Glyph class methodsFor: 'instance creation'!

new
	"Answer a new Glyph at 0@0."

	^self basicNew initialize! !

ModuleDisjunction subclass: #ModuleConjunction
	instanceVariableNames: 'varEquations orEquations '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-Module Compiler'!
ModuleConjunction comment:
'I represent a conjunction (AND) of terms.

Each term has one of the following forms:
	1. aStrength <= aWalkEquation
	2. aModuleVarTableEntry <= aWalkEquation
	3. an OrEquation

Terms of the first form are kept in an OrderedCollection of Arrays of the form:
	(aStrength, aWalkEquation)
while terms of the second form are kept in a dictionary indexed by variable. The entries of this dictionary are WalkEquations. Terms of the third form are kept in an OrderedCollection.

My simplification rules are similar to those of OrEquations, except that:
	1. ''true'' terms are removed instead of ''false'' terms
	2. a ''false'' term makes the entire conjection ''false'' regardless of other terms
	3. OrEquation terms are simplified

Instance variables (in addition to those inherited):

	varEquations...		maps ModuleVarTableEntries to WalkEquations
	orEquations...			a collection of OrEquations
'!


!ModuleConjunction methodsFor: 'initialize-release'!

initialize

	super initialize.
	varEquations _ IdentityDictionary new.
	orEquations _ OrderedCollection new.! !

!ModuleConjunction methodsFor: 'operations'!

addOrTerm: orEquation
	"Add the given disjunctive term. If it has only one term, remove the enclosing disjunction and add the term inside."

	(orEquation hasOnlyOneTerm)
		ifTrue: [orEquation addTermsTo: self]
		ifFalse: [orEquations add: orEquation].
	knownValue _ nil.!

var: var weakerOrEq: walkEquation
	"Add an equation of the form:
		var <= walkEquation
	walkEquation is a WalkEquation of the form 'A weakest: B weakest: C ...'
	var is a ModuleVarTableEntry"

	| newEq |
	(varEquations includesKey: var)
		ifTrue:
			[newEq _ (varEquations at: var) weakest: walkEquation.
			 varEquations at: var put: newEq]
		ifFalse:
			[varEquations at: var put: walkEquation].
	knownValue _ nil.! !

!ModuleConjunction methodsFor: 'printing'!

printOn: aStream

	| left right |
	aStream nextPutAll: 'AND('; cr.
	constEquations do:
		[: eqn | self printLeft: (eqn at: 1) right: (eqn at: 2) on: aStream].
	varEquations associationsDo:
		[: eqn | self printLeft: (eqn key) right: (eqn value) on: aStream].
	orEquations do:
		[: eqn | eqn printOn: aStream].
	aStream nextPutAll: ')'; cr.! !

!ModuleConjunction methodsFor: 'code generation'!

storeOn: aStream
	"Append to aStream code to be compiled to evalute myself at run-time."

	(self isTrue) ifTrue: [^aStream nextPutAll: 'true'].
	(self isFalse) ifTrue: [^aStream nextPutAll: 'false'].
	constEquations do:
		[: eqn |
		 aStream tab.
		 self codeLeft: (eqn at: 1) right: (eqn at: 2) on: aStream.
		 aStream nextPutAll: ' &'; cr].
	varEquations associationsDo:
		[: eqn |
		 aStream tab.
		 self codeLeft: (eqn key) right: (eqn value) on: aStream.
		 aStream nextPutAll: ' &'; cr].
	orEquations do:
		[: eqn |
		 aStream tab.
		 eqn storeOn: aStream.
		 aStream nextPutAll: ' &'; cr].
	(constEquations isEmpty & varEquations isEmpty & orEquations isEmpty) ifFalse:
		[aStream skip: -3].! !

!ModuleConjunction methodsFor: 'private'!

emptyCheck
	"See if I have no terms and, if so, set my knownValue based on this."
	"An empty conjunction (AND) is true because the true constant terms were filtered out."

	(constEquations isEmpty & varEquations isEmpty & orEquations isEmpty)
		ifTrue: [knownValue _ true].!

keepTermLeft: left right: right
	"This method is used in simplifying module boolean equations. Answer true if the given term should be kept. A term has the form:
	aStrength notStronger: aWalkEquation
As a side effect, set the known value of myself (a boolean conjunction or disjunction) if possible. Assume that the sender has verified that the left side is a constant and that the right side has a constant part."
	"Since I am a conjunction (AND), I can remove all true constant terms. A false constant term makes the entire conjunction false."

	(left stronger: right constant)
		ifTrue:
			["term is false, keep it and set known value"
			 knownValue _ false.
			 ^true]
		ifFalse:
			[(right vars isEmpty)
				ifTrue:
					["term is true, don't keep it"
					 ^false]
				ifFalse:
					["term value is not known, keep it"
					 ^true]].!

simplify
	"Simplify this equation by removing constant terms. Set known value if possible. For further details, see the comment for this method in my superclass."

	| equations |
	super simplify.

	"empty orEquations and add back only the non-constant or false ones"
	equations _ orEquations.
	orEquations _ orEquations species new.
	equations do:
		[: eqn |
		 (eqn isFalse) ifTrue:
			[knownValue _ false.		"any false term makes the conjunction false"
			 self addOrTerm: eqn].
		 (eqn isTrue)
			ifTrue: ["don't keep true equations"]
			ifFalse:
				["do keep non-constant equations"
				 self addOrTerm: eqn]].

	self emptyCheck.	"check for empty conjunction"! !

BasicThingView subclass: #StandAloneThingView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!


!StandAloneThingView methodsFor: 'controller access'!

defaultControllerClass

	^StandAloneThingController! !

!StandAloneThingView methodsFor: 'displaying'!

display
	"First, check to see if the window has been resized. If so, fix our FrameThing (if any)."

	self controller reframe: self insetDisplayBox extent.
	super display.!

displayBorderOn: aDisplayMedium at: aPoint clippingBox: clipBox
	"Don't display a border in StandAloneThingViews."! !

Scene subclass: #ThingAdaptor
	instanceVariableNames: 'thing selectableGlyphs inputGlyphs historyNodes thingDatas '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!


!ThingAdaptor methodsFor: 'initialize-release'!

release

	super release.
	glyphs _ selected _ nil.! !

!ThingAdaptor methodsFor: 'access'!

name
	"Answer the name of my underlying Thing."

	^thing name!

thing
	"Answer my underlying Thing."

	^thing!

thing: aThing
	"Set my underlying Thing and update my caches accordingly."

	thing _ aThing.
	self updateCaches.!

thingDatas
	"Warning: thingDatasCache is a cache of my underlying Thing's ThingDatas. Care must be used to ensure that this cache is kept up to date. If in doubt, send me the message updateGlyphsCache."

	^thingDatas! !

!ThingAdaptor methodsFor: 'glyphs access'!

inputGlyphs
	"Warning: inputGlyphs is a cache of my underlying Thing's input glyphs. Care must be used to ensure that this cache is kept up to date. If in doubt, send me the message updateGlyphsCache."

	^inputGlyphs!

selectableGlyphs
	"Warning: selectableGlyphs is a cache of my underlying Thing's selectable glyphs. Care must be used to ensure that this cache is kept up to date. If in doubt, send me the message updateGlyphsCache."

	^selectableGlyphs!

visibleGlyphs
	"Warning: glyphs is a cache of my underlying Thing's glyphs. Care must be used to ensure that this cache is kept up to date. If in doubt, send me the message updateGlyphsCache."

	^glyphs! !

!ThingAdaptor methodsFor: 'glyphs'!

addGlyph: aThing

	self shouldNotImplement.!

isChanging: aThingGlyph
	"Answer true if the give glyph is undergoing changes that could effect how it is displayed."

	aThingGlyph glyphDependsOn do:
		[: aThing |
		 (self thingIsChanging: aThing) ifTrue:
			[^true]].		"must redisplay this glyph every time"

	"the glyph does not depend on any changing parts"
	^false!

removeGlyph: aGlyph

	self shouldNotImplement.! !

!ThingAdaptor methodsFor: 'operations'!

advanceHistory
	"Advance all my cached history variables."

	historyNodes do: [: node | node advanceHistory].!

updateCaches
	"Update all my caches."

	self clearSelection.	"clear selection"
	glyphs _ thing visibleGlyphs asOrderedCollection.
	selectableGlyphs _ thing selectableGlyphs asOrderedCollection.
	inputGlyphs _ thing inputGlyphs asOrderedCollection.
	historyNodes _ self collectHistoryThings.
	thingDatas _ self collectThingdatas.! !

!ThingAdaptor methodsFor: 'private'!

collectHistoryThings
	"Collect the history keeping subparts of my Thing."

	| historyThings |
	historyThings _ IdentitySet new: 30.
	thing allThingsDo: [: aThing |
		(aThing keepsHistory) ifTrue:
			[historyThings add: aThing]].
	^historyThings asOrderedCollection!

collectThingdatas
	"Recompute thingDatas after a structural change."

	| allThingDatas |
	allThingDatas _ IdentitySet new: 100.
	thing allThingDatasInto: allThingDatas.
	^allThingDatas asOrderedCollection select: [: td | td stay not]!

thingIsChanging: aThing
	"Answer true if the given Thing has a constrained part whose stay flag is not true."

	"if the thing has no thingDatas, then it is fixed"
	(aThing thingDatas isEmpty) ifTrue: [^false].

	aThing thingDatas do:
		[: thingData |
		 (thingData stay not) ifTrue: [^true]].	"thing is not fixed"
	^false	"thing is fixed"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ThingAdaptor class
	instanceVariableNames: ''!


!ThingAdaptor class methodsFor: 'instance creation'!

on: aThing

	^(super new) thing: aThing! !

Glyph subclass: #LayoutGlyph
	instanceVariableNames: 'label cost index x y '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Layout'!


!LayoutGlyph methodsFor: 'initialize-release'!

initialize

	super initialize.
	label _ 0.
	cost _ -1.
	index _ 0.
	x _ 0.0.
	y _ 0.0.! !

!LayoutGlyph methodsFor: 'accessing'!

cost

	^cost!

cost: aNumber

	cost _ aNumber.!

index
	"The index field is used by PriorityQueue to keep track of element locations."

	^index!

index: anIndex
	"The index field is used by PriorityQueue to keep track of element locations."

	index _ anIndex.!

label

	^label!

label: aNumber

	label _ aNumber.!

x

	^x!

x: aNumber

	x _ aNumber.!

y

	^y!

y: aNumber

	y _ aNumber.! !

!LayoutGlyph methodsFor: 'layout support'!

< aVertexInfo
	"Answer true if the receiver's cost is less than the cost of the given vertex."

	^cost < aVertexInfo cost!

> aVertexInfo
	"Answer true if the receiver's cost is greater than the cost of the given vertex."

	^cost > aVertexInfo cost!

moveBy: deltaPoint
	"Move this vertice by the given amount."

	x _ x + deltaPoint x.
	y _ y + deltaPoint y.! !

!LayoutGlyph methodsFor: 'printing'!

printOn: aStream

	aStream nextPutAll: '(v'.
	label printOn: aStream.
	aStream nextPutAll: ' = '.
	cost printOn: aStream.
	aStream nextPut: $).! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LayoutGlyph class
	instanceVariableNames: ''!


!LayoutGlyph class methodsFor: 'instance creation'!

label: aNumber
	"Answer a new instance of the receiver with the given label."

	^(super new) label: aNumber! !

SceneController subclass: #PartsBinController
	instanceVariableNames: 'currentCursor '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Parts Bin'!
PartsBinController comment:
'I am a controller for PartsBinIconViews. I support PartsBin operations such as move, delete, open bin, edit icon, change name, and many more. Some of these operations are available from my menu, others through direct manipulation (dragging, double-clicking, etc).'!


!PartsBinController methodsFor: 'menu operations'!

addMenuItems: debugging
	"Answer my yellow-button menu given the current selection and possibly some other view or controller state. The goal is to present in the menu only those possibilities which are legal commands at this juncture. If debugging is true, present a additional options which might be useful to implementors and other gurus."

	| argCount arg |
	argCount _ model selected size.
	(argCount == 1)
		ifTrue: [arg _ model selected asOrderedCollection first].

	super addMenuItems: debugging.

	myMenu add: ' new thing ' action: #createThing.	
	(model isAllParts not) ifTrue:
		[myMenu add: ' new bin ' action: #createBin].
	myMenu addLine.

	(argCount == 1) ifTrue:
		[myMenu add: ' rename ' action: #changeName.
		 myMenu add: ' edit icon ' action: #changeIcon].
	(argCount > 0) ifTrue:
		[myMenu add: ' delete ' action: #delete].
	myMenu addLine.

	myMenu add: ' arrange ' action: #arrange.
	myMenu add: ' update ' action: #update.
	myMenu addLine.

	((argCount == 1) and: [arg holdsThing]) ifTrue:
		[myMenu add: ' explain ' action: #explainThing.
		 myMenu add: ' inspect ' action: #inspectThing.
		 myMenu addLine].

	(argCount == 1) ifTrue:
		[myMenu add: ' open ' action: #open.
		(debugging | arg holdsPartsBin) ifTrue:
			[myMenu add: ' push ' action: #enterBin]].
	(view canExit) ifTrue:
		[myMenu add: ' pop ' action: #exitBin].!

arrange

	BusyCursor begin.
	model arrangeIn: (0@0 extent: view insetDisplayBox extent).
	view computeEnclosingRectangle.
	view scrollOffset: 0@0.
	view displayScene.
	BusyCursor end.!

changeIcon
	"Edit the icon of the selected Thing or PartsBin."

	| arg |
	arg _ self argument.
	(arg notNil and: [model isAllParts | arg holdsPartsBin])
		ifTrue: [NotifyingBitEditor openOnForm: arg icon client: view]
		ifFalse: [view flash].!

changeName
	"Edit the name of the selected Thing or PartsBin."

	| arg name |
	arg _ self argument.
	(arg notNil and: [model isAllParts | arg holdsPartsBin])
		ifTrue:
			[name _ arg name.
			 name _ FillInTheBlank request: 'New name?' initialAnswer: name.
			 (name isEmpty not) ifTrue: [arg name: name].
			 (arg name asString = name) ifFalse: [view flash]]
		ifFalse: [^view flash].
	view displayScene.!

createBin
	"Create a new bin named 'New Bin' and select it."

	| newBin |
	(model isAllParts)
		ifTrue: [^view flash].
	newBin _ PartHolder on: (PartsBin newNamed: 'New Bin').
	model
		findLocationFor: newBin
		inside: (0@0 extent: view insetDisplayBox extent).
	model addPart: newBin.
	model clearSelection.
	model select: newBin.
	view displayView.!

createThing
	"Create a new thing and open a ThingConstructorView on it."

	| newThing |
	newThing _ Thing defineNewThing.
	PartsBin changed: #creation.
	ThingConstructorView openOn: newThing.  "never returns"!

delete
	"Delete selected objects."

	| args |
	args _ model selected asOrderedCollection.
	(args isEmpty or: [(self confirm: 'Are you sure?') not])
		ifTrue: [^self].
	args do: [: p |
		"don't delete AllParts from Top Bin"
		((p holdsAllParts) & (model name == 'Top Bin'))
			ifTrue: [view flash]
			ifFalse:
				["remove the thing or parts bin from this parts bin"
				 model deselect: p.
				 model removeGlyph: p.
				 "if my model is an All Parts bin, try to remove the deleted thing from the system entirely"
			 	 (model isAllParts & p holdsThing) ifTrue:
					[(p cargo destroyAndRemoveClass) ifFalse:
						[self error: 'Could not destroy ', p cargo name]]]].
	view displayView.
	PartsBin changed: #deletion.!

enterBin
	"The selection must be a PartsBin. Make the current view a view on this PartsBin."

	| arg |
	arg _ self argument.
	(arg notNil and: [arg holdsPartsBin])
		ifTrue: [view enter: arg cargo]
		ifFalse: [^view flash].
	view displayScene.!

exitBin
	"Undo the effect of the last 'enter' operation."

	(view canExit) ifFalse: [^view flash].
	view exit.
	view displayScene.!

explainThing
	"Open an editor on the explanation of the selected Thing."

	| arg fromFrame |
	arg _ self argument.
	(arg notNil and: [arg holdsThing])
		ifFalse: [^view flash].
	fromFrame _ arg boundingBox translateBy:
					(view modelToDisplayPoint: 0@0).
	Explanation openOn: arg cargo zoomingFrom: fromFrame.!

inspectThing
	"Inspect the currently selected Thing."

	| arg |
	arg _ self argument.
	(arg notNil and: [arg holdsThing])
		ifTrue: [arg cargo inspect]
		ifFalse: [view flash].!

open
	"Open a new view on the currently selected Thing or PartsBin."

	| arg fromFrame |
	arg _ self argument.
	(arg notNil and: [arg cargo notNil])
		ifFalse: [^view flash].
	fromFrame _ arg boundingBox translateBy:
					(view modelToDisplayPoint: 0@0).
	(arg holdsPartsBin)
		ifTrue: [
			PartsBinView
				openOn: arg cargo
				from: arg
				zoomingFrom: fromFrame
				to: arg lastFrame]
		ifFalse: [	
			ThingConstructorView
				openOn: arg cargo
				from: arg
				zoomingFrom: fromFrame
				to: arg lastFrame].!

update

	view syncWithReality.
	view displayView.! !

!PartsBinController methodsFor: 'direct manipulation'!

deposit: movingParts at: relativePositions relativeTo: aPoint orginallyAt: originalPositions copyFlag: copyFlag
	"Deposit moving parts in the view containing aPoint if it is one of ours. Otherwise, complete a move operation within this view. When this method is invoked, the parts have already been dragged in this view, so if we are copying into another view, we must move the copies in this view back to their original positions."

	| destTopView destView |
	"Are we moving parts to another view?"
	destTopView _ self destinationTopView.
	(destTopView isNil)
		ifTrue:		"no, moving within this view"
			[view shiftOrigin; displayView]
		ifFalse:		"yes, copying to another view"
			["first, undo the part moving that we did in this view"
			 movingParts
				with: originalPositions
				do: [: p : originalPos | p location: originalPos].
			 view displayView.
			 "then copy the parts to the destination view "
			 destView _ self destinationAt: aPoint in: destTopView.
			 destView
				acceptCopies: movingParts
				at: relativePositions
				withRespectTo: aPoint.
			 "bring destination view forward and display it with the new parts"
			 destTopView displaySafe: [destView displayView].
			 copyFlag	"if copyFlag is false, this is a move between bins"
				ifFalse: [self delete]].!

doubleClickAt: aPoint
	"Handle a double-click action by trying to open the object under aPoint. A double-click that is not over an icon does a selectAll."

	((self glyphAt: aPoint) isNil)
		ifTrue:
			[self selectAll.
			 sensor waitNoButton]
		ifFalse:
			[model clearSelection.
			 self selectAt: aPoint toggleFlag: false.
			 view displayScene.
			 (sensor leftShiftDown)
				ifTrue: [self enterBin]
				ifFalse: [self open]].!

moveAt: aPoint
	"Drag all selected parts for a move or copy operation. If the destination view is different than my view, then this is a copy operation. Otherwise, the parts are simply moved."

	| movingParts relativePositions copyFlag oldPositions point oldPoint |
	movingParts _ model selected asOrderedCollection.
	model moveToFront: movingParts.
	relativePositions _ movingParts collect: [: p | p location - aPoint].
	copyFlag _ sensor leftShiftDown not.
	oldPositions _ movingParts collect: [: p | p location].
	view computeBackground.
	[sensor redButtonPressed] whileTrue:
		[point _ sensor cursorPoint.
		 (point ~= oldPoint) ifTrue:
			[movingParts
				with: relativePositions
				do: [: p : relPos | p location: (relPos + point)].
			 self doCursorFeedback.
			 view displayFeedback]].
	self
		deposit: movingParts at: relativePositions
		relativeTo: sensor cursorPoint
		orginallyAt: oldPositions
		copyFlag: copyFlag.
	Cursor normal show.! !

!PartsBinController methodsFor: 'private'!

destinationAt: aPoint in: aView
	"Answer a view that can accept icons under the given point in the given top view."

	aView subViews do:
		[: subView |
		 ((subView containsPoint: aPoint) and:
		  [(subView isMemberOf: PartsBinView) |
		   (subView isMemberOf: ThingConstructorView) |
		   (subView isMemberOf: MultiThingView)])
				ifTrue: [^subView]].
	^nil!

destinationTopView
	"Answer the top view of the destination for a move or copy between views. Answer nil if the destination is myself or if there is no appropriate destination under the cursor."

	| point aTopView |
	(self viewHasCursor) ifTrue: [^nil].
	point _ sensor cursorPoint.
	ScheduledControllers scheduledControllers do:
		[: c | ((self destinationAt: point in: (c view)) notNil)
				 ifTrue: [^c view]].
	^nil!

doCursorFeedback
	"Show a bull's eye cursor if we are over a view that could be the destination for this move operation. Show the normal cursor otherwise."

	(self destinationTopView isNil)
		ifTrue: [(currentCursor ~~ Cursor normal)
			ifTrue: [(currentCursor _ Cursor normal) show]]
		ifFalse: [(currentCursor ~~ Cursor crossHair)
			ifTrue: [(currentCursor _ Cursor crossHair) show]].! !

SceneController subclass: #BasicThingController
	instanceVariableNames: 'editConstraints plan running '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!
BasicThingController comment:
'This is the controller class for BasicThingControllers.'!


!BasicThingController methodsFor: 'initialize-release'!

initialize

	super initialize.
	editConstraints _ OrderedCollection new.
	plan _ Plan new.
	running _ false.! !

!BasicThingController methodsFor: 'control defaults'!

controlActivity
	"Process user mouse and keyboard activity."

	super controlActivity.
	"if running is true, advance history variables"
	running ifTrue: [self executeAndRedisplay].! !

!BasicThingController methodsFor: 'menu operations'!

addMenuItems: debugging
	"Answer my yellow-button menu given the current selection and possibly some other view or controller state. The goal is to present in the menu only those possibilities which are legal commands at this juncture. If debugging is true, present a additional options which might be useful to implementors and other gurus."

	| argCount |
	argCount _ model selected size.

	"add superclass menu items"
	super addMenuItems: debugging.

	(running)
		ifTrue:
			[myMenu add: ' stop ' action: #stop]
		ifFalse:
			[myMenu add: ' step ' action: #step.
			 myMenu add: ' run ' action: #run].
	myMenu addLine.

	(argCount <= 1) ifTrue:
		[myMenu add: ' explain ' action: #explain.
		 myMenu add: ' inspect ' action: #inspectThing].
	myMenu add: ' debugger ' action: #openDebugger.
	myMenu addLine.!

explain
	"If a single part is selected, explain that part. Otherwise, explain the top-level Thing (the Thing under construction)."

	(self argument notNil)
		ifTrue: [Explanation openOn: self argument]
		ifFalse: [Explanation openOn: model thing].!

inspectThing
	"If a single part is selected, inspect that part. Otherwise, inspect the top-level Thing (the Thing under construction)."

	(self argument notNil)
		ifTrue: [self argument inspect]
		ifFalse: [model thing inspect].!

openDebugger
	"Open a ThingDebugView on my Thing."

	ThingDebugView openOn: model thing.!

run
	"Allow history to advance as fast as it can be computed."

	self makePlan.
	running _ true.!

step
	"Advance history one tick."

	self run.
	self executeAndRedisplay.
	self stop.!

stop
	"Stop the clock!!"

	running _ false.! !

!BasicThingController methodsFor: 'direct manipulation'!

doubleClickAt: aPoint
	"Handle a double-click action by opening an inspector on the object under aPoint or, if aPoint is not over any glyph, selecting everything."

	((self glyphAt: aPoint) isNil)
		ifTrue:
			[self selectAll.
			 sensor waitNoButton]
		ifFalse:
			[model clearSelection.
			 self selectAt: aPoint toggleFlag: false.
			 view displayScene.
			 self inspectThing].!

moveAt: aPoint
	"Move all selected parts. If only one part is being moved, try to merge it with the part (if any) at its new location."

	| parts partLocations |
	parts _ model selected asOrderedCollection.
	partLocations _ parts collect: [: p | p location].
	self
		while: [sensor anyButtonPressed]
		move: partLocations
		refPoint: aPoint.
	view computeEnclosingRectangle.
	view displayView.!

while: testBlock move: pointThings refPoint: refPoint
	"Move the given PointThings. Any glyphs attached to the points will follow the mouse until a button is pressed."

	| relativePositions point oldPoint |
	relativePositions _ pointThings collect: [: p | p asPoint - refPoint].
	self addMouseConstraintsFor: pointThings with: relativePositions.
	[testBlock value] whileTrue:
		[point _ sensor cursorPoint.
		 (oldPoint ~= sensor cursorPoint) ifTrue:
			[self executeAndRedisplay]].
	self removeMouseConstraints.! !

!BasicThingController methodsFor: 'editor support'!

acceptChange
	"This message is sent by an editor when state of Thing being edited is accepted."

	view displaySafe: [self executeAndRedisplay].!

doneEditing
	"This message is sent by an editor when it is done editing and is about to be closed."

	self removeInputConstraints.! !

!BasicThingController methodsFor: 'keyboard'!

readKeyboard
	"Keystrokes are sent to all selected Things that are interested in keyboard input."

	| interested char |
	editConstraints _ editConstraints species new.
	interested _ model selected select:
		[: thing |
		 (thing wantsKeystrokes) and: [model inputGlyphs includes: thing]].
	interested do:
		[: thing | self addInputConstraints: thing keystrokeConstraints].
	(self cannotEditThing) ifTrue:
		[sensor keyboard. "flush input character"
		^self abortInput].

	self makePlan.
	[sensor keyboardPressed] whileTrue:
		[char _ sensor keyboard.
		 interested do: [: thing | thing handleKeystroke: char view: view].
		 self executeAndRedisplay].
	self removeInputConstraints.! !

!BasicThingController methodsFor: 'mouse'!

passMouseTo: thing
	"Allow the given Thing to handle a mouse interaction. It is assumed that the given Thing wants the mouse."

	editConstraints _ editConstraints species new.
	self addInputConstraints: thing mouseConstraints.
	(self cannotEditThing) ifTrue:
		[^self abortInput].

	self makePlan.
	thing handleMouseDown: self adjustedCursorPoint view: view.
	thing handleMouseMove: self adjustedCursorPoint view: view.	
	self executeAndRedisplay.
	[sensor anyButtonPressed] whileTrue:
		[thing handleMouseMove: self adjustedCursorPoint view: view.
		 self executeAndRedisplay].
	thing handleMouseUp: self adjustedCursorPoint view: view.
	self executeAndRedisplay.
	self removeInputConstraints.! !

!BasicThingController methodsFor: 'constraints'!

abortInput
	"An input constraint could not be satisfied. Flash the view and abort."

	view flash.
	editConstraints do: [: c | c removeConstraint. c destroy].
	editConstraints _ editConstraints species new.
	running ifTrue: [self makePlan].!

addInputConstraints: constraintsList
	"Add the given list of constraints and remember them in editConstraints."

	constraintsList do:
		[: c |
		 c addConstraint.
		 editConstraints add: c].!

addMouseConstraintsFor: movingParts with: offsets 
	"Add mouse constraints (which are special user input constraints) for the given collection of parts at the associated offsets from the mouse position."

	| part offset |
	editConstraints _ editConstraints species new.
	1 to: movingParts size do:  [: i | 
		part _ movingParts at: i.
		offset _ offsets at: i.
		editConstraints add:
			(XMouseConstraint
				ref: part->#x
				strength: (ThingLabII editStrength)
				offset: offset x).
		editConstraints add:
			(YMouseConstraint
				ref: part->#y
				strength: (ThingLabII editStrength)
				offset: offset y)].
	editConstraints do: [: c | c addConstraint].
	self makePlan.!

cannotEditThing
	"Answer true if any of the edit constraints is not satisfied."

	editConstraints do: [: c |
		(c isSatisfied) ifFalse: [^true]].
	^false!

executeAndRedisplay
	"Advance history if necessary, execute the plan, and display new state."

	running ifTrue: [model advanceHistory].
	plan execute.	
	view displayFeedback.!

makePlan
	"Plan for constraint satisfaction and redisplay. This includes making a constraint satisfaction plan, computing the model's fixed glyphs, and computing the background form for redisplay."

	| allThingDatas |
	allThingDatas _ model thingDatas copy.
	editConstraints do:
		[: c |
		 (c isSatisfied) ifTrue:
			[c outDatasDo:
				[: out | allThingDatas add: out]]].
	plan _ DeltaBluePlanner
			extractPlanFromChangingThingDatas: allThingDatas.
	view computeBackground.!

removeInputConstraints

	model advanceHistory.
	editConstraints do: [: c | c removeConstraint. c destroy].
	editConstraints _ editConstraints species new.
	self makePlan.
	self executeAndRedisplay.!

removeInputConstraints: constraintsList
	"Remove the given list of constraints but do not replan."

	constraintsList do:
		[: c |
		 c removeConstraint.
		 editConstraints remove: c.
		 c destroy].!

removeMouseConstraints
	"Just provides a more mnemonic name for this function when used with mouse constraints."

	self removeInputConstraints.! !

Glyph subclass: #ButtonGlyph
	instanceVariableNames: 'form action lastMouseInButton '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Framework'!


!ButtonGlyph methodsFor: 'initialize-release'!

initialize

	super initialize.
	self form: ' Push Me!! ' asParagraph asForm.
	action _ nil.! !

!ButtonGlyph methodsFor: 'accessing'!

action: aBlock

	action _ aBlock.!

form

	^form!

form: aForm

	aForm offset: (aForm computeBoundingBox extent // -2).
	form _ aForm.! !

!ButtonGlyph methodsFor: 'glyph protocol'!

boundingBox
	"Answer my bounding box."

	^form computeBoundingBox translateBy: (location + form offset)!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	form
		displayOn: aDisplayMedium
		at: location + aDisplayPoint
		clippingBox: clipBox
		rule: (Form over)
		fillColor: (Color white).! !

!ButtonGlyph methodsFor: 'mouse'!

handleMouseDown: mousePoint view: view
	"Give feedback that the button has been pressed. The action is invoked only if the mouse goes up inside the button."

	self reverseIn: view.
	lastMouseInButton _ true.!

handleMouseMove: mousePoint view: view
	"Show feedback. If the mouse is in the button, show it reversed."

	| mouseInButton |
	mouseInButton _ self containsPoint: mousePoint.
	(mouseInButton ~= lastMouseInButton) ifTrue:
		[self reverseIn: view.
		 lastMouseInButton _ mouseInButton].!

handleMouseUp: mousePoint view: view
	"If the mouse is still in the button, then invoke the action, unless it is nil, in which case do nothing."

	(self containsPoint: mousePoint) ifTrue:
		[lastMouseInButton ifTrue: [self reverseIn: view].
		 (action notNil) ifTrue:
			[action value: view]].
	view displayScene.!

reverseIn: view
	"Show feedback by reversing. This toggles the reverse mode, so calling this method twice returns the display to its original state."

	Display reverse: 
		((self boundingBox translateBy: (view modelToDisplayPoint: 0@0))
			intersect: view insetDisplayBox).!

wantsMouse

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ButtonGlyph class
	instanceVariableNames: ''!


!ButtonGlyph class methodsFor: 'instance creation'!

at: aPoint form: aForm

	^(self new) location: aPoint; form: aForm! !

SceneView subclass: #PartsBinView
	instanceVariableNames: 'path '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Parts Bin'!
PartsBinView comment:
'I am a view used to display a two-dimensional layout of part icons. Each icon has a location and a name and is capable of displaying itself. PartsBin is my model and PartsBinIconController is my controller.'!


!PartsBinView methodsFor: 'initialize-release'!

initialize

	super initialize.
	path _ OrderedCollection new.
	PartsBin addDependent: self.!

release

	PartsBin removeDependent: self.! !

!PartsBinView methodsFor: 'controller access'!

defaultControllerClass

	^PartsBinController! !

!PartsBinView methodsFor: 'operations'!

acceptCopies: partsCollection at: relPoints withRespectTo: aPoint
	"Accept copies of the given collections of parts. Each part should be placed at the location given by the corresponding element of the relPoints collection, relative to the given point."

	| parts refPoint |
	(model isAllParts) ifTrue: [^self flash].
	parts _ partsCollection collect: [: p | p copy].
	refPoint _ aPoint - self insetDisplayBox origin.
	parts with: relPoints do:
		[: p : relLoc | model addPart: p at: (refPoint + relLoc)].
	self shiftOrigin.!

canExit

	^path isEmpty not!

enter: aPartsBin

	path addLast: model.
	self model: aPartsBin.
	self newLabel: aPartsBin name.
	self computeEnclosingRectangle.
	self scrollOffset: 0@0.!

exit

	(path isEmpty) ifTrue: [^self flash].
	self model: path removeLast.
	self newLabel: self model name.
	self computeEnclosingRectangle.
	self scrollOffset: 0@0.! !

!PartsBinView methodsFor: 'updating'!

doneEditingForm
	"Sent by a NotifyingBitEditor when it is done editing a part icon. This event is not interesting to me."!

formChanged
	"Sent by a NotifyingBitEditor when one of my part's icons has been
edited."

	self displaySafe: [self displayScene].!

shiftOrigin
	"Move all my glyphs so that they have positive locations."

	| adjustment |
	self computeEnclosingRectangle.
	adjustment _ (self enclosingRectangle origin) min: 0@0.
	(adjustment ~= (0@0))
		ifTrue:
			[(model allGlyphs) do:
				[: p | p location: (p location - adjustment)]].
	self computeEnclosingRectangle.!

syncWithReality
	"Update model from the underlying Thing database."

	^model syncWithReality: (0@0 corner: self insetDisplayBox extent)!

update: change

	(change == #deletion)
		ifTrue:
			[((self syncWithReality) and:
			  [self topView isVisible]) ifTrue:
				[^self displaySafe: [self displayView]]].
	((change == #creation) & (model isAllParts))
		ifTrue:
			[((self syncWithReality) and:
			  [self topView isVisible]) ifTrue:
				[^self displaySafe: [self displayView]]].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PartsBinView class
	instanceVariableNames: ''!


!PartsBinView class methodsFor: 'instance creation'!

openOn: aPartsBin
	"Open a view on the given parts bin."

	aPartsBin syncWithReality: nil.
	aPartsBin clearSelection.
	self
		openWithSubview: ((PartsBinView new) model: aPartsBin)
		label: (aPartsBin name)!

openOn: aPartsBin from: aPartHolder zoomingFrom: fromRect to: openFrame
	"Open a view on the given parts bin zooming from fromRect to openFrame. Remember that this view was opened from the given partHolder."

	aPartsBin syncWithReality: openFrame.
	aPartsBin clearSelection.
	self
		openWithSubview: ((PartsBinView new) model: aPartsBin)
		label: (aPartsBin name)
		fromHolder: aPartHolder
		zoomFrom: fromRect 
		to: openFrame.! !

Glyph subclass: #IconGlyph
	instanceVariableNames: 'nameForm '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Framework'!
IconGlyph comment:
'This is an abstract class for a special kind of Glyph that displays an icon with a centered text label below it. Subclasses must respond to these messages:
	name
	name:
	icon
	icon:

I cache a Form for my name in the instance variable ''nameForm'' for more efficient display. My subclasses must update this cache whenever their name changes by sending the message updateNameIcon to self.'!


!IconGlyph methodsFor: 'initialize-release'!

initialize
	"Use a dummy Form until nameForm can be updated from the actual object name."

	super initialize.
	nameForm _ Form extent: (10@12) depth: 32. nameForm fillWhite.! !

!IconGlyph methodsFor: 'accessing'!

icon

	^self subclassResponsibility!

icon: aForm

	^self subclassResponsibility!

name

	^self subclassResponsibility!

name: aString
	"Note: after changing my name, send myself the message 'updateNameForm'."

	^self subclassResponsibility!

updateNameForm
	"For efficiency, I cache a Form containing the bitmap for the text of my name."

	nameForm _
		(Paragraph
			withText: self name asText
			style: ((TextStyle default copy) lineGrid: 12; baseline: 9)) centered asForm.! !

!IconGlyph methodsFor: 'glyph protocol'!

boundingBox
	"Answer my bounding box."

	^self iconBox merge: self nameBox!

containsPoint: aPoint
	"Answer true if either my icon or name boxes contains the given point. Allow a little slop around the icon box."

	^(((self iconBox) expandBy: 2) containsPoint: aPoint) or:
	  [(self nameBox) containsPoint: aPoint]!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	self icon
		displayOn: aDisplayMedium
		at: (aDisplayPoint + self iconOffset)
		clippingBox: clipBox
		rule: (Form over)
		fillColor: (Color white).

	nameForm
		displayOn: aDisplayMedium
		at: (aDisplayPoint + self nameOffset)
		clippingBox: clipBox
		rule: (Form over)
		fillColor: (Color white).!

highlightOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	aDisplayMedium
		border: ((self iconBox translateBy: aDisplayPoint) expandBy: 1)
		widthRectangle: (1@1 corner: 1@1)
		fillColor: (Color gray)
		clippingBox: clipBox.

	nameForm
		displayOn: aDisplayMedium
		at: (aDisplayPoint + self nameOffset)
		clippingBox: clipBox
		rule: 12
		fillColor: (Color black).! !

!IconGlyph methodsFor: 'private'!

iconBox
	"Answer my icon bounding box."

	^self icon computeBoundingBox translateBy: self iconOffset!

iconOffset
	"Center my icon on my location."

	^location - (self icon extent // 2)!

nameBox
	"Answer my name bounding box."

	^nameForm computeBoundingBox translateBy: self nameOffset!

nameOffset
	"Center my nameForm under my icon."

	^location +
		((nameForm width negated // 2)@((self icon height // 2) + 2))! !

Glyph subclass: #ArrowHead
	instanceVariableNames: 'vector '
	classVariableNames: 'FormTable '
	poolDictionaries: ''
	category: 'ThingLabII-UI-Debugger'!


!ArrowHead methodsFor: 'glyph protocol'!

boundingBox
	"Answer my bounding box."

	| form |
	form _ self form.
	^form computeBoundingBox
		 translateBy: (location + form offset)!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Display myself."

	self form
		displayOn: aDisplayMedium
		at: aDisplayPoint + location
		clippingBox: clipBox
		rule: Form paint
		fillColor: Color black.!

form
	"Answer the arrowhead form for my vector."

	| slope absSlope angle |
	(vector x = 0) ifTrue:
		[(vector y >= 0)
			ifTrue: [^FormTable at: 270]
			ifFalse: [^FormTable at: 90]].

	slope _ vector y negated asFloat / vector x asFloat.
	absSlope _ slope abs.
	(absSlope < 0.5) ifTrue: [angle _ 0].
	((absSlope >= 0.5) & (absSlope < 2.0)) ifTrue: [angle _ 45].
	(absSlope >= 2.0) ifTrue: [angle _ 90].
	(slope > 0)
		ifTrue:
			[(vector x > 0)
				ifTrue: [^FormTable at: 0 + angle]
				ifFalse: [^FormTable at: 180 + angle]]
		ifFalse:
			[(vector x < 0)
				ifTrue: [^FormTable at: 180 - angle]
				ifFalse: [^FormTable at: 360 - angle]].! !

!ArrowHead methodsFor: 'access'!

vector: vectorPoint
	"Set my vector. The vector is used to choose an arrowhead with the right orientation."

	vector _ vectorPoint.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ArrowHead class
	instanceVariableNames: ''!


!ArrowHead class methodsFor: 'class initialization'!

initialize
	"Build my table of arrowhead forms."
	"ArrowHead initialize"

	FormTable _ Dictionary new.
	FormTable at: 0 put:							"0 degrees"
		(Form
			extent: 7@7
			fromArray: #(32768 24576 14336 65024 14336 24576 32768)
			offset: 0@-3).
	FormTable at: 45 put:							"45 degrees"
		(Form
			extent: 7@7
			fromArray: #(512 3072 15360 63488 14336 20480 36864)
			offset: 0@-6).
	FormTable at: 90 put:							"90 degrees"
		(Form
			extent: 7@7
			fromArray: #(4096 4096 14336 14336 31744 21504 37376)
			offset: -3@-6).
	FormTable at: 135 put:						"135 degrees"
		(Form
			extent: 7@7
			fromArray: #(32768 24576 30720 15872 14336 5120 4608)
			offset: -6@-6).
	FormTable at: 180 put:						"180 degrees"
		(Form
			extent: 7@7
			fromArray: #(512 3072 14336 65024 14336 3072 512)
			offset: -6@-3).
	FormTable at: 225 put:						"225 degrees"
		(Form
			extent: 7@7
			fromArray: #(4608 5120 14336 15872 30720 24576 32768)
			offset: -6@0).
	FormTable at: 270 put:						"270 degrees"
		(Form
			extent: 7@7
			fromArray: #(37376 21504 31744 14336 14336 4096 4096)
			offset: -3@0).
	FormTable at: 315 put:						"315 degrees"
		(Form
			extent: 7@7
			fromArray: #(36864 20480 14336 63488 15360 3072 512)
			offset: 0@0).
	FormTable at: 360 put: (FormTable at: 0).		"360 is same as 0 degrees"! !

!ArrowHead class methodsFor: 'instance creation'!

at: aPoint vector: vectorPoint
	"Create a new instance with the given orientation (determined by vectorPoint) and location."

	^(super new)
		vector: vectorPoint;
		location: aPoint! !


BasicThingController subclass: #ThingConstructorController
	instanceVariableNames: 'lastInserted '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!
ThingConstructorController comment:
'This is the controller class for ThingConstructorViews.'!


!ThingConstructorController methodsFor: 'initialize-release'!

initialize

	super initialize.
	lastInserted _ nil.! !

!ThingConstructorController methodsFor: 'menu operations'!

addMenuItems: debugging
	"Answer my yellow-button menu given the current selection and possibly some other view or controller state. The goal is to present in the menu only those possibilities which are legal commands at this juncture. If debugging is true, present a additional options which might be useful to implementors and other gurus."

	| argCount |
	argCount _ model selected size.

	"add superclass menu items"
	super addMenuItems: debugging.

	(lastInserted notNil) ifTrue:
		[myMenu add: ' another ' action: #another.
		 myMenu addLine].

	(argCount > 0) ifTrue:
		[(argCount > 1) ifTrue:
			[myMenu add: ' merge ' action: #merge].
		 myMenu add: ' unmerge ' action: #unmerge.
		 myMenu add: ' delete ' action: #delete.
		 myMenu add: ' extract ' action: #extract.
		 myMenu addLine].

	(argCount = 2) ifTrue:
		[myMenu add: ' h-align ' action: #hAlign.
		 myMenu add: ' v-align ' action: #vAlign.
		 myMenu addLine].

	(model thing isUseView)
		ifTrue: [myMenu add: ' view source ' action: #viewSource]
		ifFalse:
			[myMenu add: ' make module ' action: #defineModule.
			 (model thing class useView notNil)
				ifTrue: [myMenu add: ' view module ' action: #viewModule]].!

another
	"Insert another part like the most recently inserted part."

	 (model thing isStructureModifiable not | lastInserted isNil)
		ifTrue: [self flash]
		ifFalse: [self insertThing: lastInserted].!

defineModule

	| topView moduleView |
	topView _ view topView.
	topView removeSubViews.
	moduleView _
		(ThingModuleView new)
			model: (ThingAdaptor on: model thing).
	moduleView constructorView: view.
	topView addSubView: moduleView.
	moduleView scrollOffset: view scrollOffset.
	topView displaySubViews.
	self done: true.	"relinquish control"!

delete
	"Delete the selected parts."

	| proto partNames |
	proto _ model thing.
	(proto isStructureModifiable)
		ifFalse: [^view flash].	"can't modify this thing"

	partNames _ model selected asSet collect:
		[: part | (part allTopParentPaths first) first].
	partNames do:
		[: partName | proto removePartNamed: partName].
	model updateCaches.
	Cursor normal show.
	view displayView.!

extract
	"Extract the selected parts from all merges in which they participate."

	| proto |
	proto _ model thing.
	(proto isStructureModifiable)
		ifFalse: [^view flash].	"can't modify this thing"

	model selected asSet do:
		[: part |
		 proto extractPart: part referenceToYourself].

	model updateCaches.
	Cursor normal show.
	view displayView.!

hAlign
	"Horizontally align (with an offset) the two selected parts."

	| args offset top bottom |
	args _ model selected asOrderedCollection.
	(args size = 2) ifFalse: [view flash. ^self].

	offset _ 0.
	(Sensor leftShiftDown) ifTrue:
		[offset _
			FillInTheBlank request: 'Vertical offset (in pixels)?' initialAnswer: '0'.
		 (offset isEmpty)
			ifTrue: [offset _ 0]
			ifFalse: [offset _ (Number readFrom: offset readStream) rounded abs]].

	(args first location y < args last location y)
		ifTrue: [top _ args first. bottom _ args last]
		ifFalse: [top _ args last. bottom _ args first].

	model thing addConstraint:
		(OffsetConstraint
			ref: (top location->#y) copyFromTopParent
			ref: (bottom location->#y) copyFromTopParent
			strength: #strongPreferred
			offset: offset).

	model updateCaches.
	view displayView.!

merge
	"Merge the currently selected parts."

	| parts |
	parts _ model selected asOrderedCollection.
	(((parts size > 1) & (model thing isStructureModifiable)) and:
	  [self canMergeParts: parts])
		ifFalse: [view flash. ^self].
	(self mergeParts: parts)
		ifTrue: [view newLabel: model name].
	view displayView.!

unmerge
	"Completely unmerge each of the currently selected parts This will do nothing to the parts that were not merges."

	| parts |
	(model thing isStructureModifiable)
		ifFalse: [view flash. ^self].	
	parts _ model selected asOrderedCollection
		collect: [: p | p referenceToYourself].
	(self unmergeParts: parts)
		ifTrue: [view newLabel: model name].
	view displayView.!

vAlign
	"Vertically align (with an offset) the two selected parts."

	| args offset left right |
	args _ model selected asOrderedCollection.
	(args size = 2) ifFalse: [view flash. ^self].

	offset _ 0.
	(Sensor leftShiftDown) ifTrue:
		[offset _
			FillInTheBlank request: 'Horizonal offset (in pixels)?' initialAnswer: '0'.
		 (offset isEmpty)
			ifTrue: [offset _ 0]
			ifFalse: [offset _ (Number readFrom: offset readStream) rounded abs]].

	(args first location x < args last location x)
		ifTrue: [left _ args first. right _ args last]
		ifFalse: [left _ args last. right _ args first].

	model thing addConstraint:
		(OffsetConstraint
			ref: (left location->#x) copyFromTopParent
			ref: (right location->#x) copyFromTopParent
			strength: #strongPreferred
			offset: offset).

	model updateCaches.
	view displayView.!

viewModule
	"Change my model to the use view for my model."

	(model thing class useView isNil)
		ifTrue: [^view flash].
	self viewThing: (model thing class useView prototype).!

viewSource
	"Change my model to the construction view for my model, which should be a ModuleThing."

	(model thing class constructionView isNil)
		ifTrue: [^view flash].
	self viewThing: (model thing class constructionView prototype).!

viewThing: aThing
	"Change my model to the given Thing."

	view model thing: aThing.
	view newLabel: model name.
	view displayView.! !

!ThingConstructorController methodsFor: 'direct manipulation'!

displayWithMergeFeedbackFor: aThing
	"Test whether I could merge the given part with the part 'under' it. If so, highlight the part. If not, do the normal display-while-moving."

	| proto thingLocation otherThing tempForm |
	proto _ model thing.
	(proto isStructureModifiable)
		ifFalse: [^view displayFeedback].
	thingLocation _ aThing location asPoint.
	otherThing _ (model selectableGlyphs)
		detect: [: g |
			((g ~= aThing) & (g containsPoint: thingLocation)) and:
			[proto canMerge: aThing with: g]]
		ifNone: [nil].

	(otherThing isNil)
		ifTrue: [view displayFeedback]
		ifFalse:
			["highlight the Thing we could merge with"
			 view
				displayFeedbackWithBox:
					((otherThing boundingBox)
						insetOriginBy: -6 cornerBy: -6)
				width: 2]!

moveAt: aPoint
	"Move all selected parts. If only one part is being moved, try to merge it with the part (if any) at its new location."

	| parts partLocations |
	parts _ model selected asOrderedCollection.
	(parts size == 1)
		ifTrue:	"do a merge"
			[self
				while: [sensor anyButtonPressed]
				merge: parts first
				refPoint: aPoint]
		ifFalse:	"do a group-move"
			[partLocations _ parts collect: [: p | p location].
			 self
				while: [sensor anyButtonPressed]
				move: partLocations
				refPoint: aPoint].
	view computeEnclosingRectangle.
	view displayView.!

while: testBlock merge: aThing refPoint: refPoint
	"Move the given Thing. Give feedback on the possibility of merging with any Thing under the cursor. Do the merge if the mouse is released at such a moment."

	| point oldPoint |
	self
		addMouseConstraintsFor: (Array with: aThing location)
		with: (Array with: aThing location asPoint - refPoint).
	[testBlock value] whileTrue:
		[point _ sensor cursorPoint.
		 (oldPoint ~= sensor cursorPoint) ifTrue:
			[running ifTrue: [model advanceHistory].
			 plan execute.
			 self displayWithMergeFeedbackFor: aThing]].
	self removeMouseConstraints.
	self tryToMerge: aThing.! !

!ThingConstructorController methodsFor: 'part insertion'!

insertThing: protoType
	"Insert the given Thing as a new part of my model and allow the user to place it."

	| newPart |
	lastInserted _ protoType.
	lastMenuItem _ #another.
	newPart _ protoType clone.
	(model thing addThing: newPart)
		ifTrue: [view newLabel: model name].
	model updateCaches.
	self placeWhole: newPart.!

placeWhole: aPart
	"Position the given part as a whole, including all moveable sub-parts. The moveable sub-parts will follow the cursor until a mouse button is pressed."

	| partLocations center |
	partLocations _
		(aPart selectableGlyphs asOrderedCollection)
			collect: [: p | p location].
	(partLocations isEmpty) ifTrue: [^self].
	center _
		(partLocations
			inject: (partLocations first asPoint extent: 0@0)
			into:
				[: rect : location |
				 rect merge: (location asPoint extent: 0@0)]) center.
	self
		while: [sensor anyButtonPressed not]
		move: partLocations
		refPoint: view insetDisplayBox topLeft + center.
	sensor waitNoButton.! !

!ThingConstructorController methodsFor: 'merging/unmerging'!

canMergeParts: partsList
	"Answer true if the given parts can all be merged together. I assume that the given list contains at least two parts."

	| proto part1 |
	proto _ model thing.
	(proto isStructureModifiable) ifFalse: [^false].
	part1 _ partsList first.
	(partsList copyFrom: 2 to: partsList size) do:
		[: partN | (proto canMerge: partN with: part1) ifFalse: [^false]].
	^true!

copyValueFrom: part1 to: part2
	"If part1 is a Node Thing, fix part2's value part before doing a merge. However, do not do this if part2's value is determined by a constraint. Finally, any value has precedence over a value of nil. Assume that part1 and part2 are Things of the same class."

	"ignore non-Node Things"
	(part1 isMemberOf: Node) ifFalse: [^self].

	"exterminate nil's, if there are any"
	(part1 value isNil) ifTrue:
		[part1 primvalue: part2 value].
	(part2 value isNil) ifTrue:
		[part2 primvalue: part1 value].

	"copy the value from part1 to the value slot of part2 unless part2 has constraints"
	part1 primvalue: part2 value.
	(part2 thingDataForYourself isNil) ifTrue:
		[part2 primvalue: part1 value].!

mergeParts: partsList
	"Merge the given parts. I assume that the sender has already determined that the parts can be merged. Answer true if my name had to be changed to perform the merge."

	| cluster nameChanged |
	cluster _ partsList first.
	nameChanged _ false.
	(partsList copyFrom: 2 to: partsList size) do:
		[: p |
		 self copyValueFrom: cluster to: p.
		 (model thing mergePart: p withPart: cluster) ifTrue:
			[nameChanged _ true]].

	" refresh the glyphs cache and reselect the merged part"
	model updateCaches.
	partsList do:
		[: p | (p parents notNil) ifTrue: [model select: p]].

	^nameChanged!

tryToMerge: p1
	"Attempt to merge the given part with the part 'under' it. This is done at the end of a move operation if only one part was being moved and allows the user to perform a merge by simply stacking two mergeable parts."

	| p1Location p2 |
	p1Location _ p1 location asPoint.
	p2 _ (model selectableGlyphs)
		detect: [: g |
			((g ~~ p1) & (g containsPoint: p1Location)) and:
			  [self canMergeParts: (Array
					with: p1
					with: g)]]
		ifNone: [^self].
	(self mergeParts: (Array with: p1 with: p2))
		ifTrue: [view newLabel: model name].
	model updateCaches.
	view displayView.!

unmergeCluster: aPart
	"Completely unmerge the given part (i.e. if three points were merged to create the part, it will be replaced by three new points. Collect references for all the selectable newly liberated parts into the given set. Answer true if my Thing changed its name."

	| root paths delta nameChanged |
	root _ aPart value topParent.
	paths _ (aPart value allTopParentPaths)
				collect: [: path | Reference on: root path: path].
	(paths size < 2)
		ifTrue: [^false].	"nothing to unmerge"

	delta _ 5.
	nameChanged _ false.
	(paths copyFrom: 1 to: paths size - 1) do:
		[: ref |
		 (model thing extractMergedPart: ref) ifTrue:
			[nameChanged _ true].
		 "hack to offset locations to make unmerge visible"
		 (ref value selectableGlyphs) do:
			[: g | (g location) set: #x to: (g location asPoint x + delta)].
		 delta _ delta + 5].

	"make anchor nodes revert to nil value"
	paths do:
		[: ref |
		 (ref finalVariable isMemberOf: NodeAnchor)
			ifTrue: [(ref, #(value)) value: nil]].

	model updateCaches.
	paths do:
		[: ref |
			(ref value selectableGlyphs) do:
				[: glyph | model select: glyph]].
	^nameChanged!

unmergeParts: partsList
	"Unmerge the parts with the given references and answer true if my name had to be changed to perform the operation. I assume the sender has verified that the model's structure can be modified."

	| changed |
	changed _ false.
	partsList do:
		[: part |
		 (self unmergeCluster: part) ifTrue: [changed _ true]].
	^changed! !

LayoutGlyph subclass: #ConstraintGlyph
	instanceVariableNames: 'name nameForm showLabel inVars outVars unusedVars '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Debugger'!


!ConstraintGlyph methodsFor: 'initialize-release'!

initialize
	"Use a dummy Form until nameForm can be updated from the actual object name."

	super initialize.
	self name: 'R'.
	showLabel _ true.
	inVars _ outVars _ unusedVars _ #().! !

!ConstraintGlyph methodsFor: 'accessing'!

allVarGlyphs
	"Answer the collection of all VariableGlyphs associated with this constraint."

	^inVars, outVars, unusedVars!

ins: ins outs: outs unused: unuseds
	"Tell me about the VariableGlyphs for my input, output, and unused variables."

	inVars _ ins.
	outVars _ outs.
	unusedVars _ unuseds.!

name
	"Answer my name."

	^name!

name: aString
	"Set my name and update my nameForm cache."

	name _ aString.
	nameForm _
		(Paragraph
			withText: self name asText
			style: ((TextStyle default copy) lineGrid: 12; baseline: 9)) centered asForm.
	nameForm offset: (nameForm computeBoundingBox extent // -2).! !

!ConstraintGlyph methodsFor: 'show/hide label'!

hideLabel
	"Hide my label."

	showLabel _ false.!

labelIsHidden
	"Answer true if my label is currently hidden."

	^showLabel not!

showLabel
	"Show my label."

	showLabel _ true.! !

!ConstraintGlyph methodsFor: 'glyph protocol'!

boundingBox
	"Answer my bounding box."

	^nameForm computeBoundingBox translateBy: (location + nameForm offset)!

displayConnectionsOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Draw the connections to my variables."

	| line  p |
	line _ (Line new) form: (Form extent: 1@1) black.
	line beginPoint: location.
	"draw black lines to used variables"
	inVars, outVars do:
		[: varGlyph |
		 line endPoint: (varGlyph connectArrowFrom: location).
		 line
			displayOn: aDisplayMedium
			at: aDisplayPoint
			clippingBox: clipBox
			rule: Form over
			fillColor: Color black].
	"draw gray lines to unused variables"
	unusedVars do:
		[: varGlyph |
		 line endPoint: (varGlyph connectArrowFrom: location).
		 line
			displayOn: aDisplayMedium
			at: aDisplayPoint
			clippingBox: clipBox
			rule: Form over
			fillColor: Color gray].
	"draw arrow heads to output variables"
	outVars do:
		[: varGlyph |
		 p _ varGlyph connectArrowFrom: location.
		 (ArrowHead at: p vector: (varGlyph location - location))
			displayOn: aDisplayMedium
			at: aDisplayPoint
			clippingBox: clipBox].!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	self
		displayConnectionsOn: aDisplayMedium
		at: aDisplayPoint
		clippingBox: clipBox.

	showLabel ifTrue:
		[nameForm
			displayOn: aDisplayMedium
			at: location + aDisplayPoint
			clippingBox: clipBox
			rule: (Form over)
			fillColor: (Color white)].!

highlightOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	showLabel ifTrue:
		[nameForm
			displayOn: aDisplayMedium
			at: location + aDisplayPoint
			clippingBox: clipBox
			rule: 12	"reversed"
			fillColor: (Color black)].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ConstraintGlyph class
	instanceVariableNames: ''!


!ConstraintGlyph class methodsFor: 'instance creation'!

named: labelString
	"Answer a new instance with the given name."

	^(self new) name: labelString! !

Scene subclass: #PartsBin
	instanceVariableNames: 'name icon allPartsFlag '
	classVariableNames: 'DefaultIcon GridX GridY TopBin '
	poolDictionaries: ''
	category: 'ThingLabII-UI-Parts Bin'!
PartsBin comment:
'I contain a collection of Things and PartsBins, which are stored in PartsHolder objects in my glyphs collection. Like Things, I have a name and and icon, allowing me to be contained in other PartBins. If references to me appear in several parts bins, they will all display with the same name, icon, and parts selection. Some of my instances may be ''AllParts'' bins. An ''AllParts'' bin contains every currently existing Thing prototype.'!


!PartsBin methodsFor: 'initialize-release'!

initialize: nameString isAllParts: isAllParts

	super initialize.
	name _ nameString.
	icon _ DefaultIcon deepCopy.
	allPartsFlag _ isAllParts.
	allPartsFlag
		ifTrue: [self syncWithReality: nil].! !

!PartsBin methodsFor: 'accessing'!

allPartsFlag: aBoolean

	allPartsFlag _ aBoolean.!

icon

	^icon!

icon: aForm

	icon _ aForm.!

isAllParts

	^allPartsFlag!

name

	^name!

name: aString

	name _ aString.! !

!PartsBin methodsFor: 'operations'!

addPart: aPartHolder
	"Note: You can't anything to All Parts."

	(self isAllParts) ifTrue: [^self].	"can't add to AllParts"
	self findLocationFor: aPartHolder.
	self addGlyph: aPartHolder.!

addPart: aPartHolder at: aLocation
	"Note: You can't add Things or bins to All Parts."

	(self isAllParts) ifTrue: [^self].
	self addGlyph: ((aPartHolder copy) location: aLocation).! !

!PartsBin methodsFor: 'part placement'!

aligned: aPartHolder
	"Answer true if aPartHolder is aligned with a gridpoint."

	^((aPartHolder location x \\ GridX) = 0) and:
	  [(aPartHolder location y \\ GridY) = 0]!

arrangeIn: box
	"Arrange all the parts so that they are aligned, non-overlapping, and as many as possible are inside the given box."

	| sortedGlyphs insideGlyphs outsideGlyphs l1 l2 |
	sortedGlyphs _ glyphs asSortedCollection:
		[: g1 : g2 |
		 ((selected includes: g2) and: [(selected includes: g1) not]) or:
		 [l1 _ g1 location. l2 _ g2 location.
		 (l1 x abs + l1 y abs) < (l2 x abs + l2 y abs)]].
	insideGlyphs _ OrderedCollection new: glyphs size.
	outsideGlyphs _ OrderedCollection new: glyphs size.
	sortedGlyphs do:
		[: g |
		 (self part: g inside: box)
			ifTrue: [insideGlyphs addLast: g]
			ifFalse: [outsideGlyphs addLast: g]].

	"tempoarily remove all parts so we can consider overlaps only with parts that have already been positioned; parts will be re-instated as they are positioned."
	glyphs _ glyphs species new: glyphs size.
	"move mis-aligned or overlapping parts within the view box"
	insideGlyphs do:
		[: g |
		 BusyCursor inc.
		 ((self aligned: g) not or: [self isOverlapping: g])
			ifTrue: [self findLocationFor: g inside: box].
		  glyphs addLast: g].

	"try to move parts into the view box"
	outsideGlyphs do:
		[: g |
		 BusyCursor inc.
		 g location: box origin.		"start at the top left"
		 self findLocationFor: g inside: box.
		 glyphs addLast: g].!

findLocationFor: aPartHolder
	"Use when there may not be an open view for this PartsBin. Finds a location for aPartHolder assuming typical view dimensions. The location of aPartHolder is modified."

	self
		findLocationFor: aPartHolder
		inside: (0@0 corner: 200@120).!

findLocationFor: aPartHolder inside: box
	"Find a location in this bin for the given PartHolder and move it to that location. Try to stay inside the given bounding box."

	| possibleX possibleY rightEdge |
	possibleX _ (aPartHolder location x asFloat roundTo: GridX) max: GridX.
	possibleY _ (aPartHolder location y asFloat roundTo: GridY) max: GridY.
	rightEdge _ box width - (aPartHolder boundingBox width // 2) - 5.
	[true]
		whileTrue:
			[(possibleX > rightEdge) ifTrue:
				[possibleX _ GridX.
				 possibleY _ possibleY + GridY].
			 aPartHolder location: possibleX@possibleY.
			 (self isOverlapping: aPartHolder)
				ifFalse: [^self].
			 possibleX _ possibleX + GridX].!

isOverlapping: aPartHolder
	"Answer true if aPartHolder is overlaps some other PartHolder in this bin."
	"Note: Because computing the intersection of bounding boxes proved very expensive, this algorithm simply checks to see if aPartHolder is within a small Euclidian distance of any other PartHolder in this parts bin."

	| vec |
	glyphs do:
		[: g |
		 vec _ g location - aPartHolder location.
		 ((g ~~ aPartHolder) and:
		  [(vec x abs + vec y abs) < 10])
			ifTrue: [^true]].
	^false!

part: aPartHolder inside: aRectangle
	"Answer true if aPartHolder is completely inside the given rectangle."

	^aRectangle contains: aPartHolder boundingBox! !

!PartsBin methodsFor: 'updating'!

syncWithReality: viewBox
	"Update myself from the underlying Thing database. If viewBox is not nil, then it is the window of the view on me that initiated this operation."

	| realThings oldThings pHolder changed |
	changed _ false.
	BusyCursor begin.

	"Construct a list of all Things that currently exist."
	realThings _ IdentitySet new.
	((SystemOrganization
		listAtCategoryNamed: 'Things-Built' asSymbol),
	(SystemOrganization
		listAtCategoryNamed: 'Things-Primitive' asSymbol)) do:
			[: sym |
			 realThings add: (Smalltalk at: sym) prototype.
			 BusyCursor inc].

	"Remove from this parts bin any Things that no longer exist."
	(glyphs copy) do: [: g |
		((g holdsThing) and: [(realThings includes: g cargo) not]) ifTrue:
			["remove an obsolete thing"
			 changed _ true.
			 self removeGlyph: g].
		BusyCursor inc].

	"If I am AllParts, add to myself any new Things."
	(self isAllParts) ifTrue:
		[oldThings _ self thingsSet.
		 (realThings asOrderedCollection) do:
			[: thing |
			 (oldThings includes: thing) ifFalse:
				[pHolder _ PartHolder on: thing.
				 changed _ true.
				 (viewBox notNil)
				 	ifTrue: [self findLocationFor: pHolder inside: viewBox]
				 	ifFalse: [self findLocationFor: pHolder].
				 self addGlyph: pHolder.
				 BusyCursor inc]]].

	"Update all name forms."
	glyphs do: [: g | g updateNameForm].
	BusyCursor end.
	^changed! !

!PartsBin methodsFor: 'private'!

partsBinsSet
	"Answer a set of all the PartsBins I contain."

	| bins |
	bins _ IdentitySet new: 200.
	glyphs do:
		[: partHolder |
		 (partHolder holdsPartsBin)
			ifTrue: [bins add: partHolder cargo]].
	^bins!

thingsSet
	"Answer a set of all the Things I contain."

	| things |
	things _ IdentitySet new: 200.
	glyphs do:
		[: partHolder |
		 (partHolder holdsThing)
			ifTrue: [things add: partHolder cargo]].
	^things! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PartsBin class
	instanceVariableNames: ''!


!PartsBin class methodsFor: 'instance creation'!

newAllParts
	"Answer a parts bin that contains all currently existing Things."

	^(super new)
		initialize: 'All Parts'
		isAllParts: true!

newNamed: aString
	"Answer a new, empty bin with the given name."

	^(super new)
		initialize: aString
		isAllParts: false! !

!PartsBin class methodsFor: 'top bin access'!

newTopBin
	"Ask for confirmation, then create the root of the bin tree from scratch. Note that this will throw away all user-created bins!! All Things will still be accessible via the All Parts bin, of course."
	"PartsBin newTopBin."

	(self confirm:
'Making a new Top Bin will remove all
user bins. Do you wish to continue?')
		ifFalse: [^nil].

	TopBin _ self newNamed: 'Top Bin'.
	TopBin
		addPart: (PartHolder on: (PartsBin newAllParts))
		at: GridX@GridY.!

topBin
	"Answer the root of the bin tree."

	^TopBin!

updateAllBins
	"Update all PartsBins accessible from the top bin. Used after updating all the PrimitiveThings prototypes."
	"PartsBin updateAllBins"

	| toDo partsBin |
	toDo _ OrderedCollection with: TopBin.
	[toDo isEmpty] whileFalse:
		[partsBin _ toDo removeFirst.
		 toDo addAll: partsBin partsBinsSet.
		 partsBin syncWithReality: nil].! !

!PartsBin class methodsFor: 'grid parameters'!

gridX

	^GridX!

gridX: aNumber

	GridX _ aNumber.!

gridY

	^GridY!

gridY: aNumber

	GridY _ aNumber.! !

!PartsBin class methodsFor: 'class initialization'!

initialize
	"Initialize the default PartsBin icon and the grid for parts placement."
	"PartsBin initialize."

	DefaultIcon _ Form
		extent: 16@16
		fromArray: #(16383 16387 32773 65533 32773 36901 32773 65533 32773 36901 32773 65533 32773 36901 32774 65532)
		offset: 0@0.
	GridX _ 140.
	GridY _ 60.

	"make a new TopBin"
	TopBin _ self newNamed: 'Top Bin'.
	TopBin
		addPart: (PartHolder on: (PartsBin newAllParts))
		at: GridX@GridY.! !


Scene subclass: #MultiThingAdaptor
	instanceVariableNames: 'visibleGlyphs selectableGlyphs inputGlyphs thingDatas historyNodes '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!


!MultiThingAdaptor methodsFor: 'initialize-release'!

release

	super release.
	visibleGlyphs _ selectableGlyphs _ inputGlyphs _ nil.
	thingDatas _ historyNodes _ nil.! !

!MultiThingAdaptor methodsFor: 'access'!

name
	"Answer my name."

	^'Thing Scene'!

thing
	"Answer my underlying Thing."

	self shouldNotImplement!

thing: aThing
	"Set my underlying Thing and update my caches accordingly."

	self shouldNotImplement!

thingDatas
	"Warning: thingDatasCache is a cache of my underlying Thing's ThingDatas. Care must be used to ensure that this cache is kept up to date. If in doubt, send me the message updateGlyphsCache."

	^thingDatas! !

!MultiThingAdaptor methodsFor: 'glyphs access'!

inputGlyphs
	"Warning: inputGlyphs is a cache of my underlying Thing's input glyphs. Care must be used to ensure that this cache is kept up to date. If in doubt, send me the message updateGlyphsCache."

	^inputGlyphs!

selectableGlyphs
	"Warning: selectableGlyphs is a cache of my underlying Thing's selectable glyphs. Care must be used to ensure that this cache is kept up to date. If in doubt, send me the message updateGlyphsCache."

	^selectableGlyphs!

visibleGlyphs
	"Warning: glyphs is a cache of my underlying Thing's glyphs. Care must be used to ensure that this cache is kept up to date. If in doubt, send me the message updateGlyphsCache."

	^visibleGlyphs! !

!MultiThingAdaptor methodsFor: 'glyphs'!

addGlyph: aThing

	super addGlyph: aThing.
	self updateCaches.!

isChanging: aThingGlyph
	"Answer true if the give glyph is undergoing changes that could effect how it is displayed."

	aThingGlyph glyphDependsOn do:
		[: aThing |
		 (self thingIsChanging: aThing) ifTrue:
			[^true]].		"must redisplay this glyph every time"

	"the glyph does not depend on any changing parts"
	^false!

removeGlyph: aThing

	super removeGlyph: aThing.
	self updateCaches.!

thingIsChanging: aThing
	"Answer true if the given Thing has a constrained part whose stay flag is not true."

	"if the thing has no thingDatas, then it is fixed"
	(aThing thingDatas isEmpty) ifTrue: [^false].

	aThing thingDatas do:
		[: thingData |
		 (thingData stay not) ifTrue: [^true]].	"thing is not fixed"
	^false	"thing is fixed"! !

!MultiThingAdaptor methodsFor: 'operations'!

advanceHistory
	"Advance all my cached history variables."

	historyNodes do: [: node | node advanceHistory].!

updateCaches
	"Update all my caches."

	self clearSelection.	"clear selection"
	visibleGlyphs _ IdentitySet new.
	selectableGlyphs _ IdentitySet new.
	inputGlyphs _ IdentitySet new.
	thingDatas _ IdentitySet new.
	historyNodes _ IdentitySet new.

	glyphs do:
		[: aThing |
		 aThing visibleGlyphsInto: visibleGlyphs.
		 aThing selectableGlyphsInto: selectableGlyphs.
		 aThing inputGlyphsInto: inputGlyphs.
		 aThing allThingDatasInto: thingDatas.
		 aThing allThingsDo:
			[: subThing |
			 (subThing keepsHistory) ifTrue:
				[historyNodes add: subThing]]].

	visibleGlyphs _ visibleGlyphs asOrderedCollection.
	selectableGlyphs _ selectableGlyphs asOrderedCollection.
	inputGlyphs _ inputGlyphs asOrderedCollection.
	thingDatas _ thingDatas asOrderedCollection.
	historyNodes _ historyNodes asOrderedCollection.! !

LayoutGlyph subclass: #VariableGlyph
	instanceVariableNames: 'name nameForm showLabel '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Debugger'!


!VariableGlyph methodsFor: 'initialize-release'!

initialize
	"Use a dummy Form until nameForm can be updated from the actual object name."

	super initialize.
	self name: '???'.
	showLabel _ true.! !

!VariableGlyph methodsFor: 'accessing'!

icon

	^(Form
		extent: 13@13
		fromArray: #(8128 8224 16400 32776 32776 32776 32776 32776 32776 32776 16400 8224 8128)
		offset: -6@-6)!

name
	"Answer my name."

	^name!

name: aString
	"Set my name and update my nameForm cache."

	name _ aString.
	nameForm _
		(Paragraph
			withText: self name asText
			style: ((TextStyle default copy) lineGrid: 12; baseline: 9)) centered asForm.
	nameForm offset: (nameForm computeBoundingBox extent // -2).! !

!VariableGlyph methodsFor: 'show/hide label'!

hideLabel
	"Hide my label."

	showLabel _ false.!

labelIsHidden
	"Answer true if my label is currently hidden."

	^showLabel not!

showLabel
	"Show my label."

	showLabel _ true.! !

!VariableGlyph methodsFor: 'connections'!

angle: vector
	"Answer the approximate angle of the given vector."

	| slope absSlope angle |
	(vector x = 0) ifTrue:
		[(vector y >= 0)
			ifTrue: [^270]
			ifFalse: [^90]].

	slope _ vector y negated asFloat / vector x asFloat.
	absSlope _ slope abs.
	(absSlope < 0.5) ifTrue: [angle _ 0].
	((absSlope >= 0.5) & (absSlope < 2.0)) ifTrue: [angle _ 45].
	(absSlope >= 2.0) ifTrue: [angle _ 90].
	(slope > 0)
		ifTrue:
			[(vector x > 0)
				ifTrue: [^0 + angle]
				ifFalse: [^180 + angle]]
		ifFalse:
			[(vector x < 0)
				ifTrue: [^180 - angle]
				ifFalse: [^360 - angle]].!

connectArrowFrom: aPoint
	"Answer the proper endpoint of a line with an arrow head pointing to me from the given point."

	| angle |
	angle _ self angle: (location - aPoint).
	(angle == 0) ifTrue: [^-12@0 + location].
	(angle == 45) ifTrue: [^-11@11 + location].
	(angle == 90) ifTrue: [^0@12 + location].
	(angle == 135) ifTrue: [^11@11 + location].
	(angle == 180) ifTrue: [^12@0 + location].
	(angle == 225) ifTrue: [^11@-11 + location].
	(angle == 270) ifTrue: [^0@-12 + location].
	(angle == 315) ifTrue: [^-11@-11 + location].
	(angle == 360) ifTrue: [^-12@0 + location].!

connectLineFrom: aPoint
	"Answer the proper endpoint of a line (sans arrow head) to me from the given point."

	| angle |
	angle _ self angle: (location - aPoint).
	(angle == 0) ifTrue: [^-6@0 + location].
	(angle == 45) ifTrue: [^-5@5 + location].
	(angle == 90) ifTrue: [^0@6 + location].
	(angle == 135) ifTrue: [^5@5 + location].
	(angle == 180) ifTrue: [^6@0 + location].
	(angle == 225) ifTrue: [^5@-5 + location].
	(angle == 270) ifTrue: [^0@-6 + location].
	(angle == 315) ifTrue: [^-5@-5 + location].
	(angle == 360) ifTrue: [^-6@0 + location].! !

!VariableGlyph methodsFor: 'glyph protocol'!

boundingBox
	"Answer my bounding box."

	| icon |
	icon _ self icon.
	^((icon computeBoundingBox translateBy: icon offset) merge:
	  (nameForm computeBoundingBox translateBy: nameForm offset + (0@15)))
		translateBy: location!

containsPoint: aPoint
	"Answer true if either my icon or name boxes contains the given point. Allow a little slop around the icon box."

	| iconBox labelBox |
	iconBox _ (self icon computeBoundingBox) translateBy: (location + self icon offset).
	((iconBox expandBy: 2) containsPoint: aPoint) ifTrue:
		[^true].

	showLabel ifTrue:
		[labelBox _ (nameForm computeBoundingBox) translateBy:
					(location + nameForm offset + (0@15)).
		 (labelBox containsPoint: aPoint) ifTrue:
			[^true]].
	^false!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	self icon
		displayOn: aDisplayMedium
		at: location + aDisplayPoint
		clippingBox: clipBox
		rule: (Form under)
		fillColor: (Color black).

	showLabel ifTrue:
		[nameForm
			displayOn: aDisplayMedium
			at: location + aDisplayPoint + (0@15)
			clippingBox: clipBox
			rule: (Form over)
			fillColor: (Color white)].!

highlightOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	| icon iconBox |
	icon _ self icon.
	iconBox _ icon computeBoundingBox expandBy: 1.
	aDisplayMedium
		border: (iconBox translateBy: location + aDisplayPoint + icon offset)
		widthRectangle: (1@1 corner: 1@1)
		fillColor: (Color gray)
		clippingBox: clipBox.

	showLabel ifTrue:
		[nameForm
			displayOn: aDisplayMedium
			at: location + aDisplayPoint + (0@15)
			clippingBox: clipBox
			rule: 12	"reversed"
			fillColor: (Color black)].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VariableGlyph class
	instanceVariableNames: ''!


!VariableGlyph class methodsFor: 'instance creation'!

named: aString at: aPoint
	"Answer a new instance with the given name and location."

	^(super new)
		name: aString;
		location: aPoint! !

BasicThingController subclass: #MultiThingController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!


!MultiThingController methodsFor: 'menu operations'!

explain
	"If a single part is selected, explain that part. Otherwise, explain the top-level Thing (the Thing under construction)."

	(self argument notNil)
		ifTrue: [Explanation openOn: self argument]
		ifFalse: [view flash].!

inspectThing
	"If a single part is selected, inspect that part. Otherwise, inspect the top-level Thing (the Thing under construction)."

	(self argument notNil)
		ifTrue: [self argument inspect]
		ifFalse: [	view flash].!

openDebugger
	"Open a ThingDebugView on my Thing."

	view flash.! !

IconGlyph subclass: #PartHolder
	instanceVariableNames: 'cargo lastFrame '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Parts Bin'!
PartHolder comment:
'I am a holder for parts and parts bins. I inherit a location variable from Glyph and protocol for displaying myself from IconGlyph. I have a contents variable to store the Thing or PartsBin that I contain. My name and icon are those of my contents; I can only store objects that have names and icons.'!


!PartHolder methodsFor: 'initialize-release'!

initialize

	super initialize.
	cargo _ nil.
	lastFrame _ nil.! !

!PartHolder methodsFor: 'accessing'!

cargo

	^cargo!

cargo: anObject

	cargo _ anObject.
	self updateNameForm.!

icon

	^cargo icon!

icon: aForm

	cargo icon: aForm.!

lastFrame
	"Answer the view frame when this part was last closed."

	^lastFrame!

lastFrame: aRectangle
	"Set the view frame when this part was last closed."

	lastFrame _ aRectangle.!

name

	^cargo name!

name: aString

	cargo name: aString.
	self updateNameForm.! !

!PartHolder methodsFor: 'testing'!

holdsAllParts
	"Answer true if my cargo is an 'All Parts' PartsBin."

	^(self cargo isMemberOf: PartsBin) and:
	 [self cargo isAllParts]!

holdsPartsBin
	"Answer true if my cargo is a PartsBin."

	^self cargo isMemberOf: PartsBin!

holdsThing
	"Answer true if my cargo is a Thing."

	^self holdsPartsBin not! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PartHolder class
	instanceVariableNames: ''!


!PartHolder class methodsFor: 'instance creation'!

on: anObject
	"Answer a new PartHolder for the given object."

	^(super new) cargo: anObject! !

SceneController subclass: #ThingDebugController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Debugger'!


!ThingDebugController methodsFor: 'menu operations'!

addMenuItems: debugging
	"Answer my yellow-button menu given the current selection and possibly some other view or controller state. The goal is to present in the menu only those possibilities which are legal commands at this juncture. If debugging is true, present a additional options which might be useful to implementors and other gurus."

	super addMenuItems: debugging.
	myMenu add: ' layout ' action: #layout.
	myMenu add: ' center constraints ' action: #centerConstraints.	
	myMenu addLine.

	myMenu add: ' toggle constraint labels ' action: #toggleConstraintLabels.	
	myMenu add: ' toggle variable labels ' action: #toggleVariableLabels.	
	(model selected size == 1) ifTrue:
		[myMenu add: ' change label ' action: #changeLabel].	

	myMenu addLine.
	myMenu add: ' select current solution ' action: #currentSolution.

	myMenu addLine.
	myMenu add: ' update all current solutions ' action: #updateCurrentSolutions.
	myMenu add: ' update from thing ' action: #update.!

centerConstraints
	"Place constraints at the center of their operands."

	model centerConstraints.
	self redisplay.!

changeLabel
	"Change the label for a constraint or variable."

	| arg name |
	arg _ self argument.
	name _ FillInTheBlank
				request: 'New label?'
				initialAnswer: arg name.
	(name isEmpty not) ifTrue: [arg name: name].
	self redisplay.!

currentSolution
	"Select the current solution."

	model currentSolution.
	view displayScene.!

layout
	"Make a nice layout."

	model animateOn: view.
	self redisplay.!

toggleConstraintLabels
	"Toggle the visibility of my constraint labels."

	model toggleConstraintLabels.
	self redisplay.!

toggleVariableLabels
	"Toggle the visibility of my variable labels."

	model toggleVariableLabels.
	self redisplay.!

update
	"Update my model from the underlying Thing."

	model rebuildFromThing.
	self redisplay.!

updateCurrentSolutions
	"Update the current solutions of all partitions from the underlying Thing."

	model updateCurrentSolutions.
	self redisplay.! !

!ThingDebugController methodsFor: 'private'!

redisplay
	"Used when changing partitions. Fix the enclosing rectangle (since we now have a new set of graphical objects), then redisplay."

	view computeEnclosingRectangle.
	view displayView.! !

BasicThingController subclass: #StandAloneThingController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ThingLabII-UI-Thing Views'!


!StandAloneThingController methodsFor: 'initialize-release'!

controlActivity
	"Circumvent click/double click gesture stuff."

	(sensor redButtonPressed) ifTrue: [^self dragAt: sensor cursorPoint].
	super controlActivity.!

model: aThingAdaptor
	"This message gets called when the view is first opened. I take this opportunity to put myself in 'run' mode."

	super model: aThingAdaptor.
	self run.! !

!StandAloneThingController methodsFor: 'reframing'!

reframe: extent
	"Find a FrameThing in my model and ensure that its topLeft corner is 0@0 and its bottomRight corner is the current extent. If there is no FrameThing or if it doesn't need to be updated, do nothing."

	| frame |
	frame _ nil.
	model thing allThingsDo:
		[: thing |
		 (thing isMemberOf: FrameThing) ifTrue:
			[frame _ thing]].

	((frame notNil) and:
	   [(frame topLeft asPoint ~= (0@0)) |
	    (frame bottomRight asPoint ~= extent)]) ifTrue:
		[frame
			setAll: #(topLeft.x topLeft.y bottomRight.x bottomRight.y)
			to: (Array
				with: 0
				with: 0
				with: extent x
				with: extent y)
			strength: #required.
		 self makePlan].! !

!StandAloneThingController methodsFor: 'direct manipulation'!

addMenuItems: debugging
	"Answer my yellow-button menu given the current selection and possibly some other view or controller state. The goal is to present in the menu only those possibilities which are legal commands at this juncture. If debugging is true, present a additional options which might be useful to implementors and other gurus."

	| argCount |
	argCount _ model selected size.

	myMenu add: ' select all ' action: #selectAll.
	(model selected size > 0) ifTrue:
		[myMenu add: ' clear selection ' action: #clearSelection].
	myMenu addLine.

	(running)
		ifTrue:
			[myMenu add: ' pause ' action: #stop]
		ifFalse:
			[myMenu add: ' step ' action: #step.
			 myMenu add: ' run ' action: #run].
	myMenu addLine.

	(argCount <= 1) ifTrue:
		[myMenu add: ' explain ' action: #explain].
	((argCount <= 1) & debugging) ifTrue:
		 [myMenu add: ' inspect ' action: #inspectThing].
	(debugging) ifTrue:
		[myMenu add: ' debugger ' action: #openDebugger].
	myMenu addLine.!

scrollAt: aPoint
	"This is a noop for StandAlongThingControllers."!

selectAreaAt: aPoint toggleFlag: toggleFlag
	"This is a noop for StandAlongThingControllers."! !

"*************** Class and System Initialization ***************"!

	"Put class initializations here (NOTE: verify these and check ordering):"!
	ArrowHead initialize!
	BusyCursor initialize!
	EquationTranslator initialize!
	Strength initialize!
	ThingLabII initialize!
	Thing initialize!
	PrimitiveThing initialize!
	ModuleCompilerView initialize!
	ThingLabIIControlPanel initialize!
	PartsBin initialize!

	"Initialize the ScreenController yellow button menu:"!
	ScreenController initialize!
	"ScreenController allInstancesDo: [: c | c initializeYellowButtonMenu]"!

"Th-th-that's all, Folks..."!

!DisplayMedium methodsFor: 'ThingLab compatibility'!

white: aRectangle 
	self fillWhite: aRectangle.!

white
	self fillWhite.!

gray: aRectangle
	self fillGray: aRectangle.!

lightGray: aRectangle 
	self fillLightGray: aRectangle.!

lightGray
	self fillLightGray.!

fillLightGray
	self fill: self boundingBox fillColor: Color lightGray.!

black: aRectangle 
	self fillBlack: aRectangle.!

black
	self fillBlack.! !

!Point methodsFor: 'ThingLab compatibility'!

x: aNumber
    self setX: aNumber setY: y.!
    
y: aNumber
    self setX: x setY: aNumber.!

unitVector
    ^self normalized.! !

!Smalltalk class methodsFor: 'ThingLab compabibility'!

quit
    SmalltalkImage current snapshot: false andQuit: true.! !

!Rectangle methodsFor: 'ThingLab compatibility'!

moveBy: aPoint 
	"Change the corner positions of the receiver so that its area translates by
	the amount defined by the argument, aPoint."
	origin _ origin + aPoint.
	corner _ corner + aPoint!
	
contains: aRect
	^self containsRect: aRect! !

!View methodsFor: 'ThingLab compatibility'!

displaySafe: aBlock
    "Who knows what this method used to be for?"

    ^aBlock value! !

!PluggableTextView class methodsFor: 'ThingLab compatibility'!
on: anObject aspect: aspectMsg change: changeMsg menu: menuMsg
	^ self on: anObject text: aspectMsg accept: changeMsg readSelection: nil menu: menuMsg.! !

!StringHolderView methodsFor: 'ThingLab compatibility'!
getContents
	^model contents!