# get the values that a KeyValueEditor is displaying to the user
kv_read = (elem) ->
    data = {}
    invalid_keys = []
    required_keys = []

    for row in $(elem).children("div.row")
        [key_elem, value_elem, valid_elem] = $(row).children()
        key = $(key_elem).val()
        if key == ""
            continue

        value = $(value_elem).val()
        valid = ($(valid_elem).attr("alt") == "OK")
        required = $(key_elem).attr("disabled")

        try
            value = JSON.parse value
        catch e
            # keep value as a string

        data[key] = value
        if not valid then invalid_keys.push(key)
        if required then required_keys.push(key)

    return [data, invalid_keys, required_keys]

# update a KeyValueEditor
kv_write = (elem, data) ->
    have_set = {}
    remove_later = []

    data = $.extend {}, data # copy

    for key, value of data
        if typeof value != "string"
            data[key] = JSON.stringify(value)

    for row in $(elem).children("div.row")
        [key_elem, value_elem, valid_elem] = $(row).children()
        key = $(key_elem).val()
        if key != "" and data[key]?
            $(value_elem).val(data[key]).change()
            have_set[key] = true
        else if key != ""
            remove_later.push key_elem

    for key_elem in remove_later
        if $(key_elem).attr("disabled")
            throw "can't remove required key"
        $(key_elem).val("")
        $(key_elem).change()

    for key, value of data
        if have_set[key]?
            continue

        empty_row = $(elem).children("div.row").last()
        [key_elem, value_elem, valid_elem] = $(empty_row).children()

        # these are sanity checks or asserts, not tests
        if $(key_elem).val() != ""
            throw "last row was not empty"

        $(key_elem).val(key).change()
        $(value_elem).val(value).change()

describe "the keyvalue test helpers", ->
    kv_elem = null
    kv_data_func = null

    beforeEach ->
        # from one of the payload_configuration tests
        $("#go_pcfg_modify").click()
        doc = $.extend true, {}, test_docs.pcfg1
        doc._id = "something fake"
        doc.time_created = "2012-08-02T00:04:17+01:00"
        doc.sentences[0].filters.post.push
            type: "normal"
            filter: "path.to.filter"
            thing_one: 5
            text_blah: "moo"
            object: {key: "value", bob: "whatever"}
        row = {id: doc._id, key: ["blah", 1234], doc: doc}
        o = couchdbspy.view.mostRecentCall.args[1]
        o.success {total_rows: 1, offset: 0, rows: [row]}

        $("#browse_list > .row").first().click()
        $("#sentences_list > .row button").first().click()
        filter_row = $("#sentence_post_filters > .row").last()

        kv_elem = filter_row.children(".keyvalue").first()
        kv_data_func = ->
            data = filter_row.data("filter_data")()
            delete data.type # sentence_manual adds this
            return data

        expect(kv_elem).toBeVisible()

    it "should read data", ->
        [data, invalid_keys, required_keys] = kv_read kv_elem
        expect(data).toEqual
            # sentence_maual drops the type key
            filter: "path.to.filter"
            thing_one: 5
            text_blah: "moo"
            object: {key: "value", bob: "whatever"}

    it "should identify invalid keys", ->
        kv_write kv_elem,
            filter: " an invalid path "
            thing_one: 5
            text_blah: "moo"
            object: {key: "value", bob: "whatever"}

        [data, invalid_keys, required_keys] = kv_read kv_elem
        expect(invalid_keys).toEqual(["filter"])

    it "should identify required keys", ->
        [data, invalid_keys, required_keys] = kv_read kv_elem
        expect(required_keys).toEqual(["filter"])

    it "should write data", ->
        data =
            filter: "path.to.filter2"
            # delete key thing_one
            thing_two: 100
            text_blah: ["an", "array"]
            object: {key: "value two"}

        kv_write kv_elem, data
        expect(kv_data_func()).toEqual(data)

describe "the sentence editor (manual)", ->
    for filter_type in ["intermediate", "post"]
        filter_list = "#sentence_#{filter_type}_filters"

        it "should support normal #{filter_type} filters", ->
            # add, remove, modify
            throw "not yet written"

        it "should support hotfix #{filter_type} filters", ->
            # add, remove, modify
            throw "not yet written"

        it "should require a valid normal filter name", ->
            throw "not yet written"

        it "shouldn't save if there's a filter validation error", ->
            throw "not yet written"

        it "should support #{filter_type} re-ordering", ->
            throw "not yet written"

    it "should support normal fields", ->
        # add, remove, modify
        throw "not yet written"

    it "should support custom fields", ->
        # add, remove, modify
        throw "not yet written"

    it "should support field re-ordering", ->
        throw "not yet written"
