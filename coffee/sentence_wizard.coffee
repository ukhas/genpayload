# Copyright (c) 2012 Daniel Richman; GNU GPL 3

time_regex = /^((0|1)[0-9]|2[0-3])(:|)[0-5][0-9](|\3[0-5][0-9]|60)$/

wizard_callback = null
wizard_sentence = null
wizard_field_values = null
wizard_field_elems = null
wizard_current_field = null
wizard_stage = null
nolock_temp = null

# shorthand
wizard_edit_f = -> wizard_sentence.fields[wizard_current_field]

# Main start point for wizard. #sentence_wizard should be visible.
# ignored: to have the same signature as sentence_edit
# callback: called when finished, with the new `s` as a single argument, or false if the user cancelled
sentence_wizard = (ignored, callback) ->
    wizard_callback = callback

    $("#wizard_text_box").val ""
    $("#wizard_text_box").show()
    $("#wizard_success").hide()
    $("#wizard_form").hide()
    $("#wizard_misc").hide()
    $("#wizard_error").hide()
    $("#wizard_prev").button("disable")

    wizard_stage = "paste"

# Calculates the CRC16 CCITT checksum of *data*.
# (CRC16 CCITT: start 0xFFFF, poly 0x1021).
# Returns a 4 character uppercase hexadecimal string.
crc16_ccitt = (data) ->
    crc = 0xFFFF
    for char in data
        crc ^= (char.charCodeAt(0) << 8)
        for i in [0...8]
            if crc & 0x8000
                crc = (crc << 1) ^ 0x1021
            else
                crc <<= 1
        crc &= 0xFFFF

    return hexify crc, 4

# Calculates the XOR checksum of *data*
xor_checksum = (data) ->
    crc = 0
    for char in data
        crc ^= char.charCodeAt(0)
    return hexify crc, 2

# Calculate the Fletcher-16 checksum of *data*, default modulus 255
fletcher_16 = (data, modulus=255) ->
    a = b = 0
    for char in data
        num = char.charCodeAt(0)
        a += num
        b += a
        a %= modulus
        b %= modulus
    crc = (a << 8) | b
    return hexify crc, 4

# Padded hexadecimal string of number, length len
hexify = (num, len) ->
    v = num.toString(16).toUpperCase()
    pad = len - v.length
    zeroes = Array(pad + 1).join("0")
    return zeroes + v

# Sanity check and then split a UKHAS string into fields.
parse_ukhas_string = (s) ->
    s = s.trim()

    if (s.indexOf "$$") is -1
        s = "$$" + s
    else if (s.indexOf "$$") is not 0
        return error: "The string contained $$, but not at the start"
    else if (s.indexOf "$", 2) is not -1
        return error: "The string contained extra $s"

    if not /^[\x20-\x7E]+$/.test s
        return error: "The string contains non-ascii characters. The parser would reject it."

    if (s.indexOf "*") is -1
        return error: "Couldn't find a checksum. I would recommend crc16-ccitt"

    if (s.length - s.indexOf "*") not in [3, 5]
        return error: "The checksum had a length I don't recognise"

    checksum_start = s.indexOf "*"
    checksummable = s[2...checksum_start]

    fields = s[2...checksum_start]
    checksum = s[checksum_start + 1..].toUpperCase()

    if not /^[a-fA-F0-9]+$/.test checksum
        return error: "Checksum found, but it contained non hexadecimal digits"

    checksum_type =
        if checksum.length is 4
            if (crc16_ccitt checksummable) == checksum then           "crc16-ccitt"
            else if (fletcher_16 checksummable) == checksum then      "fletcher-16"
            else if (fletcher_16 checksummable, 256) == checksum then "fletcher-16-256"
            else null
        else if checksum.length is 2
            if (xor_checksum checksummable) == checksum then          "xor"
            else null

    if not checksum_type
        return error: "Checksum invalid or type unrecognised. Tried " +
                        "xor crc16-ccitt fletcher-16 fletcher-16-256"

    fields = fields.split ','
    callsign = fields[0]
    fields = fields[1..]

    if not callsign.length
        return error: "Invalid callsign: zero length"

    if not /^[a-zA-Z0-9/_\\-]+$/.test callsign
        return error: "Invalid callsign: contains characters besides A-Z0-9_/. " +
                       "The server would reject it"

    if fields.length <= 0
        return error: "Did not detect any fields"

    return {
        callsign: callsign
        checksum_type: checksum_type
        fields: fields
        checksum: checksum
        string: s
    }

