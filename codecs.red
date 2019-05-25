Red [
    File:    %codecs.red
    Title:   "Add JSON to system codecs"
    Purpose: "Adds JSON as a valid data type to use with LOAD/AS and SAVE/AS"
    Date:    9-Aug-2018
    Version: 0.0.2
    Author: [
        "Gabriele Santilli" {
            Created this file.
        }
    ]
    History: [
        0.0.2 9-Aug-2018 "Created this file" Gabriele
    ]
	License: [
		http://www.apache.org/licenses/LICENSE-2.0 
		and "The Software shall be used for Good, not Evil."
	]
]

#include %load-json.red
#include %to-json.red

put system/codecs 'json context [
    Title:     "JSON codec"
    Name:      'JSON
    Mime-Type: [application/json]
    Suffixes:  [%.json]
    encode: func [data [any-type!] where [file! url! none!]] [
        to-json data
    ]
    decode: func [text [string! binary! file!]] [
        if file? text [text: read text]
        if binary? text [text: to string! text]
        load-json text
    ]
]
