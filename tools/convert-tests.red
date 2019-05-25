Red []

results-file?: func [file] [
    %.results = suffix? file
]

convert-tests: function [file] [
    print rejoin [{===start-group=== "} file {"^/}]
    results: load/all file
    repeat i length? results [
        result: pick results i
        switch result/status [
            Pass [
                switch/default result/type [
                    error! [
                        print rejoin [{    --test-- "} file {-} i {"}]
                        print rejoin [{        --assert error? try } mold result/test]
                    ]
                ] [
                    print rejoin [{    --test-- "} file {-} i {"}]
                    print rejoin [{        --assert } mold/all result/result " = " mold/only result/test]
                ]
            ]
        ]
    ]
    print "===end-group===^/"
]

print {~~~start-file~~~ "JSON"^/}

foreach file read %../tests/ [
    if results-file? file [
        convert-tests rejoin [%../tests/ file]
    ]
]

print {~~~end-file~~~}
