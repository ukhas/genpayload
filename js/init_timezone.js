(function () {
    var _tz = timezoneJS.timezone;
    _tz.loadingScheme = _tz.loadingSchemes.MANUAL_LOAD;
    _tz.loadZoneDataFromObject(timezone_js_data);
    _tz.transport = null;
})();
