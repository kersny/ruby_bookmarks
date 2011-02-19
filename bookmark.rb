class Bookmark
  Chrome = 0
  Safari = 1
  attr_accessor :url, :name, :date_added, :id, :uuid
  def initialize(name, url, id, idtype, date_added=Time.now.ticks)
    @name = name
    @url = url
    if (idtype == Chrome)
      @id = id
    elsif (idtype == Safari)
      @uuid = id
    end
    @date_added = date_added
  end

  def id
    if @id.nil? || @id.empty?
      @id = rand(300)
    end
    @id
  end

  def uuid
    if @uuid.nil? || @uuid.empty?
      @uuid = Apple.new_uuid
    end
    @uuid
  end

  def chrome_hash
    return { "type"=> "url", "id"=> self.id, "url"=> @url, "name" => @name, "date_added" => @date_added}
  end

  def safari_hash
    return {"URIDictionary" => {"title" => @name},
      "URLString" => @url, "WebBookmarkType" => "WebBookmarkTypeLeaf", "WebBookmakUUID" => self.uuid}
  end
  
  def self.new_chrome(hash)
    return self.new(hash["name"], hash["url"], hash["id"], Chrome, hash["date_added"])
  end

  def self.new_safari(hash)
    return self.new(hash["URIDictionary"]["title"], hash["URLString"], hash["WebBookmakUUID"], Safari)
  end

  def safari_cache_hash
    return { "Name" => @name, "URL" => @url }
  end
  
end
