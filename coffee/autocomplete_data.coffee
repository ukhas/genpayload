# Copyright (c) 2012 Daniel Richman; GNU GPL 3

suggest_field_data_ok = [
    "altitude",
    "battery",
    "ascentrate",
    "heading",
    "sentence_id",
    "fix_age",
    "gps_lock",
    "latitude",
    "longitude",
    "time",
    "temperature_internal",
    "temperature_external",
    "temperature",
    "satellites",
    "speed",
]

suggest_field_data_ok.sort()

suggest_field_data_correct = {
    "ascent_rate": "ascentrate",
    "bearing": "heading",
    "direction": "heading",
    "current_battery": "battery",
    "custom_data": "custom",
    "extra_data": "custom",
    "GPS_status": "gps_lock",
    "lockstatus": "gps_lock",
    "fixage": "fix_age",
    "internal_pressure": "pressure_internal",
    "internal_temp": "temperature_internal",
    "internal_temperature": "temperature_internal",
    "temp_int": "temperature_internal",
    "temp_ext": "temperature_external",
    "int_temp": "temperature_internal",
    "ext_temp": "temperature_external",
    "battery_volts": "battery",
    "battery_voltage": "battery",
    "sequence_id": "sentence_id",
    "sats": "satellites",
    "voltage": "battery",
}

suggest_field_names = (what) ->
    if what is ""
        return suggest_field_data_ok

    results = []

    # Try a few correction strategies
    c_a = what.replace /\ /g, '_'
    c_a = c_a.replace /^_+/, ''
    c_b = c_a.toLowerCase()
    c_c = suggest_field_data_correct[c_b] or c_b

    if c_c != c_b and c_c.length then results.push c_c
    if c_b != c_a and c_b.length then results.push c_b
    if c_a != what and c_a.length then results.push c_a

    # Otherwise just suggest
    results.push f for f in suggest_field_data_ok when f != c_c and (f.indexOf c_c) != -1

    return results

# Copied from cusf-standalone-predictor/predict/sites.json
suggest_launch_data = [
    label:      "Churchill College, Cambridge, England"
    latitude:   52.2135
    longitude:  0.0964
,
    label:      "EARS, Cambridge, England"
    latitude:   52.2511
    longitude:  -0.0927
,
    label:      "Adelaide Airport, Adelaide, Australia"
    latitude:   -34.9499
    longitude:  138.5194
,
    label:      "Brightwalton, Berkshire, England"
    latitude:   51.51143
    longitude:  -1.38870
,
    label:      "Boston Spa, Leeds, England"
    latitude:   53.8997
    longitude:  -1.3629
,
    label:      "Wistow, Adelaide, Australia"
    latitude:   -35.1217
    longitude:  138.8503
,
    label:      "Cookstown, County Tyrone, Northern Ireland"
    latitude:   54.632162,
    longitude:  -6.757982
,
    label:      "Preston St Mary, Suffolk, England"
    latitude:   52.1215
    longitude:  0.8078
]

# timezone_list is from js/zone_list.js
timezone_area_list = []
do ->
    areas = {}
    for zone in timezone_list
        area = zone[...zone.indexOf('/')]
        if areas[area]
            continue

        areas[area] = true
        timezone_area_list.push area

    timezone_area_list.sort()

suggest_timezone = (what) ->
    # match Anything/Something Europe/ and Europe :
    if (what.indexOf "/") == -1 or what in timezone_area_list
        suggest_from = timezone_area_list
        item = (f) -> {label: f, value: f + '/'}
    else
        suggest_from = timezone_list
        item = (f) -> f

    results = []
    for f in suggest_from
        if f != what and (f.indexOf what) != -1
            results.push item f

    return results
