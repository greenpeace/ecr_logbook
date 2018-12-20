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
$mapping = JSON.parse(File.read("#{Dir.pwd}/lib/mappings/mapping.json"))
$mapping_slug = JSON.parse(File.read("#{Dir.pwd}/lib/mappings/mapping_slug.json"))
$lubrication = JSON.parse(File.read("#{Dir.pwd}/lib/mappings/lubrication.json"))

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
  @enabledDates = get_dates.to_json
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
  e = parse_mapping
  if e == true
    "ok" 
  else 
    `mv #{oldfile} #{Dir.pwd}/lib/mappings/mapping.csv`
    e
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
  if parse_mapping
    "ok" 
  else 
    `mv #{oldfile} #{Dir.pwd}/lib/mappings/lubrication.csv`
    "error"
  end
end

post "/edit_previous/?" do 
  pass unless request.ip.match(/^192\.168\.212\.\d+/) or request.ip.match(/^127\.0\.0\.1/)
  unparse JSON.parse(File.read("#{Dir.pwd}/public/output/#{params["date"].gsub("-","")}-engine_log.json"))
end

not_found do 
  redirect to "/"
end

error do 
  @error = env['sinatra.error']
  return haml :error
end

$shipname = "Esperanza"
$shipabbr = "MYEZ"
$shipnick = "Espy"
$sitename = "#{$shipabbr} Engine Room Log"
$title = $sitename
$domain = "//daylog.myez.gl3"
$description = ""

def parse pa
  re = {}
  on = $mapping_slug.keys.map{|k|[k,[]]}.to_h
  row = [pa["user"]]
  pa.each do |k,v|
    next unless v and v.to_s.length > 0
    ro, sy, me = *k.split("_")
    if ["date","user"].include? k
      re[k] = v
    elsif ["notes"].include? k
      re[k] = " \n#{v}"
    elsif ["lube"].include? k
      re[k] = v
    elsif me == "is-currently-working" and v == "on"
      on[ro] << sy
    elsif on[ro].include? sy
      re[ro] = {} unless re.has_key?(ro)
      re[ro][sy] = {} unless re[ro].has_key?(sy)
      re[ro][sy][me] = v
      row[$mapping_slug[ro][sy][me]["mid"].to_i] = v if me
    end
  end
  row.unshift Time.now.to_i
  CSV.open("#{Dir.pwd}/public/output/engine_log.csv", "a") do |csv|
    csv << row
  end
  re
end

def unparse pa
  re = []
  lube = []
  pa.each do |room,sys|
    if room == "lube"
      sys.each_with_index do |lub,ind|
        lube << [lub["room"],[{:name=>"unit",:value=>lub["unit"]},{:name=>"type",:value=>lub["type"]},{:name=>"amount",:value=>lub["amount"]}]]
      end
    elsif sys.is_a? Hash
      sys.each do |system, meas|
        meas.each do |measurement, value|
          re << "#{[room,system,measurement].join("_")}=#{value}"
        end
      end
    elsif sys.is_a? String
      re << "#{room}=#{sys}"
    end
  end
  [re.join("&"),lube].to_json
end
