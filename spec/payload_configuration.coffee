describe "the payload_configuration editor", ->
    it "should be able to create doc one", ->
        $("#go_pcfg_new").click()
        expect($("#payload_configuration")).toBeVisible()

        $("#pcfg_name").val("Test payload 1")
        $("#pcfg_description").val("Test doc one")

        for t in test_docs.pcfg1.transmissions
            row = $("<div></div>").data("transmission", t)
            $("#transmissions_list").append row
        for s in test_docs.pcfg1.sentences
            row = $("<div></div>").data("sentence", s)
            $("#sentences_list").append row

        $("#pcfg_save").click()

        saved = couchdbspy.saveDoc.calls[0].args[0]

        a = new timezoneJS.Date(saved.time_created)
        b = new Date()
        expect(a.getMilliseconds()).toBe(0)
        expect(a.getTime()).toBeCloseTo(b.getTime(), 2000)

        delete saved.time_created
        expect(saved).toEqual(test_docs.pcfg1)

    it "should allow editing of existing docs", ->
        $("#go_pcfg_modify").click()

        expect(couchdbspy.view).toHaveBeenCalled()
        o = couchdbspy.view.mostRecentCall.args[1]

        doc = $.extend true, {}, test_docs.pcfg1
        doc._id = "something fake"
        doc.time_created = "2012-08-02T00:04:17+01:00"
        row =
            id: doc._id
            key: ["blah", 1234]
            doc: doc

        o.success
            total_rows: 1
            offset: 0
            rows: [row]

        $("#browse_list > div.row").click()
        expect($("#payload_configuration")).toBeVisible()

        expect($("#pcfg_name").val()).toBe("Test payload 1")
        expect($("#pcfg_description").val()).toBe("Test doc one")

        for t, i in test_docs.pcfg1.transmissions
            row = $("#transmissions_list > .row:nth-child(#{i + 1})")
            expect(row.data("transmission")).toEqual(t)
        for s, i in test_docs.pcfg1.sentences
            row = $("#sentences_list > .row:nth-child(#{i + 1})")
            expect(row.data("sentence")).toEqual(s)

        # actual editing (of sentence, transmission) tested in the
        # relevant suite

        while $("#transmissions_list > .row").length > 1
            $("#transmissions_list > .row:last-child button:nth-child(2)").click()

        $("#pcfg_save").click()
        saved = couchdbspy.saveDoc.calls[0].args[0]
        delete saved.time_created
        delete doc.time_created
        delete doc._id
        doc.transmissions[1..] = []
        expect(saved).toEqual(doc)
