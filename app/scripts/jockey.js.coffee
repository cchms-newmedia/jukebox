jQuery ->
  searching = !!(location.pathname.match(/^\/search/))
  init_path = location.pathname
  query = null

  loading = (f) ->
    if f
      $("h1").text("Loading")
    else
      $("h1").text("Jockey")

  enque_hook = ->
    $("a.enque").click (e) ->
      e.preventDefault()
      $.post '/api/enque', {id: $(this).data('song')}
  enque_hook()

  realtime = new EventSource("/api/realtime?html=1")

  $(realtime).bind 'playing', (e) ->
    json = JSON.parse(e.originalEvent.data)
    $("#playing").html json.html

  $(realtime).bind 'upcoming', (e) ->
    json = JSON.parse(e.originalEvent.data)
    return if searching
    return unless location.pathname == "/"
    $("#content").html json.html
    enque_hook()

  $(realtime).bind 'history', (e) ->
    json = JSON.parse(e.originalEvent.data)
    return if searching
    return unless location.pathname == "/history"
    $("#content").html json.html
    enque_hook()

  do_search = ->
    return if query == $("#search_box").val()
    query = $("#search_box").val()
    return if query.length < 3

    loading true
    $.pjax({
      url: "/search?q=#{encodeURIComponent(query)}",
      container: '#content',
      timeout: 60000,
      push: !searching,
      replace: searching,
      success: ->
        searching = true
        loading false
        enque_hook()
    })
    # FIXME: Error handling

  $("#search_form").submit (e) ->
    e.preventDefault()

  search_timer = null
  $("#search_box").keyup (e) ->
    if e.keycode == 13
    else
      clearTimeout search_timer if search_timer
      search_timer = setTimeout(do_search, 500)

  $(window).bind 'pjax:popstate', (e) ->
    path = e.state.url.replace(location.origin,'')
    switch path
      when "/"
        $("#search_box").val('')
        $("#content").load '/?no_layout=1', enque_hook
        searching = false
      when "/history"
        $("#search_box").val('')
        $("#content").load '/history?no_layout=1', enque_hook
        searching = false


