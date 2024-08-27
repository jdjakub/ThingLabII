Controller subclass: #SwitchController
	instanceVariableNames: 'selector arguments cursor '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ST80-Interface-Menus'!
SwitchController comment:
'
I coordinate the interaction of a Switch, a SwitchView, and input events (user actions, see class Sensor).  My instances own a message in the form of a selector and an array of arguments.  Whenever the Switch is selected, this message is sent to the Switch.

Instance Variables:

	selector	<Symbol>
	arguments	<Array>
'!


!SwitchController methodsFor: 'initialize-release'!
initialize
	super initialize.
	selector _ #switch.
	arguments _ Array new: 0! !

!SwitchController methodsFor: 'accessing'!
addArgument: aValue 
	"Add the argument, aValue, as one of the arguments of the message
	the receiver sends to its model."
	arguments _ arguments copyWith: aValue!
arguments
	"Answer the arguments the receiver sends in a message to its receiver."
	^arguments!
arguments: anArray
	"The argument, anArray, consists of the arguments of the message
	the receiver sends to its model."
	arguments _ anArray!
cursor: aCursor
	cursor _ aCursor!
selector
	"Answer the selector the receiver sends in a message to its receiver."
	^selector!
selector: aSymbol 
	"Set aSymbol to be the selector the receiver sends in a message to its model."
	selector _ aSymbol! !

!SwitchController methodsFor: 'basic control sequence'!
controlInitialize
	view indicatorReverse!
controlTerminate
	view indicatorReverse.
	self viewHasCursor ifTrue: [self sendMessage]!
sendMessage
	"The receiver consists of a selector and possibly of arguments that should be
	used to create a message to send to the receiver's model."
	arguments size = 0
		ifTrue: [model perform: selector]
		ifFalse: [model perform: selector withArguments: arguments]! !

!SwitchController methodsFor: 'control defaults'!
controlActivity
	^ self!
isControlActive
	^sensor anyButtonPressed & self viewHasCursor!
isControlWanted
	self viewHasCursor ifTrue: [cursor == nil ifFalse: [cursor show]].
	^self viewHasCursor & sensor redButtonPressed! !

View subclass: #SwitchView
	instanceVariableNames: 'complemented label selector keyCharacter highlightForm arguments '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'ST80-Interface-Menus'!
SwitchView comment:
'I am a view of a Switch.  My instances have labels and display modes (set to "normal" or "complemented").  When one of my instances is displayed in complemented mode, its inside color is reversed.  The value of the display mode corresponds to the value of the model so that, for example, when a Switch is off, its SwitchView is displayed with black text (for the label) on a white background, and when the Switch is off, its SwitchView is displayed with white text on a black background.  My instances have a key character that can be used for switching on or off.  Highlighting can be done specially using a stored form, rather than simply changing all black bits to white and vice versa.  My default controller is SwitchController.

Instance Variables:
		complemented		<Boolean> true if the model is on
		label				<DisplayObject>, for example, a DisplayText or a Form
		selector				<Symbol>
		keyCharacter		<Character>
		highlightForm		<Form>
		arguments			<Array>
'!


!SwitchView methodsFor: 'initialize-release'!
initialize
	super initialize.
	insideColor _ Color white.
	complemented _ false.
	label _ nil.
	selector _ #isOn.
	arguments _ #()!
release
	super release.
	label release! !

!SwitchView methodsFor: 'accessing'!
arguments
	"Answer the arguments the receiver sends in a message to its receiver."
	^arguments!
arguments: anArray
	"The argument, anArray, consists of the arguments of the message
	the receiver sends to its model."
	arguments _ anArray!
highlightForm: aForm 
	"The argument is the form to be used to highlight the receiver."
	highlightForm _ aForm!
key: aCharacter 
	"Set the receiver to be selected by the argument, aCharacter."
	keyCharacter _ aCharacter! !

!SwitchView methodsFor: 'testing'!
containsKey: aCharacter 
	"Answer whether the receiver can be selected by the argument, aCharacter."
	^keyCharacter = aCharacter! !

!SwitchView methodsFor: 'controller access'!
defaultControllerClass
	^SwitchController! !

!SwitchView methodsFor: 'window access'!
defaultWindow
	"Returns the frame of the SwitchView's label's frame (slightly enlarged) 
	if the label exists, and returns the standard View default window (see 
	View|defaultWindow), otherwise."

	label == nil
		ifTrue: [^super defaultWindow]
		ifFalse: [^label boundingBox expandBy: 6]!
window: aWindow 
	super window: aWindow.
	self centerLabel! !

!SwitchView methodsFor: 'displaying'!
display
	"Sets the SwitchView mode to 'normal', displays the border, displays the 
	inside and, if its model is 'on', complements the inside."

	self displayBorder.
	complemented _ self interrogateModel.
	highlightForm == nil
		ifTrue: [self displayView.
				complemented ifTrue: [self highlight]]
		ifFalse: [self displaySpecial]!
displayComplemented
	"Complement the receiver if its mode is 'normal'."
	complemented
		ifFalse: 
			[complemented _ true.
			self highlight]!
displayNormal
	"Complement the receiver if its mode is 'complemented'."
	complemented
		ifTrue: 
			[complemented _ false.
			self highlight]!
displaySpecial
	complemented
		ifTrue: [self displaySpecialComplemented].
	label == nil 
		ifFalse: [label
					displayOn: Display
					transformation: self displayTransformation
					clippingBox: self insetDisplayBox
					align: label boundingBox center
					with: label boundingBox center
					rule: Form under
					fillColor: Color black]!
