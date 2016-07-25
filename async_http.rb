require_relative './promise'
require_relative './cheap_async'
require 'net/http'

module AsyncHTTP
  def self.get(*args)
    CheapAsync.perform do |promise|
      begin
        promise.resolve!(Net::HTTP.get(*args))
      rescue Exception => e
        promise.reject!(e)
      end
    end
  end
end
