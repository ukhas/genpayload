describe "the sentence wizard", ->
    beforeEach ->
        $("#go_pcfg_new").click()
        expect($("#payload_configuration")).toBeVisible()

    possible_types = -> $("#wizard_field_sensor > option").text()

    it "should create sentence one (checks auto description)", ->
        $("#go_wizard").click()
        expect($("#wizard_text_box")).toBeVisible()

        $("#wizard_text_box").val("$$APEX,1482,21:34:31,5124.6345,-00016.2167" +
                ",00030,05,000.0,19.13,20.50,64,36,15,7,0,0,6.08*1D68")
        $("#wizard_next").click()

        expect($("#wizard_fields")).toBeVisible()
        f = $("#wizard_fields span.invalid").first()
        expect(f.text()).toBe("05")
        f.click()

        expect(f).toHaveClass("highlight")
        expect(possible_types()).toBe("StringConstantIntegerFloat")
        $("#wizard_field_name").val("satellites")
        $("#wizard_field_sensor").val("base.ascii_int")
        $("#wizard_next").click()

        for i in ["speed", "temperature_external", "temperature_internal"]
            expect(possible_types()).toBe("StringConstantCoordinateFloat")
            $("#wizard_field_name").val(i)
            $("#wizard_field_sensor").val("base.ascii_float")
            $("#wizard_next").click()

        for i in ["light", "light_red", "light_green", "light_blue",
                  "gas_co2", "gas_combustible"]
            expect(possible_types()).toBe("StringConstantIntegerFloat")
            $("#wizard_field_name").val(i)
            $("#wizard_field_sensor").val("base.ascii_int")
            $("#wizard_next").click()

        $("#wizard_field_name").val("battery")
        expect($("#wizard_field_name")).toBeVisible()
        $("#wizard_field_sensor").val("base.ascii_float")
        $("#wizard_next").click()

        expect($("#wizard_description")).toBeVisible()
        $("#wizard_description").val("Normal format")
        $("#wizard_no_lock").val("zeroes")
        $("#wizard_next").click()

        expect($("#payload_configuration")).toBeVisible()

        s = "Normal format: $$APEX"
        expect_data = test_docs.pcfg1.sentences[0]
        for i in expect_data.fields
            s += "," + i.name
        s += "*FFFF (1 filter) (UKHAS)"

        row = $("#sentences_list").children().first()
        a = row.children().first().text()
        expect(a).toBe(s)
        expect(row.data("sentence")).toEqual(expect_data)

    # also tests: xor, enter string without $$
    it "shouldn't continue if a field is not configured", ->
        $("#go_wizard").click()
        expect($("#wizard_text_box")).toBeVisible()

        $("#wizard_text_box").val("A,A*2C")
        $("#wizard_next").click()
        expect($("#wizard_checksum_type").text()).toBe("xor")
        expect($("#wizard_field_name")).toBeVisible()

        window.alert.andReturn(undefined) # stop it throwing (see jasmine.html)

        $("#wizard_next").click()

        expect(window.alert).toHaveBeenCalled()
        expect($("#wizard_fields span.invalid").length).toBe(1)
        expect($("#wizard_field_name")).toBeVisible()

    for [test, val] in [["empty", ""], ["system", "_bad"], ["bad", " spaces "]]
        it "should forbid #{test} field names", ->
            $("#go_wizard").click()
            $("#wizard_text_box").val("A,A*2C")
            $("#wizard_next").click()

            window.alert.andReturn(undefined)
            $("#wizard_next").click()

            $("#wizard_field_name").val(val)

            expect(window.alert).toHaveBeenCalled()
            expect($("#wizard_fields span.invalid").length).toBe(1)

    it "shouldn't give a no-lock option if there is no lat/lon", ->
        $("#go_wizard").click()
        expect($("#wizard_text_box")).toBeVisible()

        $("#wizard_text_box").val("$$A,A*2C")
        $("#wizard_next").click()
        expect($("#wizard_checksum_type").text()).toBe("xor")
        $("#wizard_field_name").val("something")
        $("#wizard_next").click()

        expect($("#wizard_description")).toBeVisible()
        expect($("#wizard_no_lock")).toBeHidden()
        $("#wizard_next").click()

        val = $("#sentences_list").children().first().data("sentence")
        expect(val.filters?).toBe(false)

    describe "should have a no-lock section, which", ->
        do_and_get_filter = (type, extra=->) ->
            $("#go_wizard").click()
            $("#wizard_text_box").val("$$AA,00,00:00:00,51.00000,1.5000*00")
            $("#wizard_next").click() for i in [1..5]
            expect($("#wizard_no_lock")).toBeVisible()
            $("#wizard_no_lock").val(type)
            $("#wizard_no_lock").change()
            extra()
            $("#wizard_next").click()
            expect($("#payload_configuration")).toBeVisible()
            val = $("#sentences_list").children().first().data("sentence")
            if val.filters?
                expect(val.filters.intermediate?).toBe(false)
                expect(val.filters.post.length).toBe(1)
                return val.filters.post[0]
            else
                return null

        it "should support latlng zeroes", ->
            # also tested by 'create sentence one'
            f = do_and_get_filter "zeroes"
            expect(f).toEqual
                type: "normal"
                filter: "common.invalid_location_zero"

        it "should support lockfield", ->
            f = do_and_get_filter "lockfield", ->
                expect($("#wizard_select_lockfield")).toBeVisible()
                a = $("#wizard_fields span:nth-child(2)")
                a.click()
                expect(a).toHaveClass("highlight")

                v = $("#wizard_lockfield_ok")
                valid = -> (v.siblings("img").attr("alt") is "OK")
                expect(valid()).toBe(false)

                v.val("1,2,3.0")
                v.change()
                expect(valid()).toBe(false) # float

                v.val("1,2,3")
                v.change()
                expect(valid()).toBe(true)

            expect(f).toEqual
                type: "normal"
                filter: "common.invalid_gps_lock"
                source: "sentence_id" # :P because it was there
                ok: [1,2,3]

        it "should support other", ->
            f = do_and_get_filter "other"
            expect(f).toBe(null)

        it "should support always", ->
            f = do_and_get_filter "always"
            expect(f).toEqual
                type: "normal"
                filter: "common.invalid_always"

    describe "should allow creation of numeric scale filters, which", ->
        try_settings = (settings) ->
            $("#go_wizard").click()
            $("#wizard_text_box").val("$$AA,1234,4321*00")
            $("#wizard_next").click()
            $("#wizard_field_name").val("bill")

            expect($("#wizard_numeric_scale_opts")).toBeHidden()
            $("#wizard_numeric_scale").prop("checked", true).change()
            expect($("#wizard_numeric_scale_opts")).toBeVisible()

            for k, v of settings
                if k is "do_round"
                    $("#wizard_numeric_scale_do_round").prop("checked", v).change()
                else
                    $("#wizard_numeric_scale_#{k}").val(v).change()
            ex = +($("#wizard_numeric_scale_example").text())
            $("#wizard_next").click()

            if $("#wizard_fields span:nth-child(2)").is(".invalid")
                $("#wizard_cancel").click()
                expect($("#payload_configuration")).toBeVisible()
                return "invalid"
            else
                $("#wizard_field_name").val("bob")
                $("#wizard_next").click()
                $("#wizard_next").click()
                expect($("#payload_configuration")).toBeVisible()
                val = $("#sentences_list").children().first().data("sentence")
                expect([val.filters.intermediate?, val.filters.post.length])
                    .toEqual([false, 1])
                r = val.filters.post[0]
                r.expected = ex
                return r

        it "are well formed", ->
            # a simple sanity test, I guess
            expect(try_settings {}).toEqual
                type: "normal"
                filter: "common.numeric_scale"
                factor: 1
                round: 3
                source: "bill"
                expected: 1230

        it "can multiply and round to a given precision", ->
            expect try_settings
                factor: 2.41
                round: 2
            .toEqual
                type: "normal"
                filter: "common.numeric_scale"
                factor: 2.41
                round: 2
                source: "bill"
                expected: 3000 # 2973.94

        it "have the option of not rounding", ->
            # also test negative factors, woo
            expect try_settings
                factor: - (1 / 3)
                do_round: false
            .toEqual
                type: "normal"
                filter: "common.numeric_scale"
                factor: -0.33333333333333333
                source: "bill"
                expected: -411.3333333333333333

        it "can divide by a given value (instead of the default of multiplying)", ->
            expect try_settings
                factor: 7
                type: 'd'
            .toEqual
                type: "normal"
                filter: "common.numeric_scale"
                factor: (1 / 7)
                round: 3
                source: "bill"
                expected: 176.0 # 176.29

        for [name, bads...] in  [["factor", "asdf", ""], ["offset", "dfgh", ""],
                                 ["round", "4.2", "asdf", ""]]
            it "validate the #{name} property ", ->
                for b in bads
                    s = {}
                    s[name] = b
                    expect(try_settings s).toEqual("invalid")
