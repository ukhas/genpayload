# Copyright (c) 2012 Daniel Richman; GNU GPL 3

wizard_callback = null
wizard_sentence = null
wizard_fields = null
wizard_current_field = null
wizard_stage = null
nolock_temp = null

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
    s = $.trim s

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

    if not callsign_regexp.test callsign
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

    wizard_fields = []

    for v, i in p.fields
        f = guess_field_type v, i
        wizard_sentence.fields.push f

        e = $("<span />").text v
        $("#wizard_fields").append ',', e
        do (i) -> e.click ->
            switch wizard_stage
                when "sentence" then wizard_jump i
                when "second" then wizard_lockfield i
            return

        if f.name is ""
            e.addClass "invalid"

        wizard_fields.push
            elem: e
            value: v
            sensor_options: plausible_field_types v

    $("#wizard_fields").append '*', $("<span />").text p.checksum
    $("#wizard_form").show()

    wizard_jump 0, true

# Go directly to the specified field
wizard_jump = (index, first=false) ->
    if not first
        f = wizard_field_save()
        wizard_sentence.fields[wizard_current_field] = f

        e = wizard_fields[wizard_current_field].elem
        if f.invalid
            e.addClass "invalid"
        else
            e.removeClass "invalid"

    if index is wizard_sentence.fields.length
        wizard_try_finish()
        return

    $("#wizard_fields .highlight").removeClass "highlight"

    wizard_current_field = index
    ne = wizard_fields[wizard_current_field].elem
    ne.removeClass "invalid"
    ne.addClass "highlight"

    if index == 0
        $("#wizard_prev").button("disable")
    else if index != 0
        $("#wizard_prev").button("enable")

    wizard_field_load wizard_fields[index], wizard_sentence.fields[index]

# Populate #wizard_form from `m` (wizard_fields item) and `f` (wizard_sentence.fields item)
wizard_field_load = (m, f) ->
    $("#wizard_field_sensor").empty()
    for o in m.sensor_options
        e = $("<option />")
        e.val o
        e.text sensor_list[o]
        $("#wizard_field_sensor").append e

    $("#wizard_field_name").val f.name
    $("#wizard_field_sensor").val f.sensor
    $("#wizard_coordinate_format").val f.format or "dd.dddd"
    $("#wizard_numeric_scale").prop "checked", f.numeric_scale?

    if f.numeric_scale?
        $("#wizard_numeric_scale_type").val f.numeric_scale.type
        $("#wizard_numeric_scale_factor").val f.numeric_scale.factor
        $("#wizard_numeric_scale_offset").val f.numeric_scale.offset
        $("#wizard_numeric_scale_do_round").prop "checked", f.numeric_scale.round?
        $("#wizard_numeric_scale_round").val f.numeric_scale.round or "3"
    else
        $("#wizard_numeric_scale_type").val "m"
        $("#wizard_numeric_scale_factor").val "1.0"
        $("#wizard_numeric_scale_offset").val "0.0"
        $("#wizard_numeric_scale_do_round").prop "checked", true
        $("#wizard_numeric_scale_round").val "3"

    $("#wizard_form input, #wizard_form select").change()

# Read values from #wizard_form into f. Sets f.invalid if some things are wrong
wizard_field_save = ->
    f =
        name: $("#wizard_field_name").val()
        sensor: $("#wizard_field_sensor").val()

    if f.name == "" or f.name[0] == "_"
        f.invalid = true

    if f.sensor is "base.constant"
        f.expect = wizard_fields[wizard_current_field].value

    if f.sensor is "stdtelem.coordinate"
        f.format = $("#wizard_coordinate_format_select").val()

    if f.sensor in ["base.ascii_int", "base.ascii_float"] and $("#wizard_numeric_scale").prop "checked"
        f.numeric_scale =
            factor: strict_numeric $("#wizard_numeric_scale_factor").val()
            offset: strict_numeric $("#wizard_numeric_scale_offset").val()

        if $("#wizard_numeric_scale_do_round").prop "checked"
            f.numeric_scale.round = strict_integer $("#wizard_numeric_scale_round").val()

        for k, v of f.numeric_scale
            if isNaN v
                f.invalid = true

        f.numeric_scale.type = $("#wizard_numeric_scale_type").val()

    return f

