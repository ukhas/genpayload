# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# Current state
browse_callback = null

# Main start point for browser. #browse should be visible. type is one of "flight",
# "payload_configuration" or "sentence" dependig on what we want to look for. callback(doc) is called
# if the user picks something, callback(false) otherwise.
browse = (type, callback) ->
    browse_callback = callback

    # TODO browse

    $("#browse_list").empty()

    if type is "payload_configuration"
        e = $("<a href='#' />").text("use local test doc").click -> callback deepcopy test_doc
        $("#browse_list").append e

$ ->
    $("#browse_cancel").click -> browse_callback false

# remove this.
test_doc =
    name: "test doc"
    version: 5
    description: "testing"
    transmissions: [
        "frequency": 434200000
        "mode": "USB"
        "modulation": "RTTY"
        "shift": 425
        "encoding": "ASCII-8"
        "baud": 50
        "parity": "none"
        "stop": 2
    ]
    sentences: [
        "protocol": "UKHAS"
        "checksum": "crc16-ccitt"
        "callsign": "EURUS"
        "fields": [
            "name": "sentence_id"
            "sensor": "base.ascii_int"
          ,
            "name": "time"
            "sensor": "stdtelem.time"
          ,
            "name": "latitude"
            "sensor": "stdtelem.coordinate"
            "format": "dd.dddd"
          ,
            "name": "longitude"
            "sensor": "stdtelem.coordinate"
            "format": "dd.dddd"
          ,
            "name": "altitude"
            "sensor": "base.ascii_int"
          ,
            "name": "satellites"
            "sensor": "base.ascii_int"
          ,
            "name": "gps_lock"
            "sensor": "base.ascii_int"
          ,
            "name": "nav_mode"
            "sensor": "base.ascii_int"
          ,
            "name": "battery"
            "sensor": "base.ascii_int"
          ,
            "name": "iss_elevation"
            "sensor": "base.ascii_int"
          ,
            "name": "iss_azimuth"
            "sensor": "base.ascii_int"
          ,
            "name": "aprs_status"
            "sensor": "base.ascii_int"
          ,
            "name": "aprs_attempts"
            "sensor": "base.ascii_int"
        ]
    ]
