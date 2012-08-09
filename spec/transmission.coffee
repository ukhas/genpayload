describe "the transmission editor", ->
    beforeEach ->
        $("#go_pcfg_new").click()
        expect($("#payload_configuration")).toBeVisible()

    get_transmission_stuff = ->
        row = $("#transmissions_list").children().first()
        auto_descr = row.children().first().text()
        data = row.data("transmission")
        return [row, data, auto_descr]

    it "should be able to create transmission one", ->
        $("#transmission_new").click()
        expect($("#transmission_edit")).toBeVisible()

        $("#transmission_description").val("Fast RTTY")
        $("#transmission_frequency").val("0.01")
        $("#transmission_modulation").val("RTTY")
        $("#transmission_mode").val("LSB")
        $("#transmission_shift").val("200")
        $("#transmission_encoding").val("ASCII-7")
        $("#transmission_baud").val("300")
        $("#transmission_parity").val("even")
        $("#transmission_stop").val("1")

        $("#transmission_confirm").click()
        expect($("#payload_configuration")).toBeVisible()

        [row, data, auto_descr] = get_transmission_stuff()
        expect(data).toEqual(test_docs.pcfg1.transmissions[0])
        expect(auto_descr).toBe("Fast RTTY: 0.01MHz LSB RTTY 300 baud " +
                "200Hz shift ASCII-7 even parity 1 stop bit")

    it "should be able to create transmission two", ->
        $("#transmission_new").click()
        expect($("#transmission_edit")).toBeVisible()

        $("#transmission_frequency").val("0.02")
        $("#transmission_mode").val("USB")
        $("#transmission_modulation").val("DominoEX")
        $("#transmission_speed").val("11")

        $("#transmission_confirm").click()
        expect($("#payload_configuration")).toBeVisible()

        [row, data, auto_descr] = get_transmission_stuff()
        expect(data).toEqual(test_docs.pcfg1.transmissions[1])
        expect(auto_descr).toBe("0.02MHz USB DominoEX 11")

    it "should be able to create transmission three", ->
        $("#transmission_new").click()
        expect($("#transmission_edit")).toBeVisible()

        $("#transmission_frequency").val("0.02")
        $("#transmission_confirm").click()
        expect($("#payload_configuration")).toBeVisible()

        b = $("#transmissions_list").children().last().find("button").first()
        expect(b.text()).toBe("Edit")
        b.click()

        expect($("#transmission_edit")).toBeVisible()

        $("#transmission_description").val("Moderately long description. " +
                                           "Testing, one two three")
        $("#transmission_frequency").val("0.03")
        $("#transmission_mode").val("FM")
        $("#transmission_modulation").val("Hellschreiber")
        $("#transmission_variant").val("feldhell")

        $("#transmission_confirm").click()
        expect($("#payload_configuration")).toBeVisible()

        [row, data, auto_descr] = get_transmission_stuff()
        expect(data).toEqual(test_docs.pcfg1.transmissions[2])

        expect(auto_descr).toBe("Moderately long description. " +
                                "Testing, one two three")
        # i.e., doesn't append auto description

    it "should validate transmissions", ->
        # fairly weak test.
        window.alert.andReturn(undefined) # stop it throwing (see jasmine.html)

        $("#transmission_new").click()
        expect($("#transmission_edit")).toBeVisible()

        $("#transmission_frequency").val("moo")
        $("#transmission_confirm").click()

        expect(window.alert).toHaveBeenCalled()
