module Apple
  def Apple.new_uuid
    uuid = ""
    IO.popen("uuidgen") {|io| uuid = io.read.chomp }
    uuid
  end
end

class Time
  def ticks
    # there are 1*10^9 nanoseconds in a second
    # but 100 nanoseconds in a tick
    return (self.tv_sec * (1 * 10**9) + self.tv_nsec) / 100;
  end
end
