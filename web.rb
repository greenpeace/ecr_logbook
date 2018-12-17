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
$shipname = "Esperanza"
$shipnick = "Espy"
$mapping = JSON.parse(File.read("#{Dir.pwd}/lib/mappings/mapping.json"))
$lubrication = JSON.parse(File.read("#{Dir.pwd}/lib/mappings/lubrication.json"))
pp $lubrication

get "/?" do 
  haml :index
end

post "/log/?" do 
  pp params
  File.open("#{Dir.pwd}/public/output/#{Date.strptime(params["date"],"%b %d, %Y").strftime("%Y%m%d")}-engine_log.json","w") do |file|
    file << JSON.pretty_generate(parse params) #.gsub(/\n/,"<br/>").gsub(/\s/,"&nbsp; ")
  end
  return redirect to :thanks
end

get "/newlube/?" do 
  @room = params["room"]
  pass unless $lubrication.keys.map(&:slug).include?(@room)
  @data = {}
  $lubrication.each do |k,v|
    next unless k.slug == params["room"]
    @data["units"] = v
    break
  end
  @data["oils"] = $lubrication["oils"]
  haml :lube, :layout => false
end

get "/thanks/?" do 
  haml :thanks
end

get "/admin/?" do 
  pass unless request.ip.match(/^192\.168\.212\.\d+/) or request.ip.match(/^127\.0\.0\.1/)
  dates = []
  Dir.foreach("#{Dir.pwd}/public/output") do |file|
    if file.match(/\.json$/)
      date = file.match(/^\d{8}/)[0]
      dates << "#{date[0..3]}-#{date[4..5]}-#{date[6..7]}"
    end
  end
  @enabledDates = dates.to_json
  haml :admin
end

post "/download_log_sheet/?" do 
  pass unless request.ip.match(/^192\.168\.212\.\d+/) or request.ip.match(/^127\.0\.0\.1/)
  send_file output("#{Dir.pwd}/public/output/#{params["date"].gsub(/-/,'')}-engine_log.json"), filename: "#{params["date"].gsub(/-/,'')}-engine_log.json"
end

get "/current_layout/?" do 
  pass unless request.ip.match(/^192\.168\.212\.\d+/) or request.ip.match(/^127\.0\.0\.1/)
  send_file "#{Dir.pwd}/lib/layouts/layout.xlsx", filename: "layout.xlsx"
end

post "/update_layout/?" do 
  pass unless request.ip.match(/^192\.168\.212\.\d+/) or request.ip.match(/^127\.0\.0\.1/)
  oldfile = "#{Dir.pwd}/lib/layouts/old/layout_#{Time.now.strftime("%y%m%d%H%M%S")}.xlsx"
  `mv #{Dir.pwd}/lib/layouts/layout.xlsx #{oldfile}`
  `mv #{params['layout_file']['tempfile'].path} #{Dir.pwd}/lib/layouts/layout.xlsx`
  "ok" 
end

get "/current_mapping/?" do 
  pass unless request.ip.match(/^192\.168\.212\.\d+/) or request.ip.match(/^127\.0\.0\.1/)
  send_file "#{Dir.pwd}/lib/mappings/mapping.csv", filename: "mapping.csv"
end

post "/update_mapping/?" do 
  pass unless request.ip.match(/^192\.168\.212\.\d+/) or request.ip.match(/^127\.0\.0\.1/)
  oldfile = "#{Dir.pwd}/lib/mappings/old/mapping_#{Time.now.strftime("%y%m%d%H%M%S")}.csv"
  `mv #{Dir.pwd}/lib/mappings/mapping.csv #{oldfile}`
  `mv #{params['mapping_file']['tempfile'].path} #{Dir.pwd}/lib/mappings/mapping.csv`
  if parse_mapping
    "ok" 
  else 
    `mv #{oldfile} #{Dir.pwd}/lib/mappings/mapping.csv`
    "error"
  end
end

get "/current_lubrication/?" do 
  pass unless request.ip.match(/^192\.168\.212\.\d+/) or request.ip.match(/^127\.0\.0\.1/)
  send_file "#{Dir.pwd}/lib/mappings/lubrication.csv", filename: "lubrication.csv"
end

post "/update_lubrication/?" do 
  pass unless request.ip.match(/^192\.168\.212\.\d+/) or request.ip.match(/^127\.0\.0\.1/)
  oldfile = "#{Dir.pwd}/lib/mappings/old/lubrication_#{Time.now.strftime("%y%m%d%H%M%S")}.csv"
  `mv #{Dir.pwd}/lib/mappings/lubrication.csv #{oldfile}`
  `mv #{params['lubrication_file']['tempfile'].path} #{Dir.pwd}/lib/mappings/lubrication.csv`
  if parse_lubrication
    "ok" 
  else 
    `mv #{oldfile} #{Dir.pwd}/lib/mappings/lubrication.csv`
    "error"
  end
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
    elsif ["lube"].include? k
      re[k] = v
    else
      ro, sy, me = *k.split("_")
      re[ro] = {} unless re.has_key?(ro)
      re[ro][sy] = {} unless re[ro].has_key?(sy)
      re[ro][sy][me] = v
    end
  end
  re
end
