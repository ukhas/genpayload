# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# add callbacks to the go_ buttons in the create div and the quick_ links
setup_create_actions = ->
    $("#go_pcfg_new").click btn_cb ->
        toplevel "#payload_configuration"
        pcfg_edit null, (doc) -> toplevel "#home"

    $("#go_pcfg_modify").click btn_cb ->
        toplevel "#browse"
        browse "payload_configuration", (doc) ->
            if doc
                toplevel "#payload_configuration"
                pcfg_edit doc, (doc) -> toplevel "#home"
            else
                toplevel "#home"

    $("#go_flight_new").click btn_cb ->
        toplevel "#flight"
        flight_edit null, (doc) -> toplevel "#home"

    $("#go_flight_modify").click btn_cb ->
        toplevel "#browse"
        browse "flight", (doc) ->
            edit_cb = (doc) -> toplevel "#home"

            if doc and doc.payloads? and doc.payloads.length
                toplevel "#loading_docs"
                load_docs doc.payloads, (other_docs) ->
                    if other_docs
                        toplevel "#flight"
                        flight_edit doc, edit_cb, other_docs
                    else
                        toplevel "#home"
            else if doc
                toplevel "#flight"
                flight_edit doc, edit_cb
            else
                toplevel "#home"

    $("#quick_pcfg").click btn_cb ->
        $("#go_pcfg_new").click()
        $("#go_wizard").click()

    $("#quick_flight").click btn_cb ->
        $("#go_flight_new").click()

$ ->
    setup_create_actions()

    # main start point of the app
    toplevel "#home"
    return