# Guess the sensor and name of a field.
# Assumes $$callsign,sentence_id,time,lat,lon,alt, and assigns int/float/string to remaining fields
guess_field_type = (fs, index) ->
    if index is 1
        if time_regex.test fs
            name = if index is 1 then "time" else ""
            return sensor: "stdtelem.time", name: name

    if index is 2 or index is 3
        name = if index is 2 then "latitude" else "longitude"
        if /^(-|)[0-9]{1,3}\.[0-9]{4,8}$/.test fs
            return sensor: "stdtelem.coordinate", format: "dd.dddd", name: name
        if /^(-|)[0-9]{3,5}\.[0-5][0-9]{3,5}$/.test fs
            return sensor: "stdtelem.coordinate", format: "ddmm.mmmm", name: name

    if /^(-|)[0-9]+$/.test fs
        name = switch index
            when 0 then "sentence_id"
            when 4 then "altitude"
            else ""

        return sensor: "base.ascii_int", name: name

    if /^(-|)[0-9]+\.[0-9]+$/.test fs
        name = if index is 4 then "altitude" else ""
        return sensor: "base.ascii_float", name: ""

    return sensor: "base.string", name: ""

# Like guess_field_type, but the regexes are far more relaxed. Returns all possibilities
plausible_field_types = (fs) ->
    results = ["base.string", "base.constant"]
    if time_regex.test fs then results.push "stdtelem.time"
    if (/^(-|)[0-9\.]+$/.test fs) and not isNaN(strict_numeric fs)
        if (fs.indexOf '.') == -1
            results.push "base.ascii_int"
        else
            results.push "stdtelem.coordinate"
        results.push "base.ascii_float"
    return results

# Examine the provided telemetry and make some guesses about the first few fields.
wizard_guess = ->
    s = $("#wizard_text_box").val()

    p = parse_ukhas_string s
    if p.error
        $("#wizard_error").text(p.error)
        $("#wizard_error").show()
        $("#wizard_text_box").val ""
        return

    $("#wizard_text_box").hide()
    $("#wizard_error").hide()

    wizard_stage = "sentence"

    wizard_sentence =
        protocol: "UKHAS"
        checksum: p.checksum_type
        callsign: p.callsign
        fields: []

    $("#wizard_success").show()
    $("#wizard_callsign").text p.callsign
    $("#wizard_checksum_type").text p.checksum_type

    $("#wizard_fields").show()
    $("#wizard_fields").empty()
    $("#wizard_fields").append "$$"
    $("#wizard_fields").append $("<span />").text p.callsign

    wizard_field_elems = []
    wizard_field_values = p.fields

    for i in [0...p.fields.length]
        f = guess_field_type p.fields[i], i
        wizard_sentence.fields.push f

        e = $("<span />").text p.fields[i]
        $("#wizard_fields").append ',', e
        wizard_field_elems.push e
        do (i) -> e.click ->
            switch wizard_stage
                when "sentence" then wizard_jump i
                when "no_lock" then wizard_lockfield i

        if f.name is ""
            e.addClass "invalid"

    $("#wizard_fields").append '*', $("<span />").text p.checksum
    $("#wizard_form").show()

    wizard_jump 0, true

# Set/clear field's validity based on the form
wizard_update_field_invalid = ->
    e = wizard_field_elems[wizard_current_field]
    if $("#wizard_form .invalid").length
        e.addClass "invalid"
    else
        e.removeClass "invalid"

