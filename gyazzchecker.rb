#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$:.unshift(File.dirname(__FILE__)+'/lib') unless
  $:.include?(File.dirname(__FILE__)+'/lib') || $:.include?(File.expand_path(File.dirname(__FILE__)+'/lib'))

require 'gyazz'
require 'im-kayac'
require 'rubygems'
require 'yaml'
require 'tokyocabinet'
include TokyoCabinet

if ARGV.size < 1
  puts 'ruby gyazzchecker.rb searchword'
  exit 1
end

begin
  config = YAML::load open(File.dirname(__FILE__) + '/config.yaml')
rescue
  puts 'config.yaml not found'
  exit 1
end
p config

name = ARGV.shift # searchword

pages = HDB.new
pages.open(File.dirname(__FILE__)+"/#{name}.tch", HDB::OWRITER|HDB::OCREAT)

Gyazz.search(name)[0...10].each{|page|
  puts title = page[:title]
  data = Gyazz.getdata(name, title)
  if pages[title] == nil
    pages[title] = data
    puts data
    config['im_kayac_users'].each{|im_user|
      ImKayac.send(im_user, "newpage http://gyazz.com/#{name}/#{title}\n #{data}")
    }
  else
    Gyazz.newlines(pages[title], data).each{|line|
      puts line
      config['im_kayac_users'].each{|im_user|
        ImKayac.send(im_user, "http://gyazz.com/#{name}/#{title}\n #{line}")
        sleep 3
      }
    }
    #pages[title] = data
  end
  sleep 10
}

pages.close
