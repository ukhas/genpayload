# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# add show/hide help callbacks, and set default state from cookie
setup_home = ->
    $("#show_help").click open_help
    $("div#hide_help > a").click close_help

    $("#help_once").change ->
        newpref = if $("#help_once").prop "checked" then "hide" else null
        $.cookie("genpayload_help", newpref, expires: 365)

    pref = $.cookie("genpayload_help")

    if pref is "hide"
        $("#help_once").prop "checked", true
        close_help()
    else
        open_help()

# open help section and update show/hide links accordingly
open_help = ->
    $("#help").show()
    $("#create").hide()
    $("#show_help").hide()
    $("#hide_help").show()

# close help section and update show/hide links accordingly
close_help = ->
    $("#help").hide()
    $("#create").show()
    $("#show_help").show()
    $("#hide_help").hide()

default_pcfg_doc =
    name: ""
    description: ""
    type: "payload_configuration"
    sentences: []
    transmissions: []

default_flight_doc = {} # TODO default flight doc

# add callbacks to the go_ buttons in the create div
setup_create_actions = ->
    $("#go_pcfg_new").click ->
        toplevel "#payload_configuration"
        d = deepcopy(default_pcfg_doc)
        pcfg_edit d, (doc) -> toplevel "#home"

    $("#go_pcfg_modify").click ->
        toplevel "#browse"
        browse "payload_configuration", (doc) ->
            if doc
                toplevel "#payload_configuration"
                pcfg_edit doc, (doc) -> toplevel "#home"
            else
                toplevel "#home"

    $("#go_flight_new").click ->
        toplevel "#flight"
        d = deepcopy(default_flight_doc)
        flight_edit d, (doc) -> toplevel "#home"

    $("#go_flight_modify").click ->
        toplevel "#browse"
        browse "flight", (doc) ->
            if doc
                toplevel "#flight"
                flight_edit doc, (doc) -> toplevel "#home"
            else
                toplevel "#home"

$ ->
    setup_create_actions()

    # main start point of the app
    toplevel "#home"
    setup_home()
