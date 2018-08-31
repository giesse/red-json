Red [
    File:    %to-json.red
    Title:   "JSON formatter"
    Purpose: "Convert Red to JSON."
    Date:    31-Aug-2018
    Version: 0.0.3
	Author: [
		"Gregg Irwin" {
			Ported from %json.r by Romano Paolo Tenca, Douglas Crockford, 
			and Gregg Irwin.
			Further research: json libs by Chris Ross-Gill, Kaj de Vos, and
			@WiseGenius.
		}
        "Gabriele Santilli" {
            See History.
        }
	]
	History: [
		0.0.1 10-Sep-2016 "First release. Based on %json.r"    Gregg
        0.0.2  9-Aug-2018 "Refactoring and minor improvements" Gabriele
        0.0.3 31-Aug-2018 "Converted to non-recursive version" Gabriele
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
]

context [
    do %common.red ; just want export for right now

    red-to-json-value: function [output indent ascii? val] [
        stack: clear []
        state: object [
            value: :val
            map:   none
            block: none
            name:  'atom
        ]
        indent-level: 0
        ; 34 is double quote "
        ; 92 is backslash \
        normal-chars: either ascii? [
            charset [32 33 35 - 91 93 - 127]
        ] [
            complement charset [0 - 31 34 92]
        ]
        escapes: #(
            #"^"" {\"}
            #"\"  "\\"
            #"^H" "\b"
            #"^L" "\f"
            #"^/" "\n"
            #"^M" "\r"
            #"^-" "\t"
        )
        special-char: none
        forever [
            switch/default type?/word :state/value [
                none!           [append output "null"]
                logic!          [append output pick ["true" "false"] state/value]
                integer! float! [append output state/value]
                percent!        [append output to float! state/value]
                string! [
                    append output #"^""
                    parse state/value [
                        any [
                            mark1: some normal-chars mark2: (append/part output mark1 mark2)
                            |
                            set special-char skip (
                                either escape: select escapes special-char [
                                    append output escape
                                ] [
                                    insert insert tail output "\u" to-hex/size to integer! special-char 4
                                ]
                            )
                        ]
                    ]
                    append output #"^""
                ]
                block! [
                    either empty? state/value [
                        append output "[]"
                    ] [
                        append stack copy state
                        state/block: state/value
                        state/value: first state/value
                        state/name:  'block-first
                        either indent [
                            append output "[^/"
                            indent-level: indent-level + 1
                            append/dup output indent indent-level
                        ] [
                            append output #"["
                        ]
                    ]
                ]
                map! object! [
                    keys: words-of state/value
                    either empty? keys [
                        append output "{}"
                    ] [
                        append stack copy state
                        state/map:   state/value
                        state/block: keys
                        state/value: first keys
                        if any-word? :state/value [state/value: form state/value]
                        unless string? :state/value [state/value: mold :state/value]
                        state/name: 'map-key
                        either indent [
                            append output "{^/" ; }
                            indent-level: indent-level + 1
                            append/dup output indent indent-level
                        ] [
                            append output #"{" ; }
                        ]
                    ]
                ]
            ] [
                state/name:  'recurse
                either any-block? :state/value [
                    state/value: to block! :state/value
                ] [
                    state/value: either any-string? :state/value [form state/value] [mold :state/value]
                ]
                state/name: 'recurse
            ]
            forever [
                switch/default state/name [
                    block-next [
                        state/block: next state/block
                        either tail? state/block [
                            if indent [
                                append output #"^/"
                                indent-level: indent-level - 1
                                append/dup output indent indent-level
                            ]
                            append output #"]"
                            state: take/last stack
                        ] [
                            state/value: first state/block
                            unless #"[" = last output [
                                either indent [
                                    append output ",^/"
                                    append/dup output indent indent-level
                                ] [
                                    append output #","
                                ]
                            ]
                            break
                        ]
                    ]
                    map-next-key [
                        state/block: next state/block
                        either tail? state/block [
                            if indent [
                                append output #"^/"
                                indent-level: indent-level - 1
                                append/dup output indent indent-level
                            ]
                            append output #"}"
                            state: take/last stack
                        ] [
                            state/value: first state/block
                            if any-word? :state/value [state/value: form state/value]
                            unless string? :state/value [state/value: mold :state/value]
                            unless #"{" = last output [ ; }
                                either indent [
                                    append output ",^/"
                                    append/dup output indent indent-level
                                ] [
                                    append output #","
                                ]
                            ]
                            state/name: 'map-key
                            break
                        ]
                    ]
                ] [break]
            ]
            switch state/name [
                atom        [break/return output]
                recurse     [state/name: 'atom]
                block-first [state/name: 'block-next]
                map-key     [state/name: 'map-value]
                map-value [
                    append output #":"
                    if indent [append output #" "]
                    state/name: 'map-next-key
                    state/value: select/case state/map first state/block
                ]
            ]
        ]
    ]

    export to-json: function [
        [catch]
        "Convert Red data to a JSON string"
        data
        /pretty indent [string!] "Pretty format the output, using given indentation"
        /ascii "Force ASCII output (instead of UTF-8)"
    ] [
        result: make string! 4000
        red-to-json-value result indent ascii data
    ]
]
