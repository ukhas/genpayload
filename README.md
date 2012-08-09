habitat-genpayload
==================

Generate and save payload_configuration and flight documents for habitat

Building
========

 - Install coffee-script (Super easy: install node, which comes with npm,
   then npm install -g coffee-script)
 - Checkout the habitat-template submodule
 - Compile js/genpayload.js

    $ npm install -g coffee-script
    $ git submodule update --init
    $ coffee --join js/genpayload.js --compile coffee/*.coffee

Compile errors? coffee gives less-helpful error messages when --joining files.
Try this: ```coffee --print --compile coffee/*.coffee > /dev/null```

Deploying
=========

 - Clone the repository into a web accessible directory. You may have to
   change the database at the bottom of coffee/1_misc.coffee; it defaults to
   /habitat.
 - Follow the building instructions above.
 - Done :-)

Testing
=======

Tests run using jasmine in the browser. Having compiled js/specs.js, visit
jasmine.html.

You will need python with PyYAML to build the test docs.

    $ coffee --join js/specs.js --compile spec/*.coffee
    $ python spec/make_test_docs.py
    $ x-www-browser jasmine.html

Legal stuff
===========

genpayload.html css/* coffee/* and spec/* are
Copyright 2012 Daniel Richman and licensed under the GNU GPL 3;
please see http://www.gnu.org/licenses/

    genpayload is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

Several libraries are included in the js/ directory, and their various licenses
(and links to their homepages) are listed in js/README.md

The habitat template / theme is Copyright 2012 Daniel Saul, and is imported
via git submodule
