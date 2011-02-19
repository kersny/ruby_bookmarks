require './util'
require './bookmark'
require './folder'
require './bookmarkcollection'

require './chrome'
require './safari'

include Chrome
include Safari

bc = BookmarkCollection.new([ChromeProvider.new, SafariProvider.new])
bc.load
bc.save

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
