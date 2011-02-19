class Bookmark
  attr_accessor :url, :name
  def initialize(name, url)
    @name = name
    @url = url
  end
end
