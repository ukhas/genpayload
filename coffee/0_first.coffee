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

    alert "Error occured: #{msg} (#{where}). Sorry :-(." +
          "The application may become unstable or behave erratically, " +
          "you should probably refresh the page. "
    alert "Please report this to us via GitHub " +
          "https://github.com/ukhas/genpayload/issues " +
          "or on IRC (#highaltitude on irc.freenode.net) " +
          "if you do not have an account"
    return

