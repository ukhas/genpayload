# Copyright (c) 2012 Daniel Richman; GNU GPL 3

sentence_callback = null

# Main start point for sentence editing. #sentence_edit should be visible.
# s: the sentence dict to modify. callback: called when finished, with the new `s` as a single argument,
# or false if the user cancelled
sentence_edit = (s, callback) ->
    sentence_callback = callback

    if s.protocol != "UKHAS"
        alert "genpayload doesn't know how to configure the #{s.protocol} protocol"
        callback false

    $("#sentence_description").val s.description or ""
    $("#sentence_callsign").val(s.callsign).change()
    $("#sentence_checksum").val s.checksum or "crc16-ccitt"

    $("#sentence_fields, #sentence_intermediate_filters, #sentence_post_filters").empty()

    for f in s.fields
        $("#sentence_fields").append sentence_field_div f, not is_normal_field f

    if s.filters?.intermediate?
        for f in s.filters.intermediate
            $("#sentence_intermediate_filters").append sentence_filter_div f
    if s.filters?.post?
        for f in s.filters.post
            $("#sentence_post_filters").append sentence_filter_div f

    $("#sentence_fields, #sentence_intermediate_filters, #sentence_post_filters").sortable "refresh"

# Save and callback with the result
sentence_save = (s, callback) ->
    try
        sentence =
            protocol: "UKHAS"
            callsign: $("#sentence_callsign").val()
            checksum: $("#sentence_checksum").val()
            fields: (array_data_map "#sentence_fields", "field_data", true)
            filters:
                intermediate: (array_data_map "#sentence_intermediate_filters", "filter_data", true)
                post: (array_data_map "#sentence_post_filters", "filter_data", true)

        empty = 2
        if sentence.filters.intermediate.length == 0
            delete sentence.filters.intermediate
            empty -= 1
        if sentence.filters.post.length == 0
            delete sentence.filters.post
            empty -= 1
        if empty == 0
            delete sentence.filters

        if not callsign_regexp.test sentence.callsign
            throw "invalid callsign"
    catch e
        alert "There are errors in your form. Please fix them"
        return

    if sentence.fields.length == 0
        alert "You should probably add atleast one field"
        return

    d = $("#sentence_description").val()
    if d != ""
        sentence.description = d

    sentence_callback sentence

# can this field be displayed as a non-expert field?
is_normal_field = (f) ->
    if typeof f.sensor != "string"
        return false
    if typeof f.name != "string"
        return false

    extra = deepcopy f
    delete extra.sensor
    delete extra.name

    keys = (k for k, v of extra)

    if f.sensor in ["stdtelem.time", "base.ascii_int", "base.ascii_float", "base.string"]
        # expect no extra properties
        return keys.length == 0

    # otherwise, must be constant or coordinate, and need one property:
    if not (f.sensor in ["stdtelem.coordinate", "base.constant"])
        return false

    if keys.length != 1
        return false

    extra_key = keys[0]

    expect = switch f.sensor
        when "base.constant" then "expect"
        when "stdtelem.coordinate" then "format"

    if extra_key != expect
        return false

    if f.sensor is "stdtelem.coordinate"
        return (parse_sensor_format f.format) != null
    else
        return (typeof f.expect == "string")

sentence_sort_icon = -> $("<span class='ui-icon ui-icon-arrowthick-2-n-s sentence_icon' />")

# Create a div containing input elements that describe a field.
# Returns the div to be appended to some document somewhere.
# A function is attached to the element using jquery's .data(); key 'field_data', which returns
# the field object from the form.
sentence_field_div = (field, expert=false) ->
    m = $("<div class='row' />")

    i = $("<div class='item_icons' />")
    i.append sentence_sort_icon()
    menu = new HiddenMenu
        scale:
            text: "Add numeric scale filter"
            func: ->
                try
                    source = (m.data "field_data")().name
                catch err
                    source = ""

                $("#sentence_post_filters").append sentence_normal_filter_div
                    filter: "common.numeric_scale"
                    source: source
                    factor: 1
                    round: 3
                $("#sentence_post_filters").sortable "refresh"
                return
        delete:
            text: "Delete"
            func: ->
                p = m.parent()
                m.remove()
                p.sortable "refresh"
                return
    i.append menu.container
    m.append i

    if not expert
        e = $("<div class='normal_field validated'>")
        n = $("<input type='text' title='Field Name' placeholder='Field Name' />")
        field_name_input n
        s = $("<select class='big_select' />")
        sensor_select s
        f = $("<select class='big_select' />")
        sensor_format_select f
        c = $("<input type='text' title='Expected Value' placeholder='Value' />")
        v = $("<img />")
        e.append n, s, f, c, v

        n.val field.name
        s.val field.sensor
        if field.sensor is "stdtelem.coordinate" then f.val parse_sensor_format field.format
        if field.sensor is "base.constant" then c.val field.expect

        s.change ->
            v = s.val()
            if v is "stdtelem.coordinate"
                f.show()
            else
                f.hide()
            if v is "base.constant"
                c.show()
            else
                c.hide()
            return

        n.change()
        s.change()

        m.data "field_data", (validate=true) ->
            d = name: n.val(), sensor: s.val()
            if validate and not is_valid_field_name d.name
                throw "invalid field name"
            if d.sensor is "stdtelem.coordinate"
                d.format = f.val()
            if d.sensor is "base.constant"
                d.expect = c.val()
            return d

        menu.update
            convert:
                text: "Convert this to a custom field"
                func: ->
                    data = (m.data "field_data") false
                    m.replaceWith sentence_field_div data, true
                    return
    else
        kv = new KeyValueEdit
            data: field
            required: ["name", "sensor"]
            validator: (key, value) ->
                switch key
                    when "name" then is_valid_field_name value
                    when "sensor" then (typeof value is "string" and
                                        callable_regexp.test value)
                    else true
        e = kv.elem
        m.data "field_data", -> kv.data()

        menu.update
            convert:
                text: "Convert this to a normal field"
                func: ->
                    try
                        data = kv.data()
                        if not is_normal_field data
                            throw "couldn't convert"
                    catch err
                        alert "Could not convert the field. (non-standard type, options, or validation errors)"
                        return
                    m.replaceWith sentence_field_div data, false
                    return

    m.append e

    return m

