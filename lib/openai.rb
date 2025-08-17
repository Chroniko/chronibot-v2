SYSTEM_ROLE_CONTENT = "
Pretend you are a teenage girl called Rubine
You speak in a condescending tone with a tone of superiority
You use valley girl slang with faulty grammar including common social media abbreviations and acronyms
Don't talk about fashion and TikTok
Given the following conversation, how would you jump in and contribute?
Reply as if you were making conversation
Keep the response short
"

def ask(bot, event, openai_client)
  key = key(event.message.content, 2)
  response = openai_client.responses.create(
    parameters: {
      model: "gpt-5-nano",
      input: key,
      reasoning: { "effort": "low" },
      text: { "verbosity": "low" }
    })
  event.respond(response.dig("output", 1, "content", 0, "text"))
end

def gigaask(bot, event, openai_client)
  key = key(event.message.content, 2)
  response = openai_client.responses.create(
    parameters: {
      model: "gpt-5-nano",
      input: key,
      reasoning: { "effort": "high" },
      text: { "verbosity": "high" }
    })
  event.respond(response.dig("output", 1, "content", 0, "text"))
end

def chat(bot, event, openai_client)
  response = openai_client.responses.create(
    parameters: {
      model: "gpt-5-nano",
      input: "#{SYSTEM_ROLE_CONTENT}\n\n" +
          context(event).join("\n") +
          "\nRubine: ",
      reasoning: { "effort": "low" },
      text: { "verbosity": "low" }
    })
  event.respond(response.dig("output", 1, "content", 0, "text"))
end

def generate(bot, event, openai_client)
  key = key(event.message.content, 2)
  response = openai_client.images.generate(
    parameters: {
      model: "dall-e-3",
      prompt: key,
      size: "1024x1024"
    })
  File.open("/tmp/generated_image.jpg", "wb") do |f|
    f.write(HTTParty.get(response.dig("data", 0, "url")).body)
  end
  File.open("/tmp/generated_image.jpg", "r") do |f|
    event.channel.send_file(f)
  end
end

def random_chat(bot, event, openai_client)
  return unless allowed_random_chat_location?(event)
  return if event.message.content.start_with?(ENV.fetch("BOT_PREFIX"))
  chat(bot, event, openai_client) if rand < ENV.fetch("RANDOM_CHAT_CHANCE", "0.01").to_f
end

def allowed_random_chat_location?(event)
  ENV.fetch("ALLOWED_RANDOM_CHAT_SERVERS", "0").split(",").map(&:to_i).include?(event.server.id) ||
    ENV.fetch("ALLOWED_RANDOM_CHAT_CHANNELS", "0").split(",").map(&:to_i).include?(event.channel.id)
end

def context(event)
  messages = event.channel.history(30)
  messages.reject! {|m| clean_text(m.content).strip.empty?}
  messages.first(15).reverse.map do |message|
    "#{message.author.name}: #{sanitize_ping(sanitize_emoji(clean_text(message.content)), event)}"
  end
end

def clean_text(content)
  content.gsub(/^#{quoted_prefix} chat ?(.*)/i, '\1')
end

def sanitize_emoji(content)
  content.gsub(/<(:.+:)[0-9]+>/, '\1')
end

def sanitize_ping(content, event)
  content.gsub!(/<@(\d+)>/, '\1')
  user = event.server.member(Regexp.last_match[1]) if Regexp.last_match
  return content unless user

  content.gsub(Regexp.last_match[1], user.name)
end
