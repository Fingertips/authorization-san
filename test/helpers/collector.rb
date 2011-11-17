class Collector
  attr_accessor :lines
  
  def initialize
    @lines = []
  end
  
  def write(line)
    @lines << line
  end
  
  def puts(line)
    write("#{line}\n")
  end
end