# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# Current state
browse_callback = null
browse_type = null
browse_next_what = null
browse_prev_what = null
browse_search_enabled = false
browse_search_timer = null

browse_per_page = 100

# Creates and returns a row for #browse_list. first: text, placed in a h3. second: elements.
# third cell is created automatically.
browse_row = (first, second, id, date) ->
    append_array = (elem, things) ->
        elem.append t for t in things
        return elem

    r = $("<div class='sixteen columns row browse_item' />")
    r.append $("<div class='four columns alpha' />").append ($("<h4 />").text first)
    r.append append_array $("<div class='eight columns' />"), second
    r.append append_array $("<div class='four columns omega' />"), browse_item_date_id id, date
    return r

browse_item_date_id = (id, date) ->
    localestring = (new timezoneJS.Date date).toString()
    return [($("<div />").append $("<small />").text id),
            ($("<div />").append $("<small />").text(date).attr("title", localestring))]

browse_types =
    payload_configuration:
        view: "payload_configuration/name_time_created"
        include_docs: true
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
            second = [$("<div class='nocollapse' />").text callsigns]

            if doc.metadata?.description?
                description = $("<small class='long_protection' />")
                description.text '"' + doc.metadata.description + '"'
                if doc.metadata.description.length > 30
                    description.attr "title", doc.metadata.description
                second.push $("<div class='nocollapse' />").append description

            d = browse_row doc.name, second, doc._id, doc.time_created
            d.data "browse_return", doc
            return d

    sentence:
        view: "payload_configuration/callsign_time_created_index"
        include_docs: false
        term_key: (term) -> [term]
        display: (row) ->
            callsign = row.key[0]
            index = row.key[2]
            [metadata, sentence] = row.value

            second = [$("<div class='nocollapse' />").text "from #{metadata.name}"]
            if sentence.description?
                description = $("<small class='long_protection' />")
                description.text '"' + sentence.description + '"'
                if sentence.description.length > 30
                    description.attr "title", sentence.description
                second.push $("<div class='nocollapse' />").append description

            d = browse_row callsign, second, "#{row.id} #{index}", metadata.time_created
            d.data "browse_return", sentence
            return d

    flight:
        view: "flight/all_name_time_created"
        include_docs: true
        term_key: (term) -> term
        display: (row) ->
            doc = row.doc

            second = [($("<div class='nocollapse' />").text if doc.approved then "Approved" else ""),
                      ($("<div class='nocollapse' />").text "#{doc.metadata?.group or ""} #{doc.metadata?.project or ""}")]

            d = browse_row doc.name, second, doc._id, doc.launch.time
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
        include_docs: browse_types[browse_type].include_docs

    if what.search? and what.search == ""
        delete what.search

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

        resp.offset = resp.total_rows - resp.offset - resp.rows.length
        resp.rows.reverse()

    else
        throw "invalid state"

    return [pages_before, pages_after]

# Update the ui with the results
browse_display = (what, resp) ->
    if resp.rows.length == 0
        $("#browse_status").text "No results"
    else if not what.search?
        $("#browse_status").text "Rows #{resp.offset + 1}-#{resp.offset + resp.rows.length}"
    else
        # Can't figure out row counts when asking for subset.
        $("#browse_status").text ""

    for row in resp.rows
        $("#browse_list").append browse_types[browse_type].display row

    $("#browse_list > div.row").click btn_cb ->
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
