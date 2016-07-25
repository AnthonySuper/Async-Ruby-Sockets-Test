require_relative './event_manager.rb'
require_relative './delay_value.rb'
require_relative './async_http.rb'
require 'uri'
require 'json'


def get_board(name)
  u = URI("https://a.4cdn.org/#{name}/catalog.json")
  return JSON.parse(AsyncHTTP.get(u).await)
end

def get_board_names
  board_uri = URI("https://a.4cdn.org/boards.json")
  resp = JSON.parse(AsyncHTTP.get(board_uri).await)
  resp["boards"].map{|h| h["board"]}
end

EventManager.run do
  async do
    board_names = get_board_names
    board_names.each do |name|
      async do
        length = get_board(name).length
        puts "The board #{name} has #{length} pages currently"
        puts DelayValue.give_after_delay("This is weird", 3).await
      end
    end
   end

  async do
    puts DelayValue.give_after_delay("Another", 2).await
    puts DelayValue.give_after_delay("Something else", 4).await
  end

  async do
    puts DelayValue.give_after_delay("Delayed value", 2).await
  end
  
end
