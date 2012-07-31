# It's quite difficult to test each of these individually
# Some of the tests overlap or rely on other tests. :-(
# Atleast if they pass then stuff is ok
describe "The spec helper", ->
    ran_first_test = false

    it "should load genpayload.html", ->
        expect($("#go_pcfg_new").length).toBe(1)

        # for "should reload ..."
        $("#go_pcfg_new").remove()
        ran_first_test = true

        # extra check for "execute genpayload.js"
        $("#go_pcfg_modify").off("click")

    it "should reload genpayload for each test", ->
        if not ran_first_test
            throw "This test cannot be run alone"
        expect($("#go_pcfg_new").length).toBe(1) # i.e., reloaded
        expect($("h1").length).toBe(1) # i.e., not loaded twice

    it "should execute genpayload.js each time", ->
        # executing genpayload.js reattaches the event to the new element
        # Technically tests something else
        $("#go_pcfg_modify").click()
        expect($("#home")).not.toBeVisible()

    it "should provide jasmine-jquery", ->
        expect($("#home")).toBeVisible()
        expect($("#browse")).toBeHidden()
        $("#home").hide()
        $("#browse").show()
        expect($("#home")).toBeHidden()
        expect($("#browse")).toBeVisible()
