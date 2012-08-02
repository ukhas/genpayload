make_view_row = (doc, key=null) ->
    doc = $.extend true, {}, doc
    doc._id = "fake id"
    doc.time_created = "2012-08-02T00:04:17+01:00"
    row =
        id: doc._id
        key: key or "blah"
        doc: doc
    return row

get_view_name = ->
    expect(couchdbspy.view).toHaveBeenCalled()
    return couchdbspy.view.mostRecentCall.args[0]

respond_to_view = (rows, offset=0, after=0) ->
    expect(couchdbspy.view).toHaveBeenCalled()
    o = couchdbspy.view.mostRecentCall.args[1]
    rows = for r in rows
        if r.key? then r
        else make_view_row r
    o.success
        total_rows: rows + offset + after
        offset: offset
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

describe "the document browser", ->
    it "should find payload_configuration docs", ->
        $("#go_pcfg_modify").click()
        expect(get_view_name()).toContain("payload_configuration")
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
        expect(get_view_name()).toContain("sentence")
        rows = []
        for d in [test_docs.pcfg1, test_docs.pcfg2]
            for s, i in d.sentences
                # key is [callsn time idx]
                rows.push make_view_row d, [s.callsign, 123, i]
        respond_to_view rows

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
        throw "not yet written"

    it "should paginate correctly", ->
        throw "not yet written"
