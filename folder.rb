class Folder
  attr_accessor :children, :name
  def initialize(name)
    @name = name
    @children = []
  end

  def contains_url(url)
    @children.each do |child|
      return true if child.respond_to?(:url) && child.url == url
    end
    false
  end

  def contains_folder(name)
    @children.each do |child|
      return true if !child.respond_to?(:url) && child.name == name
    end
    false
  end

  def add_from_folder(folder)
    unless folder.nil?
      folder.children.each do |item|
        if (item.respond_to?(:url)) # we've got a url
          # TODO only checking folder name
          # should compare folder contents as well
          self.children.push(item) unless self.contains_url item.url
        else # a folder
          self.children.push(item) unless self.contains_folder item.name
        end
      end
    end
  end

  def add_from_array(arr)
    arr.each do |item|
      if (item.respond_to?(:url)) # we've got a url
        self.children.push(item) unless self.contains_url item.url
      else # a folder
        self.children.push(item) unless self.contains_folder item.name
      end
    end
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
