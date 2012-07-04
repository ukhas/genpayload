# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# notes on how the various sort-of-modules talk to each other:
# A button that opens another section will have a click action defined the section that it is called from
# (e.g., #go_pcfg_new is setup in home.coffee). This function should show the section, and then invoke the
# main function for that section. It will pass some arguments if neccessary and then a callback that should
# be called once the new section is finished: success or user cancel.
# This callback should hide and re-show the original or next section as appropriate.

# hide all children of body except 'open'
toplevel = (open) ->
    $("body > div").not(open).hide()
    $(open).show()

copy = (o) -> $.extend {}, o
deepcopy = (o) -> $.extend true, {}, o

# pop the element at index 'from', and insert it at 'to'
array_reorder = (array, from, to) ->
    v = array[from..from]
    array[from..from] = []
    array[to...to] = v

# like parseFloat but doesn't tolerate rubbish on the end. Returns NaN if fail.
strict_numeric = (str) ->
    if str is ""
        return NaN
    else
        return +str

# Turn all div.button > a into jquery buttons, and div > div > a into buttonsets
$ ->
    $(".buttons > a").button()
    $("#help_once").button()
    $(".buttons").buttonset()
