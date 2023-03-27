GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY")
GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX")

def image(event, google_api)
  api_keys = choose_api_keys(google_api)
  key = key(event.message.content, 2)
  results = GoogleCustomSearchApi.search(
    key,
    searchType: "image",
    google_api_key: api_keys[:google_api_key],
    google_search_cx: api_keys[:google_search_cx]
  )
  event.respond(results["items"].sample["link"])
end

def animate(event, google_api)
  api_keys = choose_api_keys(google_api)
  key = key(event.message.content, 2)
  results = GoogleCustomSearchApi.search(
    key,
    searchType: "image",
    fileType: "gif",
    google_api_key: api_keys[:google_api_key],
    google_search_cx: api_keys[:google_search_cx]
  )
  event.respond(results["items"].sample["link"])
end

def youtube(event)
  key = key(event.message.content, 2)
  results = GoogleCustomSearchApi.search(
    key,
    google_api_key: ENV.fetch("GOOGLE_API_KEY_3"),
    google_search_cx: ENV.fetch("GOOGLE_SEARCH_CX_3")
  )
  event.respond(results["items"].first(3).sample["link"])
end

def choose_api_keys(google_api)
  if google_api
    {google_api_key: ENV.fetch("GOOGLE_API_KEY"), google_search_cx: ENV.fetch("GOOGLE_SEARCH_CX")}
  else
    {google_api_key: ENV.fetch("GOOGLE_API_KEY_2"), google_search_cx: ENV.fetch("GOOGLE_SEARCH_CX_2")}
  end
end
