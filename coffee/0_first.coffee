###
Copyright (c) 2012 Daniel Richman; GNU GPL 3
###

window.onerror = (msg, url, line) ->
    try
        pos = url.lastIndexOf('/') + 1
        last = url[pos..]
        where = "#{last} @ #{line}"
    catch e
        where = "unknown location"

    alert "Error occured: #{msg} (#{where}). Sorry :-(."
    alert "The application may become unstable or behave erratically, " +
          "you should probably refresh the page. Please report this to us on IRC."
    return

