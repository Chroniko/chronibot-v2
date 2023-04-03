require "discordrb"
require "openai"
require "httparty"

require_relative "../lib/generic"
require_relative "../lib/google"
require_relative "../lib/openai"
require_relative "../lib/sourced/google_custom_search_api"

bot = Discordrb::Bot.new(token: ENV.fetch("BOT_TOKEN"))
openai_client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_TOKEN"))
google_api = true

bot.message(content: /#{quoted_prefix} image .+/i) do |event|
  image(event, google_api)
  google_api = !google_api
end

bot.message(content: /#{quoted_prefix} animate .+/i) do |event|
  animate(event, google_api)
  google_api = !google_api
end

bot.message(content: /#{quoted_prefix} (youtube|yt) .+/i) do |event|
  youtube(event)
end

bot.message(content: /#{quoted_prefix} chat.*/i) do |event|
  chat(bot, event, openai_client)
end

bot.message(content: /#{quoted_prefix} generate .+/i) do |event|
  generate(bot, event, openai_client)
end

bot.message do |event|
  random_chat(bot, event, openai_client)
end

bot.message(content: /.+ this/i) do |event|
  event.respond(":plumoji:")
end

bot.run
