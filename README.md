Old things are included here for reference. The wallet code has a minimal JSON
parser, which is the most modern version. The most value here may come from
the test files.

Red should get a basic GC before too long, so I don't think it's worth the
effort to avoid allocations on those grounds.

Once the core works, the big difference from Rebol is that we have `load/as`
and `save/as` that work with `system/codecs` (see %red/environment/codecs/)
rather than just creating `to-json/load-json` global funcs.

Note: Red's integers are only 32bits while JSON data may contain 64bit integers (eg. see tests/data/twitter.json).
This could be a source of silent bugs. Please beware.

# Testing

- %tests.red                   Runs all the tests
- %tools/json-console.red      Interactive testing for small JSON strings
- %tools/parse-test-file.red   Select one JSON file to test

# Other versions

- https://github.com/red/wallet/blob/master/libs/JSON.red

- %references/json.r                 Official R2 JSON library
- %references/chris-rg-json.r3       Chris Ross-Gill's R3 version
- %references/kaj-json.red           Kaj de Vos
- %references/wise-genius-json.red   WiseGenius's Red version

- https://github.com/rgchris/Scripts/blob/master/red/altjson.red
