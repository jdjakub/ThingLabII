"ThingLab1 Squeak 3.8 parser mods ported to Squeak 6.0 methods"
"Because I'm a Squeak noob I'm just copypasting the relevant parts to manually apply the deltas"

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

	"a table for testing tokenish, modified to support ThingLab selectors with periods"
	TokenishPeriod := String withAll: (Character allByteCharacters collect:
			[:c | c tokenish ifTrue: [c] ifFalse: [c = $. ifTrue: [c] ifFalse: [$~]]]).
 
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
	"Modified to allow embedded dots"

	| type |
	buffer reset.
	[(type := self typeTableAt: hereChar) == #xLetter
		or: [type == #xDigit
		or: [type == #xUnderscore and:[self allowUnderscoreSelectors]]
		or: [type == #period and: [aheadChar ~~ DoItCharacter and: [aheadChar isLetter]]] "ThingLab"]] whileTrue:
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

Character>>tokenish
	"Answer whether the receiver is a valid token-character--letter, digit, or colon."
	"Tweaked to allow embedded periods for ThingLab"

	self == $_ ifTrue: [ ^Scanner prefAllowUnderscoreSelectors ].
	^self == $: or: [self == $. or: [ self isAlphaNumeric ]]

ByteString>>canBeToken
	"Optimized version for the common case. Modified for ThingLab."
	
	^ (self findSubstring: '~' in: self startingAt: 1 matchTable: TokenishPeriod) = 0

ByteSymbol>>canBeToken
	"Optimized version for the common case. Modified for ThingLab."
	
	| index |
	index := 0.
	[ (index := self findSubstring: '~' in: self startingAt: index + 1 matchTable: TokenishPeriod) = 0 ]
		whileFalse: [
			(self at: index) == $_ ifFalse: [ ^false ] ].
	^true

SHParserST80>>parseSymbolIdentifier
	"Modified for ThingLab."

	| c start end |
	c := self currentChar.
	self failUnless: (
		c isLetter
			or: [ c == $: 
			or: [ allowUnderscoreSelectors and: [ c == $_ ] ] ]).
	start := sourcePosition.	
	[
		(c := self nextChar) isAlphaNumeric
			or: [ c == $:
			or: [ allowUnderscoreSelectors and: [ c == $_ ] ]
            	or: [ c == $. and: [ self peekChar isLetter ] ] ] ] whileTrue.
	end := sourcePosition - 1.
	c := source copyFrom: start - 1 to: end.
	self scanPast: #symbol start: start - 1 end: end.
	^c