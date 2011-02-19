class Folder
  attr_accessor :children, :name, :id, :uuid, :date_added, :date_modified
  def initialize(name, id=nil, idtype=nil, date_added=Time.now.ticks, date_modified=Time.now.ticks)
    @name = name
    if (idtype == Bookmark::Chrome)
      @id = id
    elsif (idtype == Bookmark::Safari)
      @uuid = id
    end
    @date_added = date_added
    @date_modified = date_modified
    @children = []
  end

  def id
    if @id.nil?
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

  def self.new_chrome(hash)
    folder = self.new(hash["name"], hash["id"], Bookmark::Chrome, hash["date_added"], hash["date_modified"])
    hash["children"].each do |item|
      if item["type"] == "folder"
        folder.children.push(self.new_chrome(item))
      elsif item["type"] == "url"
        folder.children.push(Bookmark.new_chrome(item))
      end
    end
    return folder
  end

  def self.new_safari(hash)
    unless hash.empty?
      folder = self.new(hash["Title"], hash["WebBookmarkUUID"], Bookmark::Safari)
      if hash["Children"]
        hash["Children"].each do |item|
          if item["WebBookmarkType"] == "WebBookmarkTypeList"
            folder.children.push(self.new_safari(item))
          elsif item["type"] == "WebBookmarkTypeLeaf"
            folder.children.push(Bookmark.new_safari(item))
          end
        end
      end
      return folder
    end
    return nil
  end

  def contains_url(url)
    @children.each do |child|
      return true if child.respond_to?(:url) && child.url == url
    end
    false
  end

  def contains_folder(name)
    @children.each do |child|
      return true if child.respond_to?(:date_modified) && child.name == name
    end
    false
  end

  def add_from_folder(folder)
    unless folder.nil?
      folder.children.each do |item|
        if (item.respond_to?(:date_modified)) # we've got a url
          # TODO only checking folder name
          # should compare folder contents as well
          self.children.push(item) unless self.contains_folder item.name
        else # a folder
          self.children.push(item) unless self.contains_url item.url
        end
      end
    end
  end

  def add_from_array(arr)
    arr.each do |item|
      if (item.respond_to?(:date_modified)) # we've got a folder
        self.children.push(item) unless self.contains_folder item.name
      else # a url
        self.children.push(item) unless self.contains_url item.url
      end
    end
  end

  def chrome_hash
    ret = Hash.new
    ret["type"] = "folder"
    ret["id"] = self.id
    ret["name"] = @name
    ret["date_added"] = @date_added
    ret["date_modified"] = @date_modified
    children = Array.new
    @children.each do |item|
      children.push(item.chrome_hash)
    end
    ret["children"] = children
    ret
  end

  def safari_hash
    ret = Hash.new
    if @name=="bookmarks_bar"
      @name = "BookmarksBar"
    end
    ret["Title"] = @name
    ret["WebBookmarkType"] = "WebBookmarkTypeList"
    ret["WebBookmarkUUID"] = self.uuid
    children = Array.new
    @children.each do |item|
      children.push(item.safari_hash)
    end
    ret["Children"] = children
    ret
  end

  def all_children(&block)
    @children.each do |item|
      if (item.respond_to?(:date_modified)) # we've got a folder
        item.all_children &block
      else
        yield item
      end
    end
  end
 
end