# Go directly to the specified field
wizard_jump = (index, first=false) ->
    if not first
        wizard_update_field_invalid()

    if index is wizard_sentence.fields.length
        wizard_try_finish()
        return

    $("#wizard_fields .highlight").removeClass "highlight"

    wizard_current_field = index
    wizard_field_elems[wizard_current_field].addClass "highlight"

    if index == 0
        $("#wizard_prev").button("disable")
    else if index != 0
        $("#wizard_prev").button("enable")

    f = wizard_edit_f()

    $("#wizard_field_name").val f.name
    $("#wizard_field_sensor").val f.sensor or "base.string"
    $("#wizard_coordinate_format").val f.format or "dd.dddd"
    $("#wizard_numeric_scale").prop "checked", f.numeric_scale?

    if f.numeric_scale?
        $("#wizard_numeric_scale_type").val f.numeric_scale.type
        $("#wizard_numeric_scale_factor").val f.numeric_scale.factor
        $("#wizard_numeric_scale_offset").val f.numeric_scale.offset
        $("#wizard_numeric_scale_do_round").prop "checked", f.numeric_scale.do_round
        $("#wizard_numeric_scale_round").val f.numeric_scale.round
    else
        $("#wizard_numeric_scale_type").val "m"
        $("#wizard_numeric_scale_factor").val "1.0"
        $("#wizard_numeric_scale_offset").val "0.0"
        $("#wizard_numeric_scale_do_round").prop "checked", true
        $("#wizard_numeric_scale_round").val "3"

    $("#wizard_form input, #wizard_form select").not("#wizard_numeric_scale_opts *").change()

# Next field
wizard_next = ->
    wizard_jump wizard_current_field + 1

# Previous field
wizard_prev = ->
    wizard_jump wizard_current_field - 1

# Create a filter list in wizard_sentence if neccessary, then add the filter obj
wizard_add_filter = (type, obj) ->
    if not wizard_sentence.filters?
        wizard_sentence.filters = {}
    if not wizard_sentence.filters[type]?
        wizard_sentence.filters[type] = []
    wizard_sentence.filters[type].push obj

# Validate the form and try and finish the sentence stage
wizard_try_finish = ->
    if $("#wizard_fields .invalid").length
        alert "Some fields have not been configured. Please fix them"
        return

    names = {}
    for f in wizard_sentence.fields
        if names[f.name]?
            alert "You have two fields with the same name: #{f.name}"
            return

        names[f.name] = true

    wizard_sentence_finalise()

    has_position = false
    for f in wizard_sentence.fields
        if f.name in ["latitude", "longitude"]
            has_position = true
            break
    
    if has_position
        wizard_nolock_start()
    else
        wizard_stage = null
        return wizard_callback wizard_sentence

# Tidy up wizard_sentence:
#  - Create numeric_scale filters, removing numeric_scale objects from fields
wizard_sentence_finalise = ->
    for field in wizard_sentence.fields
        if field.numeric_scale?
            factor = field.numeric_scale.factor
            if field.numeric_scale.type is "d"
                factor = 1 / factor

            filter =
                filter: "common.numeric_scale"
                type: "normal"
                source: field.name
                factor: factor

            if field.numeric_scale.do_round
                filter.round = field.numeric_scale.round

            if field.numeric_scale.offset != 0
                filter.offset = field.numeric_scale.offset

            delete field.numeric_scale

            wizard_add_filter "post", filter

# Update the example value.
wizard_numeric_scale_demo = ->
    c = wizard_edit_f().numeric_scale
    if not c?
        $("#wizard_numeric_scale_example").text ""
        return

    factor = c.factor
    if c.type is "d"
        factor = 1 / factor

    try
        data = strict_numeric wizard_field_values[wizard_current_field]
        data = (data * factor) + c.offset

        mag = Math.ceil ((Math.log data) / Math.LN10)
        precision = Math.max mag, c.round

        if c.do_round
            # parseFloat again to drop traling .000 which python won't produce.
            data = parseFloat data.toPrecision precision
    catch e
        data = "NaN"

    $("#wizard_numeric_scale_example").text data

