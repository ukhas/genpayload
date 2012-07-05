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
    if not /[0-9]/.test str
        return NaN # catch empty strings
    else
        return +str

# Again, doesn't tolerate rubbish.
strict_integer = (str) ->
    v = strict_numeric str
    if isNaN v
        return NaN
    if (str.indexOf '.') != -1 or v != Math.round v
        return NaN
    return v

# Adds a change cb to the input, marking it invalid if empty. Optionally checks if it is
# a (possive) number. If extra is provided, it's called to validate.
form_field = (elem, opts={}) ->
    e = $(elem)
    e.change ->
        v = e.val()
        ok = true

        if opts.numeric
            v = strict_numeric v
            if isNaN(v)
                ok = false
            else if opts.positive and v <= 0
                ok = false
            else if opts.integer and v != Math.round v
                ok = false

        if opts.nonempty
            if v == ""
                ok = false

        if opts.extra?
            if ok and not opts.extra v
                ok = false

        set_valid e, ok

# set/remove the valid class
set_valid = (elem, valid) ->
    if valid
        $(elem).removeClass "invalid"
    else
        $(elem).addClass "invalid"

# Turn all div.button > a into jquery button sets
$ ->
    $(".buttons > a").button()
    $("#help_once").button()
    $(".buttons").buttonset()
