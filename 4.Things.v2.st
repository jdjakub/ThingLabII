"ThingLabII Primitive Things of (20 May 1990 3:38:23 pm )"!

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
PrimitiveThing subclass: #PointThing
	instanceVariableNames: 'x y '
	classVariableNames: 'DisplayForm '
	poolDictionaries: ''
	category: 'Things-Primitive'!


!PointThing methodsFor: 'initialization'!

initializeValues

	self set: #x to: 20.
	self set: #y to: 20.! !

!PointThing methodsFor: 'access'!

asPoint

	^x@y!

primx: aValue

	x _ aValue.!

primy: aValue

	y _ aValue.!

x

	^x!

y

	^y! !

!PointThing methodsFor: 'glyphs'!

boundingBox
	"Answer a box around my DisplayForm centered on my location."

	^((x@y) + DisplayForm offset)
		extent: (DisplayForm extent)!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Display my display form at my location."

	DisplayForm
		displayOn: aDisplayMedium
		at: (aDisplayPoint + (x@y))
		clippingBox: clipBox
		rule: (Form paint)
		fillColor: (Color black)!

glyphDependsOn

	^Array with: self!

location
	"That's me!!"

	^self!

selectableGlyphsInto: aSet

	aSet add: self.!

visibleGlyphsInto: aSet

	aSet add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PointThing class
	instanceVariableNames: ''!


!PointThing class methodsFor: 'class initialization'!

initialize
	"PointThing initialize"

	self initializePrimitive.
	partIcon _ Form
		extent: 16@16
		fromArray: #(0 0 0 0 0 896 1984 1984 1984 896 0 0 0 0 0 0 )
		offset: 0@0.
	explainText _ 'A Point is the fundamental unit of location and movement within ThingLabII'.
	DisplayForm _ (Form dotOfSize: 4) offset: -2@-2.! !

PointThing initialize!

PrimitiveThing subclass: #SimpleRectThing
	instanceVariableNames: 'topLeft center bottomRight extent fillMask fillRule '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Private'!


!SimpleRectThing methodsFor: 'initialization'!

initializeStructure

	topLeft _ PointThing cloneFor: self.
	center _ PointThing cloneFor: self.
	bottomRight _ PointThing cloneFor: self.
	extent _ PointThing cloneFor: self.!

initializeValues

	self set: #topLeft.x to: 10.
	self set: #topLeft.y to: 10.
	self set: #extent.x to: 40.
	self set: #extent.y to: 30.
	self set: #bottomRight.x to: 50.
	self set: #bottomRight.y to: 40.
	self set: #fillMask to: nil.	"if fillMask is nil, the rectangle is not filled"
	self set: #fillRule to: Form over.! !

!SimpleRectThing methodsFor: 'access'!

asRectangle

	^topLeft asPoint rounded corner: bottomRight asPoint rounded!

bottomRight

	^bottomRight!

center

	^center!

extent

	^extent!

fillMask

	^fillMask!

fillRule

	^fillRule!

primfillMask: aForm

	fillMask _ aForm.!

primfillRule: aRule

	fillRule _ aRule.!

topLeft

	^topLeft! !

!SimpleRectThing methodsFor: 'glyphs'!

boundingBox
	"Answer my outline rectangle."

	^self asRectangle!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"If fillMask is not nil, the rectangle is filled according to fillRule and fillMask."

	aDisplayMedium border: self boundingBox width: 1.
	(fillMask notNil) ifTrue:
		[aDisplayMedium
			fill: (self boundingBox insetOriginBy: 1@1 cornerBy: 1@1)
			rule: fillRule fillColor: fillMask].!

glyphDependsOn

	^Array
		with: self
		with: topLeft
		with: bottomRight!

selectableGlyphsInto: aSet

	aSet add: topLeft; add: center; add: bottomRight.!

visibleGlyphsInto: aSet

	aSet add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SimpleRectThing class
	instanceVariableNames: ''!


!SimpleRectThing class methodsFor: 'class initialization'!

initialize
	"SimpleRectThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 0 0 0 16380 8196 8196 8196 8196 8196 8196 8196 8196 16380 0 0)
		offset: 0@0).
	explainText _ 'A SimpleRectThing consists of four points (topLeft, center, bottomRight, and extent) and a mask and rule for filling itself with some pattern. If the mask is nil, only its outline is displayed. A SimpleRectThing has no constraints among its parts.'.! !

SimpleRectThing initialize!

PrimitiveThing subclass: #TrebleClefThing
	instanceVariableNames: 'location middleCOffset width '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!TrebleClefThing methodsFor: 'initialization'!

initializeStructure

	location _ PointThing cloneFor: self.!

initializeValues

	self set: #location.x to: 20.
	self set: #location.y to: 40.
	self set: #middleCOffset to: 26.
	self set: #width to: 200.! !

!TrebleClefThing methodsFor: 'access'!

location

	^location!

middleCOffset

	^middleCOffset!

primmiddleCOffset: aNumber

	middleCOffset _ aNumber.!

primwidth: aNumber

	width _ aNumber.!

width

	^width! !

!TrebleClefThing methodsFor: 'glyphs'!

boundingBox

	^(self form computeBoundingBox)
		translateBy: self form offset + location asPoint!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	| offset rect |
	"display clef"
	self form
		displayOn: aDisplayMedium
		at: aDisplayPoint + location asPoint	
		clippingBox: clipBox.

	"display staff"
	0 to: 4 do:
		[: line |
		 offset _ line * 5.
		 rect _ (location asPoint + (0@offset)) extent: width@1.
		 rect _ rect intersect: clipBox.
		 aDisplayMedium black: rect].
	rect _ (location asPoint extent: 1@21) intersect: clipBox.
	aDisplayMedium black: rect.
	rect _ (location asPoint + (width@0) extent: 2@21) intersect: clipBox.
	aDisplayMedium black: rect.!

form

	^Form
		extent: 13@38
		fromArray: #(384 960 832 832 576 576 704 704 896 896 896 1792 3840 7680 15872 14848 29184 29184 59360 59376 53240 51768 51736 52760 50712 25112 12848 6752 4032 512 512 512 12800 31232 31232 29184 25600 14336)
		offset: 7@-9!

glyphDependsOn

	^Array
		with: location
		with: self!

selectableGlyphsInto: aSet

	aSet add: self.!

visibleGlyphsInto: aSet

	aSet add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TrebleClefThing class
	instanceVariableNames: ''!


!TrebleClefThing class methodsFor: 'class initialization'!

initialize
	"TrebleClefThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(128 192 160 192 384 640 1216 2464 2704 2768 2448 1184 960 128 640 256)
		offset: 0@0).
	explainText _ 'A TrebleClefThing is a staff with built in treble clef. The staff width is determined by the width component while the vertical offset of middle C (from the top of the staff) is given by the middleCOffset component.'.! !

TrebleClefThing initialize!

SimpleRectThing subclass: #RectThing
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!RectThing methodsFor: 'initialization'!

initializeConstraints
	"RectThing initialize"

	| c |
	self weakDefaultStay: #extent.x.
	self weakDefaultStay: #extent.y.
	c _ Constraint
		symbols: #(p1 center p2 delta)
		methodStrings: #(
			'p1 _ (center - (delta / 2.0)) rounded.
			   p2 _ (center + (delta / 2.0)) rounded'
			'p1 _ p2 - delta.
			   center _ (p2 - (delta / 2.0)) rounded'
			'p1 _ p2 - ((p2 - center) * 2).
			   delta _ ((p2 - center) * 2)'
			'center _ (p1 + (delta / 2.0)) rounded.
				p2 _ p1 + delta'
			'center _ ((p1 + p2) / 2.0) rounded.
			   delta _ (p2 - p1)'
			'p2 _ p1 + ((center - p1) * 2).
			   delta _ ((center - p1) * 2)').
	self addConstraint:
		(c clone bind: (Array
			with: self->#topLeft.x
			with: self->#center.x
			with: self->#bottomRight.x
			with: self->#extent.x) strength: #required).
	self addConstraint:
		(c clone bind: (Array
			with: self->#topLeft.y
			with: self->#center.y
			with: self->#bottomRight.y
			with: self->#extent.y) strength: #required).! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RectThing class
	instanceVariableNames: ''!


!RectThing class methodsFor: 'class initialization'!

initialize
	"RectThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 0 0 0 16380 8196 8196 8196 8196 8196 8196 8196 8196 16380 0 0)
		offset: 0@0).
	explainText _ 'A RectThing is like a SimpleRectThing but the corners, center, and extent are constrained so that that given any two of these we can compute the others. This generality is expensive, however, so it it best to use one of the more limited varieties of rectangle things (CenterRectThing or FixedRectThing) where appropriate.'.! !

RectThing initialize!

PrimitiveThing subclass: #PointAnchor
	instanceVariableNames: 'point '
	classVariableNames: 'DisplayForm '
	poolDictionaries: ''
	category: 'Things-Primitive'!


!PointAnchor methodsFor: 'initialization'!

initializeConstraints
	"PointerAnchor initialize"

	self stronglyPreferStay: #point.x.
	self stronglyPreferStay: #point.y.!

initializeStructure

	point _ PointThing cloneFor: self.! !

!PointAnchor methodsFor: 'access'!

point

	^point! !

!PointAnchor methodsFor: 'glyphs'!

boundingBox
	"Answer a box around my DisplayForm centered on my location."

	^(self point asPoint + DisplayForm offset)
		extent: (DisplayForm extent)!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Display my display form at my location."

	DisplayForm
		displayOn: aDisplayMedium
		at: (aDisplayPoint + point asPoint)
		clippingBox: clipBox
		rule: (Form paint)
		fillColor: (Color black).!

glyphDependsOn

	^Array with: point!

selectableGlyphsInto: aSet

	aSet add: point.!

visibleGlyphsInto: aSet

	aSet add: point; add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PointAnchor class
	instanceVariableNames: ''!


!PointAnchor class methodsFor: 'class initialization'!

initialize
	"PointAnchor initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(384 960 960 384 384 384 384 8580 29070 63903 8580 12684 6552 4080 2016 0)
		offset: 0@0).
	explainText _ 'A PointAnchor is a point with an attached "preferred stay" constraint.'.
	DisplayForm _ (Form
		extent: 16@15
		fromArray: #(384 960 960 384 384 384 384 8580 29070 63903 8580 12684 6552 4080 2016)
		offset: -8@-2).! !

PointAnchor initialize!

SimpleRectThing subclass: #CenterRectThing
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!CenterRectThing methodsFor: 'initialization'!

initializeConstraints
	"CenterRectThing initialize"

	self defaultStay: #topLeft.x.
	self defaultStay: #topLeft.y.
	self prefer: '(p1 + p2) // 2 = center'
		where: #((p1 topLeft.x) (center center.x) (p2 bottomRight.x)).
	self prefer: '(p1 + p2) // 2 = center'
		where: #((p1 topLeft.y) (center center.y) (p2 bottomRight.y)).
	self methods: #('width _ (p2 - p1) abs')
		where: #((width extent.x) (p1 topLeft.x) (p2 bottomRight.x))
		strength: #preferred.
	self methods: #('height _ (p2 - p1) abs')
		where: #((height extent.y) (p1 topLeft.y) (p2 bottomRight.y))
		strength: #preferred.!

initializeValues

	super initializeValues.
	self set: #bottomRight.x to: 60.
	self set: #bottomRight.y to: 45.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CenterRectThing class
	instanceVariableNames: ''!


!CenterRectThing class methodsFor: 'class initialization'!

initialize
	"CenterRectThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 0 0 0 16380 8196 8196 8196 8196 8196 8196 8196 8196 16380 0 0)
		offset: 0@0).
	explainText _ 'A CenterRectThing is a SimpleRectThing with the addition of constraints to keep the center point midway between the origin and corner points and to keep the extent point updated. The extent cannot be changed by any other constraints.'.! !

CenterRectThing initialize!

CenterRectThing subclass: #FrameThing
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!FrameThing methodsFor: 'initialization'!

initializeConstraints
	"FrameThing initialize"

	self stronglyPreferStay: #topLeft.x.
	self stronglyPreferStay: #topLeft.y.
	self stronglyPreferStay: #bottomRight.x.
	self stronglyPreferStay: #bottomRight.y.!

initializeValues

	self set: #topLeft.x to: 15.
	self set: #topLeft.y to: 20.
	self set: #bottomRight.x to: 300.
	self set: #bottomRight.y to: 200.! !

!FrameThing methodsFor: 'glyphs'!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	| myBox w |
	myBox _ self boundingBox.
	myBox _ myBox insetOriginBy: -2@-1 cornerBy: -2@-1.
	w _ 1.
	aDisplayMedium
		fill: ((myBox left - w)@(myBox top - w) extent:
			 (w@(myBox height + (2 * w))))
		rule: (Form over)
		fillColor: (Color black).
	aDisplayMedium
		fill: ((myBox right)@(myBox top - w) extent:
			 (w@(myBox height + (2 * w))))
		rule: (Form over)
		fillColor: (Color black).

	aDisplayMedium
		border:  ((myBox left - w)@(myBox top - 8) extent:
			 ((myBox width + (2 * w))@8))
		width: 1.
	aDisplayMedium
		fill: ((myBox left - w + 1)@(myBox top - 7) extent:
			 ((myBox width - 2 + (2 * w))@6))
		rule: (Form over)
		fillColor: (Color lightGray).

	aDisplayMedium
		fill: ((myBox left - w)@(myBox top - w) extent:
			 ((myBox width + (2 * w))@w))
		rule: (Form over)
		fillColor: (Color black).
	aDisplayMedium
		fill: ((myBox left - w)@(myBox bottom) extent:
			 ((myBox width + (2 * w))@w))
		rule: (Form over)
		fillColor: (Color black).!

selectableGlyphsInto: aSet

	aSet add: topLeft.
	aSet add: bottomRight.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FrameThing class
	instanceVariableNames: ''!


!FrameThing class methodsFor: 'class initialization'!

initialize
	"FrameThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(65535 54613 43691 54613 65535 32769 32769 32769 32769 32769 32769 32769 32769 32769 32769 65535)
		offset: 0@0).
	explainText _ 'A FrameThing acts a the placeholder for the window boundary when constructing stand-alone Things. Both corners are anchored.'.! !

