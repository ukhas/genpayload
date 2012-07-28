# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# Current state
browse_callback = null
browse_type = null
browse_next_what = null
browse_prev_what = null
browse_search_enabled = false
browse_search_timer = null

browse_per_page = 100

browse_item_date_id = (id, date, elem) ->
    cell = $("<td class='small' />")
    cell.append $("<div />").text id
    localestring = (new timezoneJS.Date date).toString()
    cell.append $("<div />").text(date).attr("title", localestring)
    elem.append cell

browse_types =
    payload_configuration:
        view: "prototype_genpayload/payload_configuration__name__created_descending"
        term_key: (term) -> [term]
        display: (row) ->
            doc = row.doc

            seen = {}
            uniques = []
            for s in doc.sentences
                if seen[s.callsign]?
                    continue
                uniques.push s.callsign
                seen[s.callsign] = true
            uniques.sort()
            callsigns = uniques.join ', '
            callsigns = $("<div />").text callsigns

            if doc.description?
                description = $("<div class='small browse_description' />")
                description.text '"' + doc.description + '"'
                if doc.description.length > 30
                    description.attr "title", doc.description
            else
                description = null

            d = $("<tr />")
            d.append $("<td class='big' />").text doc.name

            c = $("<td />")
            c.append callsigns
            if description?
                c.append description
            d.append c

            browse_item_date_id doc._id, doc.time_created, d

            d.data "browse_return", doc
            return d

    sentence:
        view: "prototype_genpayload/payload_configuration__sentence_callsign__created_descending__sentence_index"
        term_key: (term) -> [term]
        display: (row) ->
            callsign = row.key[0]
            index = row.key[2]
            sentence = row.doc.sentences[index]
            doc = row.doc
            if sentence.description?
                description = $("<div class='small browse_description' />")
                description.text '"' + sentence.description + '"'
                if sentence.description.length > 30
                    description.attr "title", sentence.description
            else
                description = null

            d = $("<tr />")
            d.append $("<td class='big' />").text callsign

            c = $("<td />")
            c.append $("<div />").text "from #{doc.name}"
            if description?
                c.append description, ' '
            d.append c

            browse_item_date_id "#{doc._id} #{index}", doc.time_created, d

            d.data "browse_return", sentence
            return d

    flight:
        view: "prototype_genpayload/flight__name"
        term_key: (term) -> term
        display: (row) ->
            name = row.key
            doc = row.doc

            d = $("<tr />")
            d.append $("<td class='big' />").text doc.name

            i = $("<td class='small' />")
            i.append $("<div />").text if doc.approved then "Approved" else ""
            i.append $("<div />").text "#{doc.metadata.group or ""} #{doc.metadata.project or ""}"
            d.append i

            browse_item_date_id doc._id, doc.launch.time, d

            d.data "browse_return", doc
            return d

# Main start point for browser. #browse should be visible. type is one of "flight",
# "payload_configuration" or "sentence" dependig on what we want to look for. callback(doc) is called
# if the user picks something, callback(false) otherwise.
browse = (type, callback) ->
    browse_callback = callback
    browse_type = type
    $("#browse_search").val ""
    browse_load()

# Reset browse ui
browse_clear = ->
    $("#browse_list").empty()
    $("#browse_status").text "Loading..."
    btn_disable "#browse_search_go, #browse_prev, #browse_next, #browse_cancel"
    browse_search_enabled = false
    if browse_search_timer?
        clearTimeout browse_search_timer
    browse_search_timer = null
    browse_next_what = null
    browse_prev_what = null

search_low_key = (term) ->
    browse_types[browse_type].term_key term.toLowerCase()
search_high_key = (term) ->
    browse_types[browse_type].term_key term.toUpperCase() + "ZZZZZZZZZZZZZ"

# Load a page of results.
# What can contain:
#  - search: search term
#  - next_after: {id: "...", key: "..."}
#  - prev_before: {id: "...", key: "..."}
browse_load = (what={}) ->
    browse_clear()

    options =
        limit: browse_per_page + 1
        include_docs: true

    if what.next_after?
        options.startkey = what.next_after.key
        options.startkey_docid = what.next_after.id
        options.skip = 1

        if what.search?
            options.endkey = search_high_key what.search

    else if what.prev_before?
        options.startkey = what.prev_before.key
        options.startkey_docid = what.prev_before.id
        options.skip = 1
        options.descending = true

        if what.search?
            options.endkey = search_low_key what.search

    else
        what.first_page = true

        if what.search?
            options.startkey = search_low_key what.search
            options.endkey = search_high_key what.search

    options.success = (resp) ->
        [pages_before, pages_after] = browse_hack_response what, resp
        browse_display what, resp
        browse_setup_page_links what, resp, pages_before, pages_after
        return

    options.error = (status, error, reason) ->
        $("#browse_status").text "Error loading rows: #{status}, #{error}, #{reason}"
        btn_enable "#browse_cancel"
        return

    database.view browse_types[browse_type].view, options

# Undoes the descending, pops the extra item off, fixes the offset.
# Figures out if there are pages before and after; returning booleans [pages_before, pages_after]
browse_hack_response = (what, resp) ->
    full_response = (resp.rows.length == browse_per_page + 1)

    if full_response
        resp.rows.pop()

    if what.first_page
        pages_before = false
        pages_after = full_response

    else if what.next_after?
        pages_before = true
        pages_after = full_response

    else if what.prev_before?
        pages_before = full_response
        pages_after = true

        resp.offset = resp.total_rows - resp.offset - 1
        resp.rows.reverse()

    else
        throw "invalid state"

    return [pages_before, pages_after]

# Update the ui with the results
browse_display = (what, resp) ->
    if not what.search?
        $("#browse_status").text "Rows #{resp.offset + 1}-#{resp.offset + resp.rows.length}"
    else
        # Can't figure out row counts when asking for subset.
        $("#browse_status").text ""

    for row in resp.rows
        $("#browse_list").append browse_types[browse_type].display row

    $("#browse_list > tr").click btn_cb ->
        data = $(this).data "browse_return"
        browse_callback data

    btn_enable "#browse_cancel, #browse_search_go"
    browse_search_enabled = true

# Setup the next/prev buttons, updating global variables to make them work.
browse_setup_page_links = (what, resp, pages_before, pages_after) ->
    if pages_before
        btn_enable "#browse_prev"
        first = resp.rows[0]
        browse_prev_what =
            prev_before:
                key: first.key
                id: first.id
        if what.search?
            browse_prev_what.search = what.search

    if pages_after
        btn_enable "#browse_next"
        last = resp.rows[resp.rows.length - 1]
        browse_next_what =
            next_after:
                key: last.key
                id: last.id
        if what.search?
            browse_next_what.search = what.search

browse_search_on_timer = ->
    browse_search_timer = null
    if browse_search_enabled
        $("#browse_search_go").click()
    return

# Setup browse ui callbacks
$ ->
    $("#browse_cancel").click btn_cb -> browse_callback false
    $("#browse_next").click btn_cb -> browse_load browse_next_what
    $("#browse_prev").click btn_cb -> browse_load browse_prev_what

    $("#browse_search_go").click btn_cb ->
        if browse_search_enabled
            search = $("#browse_search").val()
            browse_load search: search

    $("#browse_search").keydown ->
        if browse_search_timer?
            clearTimeout browse_search_timer
        browse_search_timer = setTimeout browse_search_on_timer, 500

    return
