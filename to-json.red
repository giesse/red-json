Red [
    File:    %to-json.red
    Title:   "JSON formatter"
    Purpose: "Convert Red to JSON."
    Date:    9-Oct-2018
    Version: 0.0.4
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
        0.0.1 10-Sep-2016 "First release. Based on %json.r"             Gregg
        0.0.2  9-Aug-2018 "Refactoring and minor improvements"          Gabriele
        0.0.3 31-Aug-2018 "Converted to non-recursive version"          Gabriele
        0.0.4  9-Oct-2018 "Back to an easier to read recursive version" Gabriele
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

    indent: none
    indent-level: 0
    normal-chars: none
    escapes: #(
        #"^"" {\"}
        #"\"  "\\"
        #"^H" "\b"
        #"^L" "\f"
        #"^/" "\n"
        #"^M" "\r"
        #"^-" "\t"
    )

    init-state: func [ind ascii?] [
        indent: ind
        indent-level: 0
        ; 34 is double quote "
        ; 92 is backslash \
        normal-chars: either ascii? [
            charset [32 33 35 - 91 93 - 127]
        ] [
            complement charset [0 - 31 34 92]
        ]
    ]

    emit-indent: func [output level] [
        indent-level: indent-level + level
        append/dup output indent indent-level
    ]

    emit-key-value: function [output sep map key] [
        value: select/case map :key
        if any-word? :key [key: form key]
        unless string? :key [key: mold :key]
        red-to-json-value output key
        append output sep
        red-to-json-value output :value
    ]

    red-to-json-value: function [output value] [
        special-char: none
        switch/default type?/word :value [
            none!           [append output "null"]
            logic!          [append output pick ["true" "false"] value]
            integer! float! [append output value]
            percent!        [append output to float! value]
            string! [
                append output #"^""
                parse value [
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
                either empty? value [
                    append output "[]"
                ] [
                    either indent [
                        append output "[^/"
                        emit-indent output +1
                        red-to-json-value output first value
                        foreach v next value [
                            append output ",^/"
                            append/dup output indent indent-level
                            red-to-json-value output :v
                        ]
                        append output #"^/"
                        emit-indent output -1
                    ] [
                        append output #"["
                        red-to-json-value output first value
                        foreach v next value [
                            append output #","
                            red-to-json-value output :v
                        ]
                    ]
                    append output #"]"
                ]
            ]
            map! object! [
                keys: words-of value
                either empty? keys [
                    append output "{}"
                ] [
                    either indent [
                        append output "{^/" ; }
                        emit-indent output +1
                        emit-key-value output ": " value first keys
                        foreach k next keys [
                            append output ",^/"
                            append/dup output indent indent-level
                            emit-key-value output ": " value :k
                        ]
                        append output #"^/"
                        emit-indent output -1
                    ] [
                        append output #"{" ; }
                        emit-key-value output #":" value first keys
                        foreach k next keys [
                            append output #","
                            emit-key-value output #":" value :k
                        ]
                    ]
                    append output #"}"
                ]
            ]
        ] [
            red-to-json-value output either any-block? :value [
                to block! :value
            ] [
                either any-string? :value [form value] [mold :value]
            ]
        ]
        output
    ]

    export to-json: function [
        [catch]
        "Convert Red data to a JSON string"
        data
        /pretty indent [string!] "Pretty format the output, using given indentation"
        /ascii "Force ASCII output (instead of UTF-8)"
    ] [
        result: make string! 4000
        init-state indent ascii
        red-to-json-value result data
    ]
]