FrameThing initialize!

PrimitiveThing subclass: #MidPoint
	instanceVariableNames: 'p1 midpoint p2 '
	classVariableNames: 'PenForm '
	poolDictionaries: ''
	category: 'Things-Primitive'!


!MidPoint methodsFor: 'initialization'!

initializeConstraints
	"MidPoint initialize"

	self stronglyPrefer: '(p1 + p2) // 2 = midpoint'
		where: #((p1 p1.y) (midpoint midpoint.y) (p2 p2.y)).
	self stronglyPrefer: '(p1 + p2) // 2 = midpoint'
		where: #((p1 p1.x) (midpoint midpoint.x) (p2 p2.x)).
	self defaultStay: #p1.x.
	self defaultStay: #p1.y.
	self defaultStay: #p2.x.
	self defaultStay: #p2.y.!

initializeStructure

	p1 _ PointThing cloneFor: self.
	midpoint _ PointThing cloneFor: self.
	p2 _ PointThing cloneFor: self.!

initializeValues

	self set: #p1.x to: 30.
	self set: #p1.y to: 30.
	self set: #p2.x to: 70.
	self set: #p2.y to: 70.! !

!MidPoint methodsFor: 'access'!

midpoint

	^midpoint!

p1

	^p1!

p2

	^p2! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MidPoint class
	instanceVariableNames: ''!


!MidPoint class methodsFor: 'class initialization'!

initialize
	"MidPoint initialize"

	self initializePrimitive.
	partIcon _ Form
		extent: 16@16
		fromArray: #(0 0 28 28 28 0 0 896 896 896 0 0 28672 28672 28672 0)
		offset: 0@0.
	explainText _ 'A MidPoint consists of three colinear points with the middle point constrained to lie midway between the other two.'.! !

MidPoint initialize!

SimpleRectThing subclass: #FixedRectThing
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!FixedRectThing methodsFor: 'initialization'!

initializeConstraints
	"FixedRectThing initialize"

	self methods: #(
			'p1 _ p2 - width'
			'p2 _ p1 + width')
		where: #((p1 topLeft.x) (p2 bottomRight.x) (width extent.x))
		strength: #preferred.
	self methods: #(
			'p1 _ p2 - height'
			'p2 _ p1 + height')
		where: #((p1 topLeft.y) (p2 bottomRight.y) (height extent.y))
		strength: #preferred.
	self methods: #(
			'center _ p1 + (width // 2)'
			'p1 _ center - (width // 2)')
		where: #((center center.x) (p1 topLeft.x) (width extent.x))
		strength: #preferred.
	self methods: #(
			'center _ p1 + (height // 2)'
			'p1 _ center - (height // 2)')
		where: #((center center.y) (p1 topLeft.y) (height extent.y))
		strength: #preferred.!

initializeValues

	super initializeValues.
	self set: #extent.x to: 30.
	self set: #extent.y to: 20.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FixedRectThing class
	instanceVariableNames: ''!


!FixedRectThing class methodsFor: 'class initialization'!

initialize
	"FixedRectThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 0 0 0 16380 8196 8196 8196 8196 8196 8196 8196 8196 16380 0 0)
		offset: 0@0).
	explainText _ 'A FixedRectThing is a SimpleRectThing with the addition of constraints that use its width and height to compute a corner and the center given the other corner. The center cannot be changed by any other constraints but the extent can.'.! !

FixedRectThing initialize!

PrimitiveThing subclass: #LineThing
	instanceVariableNames: 'p1 p2 '
	classVariableNames: 'PenForm '
	poolDictionaries: ''
	category: 'Things-Primitive'!


!LineThing methodsFor: 'initialization'!

initializeStructure

	p1 _ PointThing cloneFor: self.
	p2 _ PointThing cloneFor: self.!

initializeValues

	self set: #p1.x to: 10.
	self set: #p1.y to: 10.	
	self set: #p2.x to: 30.
	self set: #p2.y to: 30.! !

!LineThing methodsFor: 'access'!

p1

	^p1!

p2

	^p2! !

!LineThing methodsFor: 'glyphs'!

boundingBox
	"Return the smallest rectangle enclosing both my endpoints."

	| point1 point2 |
	point1 _ p1 asPoint.
	point2 _ p2 asPoint.
	^(point1 min: point2) corner: (point1 max: point2)!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Display the line segment between my endpoints."

	(Line
		from: (p1 asPoint)
		to: (p2 asPoint)
		withForm: PenForm)
			displayOn: aDisplayMedium
			at: aDisplayPoint
			clippingBox: clipBox
			rule: (Form paint)
			fillColor: (Color black).!

glyphDependsOn

	^Array
		with: p1
		with: p2!

selectableGlyphsInto: aSet

	aSet add: p1; add: p2.!

visibleGlyphsInto: aSet

	aSet add: p1; add: p2; add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LineThing class
	instanceVariableNames: ''!


!LineThing class methodsFor: 'class initialization'!

initialize
	"LineThing initialize"

	self initializePrimitive.
	partIcon _ Form
		extent: 16 @ 16
		fromArray: #(0 2 6 12 24 48 96 192 384 768 1536 3072 6144 12288 8192 0)
		offset: 0 @ 0.
	explainText _ 'A LineThing is an unconstrained line. It consists of two points connected by a line segment.'.
	PenForm _ Form dotOfSize: 1.! !

LineThing initialize!

LineThing subclass: #PlainLine
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!PlainLine methodsFor: 'glyphs'!

visibleGlyphsInto: aSet

	aSet add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PlainLine class
	instanceVariableNames: ''!


!PlainLine class methodsFor: 'class initialization'!

initialize
	"PlainLine initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 2 6 12 24 48 96 192 384 768 1536 3072 6144 12288 8192 0)
		offset: 0@0).
	explainText _ 'A PlainLine is like a regular line except that the endpoints are not displayed.'.! !

PlainLine initialize!

LineThing subclass: #VLine
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!VLine methodsFor: 'initialization'!

initializeConstraints
	"VLine initialize"

	self stronglyPrefer: #p1.x equals: #p2.x.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VLine class
	instanceVariableNames: ''!


!VLine class methodsFor: 'class initialization'!

initialize
	"VLine initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(384 960 960 384 384 384 384 384 384 384 384 384 384 960 960 384)
		offset: 0@0).
	explainText _ 'A VLine is a LineThing constrained to remain vertical.'.! !

VLine initialize!

LineThing subclass: #HLine
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!HLine methodsFor: 'initialization'!

initializeConstraints
	"HLine initialize"

	self stronglyPrefer: #p1.y equals: #p2.y.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HLine class
	instanceVariableNames: ''!


!HLine class methodsFor: 'class initialization'!

initialize
	"HLine initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 0 0 0 0 0 24582 65535 65535 24582 0 0 0 0 0 0)
		offset: 0@0).
	explainText _ 'An HLine is a line constrained to remain horizontal'.! !

HLine initialize!

PrimitiveThing subclass: #ListThing
	instanceVariableNames: 'box itemsList selected '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!ListThing methodsFor: 'initialization'!

initializeStructure

	box _ CenterRectThing cloneFor: self.!

initializeValues

	self set: #box.bottomRight.x to: 70.
	self set: #box.bottomRight.y to: 70.
	self set: #itemsList to: #(Apple Pear Orange Tangerine).
	self set: #selected to: #Pear.! !

!ListThing methodsFor: 'access'!

box

	^box!

itemsList

	^itemsList!

primitemsList: aCollectionOfStringsOrSymbols

	itemsList _ aCollectionOfStringsOrSymbols.!

primselected: aSymbol

	selected _ aSymbol.!

selected

	^selected! !

!ListThing methodsFor: 'glyphs'!

boundingBox

	^box asRectangle!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Print my items list in my box and highlight the selected item, if any."

	| itemsBox lineHeight left y thisItemBox index highLightBox |
	itemsBox _ (self boundingBox moveBy: aDisplayPoint) insetBy: 2.
	lineHeight _ QuickPrint lineHeight.
	left _ itemsBox left.
	y _ itemsBox top.
	itemsList do:
		[: item |
		 thisItemBox _ ((left + 1)@y) corner: itemsBox bottomRight.
		 (QuickPrint
			newOn: aDisplayMedium
			box: thisItemBox) drawString: item asString.
		 y _ y + lineHeight].

	index _ itemsList indexOf: selected ifAbsent: [0].
	((index > 0) & (index <= itemsList size)) ifTrue:
		[highLightBox _
			(left@(itemsBox top + (lineHeight * (index - 1))))
				extent: (itemsBox width@lineHeight).
		 highLightBox _ highLightBox intersect: itemsBox.
		 aDisplayMedium reverse: highLightBox].!

glyphDependsOn

	^Array
		with: self
		with: box topLeft
		with: box bottomRight!

inputGlyphsInto: aSet

	aSet add: self.!

selectableGlyphsInto: aSet

	aSet
		add: box topLeft;
		add: box bottomRight.!

visibleGlyphsInto: aSet

	box visibleGlyphsInto: aSet.
	aSet add: self.! !

!ListThing methodsFor: 'mouse'!

handleMouseMove: mousePoint view: aView

	| myBox index |
	myBox _ self boundingBox.
	(myBox containsPoint: mousePoint)
		ifTrue:
			[index _
				((mousePoint y - myBox top) // QuickPrint lineHeight) + 1.
			 ((index <= itemsList size) and:
			  [(itemsList at: index) isEmpty not])
				ifTrue: [selected _ itemsList at: index]
				ifFalse: [selected _ nil]]
		ifFalse: [selected _ nil].!

mouseConstraints

	^Array with: (
		EditConstraint
			ref: 	self->#selected
			strength: ThingLabII editStrength)!

wantsMouse

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ListThing class
	instanceVariableNames: ''!


!ListThing class methodsFor: 'class initialization'!

initialize
	"ListThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(65532 32774 49142 32774 49142 32774 65534 61502 65534 32774 49142 32774 49142 32774 65534 32766)
		offset: 0@0).
	explainText _ 'A ListThing consists of an itemsList, a bounding rectangle, and a selected item field that is nil if no item is selected.'.! !

ListThing initialize!

PrimitiveThing subclass: #Node
	instanceVariableNames: 'location value last '
	classVariableNames: 'DisplayForm '
	poolDictionaries: ''
	category: 'Things-Primitive'!


!Node methodsFor: 'initialization'!

initializeStructure

	location _ PointThing cloneFor: self.!

initializeValues

	self set: #location.x to: 20.
	self set: #location.y to: 20.
	self set: #value to: nil.
	self set: #last to: nil.! !

!Node methodsFor: 'access'!

last

	^last!

location

	^location!

primlast: aValue

	last _ aValue.!

primvalue: aValue

	value _ aValue.!

value

	^value! !

!Node methodsFor: 'glyphs'!

boundingBox
	"Answer a box around my DisplayForm centered on my location."

	^(self location asPoint + DisplayForm offset)
		extent: (DisplayForm extent)!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Display my display form at my location."

	DisplayForm
		displayOn: aDisplayMedium
		at: (aDisplayPoint + (location asPoint))
		clippingBox: clipBox
		rule: (Form paint)
		fillColor: (Color black)!

glyphDependsOn

	^Array with: self location!

selectableGlyphsInto: aSet

	aSet add: self.!

visibleGlyphsInto: aSet

	aSet add: self.! !

!Node methodsFor: 'history'!

advanceHistory

	last _ value.!

