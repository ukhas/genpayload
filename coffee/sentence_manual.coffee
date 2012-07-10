# Copyright (c) 2012 Daniel Richman; GNU GPL 3

sentence_callback = null

# Main start point for sentence editing. #sentence_edit should be visible.
# s: the sentence dict to modify. callback: called when finished, with the new `s` as a single argument,
# or false if the user cancelled
sentence_edit = (s, callback) ->
    sentence_callback = callback

    if s.protocol is not "UKHAS"
        alert "genpayload doesn't know how to configure the #{s.protocol} protocol"
        callback false

    $("#sentence_callsign").val s.callsign
    $("#sentence_checksum").val s.checksum

    $("#sentence_fields").empty()
    for f in s.fields
        $("#sentence_fields").append sentence_field_div f, not is_normal_field f
    $("#sentence_fields").sortable "refresh"

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

    if not (f.sensor in ["base.constant", "stdtelem.coordinate"])
        # expect no extra properties
        return keys.length == 0

    # otherwise, need one:
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

# Create a div containing input elements that describe a field.
# Returns the div to be appended to some document somewhere.
# A function is attached to the element using jquery's .data(); key 'field_data', which returns
# the field object from the form.
sentence_field_div = (field, expert=false) ->
    e = $("<div />")
    i = $("<span class='ui-icon ui-icon-arrowthick-2-n-s sentence_sort_icon' />")
    e.append i

    if not expert
        n = $("<input type='text' title='Field Name' placeholder='Field Name' />")
        field_name_input n
        s = $("<select />")
        sensor_select s
        f = $("<select />")
        sensor_format_select f
        c = $("<input type='text' title='Expected Value' placeholder='Value' />")
        e.append n, s, f, c

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

        n.change()
        s.change()

        e.data "field_data", ->
            d = name: n.val(), sensor: s.val()
            if d.name is "" or d.name[0] == "_"
                throw "invalid field name"
            if d.sensor is "stdtelem.coordinate"
                d.format = f.val()
            if d.sensor is "base.constant"
                d.expect = c.val()
            return d
    else
        kv = new KeyValueEdit
            data: field
            required: ["name", "sensor"]
            validator: (key, value) ->
                switch key
                    when "name" then (typeof value is "string" and /^[a-z_0-9]+$/.test value)
                    when "sensor" then (typeof value is "string" and /^[a-z_\.0-9]+$/.test value)
                    else true
        e.append kv.elem
        e.data "field_data", -> kv.data()

    return e

# Setup callbacks on page load
$ ->
    $("#sentence_fields_add").click ->
        $("#sentence_fields").append sentence_field_div
            name: ""
            sensor: "base.string"
        $("#sentence_fields").sortable "refresh"
    $("#sentence_fields_expert").click ->
        $("#sentence_fields").append sentence_field_div {}, true
        $("#sentence_fields").sortable "refresh"

    $("#sentence_edit_cancel").click -> sentence_callback false
    $("#sentence_fields").sortable()
    $("#sentence_fields").disableSelection()
