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
    "ext_temp": "temperature_internal",
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
# TODO: lots of guesswork went into some of these names. Check it
suggest_launch_data = [
    label:      "Churchill College, Cambridge, England"
    latitude:   52.2135
    longitude:  0.0964
    altitude:   0
,
    label:      "EARS, Cambridge, England"
    latitude:   52.2511
    longitude:  -0.0927
    altitude:   0
,
    label:      "Adelaide Airport, Adelaide, Australia"
    latitude:   -34.9499
    longitude:  138.5194
    altitude:   0
,
    label:      "Brightwalton, Berkshire, England"
    latitude:   51.51143
    longitude:  -1.38870
    altitude:   0
,
    label:      "Boston Spa, Leeds, England"
    latitude:   53.8997
    longitude:  -1.3629
    altitude:   0
,
    label:      "Wistow, Adelaide, Australia"
    latitude:   -35.1217
    longitude:  138.8503
    altitude:   0
,
    label:      "An Creagan, County Tyrone, Northern Ireland"
    latitude:   54.654118
    longitude:  -7.034914
    altitude:   0
,
    label:      "Preston St Mary, Suffolk, England"
    latitude:   52.1215
    longitude:  0.8078
    altitude:   70
]
