# get the values that a KeyValueEditor is displaying to the user
kv_read = (elem) ->
    if not elem.is(".keyvalue")
        throw "not a KeyValueEditor"

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
    if not elem.is(".keyvalue")
        throw "not a KeyValueEditor"

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

describe "the manual sentence editor", ->
    beforeEach ->
        $("#go_pcfg_new").click()

    from_scratch = (no_default_field=false, no_default_callsign=false) ->
        $("#go_manual").click()
        expect($("#sentence_edit")).toBeVisible()
        expect($("#sentence_edit > .itemlist > .row").length).toBe(0)

        if no_default_field
            while $("#sentence_fields > .row").length
                row = $("#sentence_fields > .row").last()
                delete_button = row.find(".hidden_menu li:nth-child(2) a")
                if delete_button.length != 1 or delete_button.text() != "Delete"
                    throw "couldn't find delete button"
                delete_button.click()

        if not no_default_callsign
            $("#sentence_callsign").val("test_payload").change()

    modify = ->
        $("#go_import").click()
        o = couchdbspy.view.mostRecentCall.args[1]
        o.success
            total_rows: 1
            offset: 0
            rows: [
                id: "id_of_pcfg2"
                key: ["T32_0", 123, 0]
                value: [
                    {name: "Test doc 2", time_created: "2012-08-02T00:04:17+01:00"}
                    test_docs.pcfg2.sentences[0]
                ]
            ]

        $("#browse_list > .row").first().click()

        expect($("#sentence_edit")).toBeVisible()
        expect($("#sentence_description").val()).toBe("I describe")
        expect($("#sentence_edit .itemlist > .row").length).toBe(8)

    save_and_get = ->
        $("#sentence_edit_save").click()
        expect($("#payload_configuration")).toBeVisible()
        sentences = $("#sentences_list > .row")
        expect(sentences.length).toBe(1)
        return sentences.first().data("sentence")

    expect_save_validate_fail = ->
        alert.reset()
        alert.andReturn(null)
        $("#sentence_edit_save").click()
        expect(alert).toHaveBeenCalled()

    get_filter_list = (type) -> $("#sentence_#{type}_filters")

    test_set_check_normal_filter = (filter_type, filter_index) ->
        filters = get_filter_list(filter_type).children(".row")

        kv_elem = filters.eq(filter_index).find(".keyvalue")
        expect(kv_elem.length).toBe(1)

        filter_data =
            filter: "module.a_function"
            arg: "a string"
            something: ["an", "array"]
        kv_write kv_elem, filter_data

        sentence = save_and_get()
        filter_data.type = "normal"
        expect(sentence.filters[filter_type][filter_index]).toEqual(filter_data)

    it "should support adding normal intermediate filters", ->
        from_scratch()
        $("#sentence_intermediate_normal_filter_add").click()
        test_set_check_normal_filter "intermediate", 0

    it "should support modifying normal intermediate filters", ->
        modify()
        test_set_check_normal_filter "intermediate", 1

    it "should support adding normal post filters", ->
        from_scratch()
        $("#sentence_post_normal_filter_add").click()
        test_set_check_normal_filter "post", 0

    it "should support modifying normal post filters", ->
        modify()
        test_set_check_normal_filter "post", 1

    test_set_check_hotfix_filter = (filter_type, filter_index) ->
        filters = get_filter_list(filter_type).children(".row")
        filter_input = filters.eq(filter_index).children("input")
        expect(filter_input).toHaveClass("hotfix_box")

        filter_data =
            type: "hotfix"
            code: "some\ncode"
            signature: "a signature"
            certificate: "my_cert.crt"
        filter_input.val JSON.stringify filter_data

        sentence = save_and_get()
        expect(sentence.filters[filter_type][filter_index]).toEqual(filter_data)

    it "should support adding hotfix intermediate filters", ->
        from_scratch()
        $("#sentence_intermediate_hotfix_filter_add").click()
        test_set_check_hotfix_filter "intermediate", 0

    it "should support modifying hotfix intermediate filters", ->
        modify()
        test_set_check_hotfix_filter "intermediate", 0

    it "should support adding hotfix post filters", ->
        from_scratch()
        $("#sentence_post_hotfix_filter_add").click()
        test_set_check_hotfix_filter "post", 0

    it "should support modifying hotfix post filters", ->
        modify()
        test_set_check_hotfix_filter "post", 0

    test_remove_filter = (filter_type) ->
        modify()

        filters = get_filter_list(filter_type).children(".row")
        expect(filters.length).toBe(2)

        b = filters.first().find(".hidden_menu li a")
        expect(b.text()).toBe("Delete")
        b.click()

        sentence = save_and_get()
        saved_filters = sentence.filters[filter_type]
        expect(saved_filters.length).toBe(1)
        second_filter = test_docs.pcfg2.sentences[0].filters[filter_type][1]
        expect(saved_filters[0]).toEqual(second_filter)

    it "should support removing intermediate filters", ->
        test_remove_filter "intermediate"

    it "should support removing post filters", ->
        test_remove_filter "post"

    test_valid_normal_filter_name = (filter_type) ->
        from_scratch()
        $("#sentence_#{filter_type}_normal_filter_add").click()

        filters = get_filter_list(filter_type).children(".row")
        kv_elem = filters.first().find(".keyvalue")

        for bad_name in ["", "asdf*asdf", "invalid filter"]
            kv_write kv_elem, {filter: bad_name}

            [data, invalid_keys, required_keys] = kv_read kv_elem
            expect(invalid_keys).toEqual(["filter"])

            expect_save_validate_fail()

        kv_write kv_elem, {filter: "valid"}
        [data, invalid_keys, required_keys] = kv_read kv_elem
        expect(invalid_keys).toEqual([])
        expect(required_keys).toEqual(["filter"])

        alert.andThrow("shouldn't have failed validation")
        save_and_get()

    it "should require a valid normal filter name (intermediate)", ->
        test_valid_normal_filter_name "intermediate"

    it "should require a valid normal filter name (post)", ->
        test_valid_normal_filter_name "post"

    test_re_order_filters = (filter_type) ->
        modify()

        filters = get_filter_list(filter_type).children(".row")
        filters.first().detach().appendTo(get_filter_list(filter_type))

        sentence = save_and_get()
        saved_filters = sentence.filters[filter_type]
        # copy array with [..]
        expect_filters = test_docs.pcfg2.sentences[0].filters[filter_type][..]
        expect_filters.reverse()
        expect(saved_filters).toEqual(expect_filters)

    it "should support intermediate filter re-ordering", ->
        test_re_order_filters "intermediate"

    it "should support post filter re-ordering", ->
        test_re_order_filters "post"

    test_valid_fieldname_key = (filter_type, key_name) ->
        from_scratch()
        $("#sentence_#{filter_type}_normal_filter_add").click()

        filters = get_filter_list(filter_type).children(".row")

        kv_elem = filters.find(".keyvalue")
        expect(kv_elem.length).toBe(1)

        filter_data = {filter: "module.a_function"}

        for bad_value in ["", "_asdf", "blah blah"]
            filter_data[key_name] = bad_value
            kv_write kv_elem, filter_data

            [data, invalid_keys, required_keys] = kv_read kv_elem
            expect(invalid_keys).toEqual([key_name])

            expect_save_validate_fail()

        filter_data[key_name] = "valid"
        kv_write kv_elem, filter_data

        [data, invalid_keys, required_keys] = kv_read kv_elem
        expect(invalid_keys).toEqual([])

        alert.andThrow("shouldn't have failed validation")
        save_and_get()

    it "should check source keys (intermediate filters)", ->
        test_valid_fieldname_key "intermediate", "source"

    it "should check source keys (post filters)", ->
        test_valid_fieldname_key "post", "source"

    it "should check destination keys (intermediate filters)", ->
        test_valid_fieldname_key "intermediate", "destination"

    it "should check destination keys (post filters)", ->
        test_valid_fieldname_key "post", "destination"

    test_empty_filters = (filter_type) ->
        modify() # so that filters is populated with 2 intermediate, 2 post
        for i in [1..2]
            row = get_filter_list(filter_type).children().first()

            b = row.find(".hidden_menu li a")
            expect(b.text()).toBe("Delete")
            b.click()
        sentence = save_and_get()
        expect(sentence.filters?).toBe(true)
        expect(sentence.filters[filter_type]?).toBe(false)

    it "shouldn't create filters.intermediate if it would be empty", ->
        test_empty_filters "intermediate"

    it "shouldn't create filters.post if it would be empty", ->
        test_empty_filters "post"

    it "shouldn't create the filters object if it would be empty", ->
        from_scratch()
        sentence = save_and_get()
        expect(sentence.filters?).toBe(false)

    it "should require atleast one field", ->
        from_scratch(true)
        expect_save_validate_fail()

    test_set_check_normal_field = (index, type) ->
        field = $("#sentence_fields > .row").eq(index)
        inputs = field.find(".normal_field").children()
        expect(inputs.length).toBe(5)

        [name_elem, sensor_elem, coord_elem, const_elem, valid_elem] = inputs

        field_data =
            name: "new_name"
            sensor: type
            expect: "some constant"
            format: "ddmm.mmmm"

        $(name_elem).val(field_data.name)
        $(sensor_elem).val(field_data.sensor).change()

        if field_data.sensor == "base.constant"
            expect($(const_elem)).toBeVisible()
            $(const_elem).val(field_data.expect)
        else
            expect($(const_elem)).toBeHidden()
            delete field_data.expect

        if field_data.sensor == "stdtelem.coordinate"
            expect($(coord_elem)).toBeVisible()
            $(coord_elem).val(field_data.format)
        else
            expect($(coord_elem)).toBeHidden()
            delete field_data.format

        sentence = save_and_get()
        expect(sentence.fields[index]).toEqual(field_data)

    it "should support adding normal fields", ->
        from_scratch(true)
        $("#sentence_fields_add").click()
        test_set_check_normal_field 0, "base.constant"

    it "should support modifying normal fields", ->
        modify()
        test_set_check_normal_field 2, "stdtelem.coordinate"

    test_set_check_custom_field = (index) ->
        kv_elem = $("#sentence_fields > .row").eq(index).find(".keyvalue")
        expect(kv_elem.length).toBe(1)

        field_data =
            name: "something"
            sensor: "some.custom_sensor"
            config: "something_else"
            blah: {an_object: ['an', 'array', 3]}

        kv_write kv_elem, field_data

        sentence = save_and_get()
        expect(sentence.fields[index]).toEqual(field_data)

    it "should support adding custom fields", ->
        from_scratch(true)
        $("#sentence_fields_expert").click()
        test_set_check_custom_field 0

    it "should support modifying custom fields", ->
        modify()
        test_set_check_custom_field 3

    it "should support removing fields", ->
        modify()

        row = $("#sentence_fields > .row").eq(2)
        delete_button = row.find(".hidden_menu li:nth-child(2) a")
        expect(delete_button.length).toBe(1)
        expect(delete_button.text()).toBe("Delete")
        delete_button.click()

        sentence = save_and_get()
        saved_fields = sentence.fields

        # copy array with [..]
        expect_fields = test_docs.pcfg2.sentences[0].fields[..]
        expect_fields[2..2] = []

        expect(saved_fields).toEqual(expect_fields)

    it "should support creating a numeric scale filter with default values", ->
        modify()

        row = $("#sentence_fields > .row").eq(2)
        scale_button = row.find(".hidden_menu li:nth-child(1) a")
        expect(scale_button.length).toBe(1)
        expect(scale_button.text()).toContain("numeric scale")
        scale_button.click()

        sentence = save_and_get()
        filters = sentence.filters.post
        expect(filters.length).toBe(3)
        expect(filters[2]).toEqual
            type: "normal"
            source: "latitude"
            filter: "common.numeric_scale"
            factor: 1
            round: 3

    test_custom_field_validation = (key_name, bad_values...) ->
        from_scratch(true)
        $("#sentence_fields_expert").click()

        kv_elem = $("#sentence_fields > .row").find(".keyvalue")
        expect(kv_elem.length).toBe(1)

        field_data =
            name: "something"
            sensor: "a.valid_sensor"
            val: 54

        for b in bad_values
            field_data[key_name] = b
            kv_write kv_elem, field_data
            [data, invalid_keys, required_keys] = kv_read kv_elem
            expect(invalid_keys).toEqual([key_name])

        field_data[key_name] = "valid"
        kv_write kv_elem, field_data
        [data, invalid_keys, required_keys] = kv_read kv_elem
        expect(required_keys).toEqual(["name", "sensor"])
        expect(invalid_keys).toEqual([])

        alert.andThrow("shouldn't have failed validation")
        save_and_get()

    it "should require a valid custom field name", ->
        test_custom_field_validation "name", "", "_asdf", " invalid ", "asd*f"

    it "should require a valid custom field sensor", ->
        test_custom_field_validation "sensor", "", " invalid ", "some.&"

    it "should be able to convert from normal to custom field", ->
        from_scratch(true)
        $("#sentence_fields_add").click()

        field = $("#sentence_fields > .row").first()
        inputs = field.find(".normal_field").children()
        values = ["the_field_name", "stdtelem.coordinate", "ddmm.mmmm"]

        for i in [0..2]
            $(inputs[i]).val(values[i]).change()

        conv = field.find(".hidden_menu li:nth-child(3) a")
        expect(conv.text()).toBe("Convert this to a custom field")
        conv.click()

        field = $("#sentence_fields > .row").first()
        kv_elem = field.find(".keyvalue")
        expect(kv_elem.length).toBe(1)

        field_data =
            name: "the_field_name"
            sensor: "stdtelem.coordinate"
            format: "ddmm.mmmm"

        [data, invalid_keys, required_keys] = kv_read kv_elem
        expect(data).toEqual(field_data)

        sentence = save_and_get()
        expect(sentence.fields[0]).toEqual(field_data)

    test_convert_custom_normal = (sensor) ->
        from_scratch(true)
        $("#sentence_fields_expert").click()

        field_data =
            name: "my_field"
            sensor: sensor

        switch sensor
            when "base.constant" then field_data.expect = "expectations"
            when "stdtelem.coordinate" then field_data.format = "dddd.dd"

        kv_elem = $("#sentence_fields > .row").find(".keyvalue")
        expect(kv_elem.length).toBe(1)
        kv_write kv_elem, field_data

        conv = $("#sentence_fields > .row .hidden_menu li:nth-child(3) a")
        expect(conv.text()).toBe("Convert this to a normal field")
        conv.click()

        if field_data.format?
            field_data.format = "dd.dddd"

        field = $("#sentence_fields > .row")
        expect(field.length).toBe(1)
        inputs = field.find(".normal_field").children()
        expect(inputs.length).toBe(5)

        input_names = ["name", "sensor", "format", "expect"]
        for i in [0..3]
            elem = $(inputs[i])
            val = field_data[input_names[i]]

            if val?
                expect(elem).toBeVisible()
                expect(elem.val()).toBe(val)
            else
                expect(elem).toBeHidden()

        sentence = save_and_get()
        expect(sentence.fields[0]).toEqual(field_data)

    it "should be able to convert custom base.ascii_int fields to normal", ->
        test_convert_custom_normal "base.ascii_int"

    it "should be able to convert custom base.ascii_float fields to normal", ->
        test_convert_custom_normal "base.ascii_float"

    it "should be able to convert custom base.string fields to normal", ->
        test_convert_custom_normal "base.string"

    it "should be able to convert custom base.constant fields to normal", ->
        test_convert_custom_normal "base.constant"

    it "should be able to convert custom stdtelem.time fields to normal", ->
        test_convert_custom_normal "stdtelem.time"

    it "should be able to convert custom stdtelem.coordinate to normal", ->
        test_convert_custom_normal "stdtelem.coordinate"

    test_interpret_coordinate_format = (give_format, expect_parsed) ->
        $("#go_import").click()
        o = couchdbspy.view.mostRecentCall.args[1]
        o.success
            total_rows: 1
            offset: 0
            rows: [
                id: "id_of_pcfg2"
                key: ["MOO", 123, 0]
                value: [
                    name: "Test doc"
                    time_created: "2012-07-31T01:40:10+01:00"
                ,
                    protocol: "UKHAS"
                    checksum: "xor"
                    callsign: "MOO"
                    fields: [
                        name: "blah"
                        sensor: "stdtelem.coordinate"
                        format: give_format
                    ]
                ]
            ]

        $("#browse_list > .row").first().click()

        expect($("#sentence_edit")).toBeVisible()

        inputs = $("#sentence_fields > .row select")
        expect(inputs.length).toBe(2)
        expect(inputs.last().val()).toBe(expect_parsed)

        $("#sentence_edit_cancel").click()

    it "should be able to interpret coordinate formats", ->
        test_interpret_coordinate_format "dd.dddd", "dd.dddd"
        test_interpret_coordinate_format "dddd.dd", "dd.dddd"
        test_interpret_coordinate_format "ddmm.mmmm", "ddmm.mmmm"
        test_interpret_coordinate_format "dm.m", "ddmm.mmmm"
        test_interpret_coordinate_format "ddddmmmmm.mmmmm", "ddmm.mmmm"

    it "should support field re-ordering", ->
        modify()

        fields = $("#sentence_fields").children(".row")
        fields.eq(2).detach().appendTo("#sentence_fields")

        sentence = save_and_get()
        saved_fields = sentence.fields
        # copy array with [..]
        expect_fields = test_docs.pcfg2.sentences[0].fields[..]
        f = expect_fields[2]
        expect_fields[2..2] = []
        expect_fields.push f

        expect(saved_fields).toEqual(expect_fields)

    it "should save sentence.description", ->
        from_scratch()
        $("#sentence_description").val("A description of this sentence")
        expect(save_and_get().description).toBe("A description of this sentence")

    it "should save sentence.callsign",  ->
        from_scratch(false, true)
        $("#sentence_callsign").val("MYCALLSIGN")
        expect(save_and_get().callsign).toBe("MYCALLSIGN")

    it "should require a valid sentence callsign", ->
        from_scratch(false, true)

        for bad_value in ["", "spaces no", "%$*asdf", "blah,blah"]
            $("#sentence_callsign").val(bad_value)
            expect($("#sentence_callsign").siblings("img").attr("alt")).toBe("Error")
            expect_save_validate_fail()

        alert.andThrow("shouldn't have failed validation")
        $("#sentence_callsign").val("Hello")

        save_and_get()

    it "should save sentence.protocol == UKHAS", ->
        from_scratch()
        expect(save_and_get().protocol).toBe("UKHAS")

        $("#sentences_list").empty()

        modify()
        expect(save_and_get().protocol).toBe("UKHAS")

    it "should load a sentence (in order to modify it) correctly", ->
        modify()

        loaded_sentence = test_docs.pcfg2.sentences[0]

        expect($("#sentence_callsign").val()).toEqual("T32_0")
        expect($("#sentence_description").val()).toEqual("I describe")

        fields = $("#sentence_fields > .row")
        intermediate_filters = $("#sentence_intermediate_filters > .row")
        post_filters = $("#sentence_post_filters > .row")

        expect(fields.length).toBe(4)
        expect(intermediate_filters.length).toBe(2)
        expect(post_filters.length).toBe(2)

        for field_index in [0..2]
            inputs = $(fields[field_index]).find(".normal_field").children()
            expect(inputs.length).toBe(5)
            [name_elem, sensor_elem, coord_elem, const_elem, valid_elem] = inputs

            expect_field = loaded_sentence.fields[field_index]
            expect($(name_elem).val()).toBe(expect_field.name)
            expect($(sensor_elem).val()).toBe(expect_field.sensor)

            if expect_field.sensor == "stdtelem.coordinate"
                # beware dd.dddd != ddd.dddd; works in this case
                expect($(coord_elem).val()).toBe(expect_field.format)
            else
                expect($(coord_elem)).toBeHidden()

            # there are no base.constant fields in pcfg2.sentences[0]
            expect($(const_elem)).toBeHidden()

        # 4th field is a custom field
        kv_elem = $(fields[3]).find(".keyvalue")
        expect(kv_elem.length).toBe(1)

        [data, invalid_keys, required_keys] = kv_read kv_elem
        expect(data).toEqual(loaded_sentence.fields[3])

        filter_types = [
            [intermediate_filters, loaded_sentence.filters.intermediate]
            [post_filters, loaded_sentence.filters.post]
        ]
        for [filter_rows, expect_filters] in filter_types
            expect(filter_rows.length).toBe(2)
            [hotfix_filter, normal_filter] = filter_rows

            hotfix_input = $(hotfix_filter).find("input")
            expect(hotfix_input.length).toBe(1)
            expect(hotfix_input).toHaveClass("hotfix_box")
            expect(JSON.parse(hotfix_input.val())).toEqual(expect_filters[0])

            kv_elem = $(normal_filter).find(".keyvalue")
            expect(kv_elem.length).toBe(1)

            [data, invalid_keys, required_keys] = kv_read kv_elem
            data.type = "normal"
            expect(data).toEqual(expect_filters[1])

        expect(save_and_get()).toEqual(test_docs.pcfg2.sentences[0])

    it "should be able to create pcfg2.sentences[0] from scratch", ->
        target_sentence = test_docs.pcfg2.sentences[0]

        from_scratch(true, true)

        $("#sentence_callsign").val("T32_0")
        $("#sentence_description").val("I describe")

        $("#sentence_fields_add").click()
        inputs = $("#sentence_fields > .row").last().find(".normal_field").children()
        $(inputs[0]).val("sentence_id")
        $(inputs[1]).val("base.ascii_int")

        $("#sentence_fields_add").click()
        inputs = $("#sentence_fields > .row").last().find(".normal_field").children()
        $(inputs[0]).val("time")
        $(inputs[1]).val("stdtelem.time")

        $("#sentence_fields_add").click()
        inputs = $("#sentence_fields > .row").last().find(".normal_field").children()
        $(inputs[0]).val("latitude")
        $(inputs[1]).val("stdtelem.coordinate")
        # dd.dddd is default

        $("#sentence_fields_expert").click()
        kv_elem = $("#sentence_fields > .row").last().find(".keyvalue")
        kv_write kv_elem, target_sentence.fields[3]

        for filter_type in ["intermediate", "post"]
            $("#sentence_#{filter_type}_hotfix_filter_add").click()
            filters = get_filter_list(filter_type).children(".row")
            filter_input = filters.first().children("input")
            target_filter = target_sentence.filters[filter_type][0]
            filter_input.val JSON.stringify target_filter

            $("#sentence_#{filter_type}_normal_filter_add").click()
            filters = get_filter_list(filter_type).children(".row")
            kv_elem = filters.last().find(".keyvalue")
            target_filter = $.extend {}, target_sentence.filters[filter_type][1]
            delete target_filter.type
            kv_write kv_elem, target_filter

        sentence = save_and_get()
        expect(sentence).toEqual(target_sentence)