# Create an item to be inserted into a filters list
sentence_filter_div = (d) ->
    switch d.type
        when "normal" then sentence_normal_filter_div d
        when "hotfix" then sentence_hotfix_filter_div d

# Create an item to be inserted into a filters list
sentence_normal_filter_div = (d={}) ->
    d = deepcopy d
    delete d.type

    kv = new KeyValueEdit
        data: d
        required: ["filter"]
        validator: (key, value) ->
            switch key
                when "filter" then (typeof value is "string" and callable_regexp.test value)
                when "source", "destination" then is_valid_field_name value
                else true

    e = $("<div class='row' />")

    i = $("<div class='item_icons' />")
    i.append sentence_sort_icon()

    menu = new HiddenMenu
        delete:
            text: "Delete"
            func: ->
                p = e.parent()
                e.remove()
                p.sortable "refresh"
                return

    i.append menu.container

    e.append i

    e.append kv.elem
    e.data "filter_data", ->
        data = kv.data()
        data.type = "normal"
        return data

    return e

# Parses s to JSON, and does some basic sanity checks. Returns JSON result
sentence_get_hotfix = (s) ->
    hotfix = JSON.parse s
    if hotfix.type != "hotfix"
        throw "isn't a hotfix"
    n = 0
    for k, v of hotfix
        if k not in ["type", "code", "signature", "certificate"]
            throw "invalid key"
        n++
    if n != 4
        throw "missing key"
    return hotfix

# Create an item to be inserted into a filters list
sentence_hotfix_filter_div = (d=null) ->
    e = $("<div class='row validated' />")

    c = $("<div class='item_icons' />")
    c.append sentence_sort_icon()
    menu = new HiddenMenu
        delete:
            text: "Delete"
            func: ->
                p = e.parent()
                e.remove()
                p.sortable "refresh"
                return
    c.append menu.container

    e.append c

    i = $("<input type='text' placeholder='Paste output of ./sign_hotfix.py' class='hotfix_box' />")
    if d != null
        i.val JSON.stringify d

    e.append i
    e.append $("<img />")

    i.change ->
        try
            sentence_get_hotfix i.val()
            set_valid i, true
        catch e
            set_valid i, false
        return
    i.change()

    e.data "filter_data", -> sentence_get_hotfix i.val()
    return e

# Setup callbacks on page load
$ ->
    form_field "#sentence_callsign", extra: (v) -> callsign_regexp.test v

    $("#sentence_fields_add").click btn_cb ->
        $("#sentence_fields").append sentence_field_div
            name: ""
            sensor: "base.string"
        $("#sentence_fields").sortable "refresh"
    $("#sentence_fields_expert").click btn_cb ->
        $("#sentence_fields").append sentence_field_div {}, true
        $("#sentence_fields").sortable "refresh"

    for section in ["intermediate", "post"]
        for type, func of {normal: sentence_normal_filter_div, hotfix: sentence_hotfix_filter_div}
            do (section, type, func) ->
                $("#sentence_#{section}_#{type}_filter_add").click btn_cb ->
                    $("#sentence_#{section}_filters").append func()

    $("#sentence_fields, #sentence_intermediate_filters, #sentence_post_filters").sortable
        revert: true
        tolerance: 5
    $("#sentence_fields, #sentence_intermediate_filters, #sentence_post_filters").disableSelection()

    $("#sentence_edit_cancel").click btn_cb -> sentence_callback false
    $("#sentence_edit_save").click btn_cb -> sentence_save()

    return
