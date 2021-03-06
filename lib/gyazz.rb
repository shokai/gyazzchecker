#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'uri'
require 'open-uri'
require 'hpricot'
require 'kconv'
require 'diff/lcs'

module Gyazz

  def Gyazz.search(name, http_opt={})
    page = http_opt ? open("http://gyazz.com/#{URI.encode(name)}/", http_opt).read.toutf8 :
      open("http://gyazz.com/#{URI.encode(name)}/").read.toutf8
    links = Hpricot(page)/:a
    links.map{|i|
      {:url => i[:href].to_s, :title => i.inner_html.to_s}
    }
  end

  def Gyazz.getdata(name, title, http_opt={})
    http_opt ? open("http://gyazz.com/#{URI.encode(name)}/#{URI.encode title}/text", http_opt).read.toutf8 :
      open("http://gyazz.com/#{URI.encode(name)}/#{URI.encode title}/text").read.toutf8
  end

  def Gyazz.diff(a, b)
    diffs = Diff::LCS.sdiff(a.split(/[\r\n]/), b.split(/[\r\n]/))
    changed = false
    str = ""
    diffs.each{|d|
      if d.old_element == d.new_element
        str += " #{d.old_element}\n"
      else
        str += "-#{d.old_element}\n" if d.old_element and d.old_element.size>0
        str += "+#{d.new_element}\n" if d.new_element and d.new_element.size>0
        changed = true
      end
    }
    return changed, str
  end

  def Gyazz.newlines(a, b)
    diffs = Diff::LCS.sdiff(a.split(/[\r\n]/), b.split(/[\r\n]/))
    new_lines = Array.new
    diffs.each{|d|
      next if d.old_element == d.new_element
      line = d.new_element.to_s
      new_lines << line if line.size > 0 and !(line =~ /^\s+$/)
    }
    new_lines
  end

end