# Next/previous field
wizard_next = -> wizard_jump wizard_current_field + 1
wizard_prev = -> wizard_jump wizard_current_field - 1

# Create a filter list in wizard_sentence if neccessary, then add the filter obj
wizard_add_filter = (type, obj) ->
    if not wizard_sentence.filters?
        wizard_sentence.filters = {}
    if not wizard_sentence.filters[type]?
        wizard_sentence.filters[type] = []
    wizard_sentence.filters[type].push obj

# Validate the form and try and finish the sentence stage
wizard_try_finish = ->
    names = {}
    for f in wizard_sentence.fields
        if f.invalid
            alert "Some fields have not been configured. Please fix them"
            return

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
    
    wizard_second_stage has_position

# Tidy up wizard_sentence:
#  - Create numeric_scale filters, removing numeric_scale objects from fields
wizard_sentence_finalise = ->
    for field in wizard_sentence.fields
        if field.numeric_scale?
            filter = field.numeric_scale

            if field.numeric_scale.type is "d"
                filter.factor = 1 / filter.factor

            delete filter.type

            filter.filter = "common.numeric_scale"
            filter.type = "normal"
            filter.source = field.name

            if filter.offset == 0
                delete filter.offset

            delete field.numeric_scale

            wizard_add_filter "post", filter

# Update the example value.
wizard_numeric_scale_demo = ->
    c = wizard_field_save().numeric_scale
    if not c?
        $("#wizard_numeric_scale_example").text ""
        return

    factor = c.factor
    if c.type is "d"
        factor = 1 / factor

    try
        data = strict_numeric wizard_fields[wizard_current_field].value
        data = (data * factor) + c.offset

        if c.round?
            # parseFloat again to remove exp format and drop traling .000 which python won't produce.
            data = parseFloat data.toPrecision c.round
    catch e
        data = "NaN"

    $("#wizard_numeric_scale_example").text data
    return

# if has_position, Start the no-lock mode wizard
wizard_second_stage = (has_position) ->
    wizard_stage = "second"
    nolock_temp = {}

    $("#wizard_form").hide()
    $("#wizard_prev").button("disable")
    $("#wizard_misc").show()

    $("#wizard_fields .highlight").removeClass "highlight"

    $("#wizard_description").val ""
    $("#wizard_no_lock").val if has_position "other" else "n/a"
    $("#wizard_no_lock").change()

    $("#wizard_lockfield_ok").empty()
    $("#wizard_lockfield_add").click()
    $("#wizard_lockfield_remove").button("disable")

# Set the field to use for lockfield mode. Only allows selection of int,float,string fields.
wizard_lockfield = (index) ->
    if $("#wizard_no_lock").val() != "lockfield"
        return

    f = wizard_sentence.fields[index]
    if f.sensor not in ["base.ascii_int", "base.ascii_float", "base.string"]
        return

    $("#wizard_fields .highlight").removeClass "highlight"
    e = wizard_fields[index].elem
    e.addClass "highlight"

    nolock_temp.lockfield = f
    nolock_temp.lockfield_elem = e

    $("#wizard_select_lockfield").hide()
    $("#wizard_lockfield").show()
    $("#wizard_lockfield_which").text nolock_temp.lockfield.name
    $("#wizard_lockfield_ok input").change()

# Collect results of no lock form
wizard_second_done = ->
    d = $("#wizard_description").val()
    if d != ""
        wizard_sentence.description = d

    switch $("#wizard_no_lock").val()
        when "always"
            wizard_add_filter "post",
                filter: "common.invalid_always"
                type: "normal"
        when "lockfield"
            if not nolock_temp.lockfield?
                alert "Please select the field that indicates a lock by clicking on it"
                return

            lf = nolock_temp.lockfield

            cast_func = switch lf.sensor
                when "base.ascii_int" then strict_integer
                when "base.ascii_float" then strict_numeric
                else (s) -> s
            verify_func = switch lf.sensor
                when "base.ascii_int", "base.ascii_float" then (v) -> not isNaN v
                else (v) -> true

            ok = (cast_func $(e).val() for e in $("#wizard_lockfield_ok input"))

            for v in ok
                if not verify_func v
                    alert "There are errors in your form. Please fix them"
                    return

            if not ok.length
                alert "Please add atleast one value that indicates a good fix"
                return

            f =
                filter: "common.invalid_gps_lock"
                type: "normal"
                ok: ok

            unless lf.name is "gps_lock"
                f.source = lf.name

            wizard_add_filter "post", f
        when "zeroes"
            wizard_add_filter "post",
                filter: "common.invalid_location_zero"
                type: "normal"

    wizard_stage = null
    wizard_callback wizard_sentence

