# -*- coding: utf-8 -*-
require 'rubygems'
require 'open-uri'
require 'uri'

module Memo3
  def Memo3.addgyazz(name, host=nil)
    name = URI.encode(name)
    url = "http://3memo.com/addgyazz/#{name}"
    url = "http://#{host}.3memo.com/addgyazz/#{name}" if host
    open(url).read.to_s
  end

end
