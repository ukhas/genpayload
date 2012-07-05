# TODO: Replace this with some couch querying?

suggest_data_ok = [
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
    "satellites"
]

suggest_data_ok.sort()

suggest_data_correct = {
    "ascent_rate": "ascentrate",
    "bearing": "heading",
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
        return suggest_data_ok

    results = []

    # Try a few correction strategies
    c_a = what.replace /\ /g, '_'
    c_a = c_a.replace /^_+/, ''
    c_b = c_a.toLowerCase()
    c_c = suggest_data_correct[c_b] or c_b

    if c_c != c_b and c_c.length then results.push c_c
    if c_b != c_a and c_b.length then results.push c_b
    if c_a != what and c_a.length then results.push c_a

    # Otherwise just suggest
    results.push f for f in suggest_data_ok when f != c_c and (f.indexOf c_c) != -1

    return results
