# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# State
transmission = null
transmission_callback = null

# Main start point for transmission editor. #transmission_edit should be visible.
# t: an transmission dict to modify.
# callback: called when finished, with the new `t` as a single argument, or false if the user cancelled
transmission_edit = (t, callback) ->
    transmission = t
    transmission_callback = callback

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

    # Update validation, open correct section
    $("#transmission_edit input, #transmission_edit select").change()

# Validate the form, then pass it back to the callback
transmission_confirm = ->
    b = switch transmission.modulation
        when "RTTY" then "#transmission_rtty"
        when "DominoEX" then "#transmission_dominoex"

    if $("#transmission_misc .invalid, #{b} .invalid").length
        alert "There are errors in the form. Please fix them"
        return

    # Prune unwanted keys from the transmission dict
    kill_list = 
        RTTY: ["shift", "encoding", "baud", "parity", "stop"]
        DominoEX: ["speed"]

    for m, l of kill_list
        if transmission.modulation is m
            continue
        for k in l
            delete transmission[k]

    transmission_callback transmission

# Report failure using the callback
transmission_cancel = -> transmission_callback false

# Add callbacks to the input elements
setup_transmission_form = ->
    # Positive integer fields
    for f in ["frequency", "shift", "baud"]
        do (f) ->
            fe = $("#transmission_#{f}")
            fe.change ->
                v = strict_numeric fe.val()
                if isNaN(v) or v <= 0
                    fe.addClass("invalid")
                else
                    fe.removeClass("invalid")
                    if f is "frequency"
                        v *= 1e6
                    transmission[f] = v

    $("#transmission_modulation").change ->
        transmission.modulation = $("#transmission_modulation").val()
        show = switch transmission.modulation
            when "RTTY" then "#transmission_rtty"
            when "DominoEX" then "#transmission_dominoex"

        $("#transmission_edit > div").not("#transmission_misc, .buttons").not(show).hide()
        $(show).show()

    # Simple <select> fields
    for f in ["mode", "encoding", "parity", "stop", "speed"]
        do (f) ->
            fe = $("#transmission_#{f}")
            fe.change -> transmission[f] = fe.val()

$ ->
    setup_transmission_form()

    $("#transmission_confirm").click -> transmission_confirm()
    $("#transmission_cancel").click -> transmission_cancel()
