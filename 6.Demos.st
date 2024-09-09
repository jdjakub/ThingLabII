Object subclass: #RodsDemo
	instanceVariableNames: 'thing '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'TLII-Demos'!
RodsDemo comment:
'This demo shows how history variables may be used to simulate a physical system evolving through time. In this example, we create a three-segment "snake" of semi-rigid rods. The rods try to keep themselves a constant length.'!


!RodsDemo methodsFor: 'public'!

makeDemo
	"RodsDemo new makeDemo"

	self buildThing.
	self addConstraints.

	ThingConstructorView openOn: thing.! !

!RodsDemo methodsFor: 'private'!

addConstraints
	"Add force constraints to the new Thing. RodThings already compute the force vector on each endpoints. If the rod is compressed, this force is outward and if the rod is compressed the force is inward. Try changing the constant multiplier of 'force' in these equations to something higher; if it is too high the system will oscillate like a spring, even though we are not modeling mass and momentum, because the difference equations become unstable. Try it!!"

	thing methods: #(
		'newP _ oldP + (force * 0.3)')
		where: #((newP rod1.p1.value)
				 (oldP rod1.p1.last)
				 (force rod1.p1Force.last))
		strength: #default.

	thing methods: #(
		'newP _ oldP + (force * 0.3)')
		where: #((newP rod3.p2.value)
				 (oldP rod3.p2.last)
				 (force rod3.p2Force.last))
		strength: #default.

	thing methods: #(
		'newP _ oldP + ((force1 + force2) * 0.3)')
		where: #(
			(newP rod2.p2.value)
			(oldP rod2.p2.last)
			(force1 rod1.p2Force.last)
			(force2 rod2.p2Force.last))
		strength: #default.

	thing methods: #(
		'newP _ oldP + ((force1 + force2) * 0.3)')
		where: #(
			(newP rod2.p1.value)
			(oldP rod2.p1.last)
			(force1 rod2.p1Force.last)
			(force2 rod3.p1Force.last))
		strength: #default.!

buildThing
	"Build a Thing consisting of three RodThings connected as follows:
		p1 - rod1 - p2/p2 - rod2 - p1/p1 - rod3 - p2"

	thing _ Thing defineNewThing.
	thing addPartsNamed: #(rod1 rod2 rod3)
		  toHold: (Array
			with: RodThing new
			with: RodThing new
			with: RodThing new).

	thing merge: #rod1.line.p2 with: #rod2.line.p2.
	thing merge: #rod2.line.p1 with: #rod3.line.p1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RodsDemo class
	instanceVariableNames: ''!


Object subclass: #QuadrilateralDemo
	instanceVariableNames: 'thing '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'TLII-Demos'!
QuadrilateralDemo comment:
'This demo builds a four-level deep quadrilateral object. This is somewhat of a classic from the original ThingLab.'!


!QuadrilateralDemo methodsFor: 'public'!

makeDemo
	"QuadrilateralDemo new makeDemo"

	self buildThing.
	self doMerges.
	self addMidPointConstraints.
	self addStays.
	self initializeParts.

	ThingConstructorView openOn: thing.! !

!QuadrilateralDemo methodsFor: 'private'!

