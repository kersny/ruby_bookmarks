require './util'
require './bookmark'
require './folder'
require './bookmarkcollection'

require './chrome'

include Chrome
include Safari

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