# Start the no-lock mode wizard
wizard_nolock_start = ->
    wizard_stage = "no_lock"
    nolock_temp =
        mode: "other"
        lockfield_name: null
        lockfield_numeric: false
        lockfield_index: null
        ok: []

    $("#wizard_form").hide()
    $("#wizard_prev").button("disable")
    $("#wizard_misc").show()

    $("#wizard_fields .highlight").removeClass "highlight"

    $("#wizard_no_lock").val "other"
    $("#wizard_no_lock").change()

    $("#wizard_lockfield_which").text "-"
    $("#wizard_lockfield_ok").empty()

# Set the field to use for lockfield mode
wizard_lockfield = (index) ->
    if nolock_temp.mode != "lockfield"
        return
    if nolock_temp.lockfield_index?
        wizard_field_elems[nolock_temp.lockfield_index].removeClass "highlight"
    wizard_field_elems[index].addClass "highlight"
    nolock_temp.lockfield_index = index
    nolock_temp.lockfield_name = wizard_sentence.fields[index].name
    sensor = wizard_sentence.fields[index].sensor
    nolock_temp.lockfield_numeric = sensor in ["base.ascii_int", "base.ascii_float"]
    $("#wizard_lockfield_which").text nolock_temp.lockfield_name
    $("#wizard_lockfield_ok input").change()

# Collect results of no lock form
wizard_nolock_done = ->
    switch nolock_temp.mode
        when "always"
            wizard_add_filter "post",
                filter: "common.invalid_always"
                type: "normal"
        when "lockfield"
            n = nolock_temp.lockfield_name
            if not n
                alert "Please select the field that indicates a lock by clicking on it"
                return

            if $("#wizard_lockfield_ok .invalid").length
                alert "There are errors in your form. Please fix them"
                return

            if not nolock_temp.ok.length
                alert "Please add atleast one value that indicates a good fix"
                return

            f =
                filter: "common.invalid_gps_lock"
                type: "normal"
                ok: nolock_temp.ok
            unless n is "gps_lock"
                f.source = n

            wizard_add_filter "post", f
        when "zeroes"
            wizard_add_filter "post",
                filter: "common.invalid_location_zero"
                type: "normal"

    wizard_stage = null
    return wizard_callback wizard_sentence

