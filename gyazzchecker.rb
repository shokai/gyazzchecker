#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$:.unshift(File.dirname(__FILE__)+'/lib') unless
  $:.include?(File.dirname(__FILE__)+'/lib') || $:.include?(File.expand_path(File.dirname(__FILE__)+'/lib'))

require 'gyazz'
require 'im-kayac'
require 'rubygems'
require 'tokyocabinet'
include TokyoCabinet

if ARGV.size < 2
  puts 'ruby gyazzchecker.rb searchword im.kayac-username'
  exit 1
end
name = ARGV.shift # searchword
im_kayac = ARGV.shift

pages = HDB.new
pages.open(File.dirname(__FILE__)+"/#{name}.tch", HDB::OWRITER|HDB::OCREAT)

Gyazz.search(name)[0...10].each{|page|
  puts title = page[:title]
  data = Gyazz.getdata(name, title)
  if pages[title] == nil
    pages[title] = data
    puts data
    ImKayac.send(im_kayac, "http://gyazz.com/#{name}/#{title}\n #{data}")
  else
    changed, diff = Gyazz.diff(pages[title], data)
    if changed
      pages[title] = data
      puts diff
      ImKayac.send(im_kayac, "newpage http://gyazz.com/#{name}/#{title}\n #{diff}")
    end
  end
  sleep 10
}

pages.close
