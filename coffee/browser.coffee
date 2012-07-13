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
        e = $("<a href='#' />").text("use local test doc").click -> browse_callback deepcopy test_doc
        $("#browse_list").append e

$ ->
    $("#browse_cancel").click -> browse_callback false

# remove this.
test_doc =
    type: "payload_configuration"
    name: "test doc"
    description: "testing"
    created: "2012-07-13T16:46:55.453+01:00"
    transmissions: [
        description: "Main radio settings"
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
        description: "EURUS long format"
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
    ,
        "protocol": "UKHAS",
        "checksum": "xor",
        "callsign": "A1",
        "fields": [
            "name": "sentence_id"
            "sensor": "base.ascii_int"
          ,
            "sensor": "stdtelem.time"
            "name": "time"
          ,
            "sensor": "stdtelem.coordinate"
            "format": "dd.dddd"
            "name": "latitude"
          ,
            "sensor": "stdtelem.coordinate"
            "format": "dd.dddd"
            "name": "longitude"
          ,
            "sensor": "base.ascii_int"
            "name": "altitude"
          ,
            "name": "fix_age"
            "sensor": "base.string"
          ,
            "name": "satellites"
            "sensor": "base.ascii_int"
          ,
            "name": "temperature"
            "sensor": "base.string"
          ,
            "name": "status"
            "sensor": "base.ascii_int"
        ]
    ]