# Attach callbacks to the #wizard_form elements
# This form must save and tolerate invalid values until atleast wizard_sentence_finalise
# is called, since we want to be able to switch between fields despite them being invalid.
wizard_setup_form = ->
    field_name_change = (v) ->
        wizard_edit_f().name = v
        if v and v[0] != "_"
            $("#wizard_field_name").removeClass "invalid"
        else
            $("#wizard_field_name").addClass "invalid"
        wizard_update_field_invalid()

    $("#wizard_field_name").change -> field_name_change $("#wizard_field_name").val()

    $("#wizard_field_name").autocomplete
        source: (w, cb) -> cb suggest_field_names w.term
        select: (e, ui) -> field_name_change if ui.item then ui.item.value else ""

    $("#wizard_field_sensor").change ->
        v = $("#wizard_field_sensor").val()
        wizard_edit_f().sensor = v
        if v is "stdtelem.coordinate"
            $("#wizard_coordinate_format").show()
        else
            $("#wizard_coordinate_format").hide()
        if v is "base.constant"
            wizard_edit_f().expect = wizard_field_values[wizard_current_field]
        else
            delete wizard_edit_f().expect
        if v in ["base.ascii_int", "base.ascii_float"]
            $("#wizard_numeric_scale_section").show()
        else
            $("#wizard_numeric_scale_section").hide()
            $("#wizard_numeric_scale").prop "checked", false
        $("#wizard_coordinate_format_select").change()

    $("#wizard_coordinate_format_select").change ->
        if wizard_edit_f().sensor is "stdtelem.coordinate"
            v = $("#wizard_coordinate_format_select").val()
            wizard_edit_f().format = v
        else
            delete wizard_edit_f().format

    $("#wizard_numeric_scale").change ->
        if $("#wizard_numeric_scale").prop "checked"
            if not wizard_edit_f().numeric_scale?
                wizard_edit_f().numeric_scale = {enable: true}
            $("#wizard_numeric_scale_opts").show()
        else
            delete wizard_edit_f().numeric_scale
            $("#wizard_numeric_scale_opts").hide()
        $("#wizard_numeric_scale_opts input, #wizard_numeric_scale_opts select").change()
        wizard_numeric_scale_demo()

    $("#wizard_numeric_scale_type").change ->
        if wizard_edit_f().numeric_scale?
            wizard_edit_f().numeric_scale.type = $("#wizard_numeric_scale_type").val()
            wizard_numeric_scale_demo()

    for k in ["factor", "offset", "round"]
        e = $("#wizard_numeric_scale_#{k}")
        do (e, k) ->
            e.change ->
                if wizard_edit_f().numeric_scale?
                    v = strict_numeric e.val()
                    wizard_edit_f().numeric_scale[k] = v
                    wizard_numeric_scale_demo()
                    if isNaN(v)
                        e.addClass "invalid"
                    else
                        e.removeClass "invalid"
                else
                    e.removeClass "invalid"
                wizard_update_field_invalid()

    $("#wizard_numeric_scale_do_round").change ->
        if wizard_edit_f().numeric_scale?
            wizard_edit_f().numeric_scale.do_round = $("#wizard_numeric_scale_do_round").prop "checked"
            wizard_numeric_scale_demo()

# Setup callbacks for no-lock form
wizard_setup_nolock_form = ->
    $("#wizard_no_lock").change ->
        nolock_temp.mode = $("#wizard_no_lock").val()
        if nolock_temp.mode is "lockfield"
            if nolock_temp.lockfield_index?
                wizard_field_elems[nolock_temp.lockfield_index].addClass "highlight"
            $("#wizard_lockfield").show()
            $("#wizard_lockfield_buttons").show()
        else
            if nolock_temp.lockfield_index?
                wizard_field_elems[nolock_temp.lockfield_index].removeClass "highlight"
            $("#wizard_lockfield").hide()
            $("#wizard_lockfield_buttons").hide()

    $("#wizard_lockfield_add").click ->
        e = $("<input type='text' />")
        e.addClass "short_input"
        e.change ->
            v = e.val()
            if nolock_temp.lockfield_numeric
                v = strict_numeric v
                if isNaN(v)
                    e.addClass "invalid"
                else
                    e.removeClass "invalid"
            else
                e.removeClass "invalid"
            nolock_temp.ok[e.index()] = v

        if nolock_temp.lockfield_numeric
            e.val 0
            nolock_temp.ok.push 0
        else
            nolock_temp.ok.push ""

        $("#wizard_lockfield_ok").append e
        $("#wizard_lockfield_remove").show()

    $("#wizard_lockfield_remove").click ->
        $("#wizard_lockfield_ok").lastChild().remove()
        nolock_temp.ok.pop()
        if $("#wizard_lockfield_ok").children().length == 0
            $("#wizard_lockfield_remove").hide()

$ ->
    $("#wizard_retry").click -> sentence_wizard false, wizard_callback # restart with same cb
    $("#wizard_cancel").click -> wizard_callback false
    $("#wizard_next").click ->
        switch wizard_stage
            when "paste" then wizard_guess()
            when "sentence" then wizard_next()
            when "no_lock" then wizard_nolock_done()
    $("#wizard_prev").click ->
        if wizard_stage is "sentence" then wizard_prev()
    wizard_setup_form()
    wizard_setup_nolock_form()
