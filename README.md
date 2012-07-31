habitat-genpayload
==================

Generate and save payload_configuration and flight documents for habitat

Building
========

 1) Install coffee-script (Super easy: install node, which comes with npm)
 2) ```coffee --join js/genpayload.js --compile coffee/*.coffee```

Compile errors? coffee gives less-helpful error messages when joining files.
Try this: ```coffee --print --compile coffee/*.coffee > /dev/null```

Deploying
=========

Clone the repository into a web accessible directory. You may have to change
the database at the bottom of coffee/misc.coffee; it defaults to habitat.

Build js/genpayload.js either on the server or elsewhere and copy it in. Done.

Testing
=======

Tests run using jasmine in the browser. Having compiled js/specs.js, visit
jasmine.html:

 1) ```coffee --join js/specs.js --compile spec/*.coffee```
 2) ```python spec/make_test_docs.py```
 3) ```x-www-browser jasmine.html```

License
=======


