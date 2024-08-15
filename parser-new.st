"Squeak 6.0 methods for ThingLab 1 parser modifications"

initialize   "self initialize"

	| order |
	AsciiOrder := (0 to: 255) as: ByteArray.

	CaseInsensitiveOrder := AsciiOrder copy.
	($a to: $z) do:
		[:c | CaseInsensitiveOrder at: c asciiValue + 1
				put: (CaseInsensitiveOrder at: c asUppercase asciiValue +1)].

	"Case-sensitive compare sorts space, digits, letters, all the rest..."
	CaseSensitiveOrder := ByteArray new: 256 withAll: 255.
	order := -1.
	' 0123456789' do:  "0..10"
		[:c | CaseSensitiveOrder at: c asciiValue + 1 put: (order := order+1)].
	($a to: $z) do:     "11-64"
		[:c | CaseSensitiveOrder at: c asUppercase asciiValue + 1 put: (order := order+1).
		CaseSensitiveOrder at: c asciiValue + 1 put: (order := order+1)].
	1 to: CaseSensitiveOrder size do:
		[:i | (CaseSensitiveOrder at: i) = 255 ifTrue:
			[CaseSensitiveOrder at: i put: (order := order+1)]].
	order = 255 ifFalse: [self error: 'order problem'].

	"a table for translating to lower case"
	LowercasingTable := String withAll: (Character allByteCharacters collect: [:c | c asLowercase]).

	"a table for translating to upper case"
	UppercasingTable := String withAll: (Character allByteCharacters collect: [:c | c asUppercase]).

	"a table for testing tokenish (for fast numArgs)"
	Tokenish := String withAll: (Character allByteCharacters collect:
									[:c | c tokenish ifTrue: [c] ifFalse: [$~]]).
 
	"% and < for #expandMacros*"
	CSMacroCharacters := CharacterSet newFrom: '%<'.

	"{\ used by #format:"
	FormatCharacterSet := CharacterSet newFrom: '{\'.
	
	"a table for exchanging cr with lf and vica versa"
	CrLfExchangeTable := Character allByteCharacters collect: [ :each |
		each
			caseOf: {
				[ Character cr ] -> [ Character lf ].
				[ Character lf ] -> [ Character cr ] }
			otherwise: [ each ] ]

xLetter
	"Form a word or keyword."

	| type |
	buffer reset.
	[(type := self typeTableAt: hereChar) == #xLetter
		or: [type == #xDigit
		or: [type == #xUnderscore and:[self allowUnderscoreSelectors]]]] whileTrue:
			[buffer nextPut: self step].
	tokenType := (type == #xColon and: [aheadChar ~~ $=])
					ifTrue: 
						[buffer nextPut: self step.
						"Allow any number of embedded colons in literal symbols"
						[(self typeTableAt: hereChar) == #xColon] whileTrue:
							[buffer nextPut: self step].
						#keyword]
					ifFalse: 
						[#word].
	token := buffer contents

numArgs 
	"Answer either the number of arguments that the receiver would take if considered a selector.  Answer -1 if it couldn't be a selector. It is intended mostly for the assistance of spelling correction."

	| numColons index size c |
	(size := self size) = 0 ifTrue: [ ^-1 ].
	index := 1.
	(self at: index) isSpecial ifTrue: [
		2 to: size do: [ :i | (self at: i) isSpecial ifFalse: [ ^-1 ] ].
		^1 ].
	self canBeToken ifFalse: [ ^-1 ].
	"Fast colon count"
	numColons := 0.
	[ 
		((c := self at: index) isLetter
		 or: [ c = $_ and: [ Scanner prefAllowUnderscoreSelectors ] ]) ifFalse:
			[ ^-1 ].
		(index := (self indexOf: $: startingAt: index) + 1) > 1 ifFalse:
			[ numColons = 0 ifTrue: [ ^0 ].
			 ^-1 ].
		numColons := numColons + 1.
		index <= size ] whileTrue.
	^numColons