class Resource
  def initialize(hash)
    @attributes = {}
    hash.each do |k,v|
      self.send("#{k}=", v)
    end
  end
  
  def id
    @attributes['id']
  end
  
  def id=(value)
    @attributes['id'] = value
  end
  
  def method_missing(m, v=nil)
    if m.to_s =~ /(.*)=$/
      @attributes[$1] = v
    else
      if @attributes.has_key?(m.to_s)
        @attributes[m.to_s]
      else
        raise NoMethodError, "We don't know anything about #{m}"
      end
    end
  end
  
  alias_method :old_respond_to?, :respond_to?
  def respond_to?(m)
    old_respond_to?(m) or @attributes.has_key?(m.to_s)
  end
end
