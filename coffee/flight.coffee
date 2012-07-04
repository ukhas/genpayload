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

    # TODO flight_edit
    alert "Not yet implemeted: flight edit"
    callback false

