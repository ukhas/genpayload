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
                r = new KeyValueRow this, key, data[key] or "", true
                delete data[key]

        for key, value of data
            r = new KeyValueRow this, key, value

        new KeyValueRow this
        return

    data: ->
        d = {}
        used_keys = {}

        for row, index in @elem.children()
            o = $(row).data("object")

            key = o.k.val()
            str_value = o.v.val()

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

    # is this a valid (string) key
    valid_key: (key) ->
        if key == ""
            return true
        else if @nice_keys
            return nice_key_regexp.test key
        else
            return true

class KeyValueRow
    constructor: (@parent, key="", value="", required=false) ->
        @row = $("<div class='row' />")
        @row.data("object", this)
        @parent.elem.append @row

        @k = $("<input type='text' title='Key' placeholder='Key' class='validated_inside' />")
        @v = $("<input type='text' title='Value' placeholder='Value' class='validated_inside long' />")
        @i = $("<img />")

        @k.val key
        if required
            @k.prop "disabled", true

        if key != ""
            if (typeof value) is "string"
                @v.val value
            else
                @v.val JSON.stringify value

        @key_valid = false
        @key_duplicate = false
        @value_valid = false

        @add_events()
        @row.append @k, @v, @i

        @key_changed() # also calls @v.change()

    # add events to deal with tab, val changing
    add_events: ->
        @kill_row = false

        @k.change =>
            @key_pre_change()
            @key_changed()
            @key_post_change()
            return

        @k.keydown (e) =>
            if e.which is 9
                @key_pre_change()

                # post_change() will fire later when change() is called normally.
                # re-running pre_change() is harmless.
            return

        @v.change =>
            # Show a blue background on things that we will save as not-strings
            try
                value = JSON.parse @v.val()
                @v.addClass "keyvalue_json"
            catch e
                value = @v.val()
                @v.removeClass "keyvalue_json"

            @value_valid = (@parent.validator @k.val(), value)
            @update_valid()
            return

    update_valid: ->
        if @k.val() is ""
            @i.hide()
        else
            @i.show()

        set_valid_img @i, (@key_valid and @value_valid and (not @key_duplicate))

    # If change just enabled the value input, need to enable it ASAP (i.e., on keydown
    # before the browser picks the next focus) so that it will focus on the value.
    # If we're destroying a row, we need to kill the value input fast so that the
    # 'next' focus is the key input in the row below, then kill the row itself afterwards

    key_pre_change: ->
        if @k.val() is ""
            if @row.is(':last-child')
                @v.prop "disabled", true
                @v.val ""
                @value_valid = true
            else
                if not @kill_row
                    @v.remove()
                    @kill_row = true
                    # see post change
        else
            # blank row just got used? add a new one
            if @row.is(':last-child')
                new KeyValueRow @parent

            @v.prop "disabled", false

    # handles duplicate keys and valid key names.
    # value input disabling/enabling and creation/deletion of rows is handled elsewhere
    key_changed: ->
        # Remove the last used key
        if @last_key? and @last_key != ""
            a = @parent.used_keys[@last_key]

            if a.length == 1
                delete @parent.used_keys[@last_key]
            else
                index = a.indexOf this
                a[index..index] = []

                if a.length == 1
                    a[0].key_duplicate = false
                    a[0].update_valid()

        # Add and check the new one
        key = @k.val()
        @last_key = key
        @key_valid = @parent.valid_key key
        @key_duplicate = false

        if key != ""
            a = @parent.used_keys[key]

            if a?
                if a.length == 1
                    a[0].key_duplicate = true
                    a[0].update_valid()

                a.push this
                @key_duplicate = true
            else
                @parent.used_keys[key] = [this]

        # parent.validator might have changed. v.change will call update_valid
        @v.change()

    key_post_change: ->
        if @kill_row
            @row.remove()
