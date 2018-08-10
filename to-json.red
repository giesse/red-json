Red [
    File:    %to-json.red
    Title:   "JSON formatter"
    Purpose: "Convert Red to JSON."
    Date:    9-Aug-2018
    Version: 0.0.2
	Author: [
		"Gregg Irwin" {
			Ported from %json.r by Romano Paolo Tenca, Douglas Crockford, 
			and Gregg Irwin.
			Further research: json libs by Chris Ross-Gill, Kaj de Vos, and
			@WiseGenius.
		}
        "Gabriele Santilli" {
            Refactoring and minor improvements.
        }
	]
	History: [
		0.0.1 10-Sep-2016 "First release. Based on %json.r"    Gregg
        0.0.2  9-Aug-2018 "Refactoring and minor improvements" Gabriele
	]
	License: [
		http://www.apache.org/licenses/LICENSE-2.0 
		and "The Software shall be used for Good, not Evil."
	]
	References: [
		http://www.json.org/
		https://www.ietf.org/rfc/rfc4627.txt
		http://www.rfc-editor.org/rfc/rfc7159.txt
		http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf
		https://github.com/rebolek/red-tools/blob/master/json.red
	]
	Notes: {
		- Ported from %json.r, by Romano Paolo Tenca, Douglas Crockford, and Gregg Irwin.
		- Further research: JSON libs by Chris Ross-Gill, Kaj de Vos, and @WiseGenius.
		
		? Do we want to have a single context or separate encode/decode contexts?
            - Split into two files (Gab)
		? Do we want to use a stack with parse, or recursive load-json/decode calls?

		- Unicode support is in the works.
		- Pretty formatting from %json.r removed. Determine what formatting options we want.

		- Would like to add more detailed decode error info.
			- JSON document is empty.
			- Invalid value.
			- Missing name for object member.
			- Missing colon after name of object member.
			- Missing comma or right curly brace after object member.
			- Missing comma or ] after array element.
			- Invalid \uXXXX escape.
			- Invalid surrogate pair.
			- Invalid backslash escape.
			- Missing closing quotation mark in string.
			- Numeric overflow.
			- Missing fraction in number.
			- Missing exponent in number.
	}
]

context [
    common: do %common.red

    enquote:                  :common/enquote
    encode-backslash-escapes: :common/encode-backslash-escapes
    ctrl-char:                :common/ctrl-char
    translit:                 :common/translit

	;-----------------------------------------------------------
	;-- JSON encoder
	;-----------------------------------------------------------

	; Indentation support, so we can make the JSON output look decent.
	dent: copy ""
	dent-size: 4
	indent:  does [append/dup dent #" " dent-size]
	outdent: does [remove/part dent dent-size]

	encode-char: func [
		"Convert a single char to \uxxxx format (NOT simple JSON backslash escapes)."
		char [char! string!]
	][
		if string? char [char: first char]
		;rejoin ["\u" to-hex/size to integer! char 4]
		append copy "\u" to-hex/size to integer! char 4
	]

;-------------------------------------------------------------------------------
;!! This is an optimization. The main reason it's here is that Red doesn't
;!! have a GC yet. Generating the lookup table once, and using that, prevents 
;!! repeated block allocations every time we encode a control character.
	make-ctrl-char-esc-table: function [][
		collect [
			;!! FORM is used here, when building the table, because TRANSLIT
			;	requires values to be strings. Yes, that's leaking it's
			;	abstraction a bit, which has to do with it using COPY vs SET
			;	in its internal PARSE rule.
			keep reduce [form ch: make char! 0  encode-char ch]
			repeat i 31 [keep reduce [form ch: make char! i  encode-char ch]]
		]
	]
	ctrl-char-esc-table: make-ctrl-char-esc-table
;-------------------------------------------------------------------------------

	encode-control-chars: func [
		"Convert all control chars in string to \uxxxx format"
		string [any-string!] "(modified)"
	][
		if find string ctrl-char [
			;translit string ctrl-char :encode-char			; Use function to encode
			translit string ctrl-char ctrl-char-esc-table	; Optimized table lookup approach
		]
		string
	]
	;encode-control-chars "^@^A^B^C^D^E^F^G^H^-^/^K^L^M^N^O^P^Q^R^S^T^U^V^W^X^Y^Z^[^\^]^(1E)^_ "


	; The reason this func does not copy the string is that a lot of
	; values will have been FORMed or MOLDed when they are passed to
	; it, so there's no sense in copying them again. The only time it's
	; a problem is for string values themselves.
	;TBD: Encode unicode chars?
	encode-red-string: func [string "(modified) Caller should copy"][
		encode-control-chars encode-backslash-escapes string
		;TBD translit string not-ascii-char :encode-char
	]

	red-to-json-name: func [val][
		append enquote encode-red-string form val ":"
	]

	; Types that map directly to a known JSON type.
	json-type!: union any-block! union any-string! make typeset! [
		none! logic! integer! float! percent! map! object! ; decimal!
	]
	
	
	red-to-json-value: func [val][
		;?? Is it worth the extra lines to make each type a separate case?
		;	The switch cases will look nicer if we do; more table like.
		switch/default type?/word :val [
			string!  [enquote encode-red-string copy val]	; COPY to prevent mutation
			none!    ["null"]							; JSON value MUST be lowercase
			logic!   [pick ["true" "false"] val]		; JSON value MUST be lowercase
			integer! float! [form val] 					; TBD: add decimal!
			percent! [form make float! val]				; FORM percent! includes sigil
			map! object! [map-to-json-object val]		; ?? hash!
			word!    [
				either all [
					not error? try [get val]			; Error means word ref's no value. FORM and escape it.
					find json-type! type? get val		; Not a type json understands. FORM and escape it.
				][
					red-to-json-value get val
				][
					; No-value error, or non-JSON types become quoted strings.
					enquote encode-red-string form val
				]
			]
		][
			either any-block? :val [block-to-json-list val] [
				; FORM forces binary! values to strings, so newlines escape properly.
				enquote encode-red-string either any-string? :val [form val] [mold :val]
			]
		]
	]

	;TBD: Eventually we should have a nice dlm string tool in Red. Is it worth
	;	  including our own for the list/object cases? 
	
	block-to-json-list: func [block [any-block!] /local result sep][
		indent
		result: copy "[^/"
		foreach value block [
			append result rejoin [dent red-to-json-value :value ",^/"]
		]
		outdent
		append clear any [find/last result ","  tail result] rejoin ["^/" dent "]"]
		;single-line-reformat result
		result
	]

	map-to-json-object: func [map [map!] /local result sep][
		indent
		result: copy "{^/"
		foreach word words-of map [
			append result rejoin [
				dent red-to-json-name :word " "
				red-to-json-value map/:word ",^/"
			]
		]
		outdent
		append clear any [find/last result ","  tail result] rejoin ["^/" dent "}"]
		;single-line-reformat result
		result
	]

	;-----------------------------------------------------------
	;-- Main encoder func

	export to-json: function [
		[catch]
		"Convert red data to a json string"
		data
	][
		result: make string! 4000	;!! factor this up from molded data length?
		foreach value compose/only [(data)] [
			append result red-to-json-value value
		]
		result
	]
]
