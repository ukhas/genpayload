# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# Current editing state
pcfg_doc = null
pcfg_callback_func = null

# Main start point for pcfg editing. #payload_configuration should be visible.
# Loads data from doc into the forms and enables editing. callback(doc) is called when the doc
# has been successfully saved to the database or callback(false) is called if the user cancels.
pcfg_edit = (doc, callback) ->
    pcfg_callback_func = callback
    pcfg_doc = doc

    # fire the change events to update the validation
    $("#pcfg_name").val(doc.name).change()
    $("#pcfg_version").val(doc.version).change()
    $("#pcfg_description").val(doc.description or "").change()

    $("#transmissions_list").empty()
    $("#sentences_list").empty()

    for t in doc.transmissions
        $("#transmissions_list").append transmissions_list_item t
    for s in doc.sentences
        $("#sentences_list").append sentences_list_item s

# Save the doc, and then callback to close #payload_configuration
pcfg_save = ->
    pcfg_doc.name = $("#pcfg_name").val()
    pcfg_doc.version = strict_numeric $("#pcfg_version").val()
    pcfg_doc.description = $("#pcfg_description").val()

    if pcfg_doc.description == ""
        delete pcfg_doc.description

    if pcfg_doc.name == "" or isNaN(pcfg_doc.version) or pcfg_doc.version <= 0
        alert "There are errors in the form: the server would reject this"
    else
        # TODO pcfg save
        alert "Not yet implemented: pcfg_save (console.log'd doc)"
        try
            console.log pcfg_doc
            console.log JSON.stringify(pcfg_doc)
        catch error
            # ignore
        pcfg_callback_func "TODO_document_id"

# Create a <tr> that describes the transmission dict, t, and give it Edit/Delete links.
transmissions_list_item = (t) ->
    description = "#{t.frequency / 1e6}MHz #{t.mode} #{t.modulation}"

    switch t.modulation
        when "RTTY"
            parity = switch t.parity
                when "none" then "no parity"
                when "odd", "even" then "#{t.parity} parity"

            description += " #{t.baud} baud #{t.shift}Hz shift #{t.encoding} #{parity} #{t.stop} stop bits"
        when "DOMINOEX"
            description += " #{t.speed}"

    row = $("<tr />")
    row.append $("<td />").text description
    row.append $("<td />").append $("<a href='#'>Edit</a>").button().click ->
        transmission_maybe_edit row.index()
    row.append $("<td />").append $("<a href='#'>Delete</a>").button().click ->
        transmission_delete row.index()

    return row

# Create a <span> describing the field. filtered_fields should be an object containing
# {key: [list of filters names]} so that the field may be annotated.
field_description = (f, filtered_fields) ->
    e = $("<span />")
    e.text f.name

    config = copy f.config
    delete config.name
    delete config.sensor

    title = "sensor: #{f.sensor}"
    unless $.isEmptyObject config
        title += "#{JSON.stringify(config)}"
    if filtered_fields[f.name]
        title += ", filters: " + filtered_fields[f.name].join(" ")

    e.attr "title", title
    return e

# Create a <span> of FF or FFFF, title text describing the checksum
checksum_description = (n) ->
    e = $("<span />")
    e.text switch n
        when "xor" then "FF"
        when "crc16-ccitt", "fletcher_16" then "FFFF"
    e.attr "title", "checksum type: #{n}"
    return e

# Create a <tr> describing the sentence dict, s, and give it Edit / Delete links
sentences_list_item = (s) ->
    row = $("<tr />")
    e = $("<td />")
    e.text "UKHAS "

    filtered_fields = {}
    if s.filters and s.filters.post
        for f in s.filters.post
            if f.source
                if filtered_fields[f.source]
                    filtered_fields[f.source].push(f.filter or "hotfix")
                else
                    filtered_fields[f.source] = [f.filter or "hotfix"]

    t = $("<span />")
    t.addClass "telemetry_string"
    t.text "$$#{s.callsign}"
    t.append ",", field_description f, filtered_fields for f in s.fields
    t.append "*", checksum_description s.checksum

    e.append t
    if s.filters
        n = 0
        if s.filters.intermediate then n += s.filters.intermediate.length
        if s.filters.post then n += s.filters.post.length

        if n
            n_s = if n != 1 then "s" else ""
            e.append " (#{n} filter#{n_s})"

    row.append e

    row.append $("<td />").append $("<a href='#'>Edit</a>").button().click ->
        sentence_maybe_edit row.index()
    row.append $("<td />").append $("<a href='#'>Delete</a>").button().click ->
        sentence_delete row.index()

    return row

