# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# notes on how the various sort-of-modules talk to each other:
# A button that opens another section will have a click action defined the section that it is called from
# (e.g., #go_pcfg_new is setup in home.coffee). This function should show the section, and then invoke the
# main function for that section. It will pass some arguments if neccessary and then a callback that should
# be called once the new section is finished: success or user cancel.
# This callback should hide and re-show the original or next section as appropriate.

nice_key_regexp = /^[a-z_0-9]+$/
callsign_regexp = /^[a-zA-Z0-9/_\\-]+$/
callable_regexp = /^[a-z_\.0-9]+$/
time_regex = /^((0|1)[0-9]|2[0-3])(:|)([0-5][0-9])(|\3([0-5][0-9]|60))$/

# parse a string into an array [hours, minutes, seconds]
time_parse = (str) ->
    r = time_regex.exec str
    if r?
        h = parseInt r[1]
        m = parseInt r[4]
        s = (parseInt r[6]) or 0
        return [h, m, s]
    else
        throw "invalid time"

# wrap a button click callback, disabling the default and ensuring a safe return value
btn_cb = (func) ->
    return (event) ->
        event.preventDefault()
        func.call this, event
        return

btn_disable = (elem) ->
    $(elem).prop "disabled", true
    $(elem).addClass "disabled"

btn_enable = (elem) ->
    $(elem).prop "disabled", false
    $(elem).removeClass "disabled"

# to populate #page_title, #page_subtitle
page_titles =
    "#home": ["habitat document generator", "payload_configuration and flight document editor"]
    "#browse": ["Database browser"]
    "#payload_configuration": ["Payload configuration"]
    "#transmission_edit": ["Transmission", "Radio and telemetry configuration"]
    "#sentence_wizard": ["Sentence wizard", "Parser configuration"]
    "#sentence_edit": ["Sentence editor", "Parser configuration"]
    "#loading_docs": ["Loading..."]
    "#flight": ["Flight"]
    "#saving": ["Saving..."]

# hide all children of body except 'open'
toplevel = (open) ->
    $("#sections > section").not(open).hide()
    $(open).show()

    $("#page_title").text page_titles[open][0]
    $("#page_subtitle").text page_titles[open][1] or ""

    return

copy = (o) -> $.extend {}, o
deepcopy = (o) -> $.extend true, {}, o

# pop the element at index 'from', and insert it at 'to'
array_reorder = (array, from, to) ->
    v = array[from..from]
    array[from..from] = []
    array[to...to] = v
    return

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
        return

# set/remove the valid class
set_valid = (elem, valid) ->
    e = $(elem)
    if e.parent().is(".validated")
        i = e.siblings("img")
        if valid
            i.attr "alt", "OK"
            i.attr "src", "t/images/tick.png"
        else
            i.attr "alt", "Error"
            i.attr "src", "t/images/exclamationmark.png"
    else if e.is(".validated_inside")
        if valid
            e.removeClass "invalid"
        else
            e.addClass "invalid"
    else
        throw "not validated"

    return

# Setup an input as a field name input with autocompletion & validation
field_name_input = (elem) ->
    form_field elem,
        nonempty: true,
        extra: (v) -> v[0] != "_"

    elem.autocomplete
        source: (w, cb) ->
            cb suggest_field_names w.term
            return
        select: (e, ui) ->
            if ui.item then set_valid elem, true
            return
        minLength: 0

    # Encourage the autocomplete box to open more often
    elem.click btn_cb -> elem.autocomplete "search"

sensor_list =
    "stdtelem.time": "Time"
    "stdtelem.coordinate": "Coordinate"
    "base.ascii_int": "Integer"
    "base.ascii_float": "Float"
    "base.string": "String"
    "base.constant": "Constant"

# populate a <select /> with sensor types
sensor_select = (s) ->
    for sensor, prettyname of sensor_list
        o = $("<option />")
        o.attr "value", sensor
        o.text prettyname
        s.append o
    return s

# populate a <select /> with format types
sensor_format_select = (s) ->
    for t in ["dd.dddd", "ddmm.mmmm"]
        s.append $("<option />").val(t).text(t)

# parse a sensor format and ensure it is either dd.dddd or ddmm.mmmm
parse_sensor_format = (f) ->
    if /^d+\.d+$/.test f then "dd.dddd"
    else if /^d+m+\.m+$/.test f then "ddmm.mmmm"
    else null

# use jquery's .data(key) on all children of elem, return the result as a pain array
# exec: execute what .data(key) returns and store that.
array_data_map  = (elems, key, exec=false) ->
    a = ($(e).data(key) for e in $(elems).children())
    if exec
        a = (f() for f in a)
    return a

database = null
saving_doc = null
save_callback = null

save_doc = (doc, callback) ->
    saving_doc = doc
    save_callback = callback

    $("#saving_status").text "Saving payload_configuration document..."
    $("#saving_doc").val JSON.stringify doc
    $("#save_success, #save_fail").hide()

    database.saveDoc doc,
        success: (resp) ->
            $("#saving_status").text "Saved."
            $("#saved_id").text resp.id
            $("#save_success").show()
            # jquery.couch will add _rev and _id to doc.
            return
        error: (status, error, reason) ->
            $("#saving_status").text "Failed :-("
            $("#save_fail_message").text "#{status} #{error} #{reason}"
            $("#save_fail").show()
            return

setup_save_buttons = ->
    $("#save_done").click btn_cb -> save_callback saving_doc
    $("#save_retry").click btn_cb -> save_doc saving_doc, save_callback
    $("#save_back").click btn_cb -> save_callback null

# load docs by list of ids with loading screen. #loading_docs should be visible
loading_docs_callback = null

load_docs = (docs, callback) ->
    loading_docs_callback = callback

    $("#loading_docs_back").hide()

    database.allDocs
        keys: docs
        include_docs: true
        success: (resp) ->
            docs = {}
            for row in resp.rows
                docs[row.id] = row.doc
            callback docs
            return
        error: (status, error, reason) ->
            $("#loading_docs_text").text "Failed: #{status} #{error} #{reason}"
            $("#loading_docs_back").show()
            return

setup_loading_docs_buttons = ->
    $("#loading_docs_back").click btn_cb -> loading_docs_callback false

$ ->
    $.ajaxSetup
        timeout: 10000

    database = $.couch.db("test_habitat")

    setup_save_buttons()
    setup_loading_docs_buttons()
    return
