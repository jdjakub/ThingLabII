"ThingLab 1 Squeak 3.8 port parser modifications"

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

	"CR and LF--characters that terminate a line"
	CSLineEnders := CharacterSet empty.
	CSLineEnders add: Character cr.
	CSLineEnders add: Character lf.

 	"separators and non-separators"
	CSSeparators := CharacterSet separators.
	CSNonSeparators := CSSeparators complement.

xLetter
	"Form a word or keyword."
	"Modified to allow embedded dots'"

	| type |
	buffer reset.
	[((type := typeTable at: hereChar asciiValue) == #xLetter or: [type == #xDigit])
		or: [type == #period and: [aheadChar isLetter]]]
		whileTrue:
			["open code step for speed"
			buffer nextPut: hereChar.
			hereChar := aheadChar.
			source atEnd
				ifTrue: [aheadChar := 30 asCharacter "doit"]
				ifFalse: [aheadChar := source next]].
	(type == #colon or: [type == #xColon and: [aheadChar ~= $=]])
		ifTrue: 
			[buffer nextPut: self step.
			["Allow any number of embedded colons in literal symbols"
			(typeTable at: hereChar asciiValue) == #xColon]
				whileTrue: [buffer nextPut: self step].
			tokenType := #keyword]
		ifFalse: 
			[type == #leftParenthesis 
				ifTrue:[buffer nextPut: self step; nextPut: $).
						tokenType := #positionalMessage]
				ifFalse:[tokenType := #word]].
	token := buffer contents

numArgs 
	"Answer either the number of arguments that the receiver would take if considered a selector.  Answer -1 if it couldn't be a selector.  Note that currently this will answer -1 for anything begining with an uppercase letter even though the system will accept such symbols as selectors.  It is intended mostly for the assistance of spelling correction."

"Tweaked to allow embedded periods for ThingLab"

	| firstChar numColons excess start ix |
	self size = 0 ifTrue: [^ -1].
	firstChar := self at: 1.
	(firstChar isLetter or: [firstChar = $:]) ifTrue:
		["Fast reject if any chars are non-alphanumeric"
		(self findSubstring: '~' in: self startingAt: 1 matchTable: TokenishPeriod) > 0 ifTrue: [^ -1].
		"Fast colon count"
		numColons := 0.  start := 1.
		[(ix := self findSubstring: ':' in: self startingAt: start matchTable: CaseSensitiveOrder) > 0]
			whileTrue:
				[numColons := numColons + 1.
				start := ix + 1].
		numColons = 0 ifTrue: [^ 0].
		firstChar = $:
			ifTrue: [excess := 2 "Has an initial keyword, as #:if:then:else:"]
			ifFalse: [excess := 0].
		self last = $:
			ifTrue: [^ numColons - excess]
			ifFalse: [^ numColons - excess - 1 "Has a final keywords as #nextPut::andCR"]].
	firstChar isSpecial ifTrue:
		[self size = 1 ifTrue: [^ 1].
		2 to: self size do: [:i | (self at: i) isSpecial ifFalse: [^ -1]].
		^ 1].
	^ -1.