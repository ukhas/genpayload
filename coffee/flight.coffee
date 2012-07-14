# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# Current editing state
flight_doc = null
flight_callback = null

# Main start point for flight editing. #flight should be visible.
# Loads data from doc into the forms and enables editing. callback(doc) is called when the doc
# has been successfully saved to the database or callback(false) is called if the user cancels.
flight_edit = (doc, callback) ->
    flight_doc = doc
    flight_callback = callback

# Save doc, call callback
flight_save = ->

setup_flight_form = ->
    form_field "#flight_name"
        nonempty: true

    $("#launch_location_name").autocomplete
        source: suggest_launch_data
        select: (e, ui) ->
            if ui.item
                $("#launch_latitude").val(ui.item.latitude).change()
                $("#launch_longitude").val(ui.item.longitude).change()
        minLength: 0

    # Encourage the autocomplete box to open more often
    $("#launch_location_name").click -> $(this).autocomplete "search"

    $("#launch_date").datepicker
        dateFormat: 'yy-mm-dd'
        onSelect: (text, inst) ->
            [year, month, day] = (+i for i in text.split("-"))
            # TODO: remove/add #launch_window_weekend from #launch_window
            # TODO: call update #launch_window_info

    $("#launch_window_start, #launch_window_end").datepicker()
    # TODO: style datepickers (margin-left align with other inputs); place window start/end side by side.

    form_field "#launch_time"
        extra: (s) -> time_regex.test s

    $("#launch_window").change ->
        v = $("#launch_window").val()
        # TODO: switch v; call update #launch_window_info

    form_field "#launch_latitude"
        nonempty: true
        numeric: true
    form_field "#launch_longitude"
        nonempty: true
        numeric: true

$ ->
    setup_flight_form()
    $("#flight_save").click flight_save
    $("#flight_abandon").click -> flight_callback false
