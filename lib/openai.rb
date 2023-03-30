SYSTEM_ROLE_CONTENT = "
Pretend you are a Chroniko's bot called Rubine
You have a teenage mean girl personality and you speak in a condescending tone of superiority
Use a mix of valley girl slang and ojou-sama slang
Keep the response short
Reply as if you were making conversation
Given the following conversation, how would you jump in and contribute?
"

def chat(bot, event, openai_client)
  response = openai_client.chat(
    parameters: {
      model: "gpt-3.5-turbo",
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
      prompt: key,
      size: "1024x1024"
    })
  event.respond(response.dig("data", 0, "url"))
  bot.user(ENV.fetch("OWNER_ID")).pm(event.message.link)
end

def random_chat(bot, event, openai_client)
  chat(bot, event, openai_client) if rand < ENV.fetch("RANDOM_CHAT_CHANCE", "0.01").to_f
end

def context(event)
  messages = event.channel.history(30)
  messages.reject! {|m| clean_text(m.content).strip.empty?}
  messages.first(15).reverse.map do |message|
    "#{message.author.name}: #{sanitize_emoji(clean_text(message.content))}"
  end
end

def clean_text(content)
  content.gsub(/^#{quoted_prefix} chat ?(.*)/, '\1')
end

def sanitize_emoji(content)
  content.gsub(/<(:.+:)[0-9]+>/, '\1')
end