keepsHistory

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Node class
	instanceVariableNames: ''!


!Node class methodsFor: 'class initialization'!

initialize
	"Node initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 0 0 0 0 2016 2016 2016 2016 2016 2016 0 0 0 0 0)
		offset: 0@0).
	explainText _ 'A Node is a value holder. It has a location and a value, which can be of any type. It also maintains a history of the last several values it has held.'.
	DisplayForm _ (Form extent: 4@4) offset: -2@-2; black.! !

Node initialize!

PrimitiveThing subclass: #VScrollThing
	instanceVariableNames: 'box node minVal maxVal '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!VScrollThing methodsFor: 'initialization'!

initializeConstraints
	"VScrollThing initialize"

	"layout constraints"
	self offset: #node.location.x by: 0 from: #box.center.x.
	self offset: #node.location.y by: 6 from: #box.bottomRight.y.!

initializeStructure

	box _ FixedRectThing cloneFor: self.
	node _ Node cloneFor: self.!

initializeValues

	self set: #box.extent.x to: 10.
	self set: #box.extent.y to: 40.
	self set: #node.location.x to: 25.
	self set: #node.location.y to: 60.
	self set: #node.value to: 0.5.
	self set: #minVal to: 0.0.
	self set: #maxVal to: 100.0.! !

!VScrollThing methodsFor: 'access'!

box

	^box!

maxVal

	^maxVal!

minVal

	^minVal!

node

	^node!

primmaxVal: aNumber

	maxVal _ aNumber.!

primminVal: aNumber

	minVal _ aNumber.! !

!VScrollThing methodsFor: 'glyphs'!

boundingBox
	"Answer my box as a Rectangle."

	^box asRectangle!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Display my marker."

	aDisplayMedium
		border:
			(((box topLeft x@self markerY) extent: (box extent x@1))
				 moveBy: aDisplayPoint)
		width: 1.!

glyphDependsOn

	^(Array
		with: self
		with: box topLeft
		with: box bottomRight),
	 (Array with: node)!

inputGlyphsInto: aSet

	aSet add: self.!

markerY
	"Answer the vertical position of my marker."

	| myBox y |
	myBox _ box asRectangle.
	y _ myBox bottom -
		((node value asFloat - minVal) * myBox height / (maxVal - minVal)).
	^(y rounded max: myBox top + 1) min: myBox bottom - 2!

selectableGlyphsInto: aSet

	aSet add: node.!

visibleGlyphsInto: aSet

	aSet add: box; add: node; add: self.! !

!VScrollThing methodsFor: 'mouse'!

handleMouseMove: mousePoint view: aView
	"Set my marker from the mouse. Ensure that the marker is between the top and bottom of my box."

	| myBox relativeY percent |
	myBox _ box asRectangle.
	relativeY _
		((myBox bottom - mousePoint y) max: 0) min: myBox height.
	percent _ relativeY asFloat / myBox height.
	node primvalue: (minVal + (percent * (maxVal - minVal)))!

mouseConstraints

	^Array with: (
		EditConstraint
			ref: 	node->#value
			strength: ThingLabII editStrength)!

wantsMouse

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VScrollThing class
	instanceVariableNames: ''!


!VScrollThing class methodsFor: 'class initialization'!

initialize
	"VScrollThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 2016 1056 1056 1056 2016 1056 1056 1056 1056 1056 1056 1056 1056 1056 2016)
		offset: 0@0).
	explainText _ 'A ScrollThing consists a node, a box, and a horizonal marker. The vertical position of the marker within the box is proportional to the value of the node within the range [minVal..maxVal].'.! !

VScrollThing initialize!

PrimitiveThing subclass: #NodeAnchor
	instanceVariableNames: 'node '
	classVariableNames: 'DisplayForm '
	poolDictionaries: ''
	category: 'Things-Primitive'!


!NodeAnchor methodsFor: 'initialization'!

initializeConstraints
	"NodeAnchor initialize"

	self stronglyPreferStay: #node.value.!

initializeStructure

	node _ Node cloneFor: self.! !

!NodeAnchor methodsFor: 'access'!

location

	^node location!

node

	^node! !

!NodeAnchor methodsFor: 'glyphs'!

boundingBox
	"Answer a box around my DisplayForm centered on my location."

	^(self node location asPoint + DisplayForm offset)
		extent: (DisplayForm extent)!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Display my display form at my location."

	DisplayForm
		displayOn: aDisplayMedium
		at: (aDisplayPoint + (node location asPoint))
		clippingBox: clipBox
		rule: (Form paint)
		fillColor: (Color black).!

glyphDependsOn

	^Array with: node location!

selectableGlyphsInto: aSet

	aSet add: node.!

visibleGlyphsInto: aSet

	aSet add: node; add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NodeAnchor class
	instanceVariableNames: ''!


!NodeAnchor class methodsFor: 'class initialization'!

initialize
	"NodeAnchor initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 960 960 960 960 384 384 8580 29070 63903 8580 12684 6552 4080 2016 0)
		offset: 0@0).
	DisplayForm _ (Form
		extent: 16@15
		fromArray: #(960 960 960 960 384 384 384 8580 29070 63903 8580 12684 6552 4080 2016)
		offset: -8@-2).
	explainText _ 'A NodeAnchor is a node with an attached "preferred stay" constraint.'.! !

NodeAnchor initialize!

PrimitiveThing subclass: #RodThing
	instanceVariableNames: 'line length p1 p2 p1Force p2Force '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Private'!


!RodThing methodsFor: 'initialization'!

initializeConstraints
	"RodThing initialize"

	self stronglyPreferEdit:#p1.last.
	self stronglyPreferEdit:#p2.last.
	self stronglyPreferEdit:#p1Force.last.
	self stronglyPreferEdit:#p2Force.last.

	"This constraint computes a force vector for each endpoint. The direction of this vector will be parallel to the rod and either inward at each endpoint (if the rod is stretched longer than its nominal length) or outward at each endpoint (if the rod is compressed)."

	self methods: #(
			'"a positive magnitude means inward force"
			 forceVector _ (p2 - p1) unitVector * ((p1 - p2) r - length).
			 p1Force _ forceVector.
			 p2Force _ forceVector * -1')
		where: #((p1 p1.value) (p2 p2.value) (length length.value)
				 (p1Force p1Force.value) (p2Force p2Force.value))
		strength: #required.

	self methods: #(
			'p _ x@y'
			'x _ p x.
			 y _ p y')
		where: #((p p1.value) (x line.p1.x) (y line.p1.y))
		strength: #required.

	self methods: #(
			'p _ x@y'
			'x _ p x.
			 y _ p y')
		where: #((p p2.value) (x line.p2.x) (y line.p2.y))
		strength: #required.!

initializeStructure

	line _ LineThing cloneFor: self.
	length _ Node cloneFor: self.
	p1 _ Node cloneFor: self.
	p2 _ Node cloneFor: self.
	p1Force _ Node cloneFor: self.
	p2Force _ Node cloneFor: self.!

initializeValues

	self set: #length.value to: 30.		"nominal length"
	self set: #line.p1.x to: 10.
	self set: #line.p1.y to: 10.	
	self set: #line.p2.x to: 40.
	self set: #line.p2.y to: 10.
	self set: #p1.value to: 10@10.
	self set: #p1.last to: 10@10.
	self set: #p2.value to: 40@10.
	self set: #p2.last to: 40@10.
	self set: #p1Force.value to: 0.
	self set: #p1Force.last to: 0.
	self set: #p2Force.value to: 0.
	self set: #p2Force.last to: 0.! !

!RodThing methodsFor: 'access'!

length

	^length!

line

	^line!

p1

	^p1!

p1Force

	^p1Force!

p2

	^p2!

p2Force

	^p2Force! !

!RodThing methodsFor: 'glyphs'!

selectableGlyphsInto: aSet
	"Only the selectable parts of my line are selectable."

	line selectableGlyphsInto: aSet.!

visibleGlyphsInto: aSet
	"Only the visible parts of my line are visible."

	line visibleGlyphsInto: aSet.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RodThing class
	instanceVariableNames: ''!


!RodThing class methodsFor: 'class initialization'!

initialize
	"RodThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 0 6280 6600 6300 6280 6144 6144 6144 6144 6280 6300 6600 6280 0 0)
		offset: 0@0).
	explainText _ 'A RodThing is a stretchable, compressible rod of some nominal length that obeys Hooke''s law for springs. I compute the force vector for each of my endpoints (which is zero if I am neither stretched nor compressed).'.! !

RodThing initialize!

PrimitiveThing subclass: #ThreeWayOp
	instanceVariableNames: 'location opForm a b c '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Private'!


!ThreeWayOp methodsFor: 'initialization'!

initializeStructure

	a _ Node cloneFor: self.
	b _ Node cloneFor: self.
	c _ Node cloneFor: self.
	location _ PointThing cloneFor: self.!

initializeValues

	self set: #a.location.x to: 20.
	self set: #a.location.y to: 20.
	self set: #b.location.x to: 20.
	self set: #b.location.y to: 50.
	self set: #c.location.x to: 80.
	self set: #c.location.y to: 30.
	self set: #location.x to: 50.
	self set: #location.y to: 30.
	self set: #opForm to:
		(Form
			extent: 9@9
			fromArray: #(65408 16640 40064 41600 33920 34944 32896 51584 32512)
			offset: -4@-4).! !

!ThreeWayOp methodsFor: 'glyphs'!

boundingBox
	"Answer a box around my opForm centered on my location."

	^(location asPoint + opForm offset)
		extent: (opForm extent)!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	| line |
	line _ Line
		from: (location asPoint)
		to: 0@0	"filled in below"
		withForm: (Form extent: 1@1) black.
	(Array with: a with: b with: c) do:
		[: part |
		 line endPoint: part location asPoint.
		 line
			displayOn: aDisplayMedium
			at: aDisplayPoint
			clippingBox: clipBox
			rule: (Form paint)
			fillColor: (Color black)].
	opForm
		displayOn: aDisplayMedium
		at: (aDisplayPoint + location asPoint)
		clippingBox: clipBox
		rule: (Form over)
		fillColor: (Color black).!

glyphDependsOn

	^Array
		with: self location
		with: a location
		with: b location
		with: c location!

selectableGlyphsInto: aSet

	a visibleGlyphsInto: aSet.
	b visibleGlyphsInto: aSet.
	c visibleGlyphsInto: aSet.
	aSet add: self.!

visibleGlyphsInto: aSet

	a visibleGlyphsInto: aSet.
	b visibleGlyphsInto: aSet.
	c visibleGlyphsInto: aSet.
	aSet add: self.! !

!ThreeWayOp methodsFor: 'access'!

a

	^a!

b

	^b!

c

	^c!

location

	^location!

opForm

	^opForm!

primopForm: aForm

	opForm _ aForm.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ThreeWayOp class
	instanceVariableNames: ''!


!ThreeWayOp class methodsFor: 'class initialization'!

initialize
	"ThreeWayOp initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(8184 16380 28686 59367 53235 52275 52787 50787 49347 49539 49155 49539 57735 28686 16380 8184)
		offset: 0@0).
	explainText _ 'A ThreeWayOp is a template Thing for three operand operators. It is used as a sub-part of other Things, rather than as a stand-alone Thing. It provides three Nodes and an operator Form.'.! !

ThreeWayOp initialize!

VScrollThing subclass: #VSliderThing
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!VSliderThing methodsFor: 'glyphs'!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Display my box and fill it with gray 'mercury' up to the marker."

	| myBox |
	myBox _ self boundingBox.
	myBox _ myBox insetBy: 1.
	myBox top: (self markerY max: myBox top).
	aDisplayMedium gray: (myBox moveBy: aDisplayPoint).
	super
		displayOn: aDisplayMedium
		at: aDisplayPoint
		clippingBox: clipBox.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VSliderThing class
	instanceVariableNames: ''!


!VSliderThing class methodsFor: 'class initialization'!

initialize
	"VSliderThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 2016 1056 1056 1056 2016 1376 1696 1376 1696 1376 1696 1376 1696 1376 2016)
		offset: 0@0).
	explainText _ 'A VSliderThing is like a VScrollThing except that it draws "mercury" instead of just a horizontal marker.'.! !

VSliderThing initialize!

PrimitiveThing subclass: #WireThing
	instanceVariableNames: 'node1 node2 line '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!WireThing methodsFor: 'initialization'!

initializeConstraints
	"WireThing initialize"

	"the values of my terminals are required to be equal"
	self require: #node1.value equals: #node2.value.

	"layout"
	self require: #node1.location.x equals: #line.p1.x.
	self require: #node1.location.y equals: #line.p1.y.
	self require: #node2.location.x equals: #line.p2.x.
	self require: #node2.location.y equals: #line.p2.y.!

initializeStructure

	node1 _ Node cloneFor: self.
	node2 _ Node cloneFor: self.
	line _ PlainLine cloneFor: self.!

