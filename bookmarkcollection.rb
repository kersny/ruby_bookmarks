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