addMidPointConstraints
	"Add 12 midpoint constraints for the x's and another 12 for the y's."

	| mp |
	mp _ Constraint
		symbols: #(p1 midPoint p2)
		methodStrings: #(
			'midPoint _ (p1 + p2) // 2'
			'p1 _ (2 * midPoint - p2) rounded'
			'p2 _ (2 * midPoint - p1) rounded').
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p1.x
			with: thing->#p5.x
			with: thing->#p2.x)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p2.x
			with: thing->#p6.x
			with: thing->#p3.x)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p3.x
			with: thing->#p7.x
			with: thing->#p4.x)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p4.x
			with: thing->#p8.x
			with: thing->#p1.x)
		 strength: #strongPreferred).

	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p5.x
			with: thing->#p10.x
			with: thing->#p6.x)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p6.x
			with: thing->#p11.x
			with: thing->#p7.x)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p7.x
			with: thing->#p12.x
			with: thing->#p8.x)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p8.x
			with: thing->#p9.x
			with: thing->#p5.x)
		 strength: #strongPreferred).

	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p9.x
			with: thing->#p13.x
			with: thing->#p10.x)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p10.x
			with: thing->#p14.x
			with: thing->#p11.x)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p11.x
			with: thing->#p15.x
			with: thing->#p12.x)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p12.x
			with: thing->#p16.x
			with: thing->#p9.x)
		 strength: #strongPreferred).

	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p1.y
			with: thing->#p5.y
			with: thing->#p2.y)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p2.y
			with: thing->#p6.y
			with: thing->#p3.y)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p3.y
			with: thing->#p7.y
			with: thing->#p4.y)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p4.y
			with: thing->#p8.y
			with: thing->#p1.y)
		 strength: #strongPreferred).

	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p5.y
			with: thing->#p10.y
			with: thing->#p6.y)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p6.y
			with: thing->#p11.y
			with: thing->#p7.y)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p7.y
			with: thing->#p12.y
			with: thing->#p8.y)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p8.y
			with: thing->#p9.y
			with: thing->#p5.y)
		 strength: #strongPreferred).

	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p9.y
			with: thing->#p13.y
			with: thing->#p10.y)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p10.y
			with: thing->#p14.y
			with: thing->#p11.y)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p11.y
			with: thing->#p15.y
			with: thing->#p12.y)
		 strength: #strongPreferred).
	thing addConstraint:
		(mp clone bind: (Array
			with: thing->#p12.y
			with: thing->#p16.y
			with: thing->#p9.y)
		 strength: #strongPreferred).!

addStays
	"Add 24 Stay constraints to keep things under control..."

	thing strongDefaultStay: #p1.x.
	thing strongDefaultStay: #p2.x.
	thing strongDefaultStay: #p3.x.
	thing strongDefaultStay: #p4.x.
	thing strongDefaultStay: #p1.y.
	thing strongDefaultStay: #p2.y.
	thing strongDefaultStay: #p3.y.
	thing strongDefaultStay: #p4.y.
	thing defaultStay: #p5.x.
	thing defaultStay: #p6.x.
	thing defaultStay: #p7.x.
	thing defaultStay: #p8.x.
	thing defaultStay: #p5.y.
	thing defaultStay: #p6.y.
	thing defaultStay: #p7.y.
	thing defaultStay: #p8.y.
	thing weakDefaultStay: #p9.x.
	thing weakDefaultStay: #p10.x.
	thing weakDefaultStay: #p11.x.
	thing weakDefaultStay: #p12.x.
	thing weakDefaultStay: #p9.y.
	thing weakDefaultStay: #p10.y.
	thing weakDefaultStay: #p11.y.
	thing weakDefaultStay: #p12.y.!

buildThing
	"Create an empty Thing and add sixteen lines and sixteen points."

	| parts |
	thing _ Thing defineNewThing.
	parts _ (1 to: 4) collect: [: i | PointThing new].
	thing addPartsNamed: #(p1 p2 p3 p4) toHold: parts.
	parts _ (1 to: 4) collect: [: i | PointThing new].
	thing addPartsNamed: #(p5 p6 p7 p8) toHold: parts.
	parts _ (1 to: 4) collect: [: i | PointThing new].
	thing addPartsNamed: #(p9 p10 p11 p12) toHold: parts.
	parts _ (1 to: 4) collect: [: i | PointThing new].
	thing addPartsNamed: #(p13 p14 p15 p16) toHold: parts.

	parts _ (1 to: 4) collect: [: i | LineThing new].
	thing addPartsNamed: #(l1 l2 l3 l4) toHold: parts.
	parts _ (1 to: 4) collect: [: i | LineThing new].
	thing addPartsNamed: #(l5 l6 l7 l8) toHold: parts.
	parts _ (1 to: 4) collect: [: i | LineThing new].
	thing addPartsNamed: #(l9 l10 l11 l12) toHold: parts.
	parts _ (1 to: 4) collect: [: i | LineThing new].
	thing addPartsNamed: #(l13 l14 l15 l16) toHold: parts.!

doMerges
	"Connect-the-dots with merges..."

	thing merge: #l1.p1 with: #p1.
	thing merge: #l1.p2 with: #p2.
	thing merge: #l2.p1 with: #p2.
	thing merge: #l2.p2 with: #p3.
	thing merge: #l3.p1 with: #p3.
	thing merge: #l3.p2 with: #p4.
	thing merge: #l4.p1 with: #p4.
	thing merge: #l4.p2 with: #p1.

	thing merge: #l5.p1 with: #p5.
	thing merge: #l5.p2 with: #p6.
	thing merge: #l6.p1 with: #p6.
	thing merge: #l6.p2 with: #p7.
	thing merge: #l7.p1 with: #p7.
	thing merge: #l7.p2 with: #p8.
	thing merge: #l8.p1 with: #p8.
	thing merge: #l8.p2 with: #p5.

	thing merge: #l9.p1 with: #p9.
	thing merge: #l9.p2 with: #p10.
	thing merge: #l10.p1 with: #p10.
	thing merge: #l10.p2 with: #p11.
	thing merge: #l11.p1 with: #p11.
	thing merge: #l11.p2 with: #p12.
	thing merge: #l12.p1 with: #p12.
	thing merge: #l12.p2 with: #p9.

	thing merge: #l13.p1 with: #p13.
	thing merge: #l13.p2 with: #p14.
	thing merge: #l14.p1 with: #p14.
	thing merge: #l14.p2 with: #p15.
	thing merge: #l15.p1 with: #p15.
	thing merge: #l15.p2 with: #p16.
	thing merge: #l16.p1 with: #p16.
	thing merge: #l16.p2 with: #p13.!

initializeParts
	"Initialize the outer four points and let constraints do the rest."

	thing set: #p1.x to: 20.
	thing set: #p1.y to: 20.
	thing set: #p2.x to: 20.
	thing set: #p2.y to: 120.
	thing set: #p3.x to: 150.
	thing set: #p3.y to: 120.
	thing set: #p4.x to: 150.
	thing set: #p4.y to: 20.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

QuadrilateralDemo class
	instanceVariableNames: ''!


MultiThingAdaptor subclass: #SortingDemo
	instanceVariableNames: 'array seed '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'TLII-Demos'!


!SortingDemo methodsFor: 'public'!

makeDemo: size
	"SortingDemo new makeDemo: 5"

	self buildArray: size.
	self buildButtons.
	MultiThingView openOn: self.! !

!SortingDemo methodsFor: 'sorting'!

bubbleSort: aView

	| lower upper temp |
	2 to: array size do:
		[: i |
		 upper _ i.
		 lower _ upper - 1.
		 [(lower > 0) and:
		   [(array at: upper) extent x < (array at: lower) extent x]] whileTrue:
			[self swap: (array at: upper) with: (array at: lower) in: aView.
			 temp _ array at: lower.
			 array at: lower put: (array at: upper).
			 array at: upper put: temp.
			 upper _ upper - 1.
			 lower _ upper - 1]].!

findPivotFrom: start to: stop
	"Answer the index of the largest of the leftmost of the first two different keys or zero if all keys from start through stop are identical."

	| firstKey |
	firstKey _ (array at: start) extent x .
	(start + 1) to: stop do:
		[: i |
		 ((array at: i) extent x > firstKey)
			ifTrue: [^i]
			ifFalse:
				[((array at: i) extent x < firstKey)
					ifTrue: [^start]]].
	^0	"all keys are the same"!

insertionSort: aView

	| j bar1 bar2 |
	2 to: array size do:
		[: i |
		 j _ i.
		 [(j > 1) and:
		  [bar1 _ array at: j.
		   bar2 _ array at: j - 1.
		   bar2 extent x > bar1 extent x]] whileTrue:
			[self swap: bar1 with: bar2 in: aView.
			 array at: j put: bar2.
			 array at: (j - 1) put: bar1.
			 j _ j - 1]].!

partitionBy: pivotKey from: start to: stop in: aView
	"Partition the sub-array from start to stop using the given pivot key. After this operation, all elements whose keys are less than pivotKey will be to the left of those whose keys are the same or equal to pivotKey."

	| left right temp |
	left _ start.
	right _ stop.
	[true] whileTrue:
		["scan left and right"
		 [(array at: left) extent x < pivotKey] whileTrue: [left _ left + 1].
		 [(array at: right) extent x >= pivotKey] whileTrue: [right _ right - 1].
		 (left > right) ifTrue:
			["partitioning complete"
			 ^left].
		 "swap"
		 self swap: (array at: left) with: (array at: right) in: aView.
		 temp _ array at: left.
		 array at: left put: (array at: right).
		 array at: right put: temp].!

quickSortFrom: start to: stop in: aView

	| pivotIndex pivotKey splitIndex |
	pivotIndex _ self findPivotFrom: start to: stop.
	(pivotIndex ~= 0) ifTrue:
		["do this only if there was more than one key"
		 pivotKey _ (array at: pivotIndex) extent x.
		 splitIndex _ self partitionBy: pivotKey from: start to: stop in: aView.
		 self quickSortFrom: start to: (splitIndex - 1) in: aView.
		 self quickSortFrom: splitIndex to: stop in: aView].!

selectionSort: aView

	| low lowKey temp |
	1 to: array size - 1 do:
		[: i |
		 low _ i.
		 lowKey _ (array at: i) extent x.
		 (i + 1) to: (array size) do:
			[: j |
			 ((array at: j) extent x < lowKey) ifTrue:
				[low _ j.
				 lowKey _ (array at: j) extent x]].
		self swap: (array at: i) with: (array at: low) in: aView.
		temp _ array at: i.
		array at: i put: (array at: low).
		array at: low put: temp].!

swap: bar1 with: bar2 in: aView

	| inputConstraints y1 y2 delta |
	inputConstraints _ (Array
		with: (EditConstraint ref: bar1->#center.y)
		with: (EditConstraint ref: bar2->#center.y)).
	aView controller addInputConstraints: inputConstraints.
	aView controller makePlan.
	y1 _ bar1 center y.
	y2 _ bar2 center y.
	delta _ (y2 - y1) // 6.
	4 timesRepeat:
		[bar1 center primy: (bar1 center y + delta).
		 bar2 center primy: (bar2 center y - delta).
		aView controller executeAndRedisplay].
	bar1 center primy: y2.
	bar2 center primy: y1.
	aView controller executeAndRedisplay.
	aView controller removeInputConstraints: inputConstraints.! !

!SortingDemo methodsFor: 'other operations'!

randomize: aView

	seed _ Time millisecondClockValue.
	self initializeBars.
	aView displayScene.!

reset: aView

	self initializeBars.
	aView displayScene.! !

!SortingDemo methodsFor: 'private'!

buildArray: count

	| center width bar |
	center _ ((NodeMinusNodes new) preferStay: #value; primvalue: 180)->#value.
	width _ ((NodeMinusNodes new) preferStay: #value; primvalue: 3)->#value.
	array _ (1 to: count) collect:
		[: i |
		 bar _ RectThing new.
		 bar set: #fillMask to: Color black.
		 EqualityConstraint require: bar->#center.x equals: center.
		 EqualityConstraint require: bar->#extent.y equals: width.
		 self addGlyph: bar.
		 bar].
	seed _ Time millisecondClockValue.
	self initializeBars.!

buildButtons

	self addGlyph: ((ButtonThingMinusNodes new)
		set: #text.node.value to: ' Reset ';
		set: #text.box.topLeft.x to: 20;
		set: #text.box.topLeft.y to: 20;
		set: #action to: [: view | view model reset: view]).
	self addGlyph: ((ButtonThingMinusNodes new)
		set: #text.node.value to: ' Bubble Sort ';
		set: #text.box.topLeft.x to: 20;
		set: #text.box.topLeft.y to: 40;
		set: #action to: [: view | view model bubbleSort: view]).
	self addGlyph: ((ButtonThingMinusNodes new)
		set: #text.node.value to: ' Selection Sort ';
		set: #text.box.topLeft.x to: 20;
		set: #text.box.topLeft.y to: 60;
		set: #action to: [: view | view model selectionSort: view]).
	self addGlyph: ((ButtonThingMinusNodes new)
		set: #text.node.value to: ' Insertion Sort ';
		set: #text.box.topLeft.x to: 20;
		set: #text.box.topLeft.y to: 80;
		set: #action to: [: view | view model insertionSort: view]).
	self addGlyph: ((ButtonThingMinusNodes new)
		set: #text.node.value to: ' Quick Sort ';
		set: #text.box.topLeft.x to: 20;
		set: #text.box.topLeft.y to: 100;
		set: #action to:
			[: view | view model quickSortFrom: 1 to: array size in: view]).
	self addGlyph: ((ButtonThingMinusNodes new)
		set: #text.node.value to: ' Randomize ';
		set: #text.box.topLeft.x to: 20;
		set: #text.box.topLeft.y to: 120;
		set: #action to: [: view | view model randomize: view]).!

initializeBars

	| bar random |
	random _ Random seed: seed. 
	1 to: array size do:
		[: i |
		 bar _ array at: i.
		 bar set: #extent.x to: (4 + (2 * (random next * 50.0) rounded)).
		 bar set: #center.y to: 20 + (8 * i)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SortingDemo class
	instanceVariableNames: ''!


Object subclass: #MusicDemo
	instanceVariableNames: 'thing pitchC stemDirC timeC timeLocC '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'TLII-Demos'!
MusicDemo comment:
'This demo shows how constraints may be used to handle a simple musical layout problem. Notes are related to each other temporally and their position is related to the time and pitch, within the context of a musical staff.'!


!MusicDemo methodsFor: 'public'!

makeDemo
	"MusicDemo new makeDemo"

	| treble bass firstNoteOfStaff lastNote |
	self buildConstraints.
	thing _ Thing defineNewThing.
	treble _ self newTrebleStaffAt: 20@40 width: 370.
	firstNoteOfStaff _ self newPitch: 67 type: #q staff: treble.
	lastNote _ self addPitch: 71 type: #h after: firstNoteOfStaff staff: treble.
	lastNote _ self addPitch: 69 type: #q after: lastNote staff: treble.
	lastNote _ self addPitch: 71 type: #q after: lastNote staff: treble.
	lastNote _ self addPitch: 72 type: #h after: lastNote staff: treble.
	lastNote _ self addPitch: 74 type: #h after: lastNote staff: treble.
	lastNote _ self addPitch: 74 type: #h after: lastNote staff: treble.
	lastNote _ self addPitch: 72 type: #h after: lastNote staff: treble.
	lastNote _ self addPitch: 71 type: #h after: lastNote staff: treble.
	lastNote _ self addPitch: 69 type: #q after: lastNote staff: treble.
	lastNote _ self addPitch: 71 type: #q after: lastNote staff: treble.

	firstNoteOfStaff set: #time to: 0.
	bass _ self newBassStaffAt: 20@70 width: 370.
	firstNoteOfStaff _ self newPitch: 47 type: #h staff: bass.
	lastNote _ self addPitch: 59 type: #w after: firstNoteOfStaff staff: bass.
	lastNote _ self addPitch: 59 type: #h after: lastNote staff: bass.
	lastNote _ self addPitch: 59 type: #q after: lastNote staff: bass.
	lastNote _ self addPitch: 59 type: #q after: lastNote staff: bass.
	lastNote _ self addPitch: 59 type: #h after: lastNote staff: bass.
	lastNote _ self addPitch: 59 type: #h after: lastNote staff: bass.
	lastNote _ self addPitch: 59 type: #h after: lastNote staff: bass.
	lastNote _ self addPitch: 59 type: #h after: lastNote staff: bass.
	firstNoteOfStaff set: #time to: 0.
	self destroyConstraints.
	ThingConstructorView openOn: thing.! !

!MusicDemo methodsFor: 'private'!

addPitch: pitch type: aSymbol after: lastNote staff: staff

	| note |
	note _ self newPitch: pitch type: aSymbol staff: staff.
	thing addConstraint:
		(timeC clone bind: (Array
			with: lastNote->#time
			with: lastNote->#duration
			with: note->#time)
		strength: #strongPreferred).
	^note!

buildConstraints
	"Create prototype constraints."

	pitchC _ Constraint
		symbols: #(staffY middleC pitch noteY)
		methodStrings: #(
			'noteY _ staffY + middleC - ((pitch - 60) * 2)'
			'pitch _ 60 + (((staffY + middleC) - noteY) // 2)').
	stemDirC _ Constraint
		symbols: #(noteY staffY stemDir)
		methodStrings: #(
			'stemDir _ ((noteY - staffY) >= 10) ifTrue: [#up] ifFalse: [#down]').
	timeC _ Constraint
		symbols: #(lastStartTime lastDur startTime)
		methodStrings: #(
			'startTime _ lastStartTime + lastDur'
			'lastStartTime _ startTime - lastDur').
	timeLocC _ Constraint
		symbols: #(staffX startTime noteX)
		methodStrings: #(
			'noteX _ staffX + 30 + (startTime // 3)'
			'startTime _ (noteX - staffX - 30) * 3').!

destroyConstraints

	pitchC destroy.
	stemDirC destroy.
	timeC destroy.
	timeLocC destroy.!

newBassStaffAt: aPoint width: width

	| staff |
	staff _ BassClefThing new.
	thing addThing: staff.
	staff set: #location.x to: aPoint x.
	staff set: #location.y to: aPoint y.
	staff set: #width to: width.
	^staff!

newPitch: pitch type: aSymbol staff: staff

	| note |
	note _ NoteThing new.
	thing addThing: note.
	note set: #pitch to: pitch.
	note set: #time to: 0.
	note set: #type to: (self symToType: aSymbol).
	note defaultStay: #pitch.
	note defaultStay: #time.
	thing addConstraint:
		(pitchC clone bind: (Array
			with: staff->#location.y
			with: staff->#middleCOffset
			with: note->#pitch
			with: note->#location.y)
		strength: #required).
	thing addConstraint:
		(stemDirC clone bind: (Array
			with: note->#location.y
			with: staff->#location.y
			with: note->#stemDirection)
		strength: #required).
	thing addConstraint:
		(timeLocC clone bind: (Array
			with: staff->#location.x
			with: note->#time
			with: note->#location.x)
		strength: #required).
	^note!

newTrebleStaffAt: aPoint width: width

	| staff |
	staff _ TrebleClefThing new.
	thing addThing: staff.
	staff set: #location.x to: aPoint x.
	staff set: #location.y to: aPoint y.
	staff set: #width to: width.
	^staff!

symToType: aSymbol

	(aSymbol == #s) ifTrue: [^1].
	(aSymbol == #e) ifTrue: [^2].
	(aSymbol == #q) ifTrue: [^3].
	(aSymbol == #h) ifTrue: [^4].
	(aSymbol == #w) ifTrue: [^5].
	^3	"default is quarter note"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MusicDemo class
	instanceVariableNames: ''!


Object subclass: #ChessBoardDemo
	instanceVariableNames: 'thing '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'TLII-Demos'!


!ChessBoardDemo methodsFor: 'public'!

makeDemo
	"Note: This demo involves a large number of constraints (126 equality constraints and 256 internal rectangle constraints) so it is somewhat slower than most of the other demos. Because all the constraints are interconnected, the entire constraint graph is traversed when any point is moved with the mouse."
	"ChessBoardDemo new makeDemo"

	self buildThing.
	self addLayoutConstraints.
	ThingConstructorView openOn: thing.! !

!ChessBoardDemo methodsFor: 'private'!

addLayoutConstraints
	"Add the layout constraints to 'glue' the squares together. While we're at it, make the square colors alternate."

	| black previousSquare square |
	black _ true.
	1 to: 8 do:
		[: row |
		 previousSquare _ nil.
		 black _ black not.
		 1 to: 8 do:
			[: col |
			 square _ thing perform:
				(('r', row printString, 'c', col printString) asSymbol).
			 square set: #fillRule to: (Form over).
			 square set: #fillMask to:
				((black) ifTrue: [Color black] ifFalse: [Color lightGray]).
			 (previousSquare isNil)
				ifTrue:
					["this is the first square of a new row"
					 square offset: #bottomRight.y by: 25 from: #topLeft.y]
				ifFalse:
					["link to the previous square in this row"
					 EqualityConstraint
						require: square->#topLeft.y
						equals: previousSquare->#topLeft.y.
				 	 EqualityConstraint
						require: square->#bottomRight.y
						equals: previousSquare->#bottomRight.y].
			 black _ black not.	"toggle color of next square"
			 previousSquare _ square]].

	1 to: 8 do:
		[: col |
		 previousSquare _ nil.
		 1 to: 8 do:
			[: row |
			 square _ thing perform:
				(('r', row printString, 'c', col printString) asSymbol).
			 (previousSquare isNil)
				ifTrue:
					["this is the first square of a new column"
					 square offset: #bottomRight.x by: 25 from: #topLeft.x]
				ifFalse:
					["link to the previous square in this column"
					 EqualityConstraint
						require: square->#topLeft.x
						equals: previousSquare->#topLeft.x.
				 	EqualityConstraint
						require: square->#bottomRight.x
						equals: previousSquare->#bottomRight.x].
			 previousSquare _ square]].

	previousSquare _ thing perform: #r1c1.
	2 to: 8 do:
		[: i |
		 square _ thing perform: (('r', i printString, 'c', i printString) asSymbol).
		 EqualityConstraint
			require: previousSquare->#bottomRight.x
			equals: square->#topLeft.x.
		 EqualityConstraint
			require: previousSquare->#bottomRight.y
			equals: square->#topLeft.y.
		 previousSquare _ square].

	"position the board as a whole"
	thing set: #r1c1.topLeft.x to: 30.
	thing set: #r1c1.topLeft.y to: 30.!

buildThing
	"Construct a chess board from 64 sqare rectangles labeled 'r1c1 through 'r8c8'."

	| names squares |
	thing _ Thing defineNewThing.
	names _ OrderedCollection new.
	squares _ OrderedCollection new.

	"first, build a list of square names and squares to add..."
	1 to: 8 do:
		[: row |
		 1 to: 8 do:
			[: col |
			 names add: ('r', row printString, 'c', col printString) asSymbol.
			 squares add:
				(SimpleRectThing new
					set: #extent.x to: 25;
					set: #extent.y to: 25)]].

	"then, add them"
	thing addPartsNamed: names toHold: squares.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ChessBoardDemo class
	instanceVariableNames: ''!


Object subclass: #BrowserDemo
	instanceVariableNames: 'thing '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'TLII-Demos'!


!BrowserDemo methodsFor: 'public'!

makeDemo
	"BrowserDemo new makeDemo"

	thing _ Thing defineNewThing.
	thing addPartsNamed: #(pane1 pane2 pane3 pane4 methodPane) toHold:
		(Array
			with: ScrollingListThingMinusNodes new
			with: ScrollingListThingMinusNodes new
			with: ScrollingListThingMinusNodes new
			with: ScrollingListThingMinusNodes new),
		(Array
			with: ParagraphThingMinusNodes new).

	self addLayoutConstraints.
	self doInitialPlacement.
	self addPaneToPaneConstraints.
	thing set: #pane1.itemsList.value to: (SystemOrganization categories).
	ThingConstructorView openOn: thing.! !

!BrowserDemo methodsFor: 'private'!

addLayoutConstraints

	thing require: #pane1.box.topLeft.y
		  equals: #pane2.box.topLeft.y.
	thing require: #pane1.box.bottomRight.y
		  equals: #pane2.box.bottomRight.y.
	thing require: #pane1.box.bottomRight.x
		  equals: #pane2.scrollBar.box.topLeft.x.

	thing require: #pane3.box.topLeft.y
		  equals: #pane4.box.topLeft.y.
	thing require: #pane3.box.bottomRight.y
		  equals: #pane4.box.bottomRight.y.
	thing require: #pane3.box.bottomRight.x
		  equals: #pane4.scrollBar.box.topLeft.x.

	thing require: #pane1.box.bottomRight.y
		  equals: #pane3.box.topLeft.y.
	thing require: #pane1.box.topLeft.x
		  equals: #pane3.box.topLeft.x.

	thing require: #pane2.box.topLeft.x
		  equals: #pane4.box.topLeft.x.
	thing require: #pane2.box.bottomRight.x
		  equals: #pane4.box.bottomRight.x.

	thing require: #pane3.scrollBar.box.topLeft.x
		  equals: #methodPane.box.topLeft.x.
	thing require: #pane4.box.bottomRight.x
		  equals: #methodPane.box.bottomRight.x.
	thing require: #pane4.box.bottomRight.y
		  equals: #methodPane.box.topLeft.y.!

addPaneToPaneConstraints

	"if a class category is selected, comute its class list"
	thing methods: #(
			'classes _ (classCat isNil)
				ifTrue: [#()]
				ifFalse: [SystemOrganization listAtCategoryNamed: classCat]')
		where: #(
			(classCat pane1.selectedItem.value)
			(classes pane2.itemsList.value))
		strength: #preferred.

	"if a class is selected, compute its message categories
	 otherwise, the message categories list is empty"
	thing methods: #(
			'methodCats _ (className isNil)
				ifTrue: [#()]
				ifFalse: [(Smalltalk at: className) organization categories]')
		where: #(
			(className pane2.selectedItem.value)
			(methodCats pane3.itemsList.value))
	 	strength: #preferred.

	"if a class and method category are selected, compute the message list
	 otherwise, the message list is empty"
	thing methods: #(
			'methods _ (className isNil | methodCat isNil)
				ifTrue: [#()]
				ifFalse: [(Smalltalk at: className) organization
							listAtCategoryNamed: methodCat]')
		where: #(
			(className pane2.selectedItem.value)
			(methodCat pane3.selectedItem.value)
			(methods pane4.itemsList.value))
		strength: #preferred.

	"if a class and method are selected, get the method text
	 otherwise, the method pane is empty"
	thing methods: #(
			'methodText _ (className isNil | methodName isNil)
				ifTrue: ['''']
				ifFalse:
					[((className = oldClassName) &
					 (methodName = oldMethodName))
						ifTrue: [oldMethodText]
						ifFalse:
							[(Smalltalk at: className)
								sourceCodeAt: methodName]]')
		where: #(
			(className pane2.selectedItem.value)
			(oldClassName pane2.selectedItem.last)
			(methodName pane4.selectedItem.value)
			(oldMethodName pane4.selectedItem.last)
			(methodText methodPane.node.value)
			(oldMethodText methodPane.node.last))
		strength: #preferred.!

doInitialPlacement

	thing set: #pane1.scrollBar.box.topLeft.x to: 20.	"left"
	thing set: #pane2.scrollBar.box.topLeft.x to: 220.	"middle"
	thing set: #pane2.box.bottomRight.x to: 420.		"right"

	thing set: #pane1.scrollBar.box.topLeft.y to: 20.	"top"
	thing set: #pane3.scrollBar.box.topLeft.y to: 85.	"middle"
	thing set: #methodPane.box.topLeft.y to: 150.	"top of method pane"
	thing set: #methodPane.box.bottomRight.y to: 320. "bottom of method pane"! !

Object subclass: #TableDemo
	instanceVariableNames: 'thing columnIndex lastColumnIndex lastColumnEdge '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'TLII-Demos'!
TableDemo comment:
'This example shows how constraints may be used to build the graphical skeleton of a simple table using horizontal and vertical lines and TextThings. Try changing one of the column labels by selecting it and typing (be patient, there are lots of constraints to solve).'!


!TableDemo methodsFor: 'public'!

makeDemo
	"TableDemo new makeDemo"

	self basicOutline.
	#(apples oranges frobitzes) do:
		[: heading |
		 self addColumnNamed: heading asString lastColumn: false].
	self addColumnNamed: 'total' lastColumn: true.

	ThingConstructorView openOn: thing.! !

!TableDemo methodsFor: 'private'!

addColumnNamed: aString lastColumn: lastColumnFlag

	| header divider |
	columnIndex _ columnIndex + 1.
	header _ ('header', columnIndex printString) asSymbol.
	thing addPartsNamed: (Array with: header)
		  toHold: (Array with: (TextThing newWith: ' ', aString, ' ')).
	thing require: (header, '.box.topLeft.x') asSymbol
		  equals: (lastColumnEdge, '.p1.x') asSymbol.
	thing require: (header, '.box.topLeft.y') asSymbol equals: #top.p1.y.
	lastColumnFlag
		ifTrue:
			[thing require: (header, '.box.bottomRight.x') asSymbol
				   equals: #right.p1.x]
		ifFalse:
			[divider _ ('columnDivider', columnIndex printString) asSymbol.
			 thing addPartsNamed: (Array with: divider)
				   toHold: (Array with: VLine new).
			 thing require: (header, '.box.bottomRight.x') asSymbol
			  	equals: (divider, '.p1.x') asSymbol.
			 thing require: ((divider, '.p1.y') asSymbol) equals: #left.p1.y.
			 thing require: ((divider, '.p2.y') asSymbol) equals: #left.p2.y.
			 lastColumnEdge _ divider].!

basicOutline
	"Make the basic outline of the table."

	thing _ Thing defineNewThing.
	thing addPartsNamed: #(left right)
			toHold: (Array
				with: (VLine new)
				with: (VLine new)).
	thing addPartsNamed: #(top divider bottom)
			toHold: (Array
				with: (HLine new)
				with: (HLine new)
				with: (HLine new)).

	thing merge: #left.p1 with: #top.p1.
	thing merge: #right.p1 with: #top.p2.
	thing merge: #left.p2 with: #bottom.p1.
	thing merge: #right.p2 with: #bottom.p2.

	thing require: #top.p1.x equals: #divider.p1.x.
	thing require: #top.p2.x equals: #divider.p2.x.
	thing offset: #divider.p1.y by: 15 from: #top.p1.y.
	thing defaultStay: #top.p1.x.
	thing defaultStay: #top.p1.y.

	thing set: #top.p1.x to: 20.
	thing set: #top.p1.y to: 20.
	thing set: #bottom.p1.x to: 20.
	thing set: #bottom.p1.y to: 120.

	columnIndex _ 0.
	lastColumnEdge _ #left.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TableDemo class
	instanceVariableNames: ''!


Object subclass: #OrbitDemo
	instanceVariableNames: 'thing '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'TLII-Demos'!


!OrbitDemo methodsFor: 'public'!

makeDemo
	"OrbitDemo new makeDemo"

	thing _ Thing defineNewThing.
	thing addPartsNamed: #(orbit radius rate)
			  toHold: (Array
				with: OrbitThing new
				with: VSliderThingMinusNodes new
				with: VSliderThingMinusNodes new).

	thing require: #orbit.radius.node.value equals: #radius.node.value.
	thing require: #orbit.rate.node.value equals: #rate.node.value.

	thing set: #radius.node.location.x to: 67.
	thing set: #radius.node.location.y to: 55.
	thing set: #radius.minVal to: 0.0.
	thing set: #radius.maxVal to: 100.0.

	thing set: #rate.node.location.x to: 82.
	thing set: #rate.node.location.y to: 55.
	thing set: #rate.minVal to: 0.0.
	thing set: #rate.maxVal to: 60.0.

	thing set: #orbit.center.x to: 100.
	thing set: #orbit.center.y to: 100.

	ThingConstructorView openOn: thing.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OrbitDemo class
	instanceVariableNames: ''!


Object subclass: #TreeDemo
	instanceVariableNames: 'thing aboveC belowC leafWidthC leftXLocationC rightXLocationC widthC yLocationC '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'TLII-Demos'!


!TreeDemo methodsFor: 'public'!

makeDemo
	"TreeDemo new makeDemo"

	self buildConstraints.
	self buildThing.
	self addConstraints.
	self destroyConstraints.

	ThingConstructorView openOn: thing.! !

!TreeDemo methodsFor: 'private'!

addConstraints

	self addLeafConstraint: 'n4'.
	self addLeafConstraint: 'n5'.
	self addLeafConstraint: 'n6'.
	self addLeafConstraint: 'n7'.
	self addWidthConstraint: 'n3' left: 'n6' right: 'n7'.
	self addWidthConstraint: 'n2' left: 'n4' right: 'n5'.
	self addWidthConstraint: 'n1' left: 'n2' right: 'n3'.
	self addRootConstraints: 'n1'.
	self addLocationConstraints: 'n1' left: 'n2' right: 'n3'.
	self addLocationConstraints: 'n2' left: 'n4' right: 'n5'.
	self addLocationConstraints: 'n3' left: 'n6' right: 'n7'.!

addLeafConstraint: leaf

	(leafWidthC clone
		bind: (Array
			with: thing->(leaf, '.width') asSymbol
			with: thing->(leaf, '.text.node.value') asSymbol)
		strength: #required) addConstraint.!

addLocationConstraints: parent left: left right: right

	(leftXLocationC clone
		bind: (Array
			with: thing->(left, '.text.box.center.x') asSymbol
			with: thing->(parent, '.text.box.center.x') asSymbol
			with: thing->(parent, '.width') asSymbol)
		strength: #required) addConstraint.

	(yLocationC clone
		bind: (Array
			with: thing->(left, '.text.box.center.y') asSymbol
			with: thing->(parent, '.text.box.center.y') asSymbol)
		strength: #required) addConstraint.

	(rightXLocationC clone
		bind: (Array
			with: thing->(right, '.text.box.center.x') asSymbol
			with: thing->(parent, '.text.box.center.x') asSymbol
			with: thing->(parent, '.width') asSymbol)
		strength: #required) addConstraint.

	(yLocationC clone
		bind: (Array
			with: thing->(right, '.text.box.center.y') asSymbol
			with: thing->(parent, '.text.box.center.y') asSymbol)
		strength: #required) addConstraint.!

addRootConstraints: root

	thing set: #n1.text.box.center.x to: 100.
	thing set: #n1.text.box.center.y to: 30.
	thing defaultStay: #n1.text.box.center.x.
	thing defaultStay: #n1.text.box.center.y.!

addWidthConstraint: parent left: left right: right

	| lineThing |
	(widthC clone
		bind: (Array
			with: thing->(parent, '.width') asSymbol
			with: thing->(parent, '.text.node.value') asSymbol
			with: thing->(left, '.width') asSymbol
			with: thing->(right, '.width') asSymbol)
		strength: #required) addConstraint.

	(Array with: left with: right) do:
		[: child |
		 lineThing _ PlainLine new.
		 thing addThing: lineThing.
		 (EqualityConstraint
			ref: thing->(parent, '.text.box.center.x') asSymbol
			ref: lineThing->#p1.x
			strength: #required) addConstraint.
		 (aboveC clone
			bind: (Array
				with: thing->(parent, '.text.box.center.y') asSymbol
				with: lineThing->#p1.y)
			strength: #required) addConstraint.
		 (EqualityConstraint
			ref: lineThing->#p2.x
			ref: thing->(child, '.text.box.center.x') asSymbol
				strength: #required) addConstraint.
		(aboveC clone
			bind: (Array
				with: lineThing->#p2.y
				with: thing->(child, '.text.box.center.y') asSymbol)
			strength: #required) addConstraint].!

buildConstraints
	"Create prototype constraints."

	widthC _ (Constraint
		symbols: #(width text leftWidth rightWidth)
		methodStrings: #(
			'width _ ((text asParagraph asForm extent x) + 16)
				max: ((leftWidth max: rightWidth) * 2)')).
	leafWidthC _ (Constraint
		symbols: #(width text)
		methodStrings: #(
			'width _ (text asParagraph asForm extent x) + 16')).
	leftXLocationC _ (Constraint
		symbols: #(x parentX parentWidth)
		methodStrings: #(
			'x _ (parentX - (parentWidth // 4))'
			'parentX _ x + (parentWidth // 4)')).
	rightXLocationC _ (Constraint
		symbols: #(x parentX parentWidth)
		methodStrings: #(
			'x _ parentX + (parentWidth // 4)'
			'parentX _ x - (parentWidth // 4)')).
	yLocationC _ (Constraint
		symbols: #(y parentY)
		equation: 'y = (parentY + 40)').
	aboveC _ (Constraint
		symbols: #(topY bottomY)
		equation: 'bottomY = (topY + 10)').!

buildThing

	thing _ Thing defineNewThing.
	thing addPartsNamed: #(n1 n2 n3 n4 n5 n6 n7)
			toHold: ((1 to: 7) collect: [: i | TreeNodeThing new]).!

destroyConstraints

	aboveC destroy.
	belowC destroy.
	leafWidthC destroy.
	leftXLocationC destroy.
	rightXLocationC destroy.
	widthC destroy.
	yLocationC destroy.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TreeDemo class
	instanceVariableNames: ''!


Object subclass: #ScopeDemo
	instanceVariableNames: 'thing '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'TLII-Demos'!


!ScopeDemo methodsFor: 'public'!

makeDemo
	"ScopeDemo new makeDemo"

	thing _ Thing defineNewThing.
	thing addPartsNamed: #(scope yScaleSlider yOffsetSlider yScalePrinter yOffsetPrinter)
			toHold:
			   (Array
				with: PenRecorderThing new
				with: VSliderThingMinusNodes new
				with: VSliderThingMinusNodes new),
			   (Array
				with: NumberDisplayer new
				with: NumberDisplayer new).

	self initializeValues.
	self addConstraints.
	self initializeValues.
	self addVisibilityMethod.
	self addSelectabilityMethod.

 	ThingConstructorView openOn: thing.! !

!ScopeDemo methodsFor: 'private'!

addConstraints

	thing require: #yScalePrinter.node.value equals: #scope.scale.value.
	thing require: #yOffsetPrinter.node.value equals: #scope.offset.value.

	thing require: '(10.0 raisedTo: sliderVal) = yScale'
		 where: #((sliderVal yScaleSlider.node.value) (yScale scope.scale.value)).
	thing require: #yOffsetSlider.node.value equals: #scope.offset.value.

	"layout"
	thing offset: #yScalePrinter.node.location.x by: 0
		  from: #yScaleSlider.node.location.x.
	thing offset: #yScalePrinter.node.location.y by: 15
		  from: #yScaleSlider.node.location.y.
	thing offset: #yOffsetPrinter.node.location.x by: 0
		  from: #yOffsetSlider.node.location.x.
	thing offset: #yOffsetPrinter.node.location.y by: 15
		  from: #yOffsetSlider.node.location.y.!

addSelectabilityMethod

	thing class compile:
'selectableGlyphsInto: aSet

	aSet add: yScalePrinter.
	aSet add: yOffsetPrinter.
	scope selectableGlyphsInto: aSet'
		classified: 'glyphs'
		notifying: nil.!

addVisibilityMethod

	thing class
		compile: '
visibleGlyphsInto: aSet

	aSet add: yScaleSlider; add: yScaleSlider box.
	aSet add: yOffsetSlider; add: yOffsetSlider box.
	aSet add: yScalePrinter; add: yScalePrinter box.
	aSet add: yOffsetPrinter; add: yOffsetPrinter box.
	scope visibleGlyphsInto: aSet'
		classified: 'glyphs'
		notifying: nil.!

initializeValues

	thing set: #yScaleSlider.box.extent.x to: 12.
	thing set: #yScaleSlider.box.extent.y to: 80.
	thing set: #yScaleSlider.node.location.x to: 180.
	thing set: #yScaleSlider.node.location.y to: 100.
	thing set: #yScaleSlider.minVal to: -1.0.
	thing set: #yScaleSlider.maxVal to: 1.0.

	thing set: #yOffsetSlider.box.extent.x to: 12.
	thing set: #yOffsetSlider.box.extent.y to: 80.
	thing set: #yOffsetSlider.node.location.x to: 130.
	thing set: #yOffsetSlider.node.location.y to: 100.
	thing set: #yOffsetSlider.minVal to: -200.0.
	thing set: #yOffsetSlider.maxVal to: 200.0.

	thing set: #scope.scale.value to: 1.0.
	thing set: #yScalePrinter.node.value to: 1.0.
	thing set: #yScaleSlider.node.value to: 0.0.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScopeDemo class
	instanceVariableNames: ''!
