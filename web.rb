#coding: utf-8

require 'sinatra'
require 'sinatra/content_for'
require 'unidecoder'
require 'json'
require 'haml'
require 'csv'
require 'pp'
require './lib/util.rb'

$session = nil
$mapping = JSON.parse(File.read("#{Dir.pwd}/lib/mapping.json"))

get "/?" do 
  haml :index
end

get "/thanks/?" do 
  haml :thanks
end

post "/log/?" do 
  File.open("#{Dir.pwd}/public/output/#{Date.strptime(params["date"],"%b %d, %Y").strftime("%Y%m%d")}-engine_log.json","w") do |file|
    file << JSON.pretty_generate(parse params) #.gsub(/\n/,"<br/>").gsub(/\s/,"&nbsp; ")
  end
  return redirect to :thanks
end

not_found do 
  redirect to "/"
end

error do 
  return haml :error
end

$content = []
$cats = {}
$cnms = {}
$sitename = "MYEZ Engine Room Log"
$title = $sitename
$domain = "//daylog.myez.gl3"
$description = ""

def parse pa
  re = {}
  pa.each do |k,v|
    if ["date","user"].include? k
      re[k] = v
    elsif ["notes"].include? k
      re[k] = " \n#{v}"
    else
      ro, sy, me = *k.split("_")
      re[ro] = {} unless re.has_key?(ro)
      re[ro][sy] = {} unless re[ro].has_key?(sy)
      re[ro][sy][me] = v
    end
  end
  re
end
