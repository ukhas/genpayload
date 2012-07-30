# Copyright (c) 2012 Daniel Richman; GNU GPL 3

# Drop down menu that is invisible until hovered over.
# Usage:
# Construct, with an optional object of menu items
# menu = new HiddenMenu
#   item_id:
#       text: "The Text"
#       func: ->
#           alert "Whatever"
# Then, $("#whatever").append menu.container
# Also, use menu.update to add new elements, replace or delete current ones:
# menu.update
#   item_to_delete: null
#   item_to_replace:
#       text: "New text"
#       func: ->
#           alert "Something else"

class HiddenMenu
    constructor: (@items={}) ->
        @container = $("<div class='hidden_menu' />")
        @icon = $("<span class='ui-icon ui-icon-triangle-1-s' />")
        subcontainer = $("<div />")
        @menu = $("<ul />")
        for id, item of @items
            @create(item)
        @menu.menu()
        subcontainer.append @menu
        @container.append @icon, subcontainer
        return

    update: (new_items={}) ->
        for id, item of new_items
            if @items[id]?
                @items[id].li.remove()
                delete @items[id]

            if item?
                @items[id] = item
                @create(item)
        @menu.menu("refresh")

    create: (item) ->
        i = $("<a href='#' />")
        i.text item.text
        i.click btn_cb item.func
        item.li = $("<li />").append i
        @menu.append (item.li)
