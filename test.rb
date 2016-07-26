require 'uri'
require 'json'

require_relative './lib/kitchen_sync.rb'

def get_board(name)
  u = URI("https://a.4cdn.org/#{name}/catalog.json")
  return JSON.parse(KitchenSync::Util::HTTP.get(u).await)
end

def get_board_names
  board_uri = URI("https://a.4cdn.org/boards.json")
  resp = JSON.parse(KitchenSync::Util::HTTP.get(board_uri).await)
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


KitchenSync::EventManager.run do
  async do
    board_names = get_board_names
    board_names.each do |name|
      async do
        info = get_board(name)
        threads = info.map{|i| i["threads"]}.flatten
        times = threads.map{|t| Time.at(t["time"].to_i)}
        oldest, newest = threads.minmax do |a, b|
          a["time"].to_i <=> b["time"].to_i
        end
        puts "---"
        puts "The oldest thread on /#{name}/ is no. #{oldest["no"]}"
        threadinfo(oldest)
        puts "The newest is no. #{newest["no"]}"
        threadinfo(newest)
        puts "---"
        puts
        puts
      end
    end
  end

  async do
    puts KitchenSync::Util::DelayValue.give_after_delay("Another", 2).await
    d2 = KitchenSync::Util::DelayValue.give_after_delay("Something else", 4)
    puts d2.await
  end

  async do
    p = KitchenSync::Util::DelayValue.give_after_delay("Delayed value", 2)
    puts p.await
  end
end
