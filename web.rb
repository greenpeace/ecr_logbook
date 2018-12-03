#coding: utf-8

require 'sinatra'
require 'sinatra/content_for'
require 'unicode_utils'
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

