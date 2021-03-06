#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
Dir.glob(File.dirname(__FILE__)+'/lib/*.rb').each{|f|
  require f
}
require 'rubygems'
require 'bundler/setup'
require 'im-kayac'
require 'yaml'
require 'tokyocabinet'
include TokyoCabinet
require 'twitter'
require 'uri'

cmd = ARGV.first

begin
  config = YAML::load open(File.dirname(__FILE__) + '/config.yaml')
rescue
  puts 'config.yaml not found'
  exit 1
end
p config

name = config['gyazz']

pages = HDB.new
pages.open(File.dirname(__FILE__)+"/#{name}.tch", HDB::OWRITER|HDB::OCREAT)

tw = nil
unless config['no_tweet']
  begin
    Twitter.configure do |c|
      c.consumer_key = config['consumer_key']
      c.consumer_secret = config['consumer_secret']
      c.oauth_token = config['access_token']
      c.oauth_token_secret = config['access_secret']
    end
  rescue => e
    STDERR.puts e
  end
end

if config['gyazz_user'] and config['gyazz_pass']
  http_opt = {
    :http_basic_authentication => [config['gyazz_user'], config['gyazz_pass']]
  }
end

if cmd == "all"
  page_list = Gyazz.search(name,http_opt)
else
  page_list = Gyazz.search(name,http_opt)[0...10]
end

page_list.each{|page|
  puts title = page[:title]

  data = Gyazz.getdata(name, title, http_opt)
  if pages[title] == nil
    pages[title] = data
    puts data
    begin
      gyazz_url = "http://gyazz.com/#{name}/#{title}"
      message = "newpage 【#{title}】#{URI.encode gyazz_url} #{data}"
      Twitter.update(message[0...140]) if !config['no_tweet']
    rescue => e
      STDERR.puts e
      STDERR.puts 'twitter update error'
    end
    config['im_kayac_users'].each{|im_user|
      begin
        ImKayac.post(im_user, "newpage http://gyazz.com/#{name}/#{title}\n #{data}")
      rescue => e
        STDERR.puts e
        STDERR.puts "IM update (#{im_user}) error"
      end
    }
  else
    newlines = Gyazz.newlines(pages[title], data)
    pages[title] = data if newlines.size > 0
    for i in 0...newlines.size do
      puts line = newlines[i]
      config['im_kayac_users'].each{|im_user|
        begin
          ImKayac.post(im_user, "http://gyazz.com/#{name}/#{title}\n #{line}")
        rescue => e
          STDERR.puts e
          STDERR.puts "IM update (#{im_user}) error"
        end
        sleep 15/config['im_kayac_users'].size
      }
      next if i > 1 # 2 tweets per 1 page
      gyazz_url = "http://gyazz.com/#{name}/#{title}"
      message = "【#{title}】#{URI.encode gyazz_url} #{line}"
      begin
        Twitter.update(message[0...140]) if !config['no_tweet']
      rescue => e
        STDERR.puts e
        STDERR.puts 'twitter update error'
      end
    end
  end
  sleep 10
}

pages.close
