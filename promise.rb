require 'fiber'

class Promise
  def initialize
  end

  def resolve!(val)
    if EventManager.has_listener? self
      EventManager.broadcast(self, [:ok, val])
    else
      @value = [:ok, val]
    end
  end

  def reject!(except)
    if EventManager.has_listener? self
      EventManager.broadcast(self, [:bad, val])
    else
      @value = [:bad, val]
    end
  end

  def await
    EventManager.current.listen(self, Fiber.current)
    status, val = get_value
    if status == :bad
      raise val
    else
      val
    end
  end

  private

  def get_value
    if @value
      value
    else
      EventManager.transfer_fiber.transfer
    end
  end

end
