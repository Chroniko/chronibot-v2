def key(content, i)
  content.split(' ')[i..-1].join(' ')
end

def quoted_prefix
  Regexp.quote(ENV.fetch("BOT_PREFIX"))
end
