# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# State
transmission_callback = null

# Main start point for transmission editor. #transmission_edit should be visible.
# t: an transmission dict to modify.
# callback: called when finished, with the new `t` as a single argument, or false if the user cancelled
transmission_edit = (t, callback) ->
    transmission_callback = callback

    $("#transmission_description").val t.description or ""

    $("#transmission_frequency").val  t.frequency / 1e6
    $("#transmission_mode").val       t.mode
    $("#transmission_modulation").val t.modulation

    # These are only required if modulation == RTTY. Load or set the defaults.
    $("#transmission_shift").val    t.shift or ""
    $("#transmission_encoding").val t.encoding or "ASCII-8"
    $("#transmission_baud").val     t.baud or ""
    $("#transmission_parity").val   t.parity or "none"
    $("#transmission_stop").val     t.stop or 2

    # modulation == DominoEX
    $("#transmission_speed").val t.speed or 22

    # modulation == Hellschreiber
    $("#transmission_variant").val t.variant or "feldhell"

    # Update validation, open correct section
    $("#transmission_edit input, #transmission_edit select").change()

# Validate the form, then pass it back to the callback
transmission_confirm = ->
    ok = true
    transmission = {}

    # keys here are numeric or select.
    get = (key, numeric=false) ->
        v = $("#transmission_#{key}").val()
        if numeric
            transmission[key] = strict_numeric v
            if (isNaN v) or v <= 0
                throw "get error"
        else
            transmission[key] = v

    try
        get "frequency", true
        transmission.frequency *= 1e6
        get "modulation"
        get "mode"

        keys = switch transmission.modulation
            when "RTTY"
                strs: ["encoding", "parity"]
                nums: ["stop", "shift", "baud"]
            when "DominoEX"
                strs: []
                nums: ["speed"]
            when "Hellschreiber"
                strs: ["variant"]
                nums: []

        get key for key in keys.strs
        get key, true for key in keys.nums

    catch e
        alert "There are errors in the form. Please fix them"
        return

    # string key; optional
    d = $("#transmission_description").val()
    if d != ""
        transmission.description = d

    transmission_callback transmission
    return

# Report failure using the callback
transmission_cancel = ->
    transmission_callback false
    return

# Add callbacks to the input elements
setup_transmission_form = ->
    # Positive integer fields
    for f in ["frequency", "shift", "baud"]
        form_field "#transmission_#{f}",
            numeric: true
            positive: true

    $("#transmission_modulation").change ->
        v = $("#transmission_modulation").val()
        show = "#transmission_" + v.toLowerCase()

        $("#transmission_edit > div").not("#transmission_misc, .buttons").not(show).hide()
        $(show).show()
        return

$ ->
    setup_transmission_form()

    $("#transmission_confirm").click -> transmission_confirm()
    $("#transmission_cancel").click -> transmission_cancel()
    return
