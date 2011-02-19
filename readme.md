ruby_bookmarks
==============

ruby_bookmarks is a framework for handling bookmarks from various browsers, currently only on OS X.

Its pretty simple to use:

	require './util'
	require './bookmark'
	require './folder'
	require './bookmarkcollection'
	
	require './chrome'
	require './safari'
	
	include Chrome
	include Safari
	
	bc = BookmarkCollection.new([ChromeProvider.new, SafariProvider.new])
	bc.load # Loads in all bookmarks from Safari & Chrome 
  	
	bc.bookmarks_bar.each do |item|
		#iterates through the bookmark bar
	end
  	
	bc.other.each do |item|
	  #iterates through the other bookmarks
	end
	
	bc.all do |item|
	  #iterates thorugh all bookmarks
	end
	 
	bc.save # Saves the combined bookmarks both Chrome and Safari


*What needs work*
-----------------

- Firefox, Opera support
- Cross platform support
- More methods on BookmarkCollection to support adding, modifying, and such
