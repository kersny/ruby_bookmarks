class BookmarkCollection
  attr_accessor :bookmarks_bar, :other
  def initialize
    @bookmarks_bar = Folder.new("bookmarks_bar")
    @other = Folder.new("Other Bookmarks")
  end

  def all_children(&block)
    @bookmarks_bar.all_children &block
    @other.all_children &block  
  end
  
end