# Attach callbacks to the #wizard_form elements
wizard_setup_form = ->
    field_name_input $("#wizard_field_name")
    sensor_select $("#wizard_field_sensor")
    sensor_format_select $("#wizard_coordinate_format_select")

    $("#wizard_field_sensor").change ->
        v = $("#wizard_field_sensor").val()
        if v is "stdtelem.coordinate"
            $("#wizard_coordinate_format").show()
        else
            $("#wizard_coordinate_format").hide()
        if v in ["base.ascii_int", "base.ascii_float"]
            $("#wizard_numeric_scale_section").show()
        else
            $("#wizard_numeric_scale_section").hide()
        return

    $("#wizard_numeric_scale").change ->
        if $("#wizard_numeric_scale").prop "checked"
            $("#wizard_numeric_scale_opts").show()
            wizard_numeric_scale_demo()
        else
            $("#wizard_numeric_scale_opts").hide()
        return

    $("#wizard_numeric_scale_type").change wizard_numeric_scale_demo

    for k in ["factor", "offset", "round"]
        e = "#wizard_numeric_scale_#{k}"
        form_field e,
            numeric: true
            integer: k == "round"
        $(e).change wizard_numeric_scale_demo

    $("#wizard_numeric_scale_do_round").change ->
        if $("#wizard_numeric_scale_do_round").prop "checked"
            $("#wizard_numeric_scale_round_opts").show()
        else
            $("#wizard_numeric_scale_round_opts").hide()
        wizard_numeric_scale_demo()
        return

# Setup callbacks for no-lock form
wizard_setup_nolock_form = ->
    $("#wizard_no_lock").change ->
        v = $("#wizard_no_lock").val()
        if v is "lockfield"
            if nolock_temp.lockfield_elem?
                nolock_temp.lockfield_elem.addClass "highlight"
                $("#wizard_lockfield").show()
                $("#wizard_lockfield_buttons").show()
                $("#wizard_select_lockfield").hide()
            else
                $("#wizard_select_lockfield").show()
        else
            $("#wizard_fields .highlight").removeClass "highlight"
            $("#wizard_lockfield").hide()
            $("#wizard_lockfield_buttons").hide()
            $("#wizard_select_lockfield").hide()
        if v is "other"
            $("#wizard_nolock_othernotice").show()
        else
            $("#wizard_nolock_othernotice").hide()
        if v is "always"
            $("#wizard_nolock_alwaysnotice").show()
        else
            $("#wizard_nolock_alwaysnotice").hide()
        return

    $("#wizard_lockfield_add").click ->
        e = $("<input type='text' />")
        e.addClass "short_input"
        form_field e, extra: (v) ->
            if not nolock_temp.lockfield?
                return true
            switch nolock_temp.lockfield.sensor
                when "base.ascii_int" then return not isNaN strict_integer v
                when "base.ascii_float" then return not isNaN strict_numeric v
                else return true
        e.change()

        $("#wizard_lockfield_ok").append e, ' '
        $("#wizard_lockfield_remove").button("enable")
        return

    $("#wizard_lockfield_remove").click ->
        $("#wizard_lockfield_ok").children().last().remove()
        if $("#wizard_lockfield_ok").children().length == 0
            $("#wizard_lockfield_remove").button("disable")
        return

# Setup callbacks on page load
$ ->
    $("#wizard_text_box").keydown (e) ->
        if e.which is 13 and wizard_stage is "paste"
            wizard_guess()
        return
    $("#wizard_retry").click ->
        sentence_wizard false, wizard_callback # restart with same cb
        return
    $("#wizard_cancel").click ->
        wizard_callback false
        return
    $("#wizard_next").click ->
        switch wizard_stage
            when "paste" then wizard_guess()
            when "sentence" then wizard_next()
            when "second" then wizard_second_done()
        return
    $("#wizard_prev").click ->
        if wizard_stage is "sentence"
            wizard_prev()
        return
    wizard_setup_form()
    wizard_setup_nolock_form()
    return
