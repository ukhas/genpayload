make_view_doc_row = (doc, key=null, id="fake id") ->
    doc = $.extend true, {}, doc
    if not doc._id
        doc._id = id
    if doc.type == "payload_configuration" and not doc.time_created?
        doc.time_created = "2012-08-02T00:04:17+01:00"
    row =
        id: doc._id
        key: key
        doc: doc
    return row

get_view_name = ->
    expect(couchdbspy.view).toHaveBeenCalled()
    return couchdbspy.view.mostRecentCall.args[0]

respond_to_view = (rows, include_docs=true) ->
    expect(couchdbspy.view).toHaveBeenCalled()
    o = couchdbspy.view.mostRecentCall.args[1]
    expect(o.include_docs).toBe(include_docs)
    rows = for r in rows
        if r.key? then r
        else make_view_doc_row r
    o.success
        total_rows: rows.length
        offset: 0
        rows: rows

check_loaded_pcfg = (doc) ->
    expect($("#payload_configuration")).toBeVisible()

    expect($("#pcfg_name").val()).toBe(doc.name)
    desc =  if doc.metadata? and doc.metadata.description?
                doc.metadata.description
            else
                ""
    expect($("#pcfg_description").val()).toBe(desc)

    expect($("#transmissions_list > .row").length)
        .toBe(doc.transmissions.length)

    for t, i in doc.transmissions
        row = $("#transmissions_list > .row:nth-child(#{i + 1})")
        expect(row.data("transmission")).toEqual(t)

    expect($("#sentences_list > .row").length)
        .toBe(doc.sentences.length)

    for s, i in doc.sentences
        row = $("#sentences_list > .row:nth-child(#{i + 1})")
        expect(row.data("sentence")).toEqual(s)

fake_view = []
for i in [1..451]
    doc =
        _id: 20000 + i
        type: "flight"
        name: "Test doc #{i}"
        launch:
            time: "2012-01-02T12:30:00+09:30"
    fake_view.push make_view_doc_row doc, Math.floor(i / 7)
    # use integer keys and ids for testing. Easier than
    # sorting strings.

fake_view_descending = fake_view[..]
fake_view_descending.reverse()

fake_view_ajax = (name, options) ->
    expect(name).toContain("flight")
    expect(options.include_docs).toBe(true)

    options.descending ?= false
    if options.descending
        rows = fake_view_descending
        small_key = 1e6
        big_key = -1
        comp_lt = (a, b) -> (a > b)
    else
        rows = fake_view
        small_key = -1
        big_key = 1e6
        comp_lt = (a, b) -> (a < b)

    comp_lte = (a, b) -> (a == b or comp_lt a, b)

    # smaller and larger than any key or id as appropriate
    options.startkey ?= small_key
    options.startkey_docid ?= small_key
    options.endkey ?= big_key
    options.endkey_docid ?= big_key
    options.skip ?= 0
    options.limit ?= 1e6

    # this is quite inefficient in the name of simplicity

    start_index = 0

    limit = -> (start_index < rows.length)
    r = -> rows[start_index]

    while (limit() and
           comp_lt r().key, options.startkey)
        start_index++

    while (limit() and
           r().key == options.startkey and
           comp_lt r().id, options.startkey_docid)
        start_index++

    start_index += options.skip
    end_index = start_index

    limit = -> (end_index < rows.length and
                end_index - start_index < options.limit)
    r = -> rows[end_index]

    while (limit() and
           comp_lt r().key, options.endkey)
        end_index++

    while (limit() and
           r().key == options.endkey and
           comp_lte r().id, options.endkey_docid)
        end_index++

    if start_index >= rows.length
        start_index = end_index = rows.length

    options.success
        total_rows: rows.length
        offset: start_index
        rows: rows[start_index...end_index]

    return

