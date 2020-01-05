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

get "/dash/?" do 
  haml :dash
end

post "/chart/?" do 
  pp params
  parse_csv(params["id"]).to_json
end

post "/log/?" do 
  begin 
    date = Date.strptime(params["date"],"%Y-%m-%d")
  rescue
    date = Date.strptime(params["date"],"%b %d, %Y")
  end
  File.open("#{Dir.pwd}/public/output/#{date.strftime("%Y%m%d")}-engine_log.json","w") do |file|
    file << JSON.pretty_generate(parse params) #.gsub(/\n/,"<br/>").gsub(/\s/,"&nbsp; ")
  end
  return "ack"
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
  @enabledDates = get_dates
  @layoutDates = []
  @mappingDates = []
  @lubeDates = []
  Dir.foreach("#{Dir.pwd}/lib/layouts/old").each do |f|
    if f.match(/^layout_\d{12}.xlsx/)
      f = f.gsub(/\D/,"")
      @layoutDates << "20#{f[0..1]}-#{f[2..3]}-#{f[4..5]}"
    end
  end
  Dir.foreach("#{Dir.pwd}/lib/mappings/old").each do |f|
    if f.match(/^mapping_\d{12}.csv/)
      f = f.gsub(/\D/,"")
      @mappingDates << "20#{f[0..1]}-#{f[2..3]}-#{f[4..5]}"
    elsif f.match(/^lubrication_\d{12}.csv/)
      f = f.gsub(/\D/,"")
      @lubeDates << "20#{f[0..1]}-#{f[2..3]}-#{f[4..5]}"
    end
  end
  haml :admin
end

post "/download_log_sheet/?" do 
  send_file output("#{Dir.pwd}/public/output/#{params["date"].gsub(/-/,'')}-engine_log.json"), filename: "#{params["date"].gsub(/-/,'')}-engine_log.xlsx"
end

post "/download_layout/?" do 
  pass unless access
  filename = nil
  Dir.foreach("#{Dir.pwd}/lib/layouts/old").sort.each do |f|
    if f.match(/^layout_#{params["date"].gsub("-","")[2..-1]}\d{6}.xlsx$/)
      filename = f
    end
  end
  return redirect back unless filename
  send_file "#{Dir.pwd}/lib/layouts/old/#{filename}", filename: filename
end

post "/update_layout/?" do 
  pass unless access
  oldfile = "#{Dir.pwd}/lib/layouts/old/layout_#{Time.now.strftime("%y%m%d%H%M%S")}.xlsx"
  `mv #{params['layout_file']['tempfile'].path} #{oldfile}`
  `mv #{params['layout_file']['tempfile'].path} #{Dir.pwd}/lib/layouts/layout.xlsx`
  "ok" 
end

post "/download_mapping/?" do 
  pass unless access
  filename = nil
  Dir.foreach("#{Dir.pwd}/lib/mappings/old").sort.each do |f|
    if f.match(/^mapping_#{params["date"].gsub("-","")[2..-1]}\d{6}.csv$/)
      filename = f
    end
  end
  return redirect back unless filename
  send_file "#{Dir.pwd}/lib/mappings/old/#{filename}", filename: filename
end

post "/update_mapping/?" do 
  pass unless access
  oldfile = "#{Dir.pwd}/lib/mappings/old/mapping_#{Time.now.strftime("%y%m%d%H%M%S")}.csv"
  `mv #{params['mapping_file']['tempfile'].path} #{oldfile}`
  `mv #{params['mapping_file']['tempfile'].path} #{Dir.pwd}/lib/mappings/mapping.csv`
  e = parse_mapping
  if e == true
    "ok" 
  else 
    `mv #{oldfile} #{Dir.pwd}/lib/mappings/mapping.csv`
    e
  end
end

post "/download_lube/?" do 
  pass unless access
  filename = nil
  Dir.foreach("#{Dir.pwd}/lib/mappings/old").sort.each do |f|
    if f.match(/^lubrication_#{params["date"].gsub("-","")[2..-1]}\d{6}.csv$/)
      filename = f
    end
  end
  return redirect back unless filename
  send_file "#{Dir.pwd}/lib/mappings/old/#{filename}", filename: filename
end

post "/update_lubrication/?" do 
  pass unless access
  oldfile = "#{Dir.pwd}/lib/mappings/old/lubrication_#{Time.now.strftime("%y%m%d%H%M%S")}.csv"
  `mv #{params['lubrication_file']['tempfile'].path} #{oldfile}`
  `mv #{params['lubrication_file']['tempfile'].path} #{Dir.pwd}/lib/mappings/lubrication.csv`
  if parse_mapping
    "ok" 
  else 
    `mv #{oldfile} #{Dir.pwd}/lib/mappings/lubrication.csv`
    "error"
  end
end

post "/edit_previous/?" do 
  p params
  params["date"] = (Date.today-1).strftime("%Y-%m-%d") if params["date"] == "yesterday" or not params.has_key?("date")
  p params
  file = "#{Dir.pwd}/public/output/#{params["date"].gsub("-","")}-engine_log.json"
  if File.exists? file
    unparse JSON.parse(File.read(file))
  else
    "{}"
  end
end

get "/env/?" do
  @env = env
  haml :env, :layout=>false
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

def access 
  if env.has_key?("HTTP_X_FORWARDED_FOR")
    ip = env["HTTP_X_FORWARDED_FOR"]
  else
    ip = env["REMOTE_ADDR"]
  end
  ip.match(/^192\.168\.212\.(199|181)$/) or ip.match(/^127\.0\.0\.1$/)
end

def parse pa
  re = {}
  on = $mapping_slug.keys.map{|k|[k,[]]}.to_h
  row = [pa["user"]]
  pa.each do |k,v|
    next unless v and v.to_s.length > 0
    ro, sy, me = *k.split("_")
    if ["date","user","port","from_port","to_port","status","notes"].include? k
      re[k] = v
    elsif ["lube"].include? k
      re[k] = v
    elsif me == "is-currently-working" and v == "on"
      on[ro] << sy
    else
      p [ro,sy,me,$mapping_slug[ro][sy][me]["mid"].to_i]
      re[ro] = {} unless re.has_key?(ro)
      re[ro][sy] = {} unless re[ro].has_key?(sy)
      re[ro][sy][me] = v
      row[$mapping_slug[ro][sy][me]["mid"].to_i] = v if me
    end
  end
  row.unshift pa["date"]
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


=begin
def parse_log log
  result = []
  log.shift
  date = log.shift
  user = log.shift
  log.unshift nil
end

def find_in_log date
  log = nil
  CSV.read("#{Dir.pwd}/public/output/engine_log.csv").reverse.each do |row|
    if row[1] == date.strftime("%Y-%m-%d")
      log = row
      break
    end
  end
  log
end
=end