displaySpecialComplemented	
	highlightForm
		displayOn: Display
		transformation: self displayTransformation
		clippingBox: self insetDisplayBox
		fixedPoint: label boundingBox center!
displayView
	"Does the standard View actions and, in addition, displays the receiver's 
	label based on the current display transformation and inset display box."

	self clearInside.
	label == nil
		ifFalse: 
			[label
				displayOn: Display
				transformation: self displayTransformation
				clippingBox: self insetDisplayBox
				fixedPoint: label boundingBox center]! !

!SwitchView methodsFor: 'updating'!
update: aParameter 
	highlightForm == nil
		ifTrue: [self interrogateModel 
					ifTrue: [self displayComplemented]
					ifFalse: [self displayNormal]]
		ifFalse: [self display]! !

!SwitchView methodsFor: 'label access'!
centerLabel
	"Align the center of the frame of the label with the center of the receiver's window."

	label == nil 
		ifFalse: 
			[label 
				align: label boundingBox center 
				with: self getWindow center]!
label
	"Answer the label, a display object, that is the receiver's screen image."
	^label!
label: aDisplayObject 
	"Set aDisplayObject to be the label that is the receiver's screen image."

	label release.
	label _ aDisplayObject.
	self centerLabel! !

!SwitchView methodsFor: 'indicating'!
indicatorOnDuring: aBlockContext 
	"Indicate the receiver during the execution of aBlockContext by 
	complementing the label (or a portion of the display box if no label is 
	defined). "

	self indicatorReverse.
	self highlight. 
	aBlockContext value.
	self highlight.
	self indicatorReverse!
indicatorReverse
	"Complement the label (or a portion of the displayBox if no label is defined)."

	Display reverse: self insetDisplayBox fillColor: Color gray.
	Display reverse: (self insetDisplayBox insetBy: 2) fillColor: Color gray! !

!SwitchView methodsFor: 'selector'!
interrogateModel
	"Answer the result of sending the receiver's model the message
	created from the receiver's selector and arguments."
	arguments size = 0
		ifTrue: [^model perform: selector]
		ifFalse: [^model perform: selector withArguments: arguments]!
selector
	"Answer the selector the receiver sends in a message to its receiver."
	^selector!
selector: aSymbol 
	"Set aSymbol to be the selector the receiver sends in a message to its model."
	selector _ aSymbol! !

!SwitchView methodsFor: 'deEmphasizing'!
deEmphasizeView
	| newForm |
	complemented
		ifTrue: [self highlight.
				newForm _ Form fromDisplay: self insetDisplayBox.
				newForm
					displayOn: Display
					at: (self insetDisplayBox topLeft + (1@0))
					clippingBox: self insetDisplayBox 
					rule: Form under 
					fillColor: Color black.
				Display fill: self insetDisplayBox rule: Form under fillColor: Color lightGray]! !

PopUpMenu subclass: #ActionMenu
	instanceVariableNames: 'selectors '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
ActionMenu comment:
'ActionMenus carry an array of selectors which correspond to the listed menu items.  This allows a menu to stand alone in parameterizing a controller, since the controller just sends the selector to its model.

ActionMenus allow the pluggable views experiment (TextView, SelectionInListView) to
handle menus much easier than having pairs of variables for the menu and its associated
selectors.  Obviously these menus eagerly await a proper objectification of protocol.'!


!ActionMenu methodsFor: 'action symbols'!
selectorAt: index
	^ selectors at: index!
setSelectors: selArray
	selectors _ selArray! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActionMenu class
	instanceVariableNames: ''!
ActionMenu class comment:
'This subclass of PopUpMenu carries a list of selectors corresponding to the various menu items.
Therefore, with only the menu as a parameter, a controller can display the menu and then
tell its model to perform the associated selector.  This saves maintaining two parallel structures,
one for the names in the menu, and one for the selectors to be performed.'!


!ActionMenu class methodsFor: 'instance creation'!
labels: aString lines: anArray selectors: selArray
	| aMenu |
	aMenu _ self labels: aString lines: anArray.
	aMenu setSelectors: selArray.
	^ aMenu!
labels: aString selectors: selArray
	^ self labels: aString lines: nil selectors: selArray! !

!ActionMenu class methodsFor: 'confirmation'!
confirm  "ActionMenu confirm"
	^ (ActionMenu labels: 'confirm\abort' withCRs selectors: nil) startUp = 1! !

!DisplayMedium methodsFor: 'ThingLab compatibility'!
border: aRectangle widthRectangle: insets fillColor: aHalfTone clippingBox: clipRect
	"Paint a border whose rectangular area is defined by aRectangle.  The width of
	each edge of the border is determined by the four coordinates of insets.
	Uses aHalfTone for drawing the border."
	(aRectangle areasOutside: (aRectangle insetBy: insets)) do:
		[:edgeStrip | self fill: (edgeStrip intersect: clipRect) fillColor: aHalfTone]! !

!Form methodsFor: 'ThingLab compatibility'!
shrinkBy: scale
    self shrink: self boundingBox by: scale!
    
reflect: modePoint
    modePoint = (0@1) ifTrue: [self flipBy: #vertical centerAt: 0@0]
        ifFalse: [self flipBy: #horizontal centerAt: 0@0] ! !

!PopUpMenu methodsFor: 'ThingLab compatibility'!

reset
	marker ifNil: [self computeForm].
	marker _  marker align: marker topLeft with: frame topLeft + frame borderWidth.
	selection _ 0.! !