describe "the fake couchdb view", ->
    it "should work", ->
        called = false
        fake_view_ajax "...flight..",
            include_docs: true
            success: (resp) ->
                expect(called).toBe(false)
                called = true
                expect(resp.total_rows).toBe(fake_view.length)
                expect(resp.offset).toBe(0)
                expect(resp.rows).toEqual(fake_view)

    it "should support startkey", ->
        called = false
        fake_view_ajax "flight",
            include_docs: true
            startkey: 24
            success: (resp) ->
                called = true
                expect(resp.rows).toEqual(fake_view[167..])
        expect(called).toBe(true)

    it "should support startkey_docid", ->
        called = false
        fake_view_ajax "flight",
            include_docs: true
            startkey: 24
            startkey_docid: 20171
            success: (resp) ->
                called = true
                expect(resp.rows).toEqual(fake_view[170..])
        expect(called).toBe(true)

    it "should support endkey", ->
        called = false
        fake_view_ajax "flight",
            include_docs: true
            endkey: 24
            success: (resp) ->
                called = true
                expect(resp.rows).toEqual(fake_view[..173])
        expect(called).toBe(true)

    it "should support endkey_docid", ->
        called = false
        fake_view_ajax "flight",
            include_docs: true
            endkey: 24
            endkey_docid: 20171
            success: (resp) ->
                called = true
                expect(resp.rows).toEqual(fake_view[..170])
        expect(called).toBe(true)

    it "should support limit", ->
        called = false
        fake_view_ajax "flight",
            include_docs: true
            limit: 20
            success: (resp) ->
                called = true
                expect(resp.rows).toEqual(fake_view[..19])
                expect(resp.rows.length).toBe(20)
        expect(called).toBe(true)

    it "should support startkeys that are larger than any in the db", ->
        called = false
        fake_view_ajax "flight",
            include_docs: true
            startkey: 1e6
            success: (resp) ->
                called = true
                expect(resp.rows).toEqual([])
                expect(resp.offset).toEqual(fake_view.length)
                expect(resp.total_rows).toEqual(fake_view.length)
        expect(called).toBe(true)

    it "should support descending", ->
        reverse = fake_view[...]
        reverse.reverse()

        called = false
        fake_view_ajax "flight",
            include_docs: true
            descending: true
            success: (resp) ->
                called = true
                expect(resp.rows).toEqual(reverse)
        expect(called).toBe(true)

    it "should support skip", ->
        called = false
        fake_view_ajax "flight",
            include_docs: true
            skip: 235
            success: (resp) ->
                called = true
                expect(resp.rows).toEqual(fake_view[235..])
        expect(called).toBe(true)

    it "should support skipping more rows than exist", ->
        called = false
        fake_view_ajax "flight",
            include_docs: true
            skip: 2000
            success: (resp) ->
                called = true
                expect(resp.rows).toEqual([])
        expect(called).toBe(true)

    it "should support all the options at once", ->
        called = false
        fake_view_ajax "flight",
            include_docs: true
            startkey: 24
            startkey_docid: 20171
            skip: 135
            limit: 12
            success: (resp) ->
                called = true
                expect(resp.rows).toEqual(fake_view[305..316])
        expect(called).toBe(true)

        reverse = fake_view[170..203 - 20]
        reverse.reverse()

        called = false
        fake_view_ajax "flight",
            include_docs: true
            endkey: 24
            endkey_docid: 20171
            startkey: 29
            startkey_docid: 20204
            descending: true
            skip: 20
            success: (resp) ->
                called = true
                expect(resp.rows).toEqual(reverse)
        expect(called).toBe(true)

