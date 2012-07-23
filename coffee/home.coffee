# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# add callbacks to the go_ buttons in the create div and the quick_ links
setup_create_actions = ->
    $("#go_pcfg_new").click ->
        toplevel "#payload_configuration"
        pcfg_edit null, (doc) -> toplevel "#home"
        return

    $("#go_pcfg_modify").click ->
        toplevel "#browse"
        browse "payload_configuration", (doc) ->
            if doc
                toplevel "#payload_configuration"
                pcfg_edit doc, (doc) -> toplevel "#home"
            else
                toplevel "#home"
        return

    $("#go_flight_new").click ->
        toplevel "#flight"
        flight_edit null, (doc) -> toplevel "#home"
        return

    $("#go_flight_modify").click ->
        toplevel "#browse"
        browse "flight", (doc) ->
            edit_cb = (doc) -> toplevel "#home"

            if doc and doc.payloads.length
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
        return

    $("#quick_pcfg").click ->
        $("#go_pcfg_new").click()
        $("#go_wizard").click()
        return

    $("#quick_flight").click ->
        $("#go_flight_new").click()
        return

$ ->
    setup_create_actions()

    # main start point of the app
    toplevel "#home"
    return
