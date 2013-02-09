describe "the flight editor", ->
    pcfg_docs = ->
        pcfg1 = $.extend true, {}, test_docs.pcfg1
        pcfg2 = $.extend true, {}, test_docs.pcfg2

        pcfg1._id = "id_of_pcfg1"
        pcfg2._id = "id_of_pcfg2"
        pcfg1.time_created = "2012-08-02T00:04:17+01:00"
        pcfg2.time_created = "2012-08-02T00:09:17+01:00"

        return [pcfg1, pcfg2]

    add_pcfg = (which) ->
        expect($("#flight")).toBeVisible()
        $("#flight_pcfgs_add").click()
        expect($("#browse")).toBeVisible()
        expect(couchdbspy.view).toHaveBeenCalled()
        o = couchdbspy.view.mostRecentCall.args[1]

        row = (doc) ->
            id: doc._id
            key: ["blah", 1234]
            doc: doc

        o.success
            total_rows: 1
            offset: 0
            rows: row d for d in pcfg_docs()

        rows = $("#browse_list > div.row:nth-child(#{which})").click()
        expect($("#flight")).toBeVisible()

    make_flight1 = ->
        $("#go_flight_new").click()
        expect($("#flight")).toBeVisible()

        $("#flight_name").val("Tarantula launch 1")
        $("#flight_project").val("Project Arachnid")
        $("#flight_group").val("Team Spider")
        # $("#launch_timezone").val("Europe/London")
        $("#launch_date").datepicker("setDate", new Date(2012, 8 - 1, 2))
        $("#launch_date").datepicker("option", "onSelect")()
        $("#launch_time").val("10:30")
        # $("#launch_window").val("day") - default
        $("#launch_location_name").val("A field")
        $("#launch_latitude").val("51.44943")
        $("#launch_longitude").val("-0.95468")
        add_pcfg 1
        add_pcfg 2

    open_flight1 = ->
        $("#go_flight_modify").click()

        doc = $.extend true, {}, test_docs.flight1
        doc._id = "something fake"
        row = {id: doc._id, key: "blah", doc: doc}
        o = couchdbspy.view.mostRecentCall.args[1]
        o.success {total_rows: 1, offset: 0, rows: [row]}

        $("#browse_list > div.row").click()

        # doc loading tested in the browse suite
        row_maker = (doc) -> {id: doc._id, key: doc._id, doc: doc}
        rows = (row_maker d for d in pcfg_docs())
        o = couchdbspy.allDocs.mostRecentCall.args[0]
        o.success {total_rows: 2, offset: 0, rows: rows}

        expect($("#flight")).toBeVisible()
        expect($("#flight_name").val()).toBe("Tarantula launch 1")

    check_flight1_pcfgs_list = ->
        prows = $("#flight_pcfgs_list > div.row")

        t = prows.first().text()
        for x in ["3 transmissions", "1 sentence", "Test payload 1",
                  "id_of_pcfg1", "created 2012-08-02T00:04:17+01:00"]
            expect(t).toContain(x)

        t = prows.last().text()
        for x in ["4 transmissions", "4 sentences", "Test doc 2",
                  "id_of_pcfg2", "created 2012-08-02T00:09:17+01:00"]
            expect(t).toContain(x)

    # These first two tests check that the timezone support works and that
    # check all features of the form work; see test_docs.yml
    it "should be able to create flight 1", ->
        make_flight1()
        check_flight1_pcfgs_list()

        $("#flight_save").click()
        saved = couchdbspy.saveDoc.calls[0].args[0]
        expect(saved).toEqual(test_docs.flight1)

    it "should be able to create flight 2 by editing flight 1", ->
        open_flight1()

        # now make changes for flight1 -> flight2
        $("#flight_name").val("Tarantula launch 2")
        $("#launch_timezone").val("Australia/Adelaide")
        $("#launch_time").val("12:30")
        $("#launch_date").datepicker("setDate", new Date(2012, 4 - 1, 10))
        $("#launch_window").val("three")
        $("#launch_latitude").val("-34.77409")
        $("#launch_longitude").val("138.51697")
        $("#launch_altitude").val("100")
        $("#aprs_payload_callsigns").val("LZ1AAA, LZ1BBB,     SPACE1")
        $("#aprs_chaser_callsigns").val("LZ1CCC")

        check_flight1_pcfgs_list() # not tested by the browse suite
        $("#flight_pcfgs_list > div.row:first-child button").click() # remove pcfg1

        $("#flight_save").click()
        saved = couchdbspy.saveDoc.calls[0].args[0]
        saved.approved = true # flight2 in test_docs is approved
        expect(saved).toEqual(test_docs.flight2)

    it "should correctly load all flight details", ->
        # stronger test than the above since it checks every single value is
        # loaded properly
        open_flight1()
        $("#flight_save").click()
        saved = couchdbspy.saveDoc.calls[0].args[0]
        expect(saved).toEqual(test_docs.flight1)

    it "should not create empty string properties in the metadata dict", ->
        make_flight1()
        $("#launch_location_name").val("")
        $("#flight_project").val("")
        $("#flight_group").val("")
        $("#flight_save").click()
        saved = couchdbspy.saveDoc.calls[0].args[0]

        want_doc = $.extend {}, test_docs.flight1
        want_doc.metadata = {}

        expect(saved).toEqual(want_doc)

    it "should not create empty lists in the aprs dict", ->
        make_flight1()
        $("#aprs_payload_callsigns").val("")
        $("#aprs_chaser_callsigns").val("TEST1, TEST2, TEST3")
        $("#flight_save").click()
        saved = couchdbspy.saveDoc.calls[0].args[0]

        want_doc = $.extend {}, test_docs.flight1
        want_doc.aprs = chasers: ["TEST1", "TEST2", "TEST3"]

        expect(saved).toEqual(want_doc)

    it "should not create an empty aprs dict", ->
        make_flight1()

        $("#aprs_payload_callsigns").val("")
        $("#aprs_chaser_callsigns").val("")
        $("#flight_save").click()
        saved = couchdbspy.saveDoc.calls[0].args[0]

        want_doc = $.extend {}, test_docs.flight1
        delete want_doc.aprs

        expect(saved).toEqual(want_doc)

    test_validation = (key, elem, badvalues...) ->
        make_flight1()

        alert.andReturn(null)
        couchdbspy.saveDoc.andThrow("shouldn't have saved")

        for b in badvalues
            $(elem).val(b)
            $("#flight_save").click()
            expect(window.alert).toHaveBeenCalled()
            expect($("#flight")).toBeVisible()
            alert.reset()

    it "should validate name", ->
        test_validation "name", "#flight_name", ""

    it "should validate time", ->
        test_validation "time", "#launch_time", "", "asdf", "40:10", "03:99"

    it "should validate timezone", ->
        test_validation "timezone", "#launch_timezone", "", "Europe/", "asdf", "blah/bleh", "null"

    it "should validate latitude", ->
        test_validation "latitude", "#launch_latitude", "", "asdf", "100.0", "-400"

    it "should validate longitude", ->
        test_validation "longitude", "#launch_longitude", "", "dfgh", "200.0", "-190.5"

    it "should validate altitude", ->
        test_validation "altitude", "#launch_altitude", "asdf"

    invalid_APRS = [" ", "aaa", ",", "LZ1AA,", " LZ1AA", "LZ1AA,LL"]

    it "should validate APRS payloads", ->
        test_validation "payloads", "#aprs_payload_callsigns", invalid_APRS...

    it "should validate APRS chasers", ->
        test_validation "chasers", "#aprs_chaser_callsigns", invalid_APRS...

    it "shouldn't let you add the same payload twice", ->
        make_flight1()
        for i in [1..10]
            add_pcfg 1
        $("#flight_save").click()
        saved = couchdbspy.saveDoc.calls[0].args[0]
        expect(saved).toEqual(test_docs.flight1)

    it "should add the weekend launch window option when appropriate", ->
        $("#go_flight_new").click()

        get_options = ->
            ($(v).val() for v in $("#launch_window").children()).join ' '
        set_date = (yyyy, mm, dd) ->
            $("#launch_date").datepicker("setDate", new Date(yyyy, mm - 1, dd))
            $("#launch_date").datepicker("option", "onSelect")()

        for dd in [14, 23, 19]
            set_date(2012, 3, dd)
            expect(get_options()).toBe("day three other")

        for dd in [10, 11, 17, 18]
            set_date(2012, 3, dd)
            expect(get_options()).toBe("day three weekend other")

    it "should allow custom launch windows", ->
        make_flight1()
        $("#launch_window").val("other")
        $("#launch_window_start").datepicker("setDate", new Date(2012, 7 - 1, 28))
        $("#launch_window_end").datepicker("setDate", new Date(2012, 8 - 1, 3))

        $("#flight_save").click()
        saved = couchdbspy.saveDoc.calls[0].args[0]

        want_doc = $.extend {}, test_docs.flight1
        want_doc.start = "2012-07-28T00:00:00+01:00"
        want_doc.end = "2012-08-03T23:59:59+01:00"

        expect(saved).toEqual(want_doc)

    it "should forbid launch windows greater than one week", ->
        make_flight1()
        $("#launch_window").val("other")
        $("#launch_window_start").datepicker("setDate", new Date(2012, 7 - 1, 20))
        $("#launch_window_end").datepicker("setDate", new Date(2012, 8 - 1, 3))

        window.alert.andReturn(null)
        $("#flight_save").click()
        expect(window.alert).toHaveBeenCalled()
        expect($("#flight")).toBeVisible()

    it "should handle the launch window straddling a DST change", ->
        # ends 2012 October 28
        make_flight1()
        $("#launch_date").datepicker("setDate", new Date(2012, 10 - 1, 28))
        $("#launch_date").datepicker("option", "onSelect")()
        $("#launch_window").val("three")

        $("#flight_save").click()
        saved = couchdbspy.saveDoc.calls[0].args[0]

        want_doc = $.extend {}, test_docs.flight1
        want_doc.start = "2012-10-27T00:00:00+01:00"
        want_doc.launch.time = "2012-10-28T10:30:00+00:00"
        want_doc.end = "2012-10-29T23:59:59+00:00"

        expect(saved).toEqual(want_doc)
