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
        $("#sentence_fields").append sentence_field_div f
    $("#sentence_fields").sortable "refresh"

# Create a div containing input elements that describe a field.
# Returns the div to be appended to some document somewhere.
# A function is attached to the element using jquery's .data(); key 'field_data', which returns
# the field object from the form.
sentence_field_div = (field) ->
    i = $("<span class='ui-icon ui-icon-arrowthick-2-n-s sentence_sort_icon' />")
    n = $("<input type='text' title='Field Name' placeholder='Field Name' />")
    field_name_input n
    s = $("<select />")
    sensor_select s
    f = $("<select />")
    sensor_format_select f
    c = $("<input type='text' title='Expected Value' placeholder='Value' />")
    e = $("<div />")
    e.append i, n, s, f, c

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
            return null
        if d.sensor is "stdtelem.coordinate"
            d.format = f.val()
        if d.sensor is "base.constant"
            d.expect = c.val()
        return d

    return e

# Setup callbacks on page load
$ ->
    $("#sentence_edit_cancel").click -> sentence_callback false
    $("#sentence_fields").sortable()
    $("#sentence_fields").disableSelection()
