class BookmarkCollection
  attr_accessor :bookmarks_bar, :other, :providers
  
  def initialize(providers)
    @bookmarks_bar = Folder.new("bookmarks_bar")
    @other = Folder.new("Other Bookmarks")
    @providers = providers
  end

  def load
    @providers.each do |provider|
      res = provider.load
      @bookmarks_bar.add_from_folder res["bar"]
      @other.add_from_folder res["other"]
    end
  end

  def save
    @providers.each do |provider|
      provider.save(self)
    end
  end

  def all(&block)
    @bookmarks_bar.all_children &block
    @other.all_children &block  
  end
end
