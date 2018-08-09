Red []

perf-file?: func [file] [
    %.perf = suffix? file
]

format-time: function [
    "Convert a time value to a human readable string"
    time [time!]
] [
    if time >= 0:00:01 [
        ; work around a bug in the current stable release
        time: form round/to time 0.001
        if decimals: find/tail time #"." [
            clear skip decimals 3
        ]
        return time
    ]
    units: ["ms" "μs" "ns" "ps"]
    foreach u units [
        time: time * 1000
        if time >= 0:00:01 [
            time: to integer! round time
            return append form time u
        ]
    ]
]

display-perf-file: function [file] [
    file: clean-path rejoin [%../tests/ file]
    file: load file
    foreach item file [
        print mold item/test
        print ["Fastest run" format-time to time! item/fastest]
        print ""
        foreach sample item/samples [
            speed: sample / item/fastest
            len: min 80 to integer! speed * 40
            print [head insert/dup insert/dup copy "" #"#" len #" " 80 - len round/to speed 0.01 "x"]
        ]
        ask "RETURN to continue..."
    ]
]

foreach file read %../tests/ [
    if perf-file? file [
        print ["File:" file]
        display-perf-file file
        print ""
        ask "RETURN to continue..."
    ]
]
