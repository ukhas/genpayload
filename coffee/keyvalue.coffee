# Copyright (c) 2012 Daniel Richman; GNU GPL 3

class KeyValueEdit
    constructor: (settings={}) ->
        @elem = $("<table class='key_value' />")
        @tbody = $("<tbody />")
        @elem.append @tbody

        data = if settings.data? then deepcopy settings.data else {}

        if settings.show_always?
            @show_always = settings.show_always
            for key in @show_always
                @add_row key, data[key] or "", true
                delete data[key]

        for key, value of data
            @add_row key, value

        @add_row()

    add_row: (key="", value="", required=false) ->
        row = $("<tr />")
        kill_row = false

        k = $("<input type='text' title='Key' placeholder='Key' />")
        k.val key
        if required
            k.prop "disabled", true

        v = $("<input type='text' title='Value' placeholder='Value' />")

        if key is ""
            v.prop "disabled", true
        else
            v.val value

        # split change -> into two functions.
        # pressing tab causes a change().
        # Need to ensure that the browser will pick the next focus correctly.
        # If change just enabled the value input, need to enable it ASAP (i.e., on keydown
        # before the browser picks the next focus) so that it will focus on the value.
        # If we're destroying a row, we need to kill the value input fast so that the
        # 'next' focus is the key input in the row below, then kill the row itself afterwards
        pre_change = =>
            if k.val() is ""
                if row.is(':last-child')
                    v.prop "disabled", true
                    v.val ""
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

        k.change ->
            pre_change()
            post_change()

        k.keydown (e) ->
            if e.which is 9
                pre_change()
                # post_change() will fire later when change() is called normally.
                # re-running pre_change() is harmless.

        row.append $("<td />").append k
        row.append $("<td />").append v
        @tbody.append row

    data: ->
        d = {}
        @tbody.children().each (index, row) =>
            [key, value] = ($(td).children().first().val() for td in $(row).children())
            if key != ""
                num = strict_numeric value
                if not isNaN num then value = num

                d[key] = value
        return d

# todo here: validation for keys: duplicates, nice (i.e., /a-z/) or by function.
# if duplicates found live rather than at save, then maybe add this elsewhere (wizard, sentence_edit)

$ ->
    kvtest = new KeyValueEdit()
    $("body").append kvtest.elem