initializeValues

	self set: #node1.location.x to: 10.
	self set: #node1.location.y to: 10.
	self set: #node2.location.x to: 30.
	self set: #node2.location.y to: 30.! !

!WireThing methodsFor: 'access'!

line

	^line!

node1

	^node1!

node2

	^node2! !

!WireThing methodsFor: 'glyphs'!

selectableGlyphsInto: aSet

	node1 selectableGlyphsInto: aSet.
	node2 selectableGlyphsInto: aSet.!

visibleGlyphsInto: aSet

	node1 visibleGlyphsInto: aSet.
	node2 visibleGlyphsInto: aSet.
	aSet add: line.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WireThing class
	instanceVariableNames: ''!


!WireThing class methodsFor: 'class initialization'!

initialize
	"WireThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 2080 4112 16376 4112 2080 0 49155 65535 49155 0 0 0 0 0 0)
		offset: 0@0).
	explainText _ 'A WireThing propagates Node values the way an electrical wire propogates voltages.'.! !

WireThing initialize!

PrimitiveThing subclass: #Sum
	instanceVariableNames: 'op '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!Sum methodsFor: 'initialization'!

initializeConstraints
	"Sum initialize"

	self stronglyPrefer: 'a + b = c'
		where: #((a op.a.value) (b op.b.value) (c op.c.value)).!

initializeStructure

	op _ ThreeWayOp cloneFor: self.!

initializeValues

	self set: #op.a.value to: 0.
	self set: #op.b.value to: 0.
	self set: #op.c.value to: 0.
	self set: #op.opForm to:
		(Form
			extent: 9@11
			fromArray: #(15872 16640 32896 34944 34944 48768 34944 34944 32896 16640 15872)
			offset: -4@-5).! !

!Sum methodsFor: 'access'!

op

	^op! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Sum class
	instanceVariableNames: ''!


!Sum class methodsFor: 'class initialization'!

initialize
	"Sum initialize"

	self initializePrimitive.
	partIcon _ Form
		extent: 16@16
		fromArray: #(8184 16380 28686 57351 49539 49539 49539 53235 53235 49539 49539 49539 57351 28686 16380 8184)
		offset: 0@0.
	explainText _ 'A Sum is a three operand arithmetic constraint, x + y = z'.! !

Sum initialize!

PrimitiveThing subclass: #PenRecorderThing
	instanceVariableNames: 'border scale offset input history '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!PenRecorderThing methodsFor: 'initialization'!

initializeConstraints
	"PenRecorderThing initialize"

	"layout constraints"
	self offset: #input.location.x by: 0 from: #border.center.x.
	self offset: #input.location.y by: 5 from: #border.bottomRight.y.!

initializeStructure

	border _ CenterRectThing cloneFor: self.
	scale _ Node cloneFor: self.
	offset _ Node cloneFor: self.
	input _ Node cloneFor: self.!

initializeValues

	self set: #border.topLeft.x to: 30.
	self set: #border.topLeft.y to: 30.	
	self set: #border.bottomRight.x to: 100.
	self set: #border.bottomRight.y to: 80.
	self set: #scale.value to: 1.
	self set: #offset.value to: 0.
	self set: #input.value to: 0.
	history _ (HistoryQueue new: 2000) clearTo: 0.! !

!PenRecorderThing methodsFor: 'access'!

border

	^border!

history

	^history!

input

	^input!

offset

	^offset!

scale

	^scale! !

!PenRecorderThing methodsFor: 'glyphs'!

boundingBox

	^border asRectangle!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	| myBox xValue yCenter yScale pen yValue |
	myBox _ clipBox intersect: (border asRectangle moveBy: aDisplayPoint).
	xValue _ (myBox left + 1) rounded.
	yScale _ scale value negated asFloat.
	yCenter _ (myBox top + myBox bottom // 2) rounded +
				(offset value negated asFloat * yScale) rounded.
	pen _ BitBlt
		destForm: aDisplayMedium
		sourceForm: ((Form extent: 1@1) black)
		halftoneForm: nil
		combinationRule: (Form over)
		destOrigin: 0@0
		sourceOrigin: 0@0
		extent: 1@1
		clipRect: myBox.
	history last: ((myBox width - 2) rounded) do:
		[: value |
		 yValue _ (value asFloat * yScale) rounded + yCenter.
		 ((yValue > myBox top) & (yValue < myBox bottom)) ifTrue:
			[pen destX: xValue.
			 pen destY: yValue.
			 pen copyBits].
		 xValue _ xValue + 1].!

glyphDependsOn

	^(Array
		with: border topLeft
		with: border bottomRight),
	  (Array
		with: scale
		with: offset
		with: input)!

location

	^border topLeft!

selectableGlyphsInto: aSet

	input selectableGlyphsInto: aSet.
	aSet add: border topLeft.
	aSet add: border bottomRight.!

visibleGlyphsInto: aSet

	border visibleGlyphsInto: aSet.
	input visibleGlyphsInto: aSet.
	aSet add: self.! !

!PenRecorderThing methodsFor: 'history'!

advanceHistory

	history add: input value.!

keepsHistory

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PenRecorderThing class
	instanceVariableNames: ''!


!PenRecorderThing class methodsFor: 'class initialization'!

initialize
	"PenRecorderThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(65535 32769 32769 33281 34049 34945 61511 32809 32785 32769 32769 32769 65535 384 384 0)
		offset: 0@0).
	explainText _ 'A PenRecorderThing records and display the last N values of its input, like an oscilloscope. The vertical scale and offset are adjustable.'.! !

PenRecorderThing initialize!

PrimitiveThing subclass: #BasicTextThing
	instanceVariableNames: 'box node '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Private'!


!BasicTextThing methodsFor: 'initialization'!

initializeStructure

	box _ FixedRectThing cloneFor: self.
	node _ Node cloneFor: self.!

initializeValues

	self set: #box.extent.x to: 60.
	self set: #box.extent.y to: 35.
	self set: #node.location.x to: 25.
	self set: #node.location.y to: 30.
	self set: #node.value to: 'Text'.! !

!BasicTextThing methodsFor: 'access'!

box

	^box!

displayText
	"Answer the text to be displayed. Subclasses may override this behavior."

	^node value!

node

	^node! !

!BasicTextThing methodsFor: 'glyphs'!

boundingBox
	"Answer the box for my text."

	^box asRectangle!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Print my text at my position."

	| textBox scanner |
	textBox _ box asRectangle moveBy: aDisplayPoint.
	aDisplayMedium white: ((textBox  insetBy: 1) intersect: clipBox).
	scanner _ QuickPrint
		newOn: aDisplayMedium
		box: (textBox insetBy: 2).
	scanner drawString: self displayText.!

glyphDependsOn

	^Array
		with: box topLeft
		with: box bottomRight
		with: node!

inputGlyphsInto: aSet

	aSet add: self.!

location

	^box topLeft!

selectableGlyphsInto: aSet

	aSet add: node; add: self.!

visibleGlyphsInto: aSet

	aSet add: node; add: box; add: self.! !

!BasicTextThing methodsFor: 'keyboard'!

handleKeystroke: aCharacter view: aView
	"Append the given character to my text. If the character is backspace, delete my character."

	((aCharacter == Character backspace) & (node value size > 0))
		ifTrue:
			[node primvalue:
				(node value copyFrom: 1 to: (node value size - 1)).
			 (node value isEmpty) ifTrue: [node primvalue: ' '].
			 ^self].

	(node value == ' ')
		ifTrue: [node primvalue: (String with: aCharacter)]
		ifFalse: [node primvalue: (node value copyWith: aCharacter)].!

keystrokeConstraints

	^Array with: (
		EditConstraint
			ref: 	node->#value
			strength: ThingLabII editStrength)!

wantsKeystrokes

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BasicTextThing class
	instanceVariableNames: ''!


!BasicTextThing class methodsFor: 'class initialization'!

initialize
	"BasicTextThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 65535 0 0 4559 14633 27944 17864 32040 17705 17871 0 0 65535 0 0)
		offset: 0@0).
	explainText _ 'A BasicTextThing holds an editable string in a resizable box plus a node containing the string to be displayed.'.! !

BasicTextThing initialize!

PrimitiveThing subclass: #HistorySplitter
	instanceVariableNames: 'op '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!HistorySplitter methodsFor: 'initialization'!

initializeConstraints
	"HistorySplitter initialize"

	self stronglyPreferEdit: #op.c.last.
	self require: #op.b.value equals: #op.c.value.
	self methods: #('outA _ last')
		where: #((outA op.a.value) (last op.c.last))
		strength: #required.

	"layout constraints"
	self offset: #op.a.location.x by: -5 from: #op.location.x.
	self offset: #op.a.location.y by: -7 from: #op.location.y.
	self offset: #op.b.location.x by: 5 from: #op.location.x.
	self offset: #op.b.location.y by: -7 from: #op.location.y.
	self offset: #op.c.location.x by: 0 from: #op.location.x.
	self offset: #op.c.location.y by: 6 from: #op.location.y.!

initializeStructure

	op _ ThreeWayOp cloneFor: self.!

initializeValues

	self set: #op.a.value to: 0.
	self set: #op.b.value to: 0.
	self set: #op.c.value to: 0.
	self set: #op.c.location.x to: 25.
	self set: #op.c.location.y to: 25.
	self set: #op.opForm to:
		(Form
			extent: 19@9
			fromArray: #(65535 57344 32832 8192 36943 8192 36937 8192 36936 8192 36937 8192 40527 8192 32832 8192 65535 57344)
			offset: -10@-5).! !

!HistorySplitter methodsFor: 'access'!

op

	^op! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HistorySplitter class
	instanceVariableNames: ''!


!HistorySplitter class methodsFor: 'class initialization'!

initialize
	"HistorySplitter initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 0 0 6192 65534 33026 41338 41290 41282 41290 48506 33026 65534 896 0 0)
		offset: 0@0).
	explainText _ 'A HistorySplitter splits the value of a node into its current and previous values.'.! !

HistorySplitter initialize!

PrimitiveThing subclass: #FormPrinter
	instanceVariableNames: 'location node '
	classVariableNames: 'BitColor PenForm '
	poolDictionaries: ''
	category: 'Things-Primitive'!
FormPrinter comment:
'This is a direct copy of NumberPrinter as of 18-Jan-89 modified to handle Forms rather than numbers.  The modification and bitEditing code was added by Bjorn Freeman-Benson.

Some changes: the box is autosizing.'!


!FormPrinter methodsFor: 'initialization'!

initializeStructure

	location _ PointThing cloneFor: self.
	node _ Node cloneFor: self.!

initializeValues

	self set: #location.x to: 30.
	self set: #location.y to: 20.	
	self set: #node.location.x to: 60.
	self set: #node.location.y to: 60.	
	self set: #node.value to: (Form extent: 30@20).! !

!FormPrinter methodsFor: 'access'!

location

	^location!

node

	^node! !

!FormPrinter methodsFor: 'glyphs'!

