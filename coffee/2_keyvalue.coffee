# Copyright (c) 2012 Daniel Richman; GNU GPL 3

class KeyValueEdit
    constructor: (settings={}) ->
        @nice_keys = if settings.nice_keys? then settings.nice_keys else true
        @used_keys = {}
        @validator = if settings.validator? then settings.validator else -> true

        @elem = $("<div class='keyvalue' />")

        data = if settings.data? then deepcopy settings.data else {}

        if settings.required?
            @required = settings.required
            for key in @required
                @add_row key, data[key] or "", true
                delete data[key]

        for key, value of data
            @add_row key, value

        @add_row()
        return

    # handles duplicate keys and valid key names.
    # value input disabling/enabling and creation/deletion of rows is handled elsewhere
    key_changed: (row, k, v) ->
        # Remove the last used key
        key = row.data "last_used_key"
        if key? and key != ""
            a = @used_keys[key]

            if a.length == 1
                delete @used_keys[key]
            else
                index = a.indexOf row
                a[index..index] = []

                if a.length == 1
                    @set_part_valid a[0], "key", @valid_key a[0].val()

        # Add and check the new one
        key = k.val()
        ok = @valid_key key

        if key != ""
            a = @used_keys[key]

            if a?
                if a.length == 1
                    @set_part_valid a[0], "key", false

                a.push row
                ok = false
            else
                @used_keys[key] = [row]

        row.data "last_used_key", key
        @set_part_valid row, "key", ok

        # @validator might have changed
        v.change()

    # is this a valid (string) key
    valid_key: (key) ->
        if key == ""
            return true
        else if @nice_keys
            return nice_key_regexp.test key
        else
            return true

    # add a row. key, value, required used by constructor
    add_row: (key="", value="", required=false) ->
        row = $("<div class='row' />")

        k = $("<input type='text' title='Key' placeholder='Key' class='validated_inside' />")
        k.val key
        if required
            k.prop "disabled", true

        v = $("<input type='text' title='Value' placeholder='Value' class='validated_inside long' />")

        if key is ""
            v.prop "disabled", true
        else
            if (typeof value) is "string"
                v.val value
            else
                v.val JSON.stringify value

        @add_row_events row, k, v

        row.append k, v, $("<img />")

        @key_changed row, k, v
        v.change()

        @elem.append row

    # add events to deal with tab, val changing
    add_row_events: (row, k, v) ->
        kill_row = false

        # If change just enabled the value input, need to enable it ASAP (i.e., on keydown
        # before the browser picks the next focus) so that it will focus on the value.
        # If we're destroying a row, we need to kill the value input fast so that the
        # 'next' focus is the key input in the row below, then kill the row itself afterwards
        pre_change = =>
            if k.val() is ""
                if row.is(':last-child')
                    v.prop "disabled", true
                    v.val ""
                    @set_part_valid row, "value", true
                else
                    if not kill_row
                        v.remove()
                        kill_row = true
            else
                if row.is(':last-child')
                    @add_row()
                v.prop "disabled", false

        post_change = =>
            if kill_row
                row.remove()

        k.change =>
            pre_change()
            @key_changed row, k, v
            post_change()
            return

        k.keydown (e) ->
            if e.which is 9
                pre_change()
                # post_change() will fire later when change() is called normally.
                # re-running pre_change() is harmless.
            return

        # Show a blue background on things that we will save as not-strings
        v.change =>
            try
                value = JSON.parse v.val()
                v.addClass "keyvalue_json"
            catch e
                value = v.val()
                v.removeClass "keyvalue_json"

            @set_part_valid row, "value", (@validator k.val(), value)
            return

    set_part_valid: (row, part, part_valid) ->
        row.data("valid_#{part}", part_valid)
        console.log([row, part, part_valid, row.data("valid_key"), row.data("valid_value")])

        valid = (row.data("valid_key") and row.data("valid_value"))
        set_valid_img row.children("img"), valid

    data: ->
        d = {}
        used_keys = {}
        for row, index in @elem.children()
            [key, str_value] = ($(i).val() for i in $(row).children())

            if key != ""
                if not @valid_key key
                    throw "invalid key"
                if used_keys[key]
                    throw "duplicate keys"

                try
                    value = JSON.parse str_value
                catch e
                    value = str_value

                if not @validator key, value
                    throw "validating #{key} failed"

                d[key] = value
                used_keys[key] = true
        return d