describe "the document browser", ->
    it "should find payload_configuration docs", ->
        $("#go_pcfg_modify").click()
        expect(get_view_name()).toBe("payload_configuration/name_time_created")
        respond_to_view [test_docs.pcfg1, test_docs.pcfg2]
        expect($("#browse_list > .row").length).toBe(2)

        r = $("#browse_list > .row:nth-child(2)")
        for x in ["Test doc 2", "description of a doc", "T32_0",
                  "T32_1", "T32_2"]
            expect(r.text()).toContain(x)
        expect(r.find(".long_protection").attr("title"))
            .toBe("A long ish description of a doc")

        r.click()
        check_loaded_pcfg test_docs.pcfg2

    it "should find sentence dicts", ->
        $("#go_pcfg_new").click()
        $("#go_import").click()
        expect(get_view_name()).toBe("payload_configuration/callsign_time_created")
        rows = []
        for d in [test_docs.pcfg1, test_docs.pcfg2]
            m =
                name: d.name
                metadata: d.metadata
                time_created: "2012-08-02T00:04:17+01:00"
            for s, i in d.sentences
                # key is [callsign time index]
                rows.push
                    id: d._id
                    key: [s.callsign, 123, i]
                    value: [m, s]
        respond_to_view rows, false

        r = $("#browse_list > .row:nth-child(2)")
        expect(r.text()).toContain("T32_0")
        expect(r.text()).toContain("I describe")
        r.click()

        expect($("#sentence_edit_save")).toBeVisible()
        $("#sentence_edit_save").click()

        s = test_docs.pcfg2.sentences[0]
        check_loaded_pcfg
            name: ""
            sentences: [s]
            transmissions: []

    it "should find flight docs", ->
        $("#go_flight_modify").click()
        expect(get_view_name()).toBe("flight/all_name")
        respond_to_view [test_docs.flight1, test_docs.flight2]
        expect($("#browse_list > .row").length).toBe(2)

        r = $("#browse_list > .row:nth-child(1)")
        for x in ["Project Arachnid", "Team Spider", "Tarantula launch 1"]
            expect(r.text()).toContain(x)

        expect($("#browse_list > .row:nth-child(2)").text())
            .toContain("Approved")

        r.click()

        expect($("#loading_docs")).toBeVisible()
        expect($("#flight")).toBeHidden()
        l = couchdbspy.allDocs.mostRecentCall.args[0]
        expect(l.keys).toEqual(["id_of_pcfg1", "id_of_pcfg2"])
        expect(l.include_docs).toBe(true)
        l.success
            rows: [make_view_doc_row(test_docs.pcfg1, "id_of_pcfg1", "id_of_pcfg1"),
                   make_view_doc_row(test_docs.pcfg2, "id_of_pcfg2", "id_of_pcfg2")]

        expect($("#flight")).toBeVisible()
        expect($("#flight_name").val()).toBe("Tarantula launch 1")
        # loading docs to modify is fully tested in the flight suite

    it "should paginate correctly (non-searches only)", ->
        # prevent modification of the dom because it's massively slow
        # replace jquery objects with fake objects

        class FakeBrowseList
            constructor: -> @rows = []
            append: (x) -> @rows.push x
            empty: -> @rows = []
            all_data: -> r.data "browse_return" for r in @rows
        class FakeAnyElement
            constructor: -> @_data = {}
            append: -> return this
            text: -> return this
            attr: -> return this
            data: (what) ->
                if arguments.length == 1
                    return @_data[what]
                else
                    @_data[what] = arguments[1]
                return this

        browse_list = new FakeBrowseList()

        fake_view_docs = (r.doc for r in fake_view)

        spyOn(window, '$').andCallFake ->
            if arguments.length == 1 and typeof arguments[0] == "string"
                if arguments[0] == "#browse_list"
                    return browse_list
                if arguments[0][0] == "<"
                    return new FakeAnyElement()

            return jQuery.apply(this, arguments)

        couchdbspy.view.andCallFake fake_view_ajax
        check_page = (page) ->
            start = (page - 1) * 100
            end = Math.min(start + 100, fake_view.length)
            if start < 0 or start > end
                throw "derp"

            status = "Rows #{start + 1}-#{end}"
            expect($("#browse_status").text()).toBe(status)

            rows = browse_list.all_data()

            expect(browse_list.all_data()).toEqual(fake_view_docs[start...end])

        $("#go_flight_modify").click()

        # walk forwards to the end and backwards to the start, checking that the
        # pages are correct.

        pages = Math.ceil(fake_view.length / 100)

        expect($("#browse_prev").prop("disabled")).toBe(true)
        check_page 1

        for page in [2..pages]
            expect($("#browse_next").prop("disabled")).toBe(false)
            $("#browse_next").click()
            check_page page

        expect($("#browse_next").prop("disabled")).toBe(true)

        for page in [pages - 1..1]
            expect($("#browse_prev").prop("disabled")).toBe(false)
            $("#browse_prev").click()
            check_page page

        $("#browse_next").click()
        $("#browse_next").click()
        check_page 3
        $("#browse_prev").click()
        check_page 2

    test_can_search = (type) ->
        respond_to_view [], (type != "sentence")
        couchdbspy.view.reset()

        $("#browse_search").val("mySeArcH")
        $("#browse_search_go").click()
        expect(couchdbspy.view).toHaveBeenCalled()
        o = couchdbspy.view.mostRecentCall.args[1]

        if type == "flight"
            expect(o.startkey).toBe("mysearch")
            expect(o.endkey).toBe("MYSEARCHZZZZZZZZZZZZZ")
        else
            expect(o.startkey).toEqual(["mysearch"])
            expect(o.endkey).toEqual(["MYSEARCHZZZZZZZZZZZZZ"])

    it "can search for payload_configuration docs", ->
        $("#go_pcfg_modify").click()
        test_can_search "payload_configuration"

    it "can search for flight docs", ->
        $("#go_flight_modify").click()
        test_can_search "flight"

    it "can search for sentence dicts", ->
        $("#go_pcfg_new").click()
        $("#go_import").click()
        test_can_search "sentence"