boundingBox
	"Answer a box around my form display box centered on my location."

	^(self location asPoint - ((self node value extent + 2) // 2))
		extent: (self node value extent + 2)!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Display my display box, print my node's value inside it, and draw a line from my display box to my node."

	| form extent |
	extent _ self node value extent + (2@2).
	form _ Form extent: extent.
	form border: ((0@0) extent: extent) width: 1.
	(Line
		from: (location asPoint)
		to: (node location asPoint)
		withForm: PenForm)
			displayOn: aDisplayMedium
			at: aDisplayPoint
			clippingBox: clipBox
			rule: (Form paint)
			fillColor: (Color black).
	form
		displayOn: aDisplayMedium
		at: (aDisplayPoint + (location asPoint) - (extent // 2))
		clippingBox: clipBox
		rule: (Form over)
		fillColor: (Color black).
	self node value
		displayOn: aDisplayMedium
		at: ((aDisplayPoint + (location asPoint) - (extent // 2)) + (1@1))
		clippingBox: clipBox
		rule: (Form over)
		fillColor: (Color black).!

glyphDependsOn

	^Array
		with: self location
		with: node location
		with: node!

inputGlyphsInto: aSet
	"I accept input."

	aSet add: self.!

visibleGlyphsInto: aSet
	"I consists of a NumberNode, my display box, and a line segment connecting them."

	aSet add: node; add: self.! !

!FormPrinter methodsFor: 'mouse'!

calculateMousePoint: mousePoint

	^mousePoint - self location asPoint + (self node value extent // 2)!

handleMouseDown: mousePoint view: aView

	(Sensor leftShiftDown)
		ifTrue:
			[^NotifyingBitEditor openOnForm: (node value) client: aView controller]
		ifFalse:
			[BitColor _ (((self node value)
				valueAt: (self calculateMousePoint: mousePoint)) == 1)
					ifTrue: [0]
					ifFalse: [1].
			 self handleMouseMove: mousePoint view: aView].!

handleMouseMove: mousePoint view: aView

	(self node value)
		valueAt: (self calculateMousePoint: mousePoint)
		put: BitColor!

mouseConstraints

	^Array with: (
		EditConstraint
			ref: 	node->#value
			strength: ThingLabII editStrength)!

wantsMouse

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FormPrinter class
	instanceVariableNames: ''!


!FormPrinter class methodsFor: 'class initialization'!

initialize
	"FormPrinter initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(65535 32769 32769 34401 34401 32769 32769 34833 34785 32769 65535 256 256 896 896 896)
		offset: 0@0).
	explainText _ 'A FormPrinter shows a Smalltalk Form in a box. The Form can be edited using the yellow (option-mouse) button hack.'.
	PenForm _ (Form extent: 1@1) black.! !

FormPrinter initialize!

VScrollThing subclass: #VScrollThingMinusNodes
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-MinusNodes'!


!VScrollThingMinusNodes methodsFor: 'glyphs'!

selectableGlyphsInto: aSet!

visibleGlyphsInto: aSet

	aSet add: box; add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VScrollThingMinusNodes class
	instanceVariableNames: ''!


!VScrollThingMinusNodes class methodsFor: 'class initialization'!

initialize
	"VScrollThingMinusNodes initialize"

	super initialize.
	explainText _ 'I am like a VScrollThing except that my connection points are hidden.'.! !

VScrollThingMinusNodes initialize!

PrimitiveThing subclass: #ScrollingListThing
	instanceVariableNames: 'box scrollBar itemsList selectedItem '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!ScrollingListThing methodsFor: 'initialization'!

initializeConstraints
	"ScrollingListThing initialize"

	self stronglyPreferEdit:#selectedItem.last.
	self methods: #(
			'selected _ (items includes: oldSelected)
				ifTrue: [oldSelected]
				ifFalse: [nil]')
		where: #((selected selectedItem.value) (items itemsList.value)
				 (oldSelected selectedItem.last))
		strength: #default.

	"layout"
	self offset: #scrollBar.box.topLeft.x by: -8 from: #box.topLeft.x.
	self offset: #scrollBar.box.topLeft.y by: 0 from: #box.topLeft.y.
	self offset: #scrollBar.box.extent.y by: 0 from: #box.extent.y.

	self offset: #itemsList.location.x by: -10 from: #box.topLeft.x.
	self offset: #itemsList.location.y by: -5 from: #box.center.y.

	self offset: #selectedItem.location.x by: -10 from: #box.topLeft.x.
	self offset: #selectedItem.location.y by: 5 from: #box.center.y.!

initializeStructure

	box _ CenterRectThing cloneFor: self.
	scrollBar _ VScrollThingMinusNodes cloneFor: self.
	itemsList _ Node cloneFor: self.
	selectedItem _ Node cloneFor: self.!

initializeValues

	self set: #box.bottomRight.x to: 85.
	self set: #box.bottomRight.y to: 60.

	self set: #scrollBar.box.extent.x to: 9.
	self set: #scrollBar.box.topLeft.x to: 20.
	self set: #scrollBar.box.topLeft.y to: 20.
	self set: #scrollBar.minVal to: 0.0.
	self set: #scrollBar.maxVal to: 1.0.
	self set: #scrollBar.node.value to: 1.0.

	self set: #itemsList.value to: #(apple pear peach kumqwat).

	self set: #selectedItem.value to: nil.
	self set: #selectedItem.last to: nil.! !

!ScrollingListThing methodsFor: 'access'!

box

	^box!

itemsList

	^itemsList!

primitemsList: aListOfStrings

	itemsList _ aListOfStrings.!

primselectedItem: aString

	selectedItem _ aString.!

scrollBar

	^scrollBar!

selectedItem

	^selectedItem! !

!ScrollingListThing methodsFor: 'glyphs'!

boundingBox

	^box asRectangle!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Print my items in my box and highlight the selected item, if any."

	| itemsBox lineHeight left y thisItemBox index highLightBox items |
	items _ self visibleItems.
	itemsBox _ (self boundingBox moveBy: aDisplayPoint) insetBy: 2.
	lineHeight _ QuickPrint lineHeight.
	left _ itemsBox left.
	y _ itemsBox top.
	items do:
		[: item |
		 thisItemBox _ ((left + 1)@y) corner: itemsBox bottomRight.
		 (QuickPrint
			newOn: aDisplayMedium
			box: thisItemBox) drawString: item asString.
		 y _ y + lineHeight].

	index _ items indexOf: (selectedItem value) ifAbsent: [0].
	((index > 0) & (index <= items size)) ifTrue:
		[highLightBox _
			(left@(itemsBox top + (lineHeight * (index - 1))))
				extent: (itemsBox width@lineHeight).
		 highLightBox _ highLightBox intersect: itemsBox.
		 aDisplayMedium reverse: highLightBox].!

glyphDependsOn

	^(Array
		with: self
		with: box topLeft
		with: box bottomRight),
	 (Array with: selectedItem)!

inputGlyphsInto: aSet

	aSet add: scrollBar.
	aSet add: self.!

selectableGlyphsInto: aSet

	aSet add: box bottomRight.
	aSet add: scrollBar box topLeft.
	aSet add: itemsList.
	aSet add: selectedItem.!

visibleGlyphsInto: aSet

	aSet add: self; add: box.
	aSet add: scrollBar; add: scrollBar box.
	aSet add: itemsList.
	aSet add: selectedItem.!

visibleItems
	"Answer the subset of my itemsList which are currently visible."

	| items itemCount visibleCount max first |
	items _ itemsList value.
	itemCount _ items size.
	visibleCount _ (box extent y // QuickPrint lineHeight) min: itemCount.
	max _ (itemCount - visibleCount) max: 0.
	first _ 1 + ((1.0 - scrollBar node value) * max) rounded.
	"Assertion: first+visibleCount-1 <= itemCount"
	^items copyFrom: first to: (first + visibleCount - 1)! !

!ScrollingListThing methodsFor: 'mouse'!

handleMouseMove: mousePoint view: aView

	| myBox index items selected |
	myBox _ box asRectangle.
	items _ self visibleItems.
	(myBox containsPoint: mousePoint)
		ifTrue:
			[index _
				((mousePoint y - myBox top) // QuickPrint lineHeight) + 1.
			 ((index <= items size) and: [(items at: index) ~= ''])
				ifTrue: [selected _ (items at: index)]
				ifFalse: [selected _ nil]]
		ifFalse: [selected _ nil].
	selectedItem primvalue: selected.!

mouseConstraints

	^Array with: (
		EditConstraint
			ref: 	selectedItem->#value
			strength: ThingLabII editStrength)!

wantsMouse

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScrollingListThing class
	instanceVariableNames: ''!


!ScrollingListThing class methodsFor: 'class initialization'!

initialize
	"ScrollingListThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(65532 32774 49142 32774 49142 32774 65534 61502 65534 32774 49142 32774 49142 32774 65534 32766)
		offset: 0@0).
	explainText _ 'A ScrollingListThing consists of a scroll bar, a menu Thing, and nodes to hold the list of menu items (itemsList) and the selected item (selectedItem). It also has several variables that it uses internally such as the visible item count and the index of the first item to display.'.! !

ScrollingListThing initialize!

ScrollingListThing subclass: #ScrollingListThingMinusNodes
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-MinusNodes'!


!ScrollingListThingMinusNodes methodsFor: 'glyphs'!

selectableGlyphsInto: aSet

	aSet add: box bottomRight.
	aSet add: scrollBar box topLeft.!

visibleGlyphsInto: aSet

	aSet add: self; add: box.
	aSet add: scrollBar; add: scrollBar box.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScrollingListThingMinusNodes class
	instanceVariableNames: ''!


!ScrollingListThingMinusNodes class methodsFor: 'class initialization'!

initialize
	"ScrollingListThingMinusNodes initialize"

	super initialize.
	explainText _ 'I am like a ScrollingListThing except that my connection points are hidden.'.! !

ScrollingListThingMinusNodes initialize!

TrebleClefThing subclass: #BassClefThing
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!BassClefThing methodsFor: 'initialization'!

initializeValues

	self set: #location.x to: 20.
	self set: #location.y to: 40.
	self set: #middleCOffset to: -5.
	self set: #width to: 200.! !

!BassClefThing methodsFor: 'glyphs'!

form

	^Form
		extent: 14@17
		fromArray: #(7936 9088 16844 49388 61664 63712 63712 28908 236 192 448 384 768 1536 3072 6144 24576)
		offset: 6@0! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BassClefThing class
	instanceVariableNames: ''!


!BassClefThing class methodsFor: 'class initialization'!

initialize
	"BassClefThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(3968 4544 8422 24694 30832 31856 31856 14454 118 96 96 192 384 768 1536 3072)
		offset: 0@0).
	explainText _ 'A BassClefThing is a staff with a built in bass clef. See the comment for TrebleClefThing for further details.'.! !

BassClefThing initialize!

BasicTextThing subclass: #NumberText
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Private'!


!NumberText methodsFor: 'initialization'!

initializeValues

	self set: #box.extent.x to: 46.
	self set: #box.extent.y to: 15.
	self set: #node.location.x to: 33.
	self set: #node.location.y to: 28.
	self set: #node.value to: 0.! !

!NumberText methodsFor: 'access'!

displayText
	"Answer the text to be displayed."

	^node value printString! !

!NumberText methodsFor: 'keyboard'!

handleKeystroke: aCharacter view: aView
	"Accept the given character. If it is a digit, update myself. If it is backspace, delete my last digit, if any. If it is a minus sign, change my sign."

	| value valueString |
	value _ node value.
	valueString _ node value printString.
	(value respondsTo: #even) ifFalse:
		[value _ 0. valueString _ '0'].	"if value isn't a number, make it zero"
	((value isInteger not) and: [value fractionPart = 0.0]) ifTrue:
		[valueString _ valueString copyFrom: 1 to: (valueString size - 1)].
	(aCharacter == Character backspace)
		ifTrue: [valueString _ valueString copyFrom: 1 to: (valueString size - 1)]
		ifFalse: [((aCharacter == $.) & (value isInteger))
			ifTrue: [valueString _ value asFloat printString]
			ifFalse: [(aCharacter == $-)
				ifTrue: [valueString _ value negated printString]
				ifFalse: [valueString _ valueString copyWith: aCharacter]]].
	node primvalue: valueString asNumber.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NumberText class
	instanceVariableNames: ''!


!NumberText class methodsFor: 'class initialization'!

initialize
	"NumberText initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 65535 0 0 4492 12882 4162 4236 4354 4626 15308 0 0 65535 0 0)
		offset: 0@0).
	explainText _ 'A NumberText is like a BasicTextThing except that it parses numbers on keyboard entry and stores the resulting numeric value in its node rather than the string itself.'.! !

NumberText initialize!

PrimitiveThing subclass: #NumberPrinter
	instanceVariableNames: 'numberText line '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!NumberPrinter methodsFor: 'initialization'!

initializeConstraints
	"NumberPrinter initialize"

	"layout"
	self require: #numberText.node.location.x equals: #line.p1.x.
	self require: #numberText.node.location.y equals: #line.p1.y.
	self require: #numberText.box.center.x equals: #line.p2.x.
	self require: #numberText.box.center.y equals: #line.p2.y.!

initializeStructure

	numberText _ NumberText cloneFor: self.
	line _ PlainLine cloneFor: self.!

initializeValues

	self set: #numberText.box.center.x to: 35.
	self set: #numberText.box.center.y to: 20.
	self set: #numberText.node.location.x to: 60.
	self set: #numberText.node.location.y to: 60.! !

!NumberPrinter methodsFor: 'access'!

line

	^line!

numberText

	^numberText! !

!NumberPrinter methodsFor: 'glyphs'!

selectableGlyphsInto: aSet

	numberText selectableGlyphsInto: aSet.!

visibleGlyphsInto: aSet

	aSet add: line.
	numberText visibleGlyphsInto: aSet.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NumberPrinter class
	instanceVariableNames: ''!


!NumberPrinter class methodsFor: 'class initialization'!

initialize
	"NumberPrinter initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(65535 32769 41753 42149 41093 41241 41477 42021 42905 32769 65535 256 256 896 896 896)
		offset: 0@0).
	explainText _ 'A NumberPrinter is a numeric value holder that prints its contents in a box. The value may be edited by typing digits, backspaces, the decimal point, and/or the minus sign while the NumberPrinter is selected.'.! !

NumberPrinter initialize!

PrimitiveThing subclass: #OrbitThing
	instanceVariableNames: 'center satellite theta radius rate '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!OrbitThing methodsFor: 'initialization'!

initializeConstraints
	"OrbitThing initialize"

	self defaultStay: #radius.node.value.
	self defaultStay: #rate.node.value.

	"incrementing theta"
	self stronglyPreferEdit:#theta.last.
	self require: 'newTheta = ((oldTheta + delta) \\ 360)'
		where: #((newTheta theta.value)
				 (oldTheta theta.last)
				 (delta rate.node.value)).

	"moving the satellite"
	self methods: #(
			'satX _ centerX + (radius * (theta degreesToRadians cos)).
			 satY _ centerY + (radius * (theta degreesToRadians sin))')
		where: #((satX satellite.x) (satY satellite.y)
				  (centerX center.x) (centerY center.y)
				  (radius radius.node.value) (theta theta.value))
		strength: #preferred.

	"layout"
	self offset: #radius.box.topLeft.x by: 0 from: #rate.box.topLeft.x.
	self offset: #rate.box.topLeft.y by: 0 from: #radius.box.bottomRight.y.!

initializeStructure

	center _ PointThing cloneFor: self.
	satellite _ PointThing cloneFor: self.
	theta _ Node cloneFor: self.
	radius _ NumberText cloneFor: self.
	rate _ NumberText cloneFor: self.!

initializeValues

	self set: #center.x to: 60.
	self set: #center.y to: 40.
	self set: #theta.value to: 0.
	self set: #theta.last to: 0.
	self set: #radius.box.topLeft.x to: 10.
	self set: #radius.box.topLeft.y to: 10.
	self set: #radius.node.value to: 15.		"radius"
	self set: #rate.box.topLeft.x to: 10.
	self set: #rate.box.topLeft.y to: 24. 
	self set: #rate.node.value to: 18.		"degrees/iteration"! !

!OrbitThing methodsFor: 'access'!

center

	^center!

radius

	^radius!

rate

	^rate!

satellite

	^satellite!

theta

	^theta! !

!OrbitThing methodsFor: 'glyphs'!

selectableGlyphsInto: aSet

	aSet add: center; add: satellite.
	aSet add: radius; add: rate.!

visibleGlyphsInto: aSet

	aSet add: center; add: satellite.
	aSet add: radius box; add: radius.
	aSet add: rate box; add: rate.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OrbitThing class
	instanceVariableNames: ''!


!OrbitThing class methodsFor: 'class initialization'!

initialize
	"OrbitThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(544 4104 0 16386 0 32768 1 384 33152 1 0 0 16398 14 4110 576)
		offset: 0@0).
	explainText _ 'An OrbitThing consists of two Points, a center and a satellite. It also has two NumberTexts for specifying the orbit radius and rate (the rate specifies how many degrees to increment theta each iteration).'.! !

OrbitThing initialize!

NumberText subclass: #NumberDisplayer
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!NumberDisplayer methodsFor: 'initialization'!

initializeConstraints
	"NumberDisplayer initialize"

	super initializeConstraints.

	"fix node to bottom, center of box"
	self offset: #node.location.x by: 0 from: #box.center.x.
	self offset: #node.location.y by: 2 from: #box.bottomRight.y.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NumberDisplayer class
	instanceVariableNames: ''!


!NumberDisplayer class methodsFor: 'class initialization'!

initialize
	"NumberDisplayer initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(65535 32769 41753 42149 41093 41241 41477 42021 42905 32769 65535 384 384 0 0 0)
		offset: 0@0).
	explainText _ 'A NumberDisplayer consists of a fixed-size box for displaying the number plus a node to hold the number. The relative locations of the node and display box are fixed by constraints. A NumberDisplayer accepts the keyboard input of numbers just like a NumberPrinter.'.! !

NumberDisplayer initialize!

PrimitiveThing subclass: #Incrementor
	instanceVariableNames: 'node '
	classVariableNames: 'DisplayForm '
	poolDictionaries: ''
	category: 'Things-Primitive'!


!Incrementor methodsFor: 'initialization'!

initializeConstraints
	"Incrementor initialize"

	self stronglyPreferEdit: #node.last.
	self methods: #('current _ last + 1')
		where: #((current node.value) (last node.last))
		strength: #strongPreferred.!

initializeStructure

	node _ Node cloneFor: self.!

initializeValues

	self set: #node.location.x to: 25.
	self set: #node.location.y to: 20.	
	self set: #node.last to: -1.! !

!Incrementor methodsFor: 'access'!

location

	^node location!

node

	^node! !

!Incrementor methodsFor: 'glyphs'!

boundingBox
	"Answer a box around my DisplayForm centered on my location."

	^(self node location asPoint + DisplayForm offset)
		extent: (DisplayForm extent)!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Display my display form at my location."

	DisplayForm
		displayOn: aDisplayMedium
		at: (aDisplayPoint + (node location asPoint))
		clippingBox: clipBox
		rule: (Form paint)
		fillColor: (Color black).!

glyphDependsOn

	^Array with: node location!

selectableGlyphsInto: aSet

	aSet add: node.!

visibleGlyphsInto: aSet

	aSet add: node; add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Incrementor class
	instanceVariableNames: ''!


!Incrementor class methodsFor: 'class initialization'!

initialize
	"Incrementor initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@15
		fromArray: #(960 960 960 960 65535 32769 32769 34833 34833 48765 34833 34833 32769 32769 65535)
		offset: 0@0).
	DisplayForm _ (Form
		extent: 16@15
		fromArray: #(960 960 960 960 65535 32769 32769 34833 34833 48765 34833 34833 32769 32769 65535)
		offset: -8@-2).
	explainText _ 'A Incrementor is history constraint that makes the current value of its node greater by some increment each time history advances.'.! !