default_transmission =
    frequency: 0
    mode: "USB"
    modulation: "RTTY"
    shift: 350
    encoding: "ASCII-8"
    baud: 50
    parity: "none"
    stop: 2

# Create a new default transmission dict, push it onto the end of transmissions, and start
# the transmission editor.
transmission_new = ->
    toplevel "#transmission_edit"
    transmission_edit (deepcopy default_transmission), (t) ->
        toplevel "#payload_configuration"
        if t
            pcfg_doc.transmissions.push t
            $("#transmissions_list").append transmissions_list_item t

# Start the transmission editor, and rollback the result if its callback reports cancellation.
transmission_maybe_edit = (index) ->
    toplevel "#transmission_edit"
    t = deepcopy pcfg_doc.transmissions[index]
    transmission_edit t, (et) ->
        toplevel "#payload_configuration"
        if et
            pcfg_doc.transmissions[index] = et
            tr = $("#transmissions_list").children()[index]
            $(tr).replaceWith transmissions_list_item et

# Remove a transmission
transmission_delete = (index) ->
    pcfg_doc.transmissions.pop index
    tr = $("#transmissions_list").children()[index]
    $(tr).remove()

# Create a new sentence using either some defaults or the provided doc
# Push it onto the end of sentences and then start the editor specified by 'method'
sentence_manual = (show, method, s=null) ->
    if not s
        s =
            protocol: "UKHAS"
            callsign: ""
            fields: []

    toplevel show
    method (deepcopy s), (es) ->
        toplevel "#payload_configuration"
        if es
            pcfg_doc.sentences.push es
            $("#sentences_list").append sentences_list_item es

# Start the browser, looking for sentences. If one is selected, pass it to
# sentence_manual which will push it onto sentences it and start the editor.
sentence_import = ->
    toplevel "#browse"
    browse "sentence", (s) ->
        if s
            sentence_manual "#sentence_edit", sentence_edit, s
        else
            toplevel "#payload_configuration"

# Start the sentence editor, and rollback the result if its callback reports cancellation.
sentence_maybe_edit = (index) ->
    toplevel "#sentence_edit"
    s = deepcopy pcfg_doc.sentences[index]
    sentence_edit s, (es) ->
        toplevel "#payload_configuration"
        if es
            pcfg_doc.sentences[index] = es
            tr = $("#sentences_list").children()[index]
            $(tr).replaceWith sentences_list_item es

# Delete a sentence
sentence_delete = (index) ->
    pcfg_doc.sentences.pop index
    tr = $("#sentences_list").children()[index]
    $(tr).remove()

# Add callbacks for the #pcfg_misc form
setup_pcfg_form = ->
    form_field "#pcfg_name",
        nonempty: true
    form_field "#pcfg_version",
        numeric: true
        positive: true
    # #pcfg_description is optional.

# Use jQuery UI's sortable, with callbacks to update the doc as items are reordered
setup_sortable_lists = ->
    transmissions_pickup = null
    sentences_pickup = null

    $("#transmissions_list").sortable
        start: (event, ui) ->
            transmissions_pickup = ui.item.index()
        stop: (event, ui) ->
            array_reorder pcfg_doc.transmissions, transmissions_pickup, ui.item.index()

    $("#sentences_list").sortable
        start: (event, ui) ->
            sentences_pickup = ui.item.index()
        stop: (event, ui) ->
            array_reorder pcfg_doc.sentences, sentences_pickup, ui.item.index()

    $("#transmissions_list, #sentences_list").disableSelection()

$ ->
    setup_pcfg_form()
    setup_sortable_lists()

    $("#transmission_new").click transmission_new

    $("#go_wizard").click -> sentence_manual "#sentence_wizard", sentence_wizard
    $("#go_manual").click -> sentence_manual "#sentence_edit", sentence_edit
    $("#go_import").click sentence_import

    $("#pcfg_save").click pcfg_save
    $("#pcfg_abandon").click -> pcfg_callback_func false
