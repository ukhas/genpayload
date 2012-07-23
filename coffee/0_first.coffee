###
Copyright (c) 2012 Daniel Richman; GNU GPL 3
###

$ ->
    # Adds a click event handler that kills the event if the button is disabled, so must go first.
    $("#help_once").button()
    $(".buttons").buttonset()
    return
