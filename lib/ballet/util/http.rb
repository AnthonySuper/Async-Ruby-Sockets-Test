require 'net/http'

module Ballet::Util
  class HTTP
    def self.get(*args)
      CheapAsync.perform do
        Net::HTTP.get(*args)
      end
    end
  end
end
