Plumekit
========

Plumekit is a web data format and protocol library for Haxe.

This library is the main driver behind [Wsave](https://github.com/chfoo/wsave).

It is currently under development.

Package summary:

| Package | Description |
| ------- | ----------- |
| `plumekit.bindata` | Binary data processing |
| `plumekit.eventloop` | Event loop management |
| `plumekit.net` | Socket connections and Internet Protocol utilities |
| `plumekit.stream` | Stream reading and writing abstractions |
| `plumekit.text` | Text processing utilities |
| `plumekit.text.codec` | WHATWG encoding living standard implementation (June 2018) |
| `plumekit.url` | WHATWG URL living standard implementation (June 2018) |
| `plumekit.www` | WWW-related data formats and protocols |
| `plumekit.www.gopher` | Gopher protocol |


Getting started
---------------

* Requires Haxe 3/4

Install using Haxelib:

    # TODO: not yet published to haxelib
    haxelib install plumekit

Or get the latest in development version:

    haxelib git plumekit https://github.com/chfoo/plumekit

Read the API documentation at (TODO).

Tests can be run using:

    haxe hxml/test.js.hxml  # run test.html in browser
    haxe hxml/test.cpp.hxml && out/cpp/TestAll-debug


Copyright
---------

Copyright (C) 2018 Christopher Foo. Licensed under [GPL 3](LICENSE.txt).
