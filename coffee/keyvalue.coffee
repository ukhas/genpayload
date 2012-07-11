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

    # handles duplicate keys and valid key names.
    # value input disabled and creation/deletion of rows handled elsewhere
    key_changed: (input) ->
        # Remove the last used key
        key = input.data "last_used_key"
        if key? and key != ""
            a = @used_keys[key]

            if a.length == 1
                delete @used_keys[key]
            else
                index = a.indexOf input
                a[index..index] = []

                if a.length == 1
                    set_valid a[0], @valid_key a[0].val()

        # Add and check the new one
        key = input.val()
        ok = @valid_key key

        if key != ""
            a = @used_keys[key]

            if a?
                if a.length == 1
                    set_valid a[0], false

                a.push input
                ok = false
            else
                @used_keys[key] = [input]

        input.data "last_used_key", key
        set_valid input, ok

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
        row = $("<div />")
        kill_row = false

        k = $("<input type='text' title='Key' placeholder='Key' />")
        k.val key
        if required
            k.prop "disabled", true

        v = $("<input type='text' title='Value' placeholder='Value' class='long_input' />")

        # If change just enabled the value input, need to enable it ASAP (i.e., on keydown
        # before the browser picks the next focus) so that it will focus on the value.
        # If we're destroying a row, we need to kill the value input fast so that the
        # 'next' focus is the key input in the row below, then kill the row itself afterwards
        pre_change = =>
            if k.val() is ""
                if row.is(':last-child')
                    v.prop "disabled", true
                    v.val ""
                    set_valid v, true
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
            @key_changed k
            post_change()

        k.keydown (e) ->
            if e.which is 9
                pre_change()
                # post_change() will fire later when change() is called normally.
                # re-running pre_change() is harmless.

        # Show a blue background on things that we will save as not-strings
        v.change =>
            try
                value = JSON.parse v.val()
                v.addClass "keyvalue_json"
            catch e
                value = v.val()
                v.removeClass "keyvalue_json"

            set_valid v, (@validator k.val(), value)

        if key is ""
            v.prop "disabled", true
        else
            if (typeof value) is "string"
                v.val value
            else
                v.val JSON.stringify value

        @key_changed k
        v.change()

        row.append k, v
        @elem.append row

    data: ->
        d = {}
        used_keys = {}
        @elem.children().each (index, row) =>
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
