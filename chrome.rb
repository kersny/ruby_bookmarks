require 'json'

module Chrome
  class Folder
    @providers << ChromeProvider
  end

  class ChromeProvider
    def ChromeProvider.load(filename='~/Library/Application Support/Google/Chrome/Default/Bookmarks')
      if filename.contains '~'
        filename.gsub!('~', ENV["HOME"])
      end
      json = JSON.parse(File.open(chromejsonfile).read)
      bookmarks_bar = ChromeFolder.new_from_hash(json["roots"]["bookmark_bar"])
      other = ChromeFolder.new_from_hash(json["roots"]["other"])
      return {"bar" => bookmarks_bar, "other" => other}
    end

    def ChromeProvider.save(collection, filename='~/Library/Application Support/Google/Chrome/Default/Bookmarks')
      if filename.contains '~'
        filename.gsub!('~', ENV["HOME"])
      end
      ret = Hash.new
      ret["checksum"] = ""
      ret["version"] = 1
      ret["roots"] = Hash.new
      ret["roots"]["bookmark_bar"] = folder_to_hash(collection.bookmarks_bar)
      ret["roots"]["other"] = folder_to_hash(collection.other)
      File.open(filename, 'w') do |file|  
        file.puts(ret.to_json)
      end
    end

    private

    def folder_to_hash(hash)
      ret = Hash.new
      ret["type"] = "folder"
      ret["id"] = hash.id || rand(300)
      ret["name"] = hash.name
      ret["date_added"] = hash.date_added || Time.now.ticks
      ret["date_modified"] = hash.date_modified || Time.now.ticks
      children = Array.new
      @children.each do |item|
        if item.responds?(:url)
          children.push(bookmark_to_hash(item))
        else
          children.push(folder_to_hash(item))
        end
      end
      ret["children"] = children
      ret
    end

    def bookmark_to_hash(bookmark)
      return { "type"=> "url", "id"=> bookmark.id || rand(300), "url"=> bookmark.url, "name" => bookmark.name, "date_added" => bookmark.date_added || Time.now.ticks }
    end
  end

  class ChromeBookmark << Bookmark
    attr_accessor :date_added, :id

    def initialize(name, url, id, date_added)
      @id = id
      @date_added = date_added
      super(name, url)
    end

    def ChromeBookmark.new_from_hash(hash)
      return self.new(hash["name"], hash["url"], hash["id"], hash["date_added"])
    end
  end

  class ChromeFolder << Folder
    attr_accessor :id, :date_added, :date_modified

    def initialize(name, id, date_added, date_modified)
      @id = id
      @date_added = date_added
      @date_modified = date_modified
      super(name)
    end

    def ChromeFolder.new_from_hash(hash)
      folder = self.new(hash["name"], hash["id"], hash["date_added"], hash["date_modified"])
      if hash["children"]
        hash["children"].each do |item|
          if item["type"] == "folder"
            folder.children.push(self.new_from_hash(item))
          elsif item["type"] == "url"
            folder.children.push(ChromeBookmark.new_from_hash(item))
          end
        end
      end
      return folder
    end
  end  
end
