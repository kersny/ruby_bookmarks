require 'cfpropertylist'

module Safari
  class SafariProvider
    def load(filename='~/Library/Safari/Bookmarks.plist')
      if filename.include? '~'
        filename.gsub!('~', ENV["HOME"])
      end
      plist = CFPropertyList::List.new(:file => filename)
      data = CFPropertyList.native_types(plist.value)
      @other = data
      index = 0
      data["Children"].each_index do |i|
        if data["Children"][i]["Title"] == "BookmarksBar"
          index = i
        end
      end

      bookmarks_bar = SafariFolder.new_from_hash(data["Children"][index])
      all = data["Children"].dup
      toremove = []
      all.each do |item|
        if (!item["WebBookmarkIdentifier"].nil? || 
          ["BookmarksMenu", "Address Book", "Bonjour", "All RSS Feeds", "BookmarksBar"].include?(item["Title"]))
          toremove.push(item)
        end
      end
      bookmarks = all - toremove
      toremove.delete_at(index)
      @extra = toremove
      toadd = []
      bookmarks.each do |bookmark|
        if bookmark["WebBookmarkType"] == "WebBookmarkTypeLeaf" 
          toadd.push(SafariBookmark.new_from_hash(bookmark))
        else
          toadd.push(SafariFolder.new_from_hash(bookmark))
        end
      end
      other = Folder.new("Other Bookmarks")
      other.add_from_array toadd
      return {"bar" => bookmarks_bar, "other" => other}
    end

    def save(collection, filename='~/Library/Safari/Bookmarks.plist')
      if filename.include? '~'
        filename.gsub!('~', ENV["HOME"])
      end
      outline = @other.dup
      outline["Children"] = []
      outline["Children"].push(folder_to_hash(collection.bookmarks_bar)) #First, as per Safari's preference
      @extra.each do |item| 
        outline["Children"].push item #Second, once again like Safari likes
      end
      collection.other.children.each do |item|
        if item.respond_to?(:url)
          outline["Children"].push(bookmark_to_hash(item))
        else
          outline["Children"].push(folder_to_hash(item))
        end
      end
      plist = CFPropertyList::List.new
      plist.value = CFPropertyList.guess(outline) # data is native ruby structure
      plist.save(filename, CFPropertyList::List::FORMAT_BINARY)
    end

    private

    def folder_to_hash(folder)
      ret = Hash.new
      if folder.name =="bookmarks_bar"
        folder.name = "BookmarksBar"
      end
      ret["Title"] = folder.name
      ret["WebBookmarkType"] = "WebBookmarkTypeList"
      ret["WebBookmarkUUID"] = folder.respond_to?(:uuid) ? folder.uuid : Apple.new_uuid
      children = Array.new
      folder.children.each do |item|
        if item.respond_to?(:url)
          children.push(bookmark_to_hash(item))
        else
          children.push(folder_to_hash(item))
        end
      end
      ret["Children"] = children
      ret
    end

    def bookmark_to_hash(bookmark)
      return {"URIDictionary" => {"title" => bookmark.name},
      "URLString" => bookmark.url, "WebBookmarkType" => "WebBookmarkTypeLeaf", "WebBookmakUUID" => bookmark.respond_to?(:uuid) ? bookmark.uuid : Apple.new_uuid}
    end

    def bookmark_to_cache_hash(bookmark)
      return { "Name" => bookmark.name, "URL" => bookmark.url }
    end
  end

  class SafariBookmark < Bookmark
    attr_accessor :uuid

    def initialize(name, url, uuid)
      @uuid = uuid
      super(name, url)
    end

    def SafariBookmark.new_from_hash(hash)
      return self.new(hash["URIDictionary"]["title"], hash["URLString"], hash["WebBookmakUUID"])
    end
  end

  class SafariFolder < Folder
    attr_accessor :uuid

    def initialize(name, uuid)
      @uuid = uuid
      super(name)
    end

    def SafariFolder.new_from_hash(hash)
      folder = self.new(hash["Title"], hash["WebBookmarkUUID"])
      if hash["Children"]
        hash["Children"].each do |item|
          if item["WebBookmarkType"] == "WebBookmarkTypeList"
            folder.children.push(self.new_from_hash(item))
          elsif item["type"] == "WebBookmarkTypeLeaf"
            folder.children.push(SafariBookmark.new_from_hash(item))
          end
        end
      end
      return folder
    end
  end
end
