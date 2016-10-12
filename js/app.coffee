window.showUAStats = (key) ->
  console.log 'key^^^^^^^', key.toString()
  $.get "/uaStats/", {key}
  .done (response) ->
    console.log 'response', JSON.stringify response
  # .error (err) ->
  #   console.log 'err', JSON.stringify err

  false