Incrementor initialize!

BasicTextThing subclass: #ParagraphThing
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!ParagraphThing methodsFor: 'initialization'!

initializeConstraints
	"ParagraphThing initialize"

	"layout constraints"
	self offset: #node.location.x by: -2 from: #box.topLeft.x.
	self offset: #node.location.y by: 0 from: #box.center.y.!

initializeStructure

	box _ CenterRectThing cloneFor: self.
	node _ Node cloneFor: self.!

initializeValues

	super initializeValues.
	self set: #box.topLeft.x to: 20.
	self set: #box.topLeft.y to: 20.	
	self set: #box.bottomRight.x to: 60.
	self set: #box.bottomRight.y to: 40.! !

!ParagraphThing methodsFor: 'glyphs'!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox
	"Print my text as a Paragraph in my box."

	| textBox paragraph |
	textBox _ ((box asRectangle) insetOriginBy: 5@1 cornerBy: 4@1)
				moveBy: aDisplayPoint.
	(textBox width < 10) ifTrue: [^self].		"too narrow to display text"

	paragraph _ Paragraph new.
	paragraph
		compositionRectangle: (0@0 extent: textBox extent);
		text: (self displayText asText).
	paragraph
		displayOn: aDisplayMedium
		at: (aDisplayPoint + textBox topLeft)
		clippingBox: (clipBox intersect: textBox).!

selectableGlyphsInto: aSet

	aSet
		add: box topLeft;
		add: box bottomRight;
		add: node;
		add: self.!

visibleGlyphsInto: aSet

	aSet add: box; add: node; add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ParagraphThing class
	instanceVariableNames: ''!


!ParagraphThing class methodsFor: 'class initialization'!

initialize
	"ParagraphThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #( 0 16383 8193 11197 8193 11757 8193 61301 57345 11229 8193 11757 8193 8193 16383 0)
		offset: 0@0).
	explainText _ 'A ParagraphThing is a read-only viewer for text.'.! !

ParagraphThing initialize!

ParagraphThing subclass: #ParagraphThingMinusNodes
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-MinusNodes'!


!ParagraphThingMinusNodes methodsFor: 'glyphs'!

selectableGlyphsInto: aSet

	aSet
		add: box topLeft;
		add: box bottomRight;
		add: self.!

visibleGlyphsInto: aSet

	aSet add: box; add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ParagraphThingMinusNodes class
	instanceVariableNames: ''!


!ParagraphThingMinusNodes class methodsFor: 'class initialization'!

initialize
	"ParagraphThingMinusNodes initialize"

	super initialize.
	explainText _ 'I am like a ParagraphThing except that my connection points are hidden.'.! !

ParagraphThingMinusNodes initialize!

BasicTextThing subclass: #TextThing
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!TextThing methodsFor: 'initialization'!

initializeConstraints
	"TextThing initialize"

	super initializeConstraints.

	self methods: #('width _ (QuickPrint width: text) + 4')
		where: #((width box.extent.x) (text node.value))
		strength: #strongPreferred.

	self methods: #('height _ (QuickPrint lineHeight) + 4')
		where: #((height box.extent.y))
		strength: #strongPreferred.! !

!TextThing methodsFor: 'glyphs'!

location

	^box topLeft!

selectableGlyphsInto: aSet

	aSet add: self.!

visibleGlyphsInto: aSet

	aSet add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextThing class
	instanceVariableNames: ''!


!TextThing class methodsFor: 'class initialization'!

initialize
	"TextThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 65535 0 0 4559 14633 27944 17864 32040 17705 17871 0 0 65535 0 0)
		offset: 0@0).
	explainText _ 'A TextThing is like a BasicTextThing except that its node and box outline are invisible. It is handy for adding labels to a Thing.'.! !

!TextThing class methodsFor: 'instance creation'!

newWith: aString
	"Answer a new instance of me initialized with the given string."

	^(self new) set: #node.value to: aString! !

TextThing initialize!

PrimitiveThing subclass: #CustomConstraintThing
	instanceVariableNames: 'label strength '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Private'!


!CustomConstraintThing methodsFor: 'initialization'!

initializeStructure

	label _ TextThing cloneFor: self.!

initializeValues

	self set: #label.node.value to: ' Custom '.
	self set: #label.box.center.x to: 40.
	self set: #label.box.center.y to: 50.
	self set: #label.box.fillRule to: Form under.
	strength _ #strongPreferred.! !

!CustomConstraintThing methodsFor: 'access'!

baseStrength

	^strength!

baseStrength: strengthSymbol

	strength _ strengthSymbol.!

label

	^label! !

!CustomConstraintThing methodsFor: 'glyphs'!

boundingBox

	^label box asRectangle!

inputGlyphsInto: aSet

	super inputGlyphsInto: aSet.
	aSet add: self.!

visibleGlyphsInto: aSet

	super visibleGlyphsInto: aSet.
	aSet add: label box.! !

!CustomConstraintThing methodsFor: 'mouse'!

handleMouseDown: mousePoint view: aView

	ConstraintDefiner openOn: self view: aView.!

mouseConstraints
	"No mouse constraints."

	^#()!

wantsMouse

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CustomConstraintThing class
	instanceVariableNames: ''!


!CustomConstraintThing class methodsFor: 'class initialization'!

initialize
	"CustomConstraintThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(384 384 65535 32769 34689 35937 39105 38913 38913 39009 36033 34689 32769 65535 384 384)
		offset: 0@0).
	explainText _ 'A CustomConstaint allows the user to define his own constraint function over N variables.'.! !

CustomConstraintThing initialize!

PrimitiveThing subclass: #TreeNodeThing
	instanceVariableNames: 'text width '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!TreeNodeThing methodsFor: 'initialization'!

initializeStructure

	text _ TextThing cloneFor: self.!

initializeValues

	self set: #text.node.value to: 'ABC'.
	self set: #width to: 0.! !

!TreeNodeThing methodsFor: 'access'!

primwidth: aNumber

	width _ aNumber.!

text

	^text!

width

	^width! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TreeNodeThing class
	instanceVariableNames: ''!


!TreeNodeThing class methodsFor: 'class initialization'!

initialize
	"TreeNodeThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 65535 0 0 4559 14633 27944 17864 32040 17705 17871 0 0 65535 0 0)
		offset: 0@0).
	explainText _ 'A TreeNodeThing holds an editable string that may be used as a label in a tree.'.! !

TreeNodeThing initialize!

PrimitiveThing subclass: #ButtonThing
	instanceVariableNames: 'text node action '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!ButtonThing methodsFor: 'initialization'!

destroy

	"constraints do:
		[: c |
		 c variables do: [: ref | ref destroy].
		 c destroy]."
	action _ nil.
	super destroy.!

initializeConstraints
	"ButtonThing initialize"

	self methods: #(
			'color _ (value = 0) ifTrue: [Color white] ifFalse: [Color black]')
		where: #((color text.box.fillMask) (value node.value))
		strength: #strongPreferred.

	"layout"
	self offset: #text.box.center.x by: 0 from: #node.location.x.
	self offset: #node.location.y by: 4 from: #text.box.bottomRight.y.!

initializeStructure

	text _ TextThing cloneFor: self.
	node _ Node cloneFor: self.!

initializeValues

	self set: #text.node.value to: ' Button '.
	self set: #text.box.fillRule to: Form reverse.
	self set: #node.value to: 0.
	self set: #node.last to: 0.
	self set: #node.location.x to: 35.
	self set: #node.location.y to: 35.
	action _ nil.! !

