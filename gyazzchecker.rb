#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$:.unshift(File.dirname(__FILE__)+'/lib') unless
  $:.include?(File.dirname(__FILE__)+'/lib') || $:.include?(File.expand_path(File.dirname(__FILE__)+'/lib'))

require 'gyazz'
require 'Memo3'
require 'im-kayac'
require 'rubygems'
require 'yaml'
require 'tokyocabinet'
include TokyoCabinet
require 'twitter'

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

tw_auth = Twitter::HTTPAuth.new(config["twitter_user"], config["twitter_pass"])
tw = Twitter::Base.new(tw_auth)

Gyazz.search(name)[0...10].each{|page|
  puts title = page[:title]
  data = Gyazz.getdata(name, title)
  if pages[title] == nil
    pages[title] = data
    puts data
    begin
      gyazz_url = Memo3.addgyazz("#{name}/#{title}", "mlab")
      message = "newpage #{name}/#{title} #{gyazz_url} #{data}"
      tw.update(message[0...140]) if !config['no_tweet']
    rescue
      puts 'twitter update error!'
    end
    config['im_kayac_users'].each{|im_user|
      ImKayac.send(im_user, "newpage http://gyazz.com/#{name}/#{title}\n #{data}")
    }
  else
    newlines = Gyazz.newlines(pages[title], data)
    pages[title] = data if newlines.size > 0
    gyazz_url = Memo3.addgyazz("#{name}/#{title}", "mlab")
    newlines.each{|line|
      puts line
      message = "#{name}/#{title} #{gyazz_url} #{line}"
      begin
        tw.update(message[0...140]) if !config['no_tweet']
      rescue
        puts 'twitter update error!'
      end
      config['im_kayac_users'].each{|im_user|
        ImKayac.send(im_user, "http://gyazz.com/#{name}/#{title}\n #{line}")
        sleep 3
      }
    }
  end
  sleep 10
}

pages.close
