require 'cfpropertylist'
require 'json'
require './util'

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

class BookmarkCollection
  attr_accessor :bookmarks_bar, :other
  def initialize
    @bookmarks_bar = Folder.new("bookmarks_bar")
    @other = Folder.new("Other Bookmarks")
    @blacklist = ["BookmarksMenu", "Address Book", "Bonjour", "All RSS Feeds", "BookmarksBar"]
    #@safari_outline = 
  end

  def add_chrome(hash)
    bookmarks_bar = Folder.new_chrome(hash["roots"]["bookmark_bar"])
    @bookmarks_bar.add_from_folder bookmarks_bar
    other = Folder.new_chrome(hash["roots"]["other"])
    @other.add_from_folder other
  end

  def add_safari(hash)
    index = 0
    @outline = hash
    hash["Children"].each_index do |i|
      if hash["Children"][i]["Title"] == "BookmarksBar"
        index = i
      end
    end
    bookmarks_bar = Folder.new_safari(hash["Children"][index])
    @bookmarks_bar.add_from_folder bookmarks_bar
    all = hash["Children"].dup
    toremove = []
    all.each do |item|
      if (!item["WebBookmarkIdentifier"].nil? || @blacklist.include?(item["Title"]))
        toremove.push(item)
      end
    end
    bookmarks = all - toremove
    toremove.delete_at(index)
    @extra = toremove
    toadd = []
    bookmarks.each do |bookmark|
      if bookmark["WebBookmarkType"] == "WebBookmarkTypeLeaf" 
        toadd.push(Bookmark.new_safari(bookmark))
      else
        toadd.push(Folder.new_safari(bookmark))
      end
    end
    @other.add_from_array toadd
  end

  def render_json
    ret = Hash.new
    ret["checksum"] = ""
    ret["version"] = 1
    ret["roots"] = Hash.new
    ret["roots"]["bookmark_bar"] = @bookmarks_bar.chrome_hash
    ret["roots"]["other"] = @other.chrome_hash
    ret.to_json
  end

  def render_plist
    @outline["Children"] = []
    @outline["Children"].push(@bookmarks_bar.safari_hash) #First, as per Safari's preference
    @extra.each do |item| 
      @outline["Children"].push item #Second, once again like Safari likes
    end
    @other.children.each do |item|
      @outline["Children"].push item.safari_hash #And finally everything else
    end
    plist = CFPropertyList::List.new
    plist.value = CFPropertyList.guess(@outline) # data is native ruby structure
    plist
##plist.save(safariplistfile, CFPropertyList::List::FORMAT_BINARY)
  end

  def all_children(&block)
    @bookmarks_bar.all_children &block
    @other.all_children &block  
  end
  
end

safariplistfile = '~/Library/Safari/Bookmarks.plist'
chromejsonfile = '~/Library/Application Support/Google/Chrome/Default/Bookmarks'
safaricachepath = '~/Library/Caches/Metadata/Safari/Bookmarks/'

safariplistfile.gsub!('~', ENV["HOME"])
chromejsonfile.gsub!('~', ENV["HOME"])
safaricachepath.gsub!('~', ENV["HOME"])


# You could do this and then parse the xml by hand to remove the dependency
# but gems are so much easier :)
#xml = IO.popen("plutil -convert xml1 #{safariplistfile} -o -")

plist = CFPropertyList::List.new(:file => safariplistfile)
data = CFPropertyList.native_types(plist.value)

json = JSON.parse(File.open(chromejsonfile).read)

bar = json["roots"]["bookmark_bar"]
other = json["roots"]["other"]





bc = BookmarkCollection.new
bc.add_chrome json
bc.add_safari data

File.open(chromejsonfile, 'w') do |file|  
  file.puts(bc.render_json)
end
bc.render_plist.save(safariplistfile, CFPropertyList::List::FORMAT_BINARY)

#Dir.glob(safaricachepath + "*").each do |name|
#  File.delete(name)
#end

#bc.all_children do |bookmark|
#  hash = bookmark.safari_cache_hash
#  name = "#{safaricachepath}#{bookmark.uuid}.webbookmark"
#  plist = CFPropertyList::List.new
#  plist.value = CFPropertyList.guess(hash) # data is native ruby structure
#  plist.save(name, CFPropertyList::List::FORMAT_BINARY)
#end