!ButtonThing methodsFor: 'access'!

action

	^action!

location

	^text box topLeft!

node

	^node!

primaction: aBlock
	"Set the action for this button, a block that takes the enclosing view as its argument."

	action _ aBlock.!

text

	^text! !

!ButtonThing methodsFor: 'glyphs'!

boundingBox

	^text boundingBox!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	text displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox.
	text box displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox.!

glyphDependsOn

	^(Array
		with: text box topLeft
		with: text box bottomRight
		with: text node	"button label text"
		with: node)		"button value"!

inputGlyphsInto: aSet

	aSet add: text; add: self.!

selectableGlyphsInto: aSet

	aSet add: text; add: node.!

visibleGlyphsInto: aSet

	aSet add: node; add: self.! !

!ButtonThing methodsFor: 'mouse'!

handleMouseDown: mousePoint view: aView

	node primvalue: 1.!

handleMouseUp: mousePoint view: aView

	((self containsPoint: mousePoint) and: [action notNil]) ifTrue:
		[action value: aView].
	node primvalue: 0.!

mouseConstraints
	"No mouse constraints."

	^Array
		with: (EditConstraint
				ref: 	self->#node.value
				strength: ThingLabII editStrength)!

wantsMouse

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ButtonThing class
	instanceVariableNames: ''!


!ButtonThing class methodsFor: 'class initialization'!

initialize
	"ButtonThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 128 128 128 672 448 128 4095 4097 8195 16389 32761 16401 16402 16404 32760)
		offset: 0@0).
	explainText _ 'A ButtonThing consists of a label and a Node. The Node value is 1 while the button is depressed, 0 otherwise.'.! !

ButtonThing initialize!

CustomConstraintThing subclass: #CustomTwo
	instanceVariableNames: 'wire1 wire2 '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!CustomTwo methodsFor: 'initialization'!

initializeConstraints
	"CustomTwo initialize"

	"layout constraints"
	super initializeConstraints.
	self offset: #wire1.node1.location.x by: 0 from: #label.box.center.x.
	self offset: #wire1.node1.location.y by: -2 from: #label.box.topLeft.y.
	self offset: #wire2.node1.location.x by: 0 from: #label.box.center.x.
	self offset: #wire2.node1.location.y by: 2 from: #label.box.bottomRight.y.!

initializeStructure

	super initializeStructure.
	wire1 _ WireThing cloneFor: self.
	wire2 _ WireThing cloneFor: self.!

initializeValues

	super initializeValues.
	self set: #wire1.node2.location.x to: (wire1 node1 location x).
	self set: #wire1.node2.location.y to: 10.
	self set: #wire2.node2.location.x to:  (wire2 node1 location x).
	self set: #wire2.node2.location.y to: 90.! !

!CustomTwo methodsFor: 'access'!

wire1

	^wire1!

wire2

	^wire2! !

!CustomTwo methodsFor: 'custom constraint'!

baseConstraint

	^self constraints
		detect: [: c | c isMemberOf: Constraint]
		ifNone:
			[Constraint
				symbols: #(a b)
				methodStrings: #()
				refs: (Array
					with: self->#wire1.node1.value
					with: self->#wire2.node1.value)
				strength: strength]!

baseConstraint: newConstraint

	| oldConstraint |
	oldConstraint _ self constraints
		detect: [: c | c isMemberOf: Constraint]
		ifNone: [nil].
	(oldConstraint notNil) ifTrue:
		[self removeConstraint: oldConstraint.
		 oldConstraint destroy].
	(newConstraint notNil) ifTrue:
		[newConstraint
			bind: (Array
				with: self->#wire1.node1.value
				with: self->#wire2.node1.value)
 			strength: strength.
		 self addConstraint: newConstraint].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CustomTwo class
	instanceVariableNames: ''!


!CustomTwo class methodsFor: 'class initialization'!

initialize
	"CustomTwo initialize"

	super initialize.! !

CustomTwo initialize!

CustomConstraintThing subclass: #CustomFour
	instanceVariableNames: 'wire1 wire2 wire3 wire4 '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!CustomFour methodsFor: 'initialization'!

initializeConstraints
	"CustomFour initialize"

	"layout constraints"
	super initializeConstraints.
	self offset: #wire1.node1.location.x by: -4 from: #label.box.center.x.
	self offset: #wire1.node1.location.y by: -2 from: #label.box.topLeft.y.
	self offset: #wire2.node1.location.x by: 4 from: #label.box.center.x.
	self offset: #wire2.node1.location.y by: -2 from: #label.box.topLeft.y.
	self offset: #wire3.node1.location.x by: -4 from: #label.box.center.x.
	self offset: #wire3.node1.location.y by: 2 from: #label.box.bottomRight.y.
	self offset: #wire4.node1.location.x by: 4 from: #label.box.center.x.
	self offset: #wire4.node1.location.y by: 2 from: #label.box.bottomRight.y.!

initializeStructure

	super initializeStructure.
	wire1 _ WireThing cloneFor: self.
	wire2 _ WireThing cloneFor: self.
	wire3 _ WireThing cloneFor: self.
	wire4 _ WireThing cloneFor: self.!

initializeValues

	super initializeValues.
	self set: #wire1.node2.location.x to: (wire1 node1 location x).
	self set: #wire1.node2.location.y to: 10.
	self set: #wire2.node2.location.x to: (wire2 node1 location x).
	self set: #wire2.node2.location.y to: 10.
	self set: #wire3.node2.location.x to: (wire3 node1 location x).
	self set: #wire3.node2.location.y to: 90.
	self set: #wire4.node2.location.x to: (wire4 node1 location x).
	self set: #wire4.node2.location.y to: 90.! !

!CustomFour methodsFor: 'access'!

wire1

	^wire1!

wire2

	^wire2!

wire3

	^wire3!

wire4

	^wire4! !

!CustomFour methodsFor: 'custom constraint'!

baseConstraint

	^self constraints
		detect: [: c | c isMemberOf: Constraint]
		ifNone:
			[Constraint
				symbols: #(a b c d)
				methodStrings: #()
				refs: (Array
					with: self->#wire1.node1.value
					with: self->#wire2.node1.value
					with: self->#wire3.node1.value
					with: self->#wire4.node1.value)
				strength: strength]!

baseConstraint: newConstraint

	| oldConstraint |
	oldConstraint _ self constraints
		detect: [: c | c isMemberOf: Constraint]
		ifNone: [nil].
	(oldConstraint notNil) ifTrue:
		[self removeConstraint: oldConstraint.
		 oldConstraint destroy].
	(newConstraint notNil) ifTrue:
		[newConstraint
			bind: (Array
				with: self->#wire1.node1.value
				with: self->#wire2.node1.value
				with: self->#wire3.node1.value
				with: self->#wire4.node1.value)
			strength: strength.
		 self addConstraint: newConstraint].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CustomFour class
	instanceVariableNames: ''!


!CustomFour class methodsFor: 'class initialization'!

initialize
	"CustomFour initialize"

	super initialize.! !

CustomFour initialize!

ButtonThing subclass: #ButtonThingMinusNodes
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-MinusNodes'!


!ButtonThingMinusNodes methodsFor: 'glyphs'!

selectableGlyphsInto: aSet

	aSet add: text.!

visibleGlyphsInto: aSet

	aSet add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ButtonThingMinusNodes class
	instanceVariableNames: ''!


!ButtonThingMinusNodes class methodsFor: 'class initialization'!

initialize
	"ButtonThingMinusNodes initialize"

	super initialize.
	explainText _ 'I am like a ButtonThing except that my connection point is hidden.'.! !

ButtonThingMinusNodes initialize!

CustomConstraintThing subclass: #CustomThree
	instanceVariableNames: 'wire1 wire2 wire3 '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!CustomThree methodsFor: 'initialization'!

initializeConstraints
	"CustomThree initialize"

	"layout constraints"
	super initializeConstraints.
	self offset: #wire1.node1.location.x by: -4 from: #label.box.center.x.
	self offset: #wire1.node1.location.y by: -2 from: #label.box.topLeft.y.
	self offset: #wire2.node1.location.x by: 4 from: #label.box.center.x.
	self offset: #wire2.node1.location.y by: -2 from: #label.box.topLeft.y.
	self offset: #wire3.node1.location.x by: 0 from: #label.box.center.x.
	self offset: #wire3.node1.location.y by: 2 from: #label.box.bottomRight.y.!

initializeStructure

	super initializeStructure.
	wire1 _ WireThing cloneFor: self.
	wire2 _ WireThing cloneFor: self.
	wire3 _ WireThing cloneFor: self.!

initializeValues

	super initializeValues.
	self set: #wire1.node2.location.x to: (wire1 node1 location x).
	self set: #wire1.node2.location.y to: 10.
	self set: #wire2.node2.location.x to: (wire2 node1 location x).
	self set: #wire2.node2.location.y to: 10.
	self set: #wire3.node2.location.x to: (wire3 node1 location x).
	self set: #wire3.node2.location.y to: 90.! !

!CustomThree methodsFor: 'access'!

wire1

	^wire1!

wire2

	^wire2!

wire3

	^wire3! !

!CustomThree methodsFor: 'custom constraint'!

baseConstraint

	^self constraints
		detect: [: c | c isMemberOf: Constraint]
		ifNone:
			[Constraint
				symbols: #(a b c)
				methodStrings: #()
				refs: (Array
					with: self->#wire1.node1.value
					with: self->#wire2.node1.value
					with: self->#wire3.node1.value)
				strength: strength]!

baseConstraint: newConstraint

	| oldConstraint |
	oldConstraint _ self constraints
		detect: [: c | c isMemberOf: Constraint]
		ifNone: [nil].
	(oldConstraint notNil) ifTrue:
		[self removeConstraint: oldConstraint.
		 oldConstraint destroy].
	(newConstraint notNil) ifTrue:
		[newConstraint
			bind: (Array
				with: self->#wire1.node1.value
				with: self->#wire2.node1.value
				with: self->#wire3.node1.value)
 			strength: strength.
		 self addConstraint: newConstraint].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CustomThree class
	instanceVariableNames: ''!


!CustomThree class methodsFor: 'class initialization'!

initialize
	"CustomThree initialize"

	super initialize.! !

CustomThree initialize!

PrimitiveThing subclass: #Product
	instanceVariableNames: 'op '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!Product methodsFor: 'initialization'!

initializeConstraints
	"Product initialize"

	self methods: #(
			'prod _ m1 asFloat * m2'
			'm1 _ prod asFloat / m2 asFloat asNonZero'
			'm2 _ prod asFloat / m1 asFloat asNonZero')
		where: #((prod op.c.value) (m1 op.a.value) (m2 op.b.value))
		strength: #required.!

initializeStructure

	op _ ThreeWayOp cloneFor: self.!

initializeValues

	self set: #op.a.value to: 0.
	self set: #op.b.value to: 0.
	self set: #op.c.value to: 0.
	self set: #op.opForm to:
		(Form
			extent: 9@11
			fromArray: #(15872 16640 32896 46720 40064 34944 40064 46720 32896 16640 15872)
			offset: -4@-5).! !

!Product methodsFor: 'access'!

op

	^op! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Product class
	instanceVariableNames: ''!


!Product class methodsFor: 'class initialization'!

initialize
	"Product initialize"

	self initializePrimitive.
	partIcon _ Form
		extent: 16@16
		fromArray: #(8184 16380 28686 57351 49155 50211 49731 49539 49539 49731 50211 49155 57351 28686 16380 8184)
		offset: 0@0.
	explainText _ 'A Product is a three operand arithmetic constraint, x * y = z'.! !

Product initialize!

PrimitiveThing subclass: #TwoWayOp
	instanceVariableNames: 'location opForm a b '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Private'!


!TwoWayOp methodsFor: 'initialization'!

initializeStructure

	a _ Node cloneFor: self.
	b _ Node cloneFor: self.
	location _ PointThing cloneFor: self.!

initializeValues

	self set: #a.location.x to: 20.
	self set: #a.location.y to: 30.
	self set: #b.location.x to: 80.
	self set: #b.location.y to: 30.
	self set: #location.x to: 50.
	self set: #location.y to: 30.
	self set: #opForm to:
		(Form
			extent: 9@9
			fromArray: #(65408 32896 40064 41600 33920 34944 32896 34944 65408)
			offset: -4@-4).! !

!TwoWayOp methodsFor: 'glyphs'!

boundingBox
	"Answer a box around my opForm centered on my location."

	^(location asPoint + opForm offset)
		extent: (opForm extent)!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	| line |
	line _ Line
		from: (location asPoint)
		to: 0@0	"filled in below"
		withForm: (Form extent: 1@1) black.
	(Array with: a with: b) do:
		[: part |
		 line endPoint: part location asPoint.
		 line
			displayOn: aDisplayMedium
			at: aDisplayPoint
			clippingBox: clipBox
			rule: (Form paint)
			fillColor: (Color black)].
	opForm
		displayOn: aDisplayMedium
		at: (aDisplayPoint + location asPoint)
		clippingBox: clipBox
		rule: (Form over)
		fillColor: (Color black).!

glyphDependsOn

	^Array
		with: self location
		with: a location
		with: b location!

selectableGlyphsInto: aSet

	a visibleGlyphsInto: aSet.
	b visibleGlyphsInto: aSet.
	aSet add: self.!

visibleGlyphsInto: aSet

	a visibleGlyphsInto: aSet.
	b visibleGlyphsInto: aSet.
	aSet add: self.! !

!TwoWayOp methodsFor: 'access'!

a

	^a!

b

	^b!

location

	^location!

opForm

	^opForm!

primopForm: aForm

	opForm _ aForm.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TwoWayOp class
	instanceVariableNames: ''!


!TwoWayOp class methodsFor: 'class initialization'!

initialize
	"TwoWayOp initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(8184 16380 28686 59367 53235 52275 52787 50787 49347 49539 49155 49539 57735 28686 16380 8184)
		offset: 0@0).
	explainText _ 'A TwoWayOp is a template for two operand operators. It is used as a sub-part of other Things, rather than as a stand-alone Thing. It provides two Nodes and an operator Form.'.! !

TwoWayOp initialize!

PrimitiveThing subclass: #Invert
	instanceVariableNames: 'op '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!
Invert comment:
'This Thing is a copy of Sum as of 18-Jan-89 modified to handle Forms.  This Thing inverts the bitmap as it goes through.'!


!Invert methodsFor: 'initialization'!

initializeConstraints
	"Invert initialize"

	self methods: #(
			'a _ b deepCopy reverse'
			'b _ a deepCopy reverse')
		where: #((a op.a.value) (b op.b.value))
		strength: #strongPreferred.!

initializeStructure

	op _ TwoWayOp cloneFor: self.!

initializeValues

	self set: #op.a.value to: (Form extent: 30@20).
	self set: #op.b.value to: (Form extent: 30@20).
	self set: #op.opForm to:
		(Form
			extent: 9@9
			fromArray: #(32512 65408 60288 60288 48768 56704 58240 65408 32512 )
			offset: -4@-4).! !

!Invert methodsFor: 'access'!

op

	^op! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Invert class
	instanceVariableNames: ''!


!Invert class methodsFor: 'class initialization'!

initialize
	"Invert initialize"

	self initializePrimitive.
	partIcon _ Form
		extent: 16@16
		fromArray: #(8184 16380 32766 65535 63903 63903 65535 65535 65535 59367 58311 61455 63519 32766 16380 8184)
		offset: 0@0.
	explainText _ 'An Invert is a two operand Form constraint, a = invert(b)'.! !

Invert initialize!

PrimitiveThing subclass: #PointSplitter
	instanceVariableNames: 'op point '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!PointSplitter methodsFor: 'initialization'!

initializeConstraints
	"PointSplitter initialize"

	self require: #op.a.value equals: #point.x.
	self require: #op.b.value equals: #point.y.

	"layout constraints"
	self offset: #op.a.location.x by: -5 from: #op.location.x.
	self offset: #op.a.location.y by: -7 from: #op.location.y.
	self offset: #op.b.location.x by: 6 from: #op.location.x.
	self offset: #op.b.location.y by: -7 from: #op.location.y.!

initializeStructure

	op _ TwoWayOp cloneFor: self.
	point _ PointThing cloneFor: self.!

initializeValues

	self set: #op.a.value to: 30.
	self set: #op.b.value to: 30.
	self set: #op.opForm to:
		(Form
			extent: 21@9
			fromArray: #(65535 63488 32800 2048 37156 18432 35364 18432 33827 34816 35361 2048 37153 2048 32800 2048 65535 63488)
			offset: -10@-5).! !

!PointSplitter methodsFor: 'access'!

op

	^op!

point

	^point! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PointSplitter class
	instanceVariableNames: ''!


!PointSplitter class methodsFor: 'class initialization'!

initialize
	"PointSplitter initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(0 0 0 0 14392 14392 65535 33025 42309 39225 39185 42257 33025 65535 0 0)
		offset: 0@0).
	explainText _ 'A PointSplitter relates a point to separate nodes for its x and y parts. This allows one to perform arithmetic on points.'.! !

PointSplitter initialize!

PrimitiveThing subclass: #FatBits
	instanceVariableNames: 'op '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!FatBits methodsFor: 'initialization'!

initializeConstraints
	"FatBits initialize"

	self methods: #(
			'a _ b shrinkBy: 2@2'
			'b _ a magnifyBy: 2@2')
		where: #((a op.a.value) (b op.b.value))
		strength: #strongPreferred.!

initializeStructure

	op _ TwoWayOp cloneFor: self.!

initializeValues

	self set: #op.a.value to: (Form extent: 30@20).
	self set: #op.b.value to: (Form extent: 30@20).
	self set: #op.opForm to:
		(Form
			extent: 9@9
			fromArray: #(32512 49536 46720 46720 32896 48768 48768 49536 32512)
			offset: -4@-4).! !

!FatBits methodsFor: 'access'!

op

	^op! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FatBits class
	instanceVariableNames: ''!


!FatBits class methodsFor: 'class initialization'!

initialize
	"FatBits initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(8184 16380 28686 58983 52851 52851 52851 49155 55323 56379 57339 53235 59367 28686 16380 8184)
		offset: 0@0).
	explainText _ 'A FatBits is a two operand graphic Thing.  One Form is constrainted to be twice the size of the other.'.! !

