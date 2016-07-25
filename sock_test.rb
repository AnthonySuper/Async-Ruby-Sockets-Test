require_relative './event_manager.rb'
require_relative './async_socket.rb'
require 'socket'

serv = Socket.new(:INET, :STREAM, 0)
serv.listen(5)
c = Socket.new(:INET, :STREAM, 0)
c.connect(serv.connect_address)

EventManager.run do
  async do
    AsyncSocket.use(c) do |sock|
      read = sock.read(1000).await
      puts "I read '#{read}'"
    end
  end

  async do
    s, info = serv.accept
    AsyncSocket.use(s) do |sock|
      res = sock.write(%q{
                       This is a test of socket writing.
                       I don't know how it works.
                       Maybe it doesn't!}).await
      puts res
    end
  end
end
