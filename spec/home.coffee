describe "#home", ->
    it "should be open by default", ->
        expect($("#home")).toBeVisible()
        expect($(".container > div").not("#home")).toBeHidden()

    it "should have 4 {new,copy and edit} {pcfg, flight} links", ->
        for [id, goto, back] in [["#go_pcfg_new", "#payload_configuration", "#pcfg_abandon"],
                                 ["#go_pcfg_modify", "#browse", "#browse_cancel"],
                                 ["#go_flight_new", "#flight", "#flight_abandon"],
                                 ["#go_flight_modify", "#browse", "#browse_cancel"]]
            expect($(id)).toBeVisible()
            $(id).click()
            expect($("#home")).toBeHidden()
            expect($(goto)).toBeVisible()
            expect($(back)).toBeVisible()
            if back is "#browse_cancel"
                expect(couchdbspy.view).toHaveBeenCalled()
                couchdbspy.view.mostRecentCall.args[1].error "nyan", "nyan", "nyan"
            expect($(back).is(".disabled")).toBe(false)
            $(back).click()
            expect($("#home")).toBeVisible()
