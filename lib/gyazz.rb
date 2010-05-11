#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'uri'
require 'open-uri'
require 'hpricot'
require 'kconv'
require 'diff/lcs'

module Gyazz

  def Gyazz.search(name)
    page = open("http://gyazz.com/#{URI.encode(name)}/").read.toutf8
    links = Hpricot(page)/:a
    links.map{|i|
      {:url => i[:href].to_s, :title => i.inner_html.to_s}
    }
  end

  def Gyazz.getdata(name, title)
    lines = open("http://gyazz.com/programs/getdata.cgi?name=#{URI.encode(name)}&title=#{URI.encode(title)}&version=0").read.toutf8
  end

  def Gyazz.diff(a, b)
    diffs = Diff::LCS.sdiff(a.split(/\n/),b.split(/\n/))
    changed = false
    str = ""
    diffs.each{|d|
      if d.old_element == d.new_element
        str += " #{d.old_element}\n"
      else
        str += "*-#{d.old_element}*\n" if d.old_element and d.old_element.size>0
        str += "*+#{d.new_element}*\n" if d.new_element and d.new_element.size>0
        changed = true
      end
    }
    return changed, str
    
  end

end
