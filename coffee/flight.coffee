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

# Return object with keys launch, start, end describing the 3 dates in the flight.
flight_get_dates = ->
    launch = $("#launch_date").datepicker "getDate"
    time = time_parse $("#launch_time").val
    launch.setHours time[0]
    launch.setMinutes time[1]
    launch.setSeconds time[2]
    launch.setMilliseconds 0

    window = $("#launch_window").val()

    if window == "weekend"
        date = new Date(launch)
        date.setHours 0
        date.setMinutes 0
        date.setSeconds 0
        date.setMilliseconds 0

        if date.getDay() == 0
            date.setDate(date.getDate() - 1)

        start = new Date(date)
        date.setDate(date.getDate() + 2)
        end = date

    else if window == "other"
        start = $("#launch_window_start").datepicker "getDate"
        end = $("#launch_window_end").datepicker "getDate"

        start.setHours 0
        start.setMinutes 0
        start.setSeconds 0
        start.setMilliseconds 0
        end.setHours 23
        end.setMinutes 59
        end.setSeconds 59
        end.setMilliseconds 0

        if start > end
            throw "start > end"

    else
        delta = strict_numeric v
        if isNaN delta
            throw "option isNaN (shouldn't be)"

        delta *= 1000 # ms
        delta /= 2 # half each way
        start = new Date(launch.getTime() - delta)
        end = new Date(launch.getTime() + delta)

    # TODO

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
        onSelect: (text, inst) ->
            date = $("#launch_date").datepicker "getDate"
            $("#launch_timezone").text date.getRFC3339Offset()

            lw = $("#launch_window")

            if date.getDay() in [0, 6]
                # weekend
                if lw.children().length == 4
                    lw.children().last().before $("<option>weekend</option>")
            else
                if lw.children().length == 5
                    if lw.val() == "weekend"
                        lw.val "172800" # 2 days
                        lw.change()

                    lw.children('[value="weekend"]').remove()

    $("#launch_window_start").datepicker
        onSelect: (text, inst) ->
            # TODO
    $("#launch_window_end").datepicker
        onSelect: (text, inst) ->
            # TODO

    form_field "#launch_time"
        extra: (s) -> time_regex.test s

    $("#launch_window").change ->
        update_launch_window_info()
        if $("#launch_window").val() == "other"
            $("#launch_window_custom").show()
        else
            $("#launch_window_custom").hide()

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
