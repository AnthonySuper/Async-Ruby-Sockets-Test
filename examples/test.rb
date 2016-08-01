require 'uri'
require 'json'
require 'bundler'

Bundler.require

def get_board(name)
  u = URI("https://a.4cdn.org/#{name}/catalog.json")
  return Ballet::Util::HTTP.get(u)
end

def get_board_names
  board_uri = URI("https://a.4cdn.org/boards.json")
  resp = JSON.parse(Ballet::Util::HTTP.get(board_uri).await)
  resp["boards"].map{|h| h["board"]}
end

def post_time(json)
  Time.at(json["time"].to_i)
end

def threadinfo(json)
  puts "\tTime \t #{post_time(json)}"
  puts "\tName \t #{json["name"]}"
  puts "\tSubject \t #{json["sub"]}"
  puts "\tReplies \t #{json["replies"]}"
  puts "\tImages \t #{json["images"]}"
end


Ballet::EventManager.run do
  async do
    board_names = get_board_names
    promises = board_names.map{|n| get_board(n)}
    responses = Ballet::Promise.all(promises).await.map{|r| JSON.parse(r)}
    threads = responses.flatten.map{|r| r["threads"]}.flatten
    oldest, newest = threads.minmax do |a, b|
      a["time"].to_i <=> b["time"].to_i
    end
    puts "Oldest thread created on #{oldest["time"]}"
    threadinfo(oldest)
    puts "Newest thread created on #{newest["time"]}"
    threadinfo(newest)
  end

  async do
    puts Ballet::Util::DelayValue.give_after_delay("Another", 2).await
    d2 = Ballet::Util::DelayValue.give_after_delay("Something else", 4)
    puts d2.await
  end

  async do
    p = Ballet::Util::DelayValue.give_after_delay("Delayed value", 2)
    puts p.await
  end
end