FatBits initialize!

PrimitiveThing subclass: #VerticalFlip
	instanceVariableNames: 'op '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!VerticalFlip methodsFor: 'initialization'!

initializeConstraints
	"VerticalFlip initialize"

	self methods: #(
			'a _ b reflect: 0@1'
			'b _ a reflect: 0@1')
		where: #((a op.a.value) (b op.b.value))
		strength: #strongPreferred.!

initializeStructure

	op _ TwoWayOp cloneFor: self.!

initializeValues

	self set: #op.a.value to: (Form extent: 30@20).
	self set: #op.b.value to: (Form extent: 30@20).
	self set: #op.opForm to:
		(Form
			extent: 9@9
			fromArray: #(32512 49536 40064 41600 32896 38016 32896 49536 32512)
			offset: -4@-4).! !

!VerticalFlip methodsFor: 'access'!

op

	^op! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VerticalFlip class
	instanceVariableNames: ''!


!VerticalFlip class methodsFor: 'class initialization'!

initialize
	"VerticalFlip initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(8184 16380 28686 57351 51171 53235 52275 49155 49155 50787 50787 50787 57351 28686 16380 8184)
		offset: 0@0).
	explainText _ 'VerticalFlip flips a Form about the X axis, i.e. it turns things upside down.'.! !

VerticalFlip initialize!

Node subclass: #NodeMinusNodes
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-MinusNodes'!


!NodeMinusNodes methodsFor: 'glyphs'!

selectableGlyphsInto: aSet!

visibleGlyphsInto: aSet! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NodeMinusNodes class
	instanceVariableNames: ''!


!NodeMinusNodes class methodsFor: 'class initialization'!

initialize
	"NodeMinusNodes initialize"

	super initialize.
	explainText _ 'I am an invisible Node.'.! !

NodeMinusNodes initialize!

VSliderThing subclass: #VSliderThingMinusNodes
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-MinusNodes'!


!VSliderThingMinusNodes methodsFor: 'glyphs'!

selectableGlyphsInto: aSet!

visibleGlyphsInto: aSet

	aSet add: box; add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VSliderThingMinusNodes class
	instanceVariableNames: ''!


!VSliderThingMinusNodes class methodsFor: 'class initialization'!

initialize
	"VSliderThingMinusNodes initialize"

	super initialize.
	explainText _ 'I am like a VSliderThing except that my connection points are hidden.'.! !

VSliderThingMinusNodes initialize!

PrimitiveThing subclass: #NoteThing
	instanceVariableNames: 'time pitch type location stemDirection '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Things-Primitive'!


!NoteThing methodsFor: 'initialization'!

initializeStructure

	location _ PointThing cloneFor: self.!

initializeValues

	self set: #location.x to: 20.
	self set: #location.y to: 40.
	self set: #time to: 0.
	self set: #pitch to: 60.		"middle c"
	self set: #type to: 3.		"quarter note"
	self set: #stemDirection to: #up.! !

!NoteThing methodsFor: 'access'!

duration
	"Duration is a read-only virtual part."

	(type == 1) ifTrue: [^15].		"sixteenth"
	(type == 2) ifTrue: [^30].		"eighth"
	(type == 3) ifTrue: [^60].		"quarter"
	(type == 4) ifTrue: [^120].		"half"
	(type == 5) ifTrue: [^240].		"whole"
	^60		"default: pretend I am a quarter note"!

location

	^location!

pitch

	^pitch!

primpitch: aNumber

	pitch _ aNumber.!

primstemDirection: aSymbol
	"#up or #down"

	stemDirection _ aSymbol.!

primtime: aNumber

	time _ aNumber.!

primtype: aNumber

	type _ aNumber.!

stemDirection
	"#up or #down"

	^stemDirection!

time

	^time!

type

	^type! !

!NoteThing methodsFor: 'glyphs'!

boundingBox

	^(self form computeBoundingBox)
		translateBy: self form offset + location asPoint!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipBox

	self form
		displayOn: aDisplayMedium
		at: aDisplayPoint + location asPoint	
		clippingBox: clipBox
		rule: Form paint
		fillColor: Color black.!

downForm

	(type == 1) ifTrue:
		[^(Form
			extent: 6@20
			fromArray: #(14336 31744 64512 63488 61440 34816 33792 33792 35840 38912 47104 62464 58368 52224 39936 47104 61440 57344 49152 32768)
			offset: -3@-2)].
	(type == 2) ifTrue:
		[^(Form
			extent: 7@20
			fromArray: #( 14336 31744 64512 63488 61440 33792 33280 33280 33280 33280 34304 34304 35840 39936 47104 61440 57344 49152 32768 32768)
			offset: -3@-2)].
	(type == 3) ifTrue:
		[^(Form
			extent: 6@20
			fromArray: #( 14336 31744 64512 63488 61440 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768)
			offset: -3@-2)].
	(type == 4) ifTrue:
		[^(Form
			extent: 6@20
			fromArray: #(14336 25600 52224 38912 61440 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768)
			offset: -3@-2)].
	(type == 5) ifTrue:
		[^(Form
			extent: 9@5
			fromArray: #(7936 26496 58240 62208 31744)
			offset: -4@-2)].

	"default: pretend I am a quarter note"
	^(Form
			extent: 6@20
			fromArray: #( 14336 31744 64512 63488 61440 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768 32768)
			offset: -3@-2)!

form

	(stemDirection == #up)
		ifTrue: [^self upForm]
		ifFalse: [^self downForm]!

glyphDependsOn

	^Array
		with: location
		with: self!

selectableGlyphsInto: aSet

	aSet add: self.!

upForm

	(type == 1) ifTrue:
		[^(Form
			extent: 11@21
			fromArray: #(1024 1024 1536 1792 1792 1408 1216 1088 1632 1824 1952 1248 1088 1056 1056 1056 15392 31808 64512 63488 28672)
			offset: -3@-18)].
	(type == 2) ifTrue:
		[^(Form
			extent: 11@21
			fromArray: #(1024 1024 1536 1792 1920 1472 1216 1120 1120 1056 1056 1056 1056 1056 1088 1152 15360 31744 64512 63488 28672)
			offset: -3@-18)].
	(type == 3) ifTrue:
		[^(Form
			extent: 6@20
			fromArray: #(1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 15360 31744 64512 63488 28672)
			offset: -3@-17)].
	(type == 4) ifTrue:
		[^(Form
			extent: 6@20
			fromArray: #(1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 15360 25600 52224 38912 28672)
			offset: -3@-17)].
	(type == 5) ifTrue:
		[^(Form
			extent: 9@5
			fromArray: #(7936 26496 58240 62208 31744)
			offset: -4@-2)].

	"default: pretend I am a quarter note"
	^(Form
		extent: 6@20
		fromArray: #(1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 1024 15360 31744 64512 63488 28672)
		offset: -3@-17)!

visibleGlyphsInto: aSet

	aSet add: self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NoteThing class
	instanceVariableNames: ''!


!NoteThing class methodsFor: 'class initialization'!

initialize
	"NoteThing initialize"

	self initializePrimitive.
	partIcon _ (Form
		extent: 16@16
		fromArray: #(128 192 224 240 184 152 140 140 140 140 136 1936 3968 8064 7936 3584)
		offset: 0@0).
	explainText _ 'A NoteThing represents a displayable note. It has a pitch, a duration type, a starting time, a stem direction, and a location.'.! !

NoteThing initialize!


