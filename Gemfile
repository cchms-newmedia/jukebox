# coding: utf-8
source "http://rubygems.org"

group :test do
  gem "rspec"
  gem "guard-rspec"
  case RUBY_PLATFORM
  when /darwin/i
    gem "rb-fsevent"
  when /linux/i
    gem "rb-inotify"
  end
end

group :development do
  gem 'shotgun'
end

gem "rb-appscript"

gem "sinatra"
gem "thin"

gem "sprockets"

# http://twitter.com/#!/r7kamura/status/199895369457479683
# $B;O$^$j$N8f;02H(B - the three beginnings
gem "haml"
gem "sass"
gem "coffee-script"
