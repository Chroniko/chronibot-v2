SYSTEM_ROLE_CONTENT = "
Pretend you are a teenage girl called Rubine
You speak in a condescending tone with a tone of superiority
You use valley girl slang with faulty grammar including common social media abbreviations and acronyms
Don't talk about fashion and TikTok
Given the following conversation, how would you jump in and contribute?
Reply as if you were making conversation
Keep the response short
"

def chat(bot, event, openai_client)
  response = openai_client.chat(
    parameters: {
      model: "gpt-4-1106-preview",
      messages: [{
        role: "user",
        content: "#{SYSTEM_ROLE_CONTENT}\n\n" +
          context(event).join("\n") +
          "\nRubine: "
      }],
      temperature: 0.7,
    })
  bot
    .user(ENV.fetch("OWNER_ID"))
    .pm("#{event.message.link}\n#{response.to_s}")
  event.respond(response.dig("choices", 0, "message", "content"))
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
  bot.user(ENV.fetch("OWNER_ID")).pm(event.message.link)
end

def random_chat(bot, event, openai_client)
  return unless allowed_random_chat_location?(event)
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
