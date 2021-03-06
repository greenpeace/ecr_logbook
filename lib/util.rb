class String
  def slug
    self.strip.to_ascii.downcase.gsub(/'+/,"").gsub(/\W+/,"-").sub(/(\s|,)+$/,"").gsub(/(^-|-$)/,"")
  end
  def abbr
    self.strip.to_ascii.downcase.gsub(/('|\([^\)]+\))+/,"").gsub(/\W+/,"-").sub(/(\s|,)+$/,"").gsub(/(^-|-$)/,"")
  end
end

module Enumerable

  def sum
    self.inject(0){|i,j| i + j }
  end

  def avg circular=false
    if circular
      x, y = 0, 0
      self.each do |e|
        x += Math.cos( e / 180.0 * Math::PI )
        y += Math.sin( e / 180.0 * Math::PI )
      end
      Math.atan2(y, x) * 180.0 / Math::PI
    else
      self.sum/self.length.to_f
    end
  end

  def smp_var circular=false
    m = self.avg(circular)
    if circular
      sum = self.inject(0) do |i,j|
        [(i-j).abs,(j-i).abs].min
      end
    else 
      sum = self.inject(0){|accum, i| accum +(i-m)**2 }
    end
    sum/(self.length - 1).to_f
  end

  def std_dev circular=false
    return 0 if self.smp_var.nan?
    Math.sqrt(self.smp_var(circular))
  end

end 

def polar2cart a, r=nil
  a, r = *a unless r
  x = Math.cos( a / 180.0 * Math::PI ) * r
  y = Math.sin( a / 180.0 * Math::PI ) * r
  [x,y]
end

def cart2polar x, y=nil
  x, y = *x unless y
  a = Math.atan2(y, x) * 180.0 / Math::PI
  r = ( x * x + y * y ) ** 0.5
  [a,r]
end

def add_polar_vectors a
  x, y = 0, 0
  a.each do |v|
    c = polar2cart v
    x += c[0]
    y += c[1]
  end
  cart2polar [x,y]
end

def fix_log_file
  new = []
  CSV.read("#{Dir.pwd}/public/data/log.csv").each_with_index do |row,ind|
    if row[5]
      row[8] = add_polar_vectors([[row[4],row[5]],[row[9],row[10]]])
      new << row
    else
      new << row
    end
  end
  CSV.open("#{Dir.pwd}/public/data/log.csv","w") do |csv|
    new.each do |row|
      csv << row
    end
  end
  nil
end

def output srcfile

  require 'rubyXL'

  ref = {}
  yef = {}
  lube = {"rows"=>[]}
  wb = RubyXL::Parser.parse("#{Dir.pwd}/lib/layouts/layout.xlsx")
  ws = wb.worksheets[0]


  w,h = ws[-1][-1].row, ws[-1][-1].column

  ws.each_with_index do |r,row|
    r && r.cells.each_with_index do |cell, col|
      if cell and cell.datatype == 's' and cell.value.match(/^\$/)
        val = cell.value
        if val.match("|")[0].length > 0
          val.split("|").each do |v|
            ref[v] = [row,col]
          end
          cell.change_contents("-")
        elsif val.match(/^\$l.$/)
          lube["rows"] << row unless lube["rows"].include? row
          if val.match(/^\$lu$/)
            lube["unit"] = col
          elsif val.match(/^\$lt$/)
            lube["type"] = col
          elsif val.match(/^\$la$/)
            lube["amount"] = col
          end
          cell.change_contents("")
        elsif val.match(/^\$y\d+$/)
          yef[val] = [row,col]
          cell.change_contents("-")
        elsif val.match(/^\$notes$/)
          ref[val] = [row,col]
          cell.change_contents("-")
          cell.text_wrap
        else
          ref[val] = [row,col]
          cell.change_contents("-")
        end
      end
    end
  end


  src = JSON.parse(File.read(srcfile))
  print(JSON.pretty_generate(src).cyan)
  yday = Date.parse(srcfile.split("/")[-1].split("-")[0], "%Y%m%d") - 1
  yfile = srcfile.sub(/\d{8}/,yday.strftime("%Y%m%d"))
  ysrc = nil
  if File.exists?(yfile)
    ysrc = JSON.parse(File.read(yfile))
  end
  res = {}
  sel = ""

  src.each do |room,sys|
    if room == "lube"
      sys.each_with_index do |lub,ind|
        lub.each do |k,v|
          next if k == "room"
          ws[lube["rows"][ind]][lube[k]].change_contents(v)
        end
      end
    elsif sys.is_a? Hash
      sys.each do |system, meas|
        meas.each do |measurement, value|
          begin
            mes = $mapping_slug[room][system][measurement]
            mid = "$#{mes["mid"]}"
            r,c = *ref[mid]
            next unless r or c
            if mes["unit"] == "enum" and mes["data"] and mes["data"] != ""
              sel = value
            elsif mes["unit"] != "enum" and mes["data"] and mes["data"].slug != sel and false
              puts "skipped (#{r},#{c}) => #{mid} - #{room} / #{system} / #{measurement} = #{value} (#{})".yellow
              next
            elsif mes["unit"] == "binary" and mes["data"] and mes["data"].split("|").length == 2
              value = (value == "yes" ? mes["data"].split("|")[0] : mes["data"].split("|")[1])
            elsif mes["unit"] == "trinary" and mes["data"] and mes["data"].split("|").length == 3
              value = (value == "L" ? mes["data"].split("|")[0] : (value == "M" ? mes["data"].split("|")[1] : mes["data"].split("|")[2]))
            end
            puts "changed (#{r},#{c}) => #{mid} - #{room} / #{system} / #{measurement} = #{value}".green
            ws[r][c].change_contents(value) #if value and value != ""
          rescue => e
            puts "error (#{e}) => #{mid} - #{room} / #{system} / #{measurement}".red
          end
        end
      end
    elsif ref.has_key?("$#{room}")
      r,c = *ref["$#{room}"]
      ws[r][c].change_contents(sys)
    end
  end

  if yef.keys.length > 0 and ysrc
    ysrc.each do |room,sys|
      if sys.is_a? Hash
        sys.each do |system, meas|
          meas.each do |measurement, value|
            begin
              mes = $mapping_slug[room][system][measurement]
              mid = "$y#{mes["mid"]}"
              next unless yef.has_key?(mid)
              r,c = *yef[mid]
              if mes["unit"] == "enum" and mes["data"] and mes["data"] != ""
                sel = value.slug
              elsif mes["unit"] != "enum" and mes["data"] and mes["data"].slug != sel
                next
              end
              ws[r][c].change_contents(value) #if value and value != ""
            rescue => e
              #puts "error (#{e}) => #{mid} - #{room} / #{system} / #{measurement}" 
            end
          end
        end
      end
    end
  end

  outfile = "#{Dir.pwd}/public/output/#{srcfile.split("/")[-1].split(".")[0]}.xlsx"
  wb.write(outfile)
  outfile
end

def parse_mapping
  begin
    lube = {"oils" => []}

    CSV.read("#{Dir.pwd}/lib/mappings/lubrication.csv").each_with_index do |row,ind|
      next if ind == 0
      lube[row[0]] = {} unless lube.has_key? row[0]
      lube[row[0]][row[1]] = row[2]
      lube["oils"] << row[2] unless lube["oils"].include?(row[2])
    end

    data = {}
    data_slug = {}
    CSV.read("#{Dir.pwd}/lib/mappings/mapping.csv").each_with_index do |row,ind|
      next if ind == 0
      data[row[1]] = {} unless data.has_key? row[1]
      data[row[1]][row[2]] = {} unless data[row[1]].has_key? row[2]
      meas = row[3]
      if row[9] and row[9].length > 0 
        if not ["enum","scale"].include?(row[4])
          meas = "#{row[9]} #{row[3]}"
        elsif row[4] == "binary" and row[9].split("|").length != 2
          meas = "#{row[9]} #{row[3]}"
        elsif row[4] == "trinary" and row[9].split("|").length != 3
          meas = "#{row[9]} #{row[3]}"
        end
      end

      #p ind,row if data[row[1]][row[2]].has_key? meas
      data[row[1]][row[2]][meas] = { "unit" => unit_sign(row[4]) }
      data[row[1]][row[2]][meas]["min"] = row[5] if row[5] and row[5].length > 0
      data[row[1]][row[2]][meas]["max"] = row[6] if row[6] and row[6].length > 0
      data[row[1]][row[2]][meas]["opt"] = row[7] if row[7] and row[7].length > 0
      data[row[1]][row[2]][meas]["notes"] = row[8] if row[8] and row[8].length > 0
      data[row[1]][row[2]][meas]["data"] = row[9] if row[9] and row[9].length > 0
      data[row[1]][row[2]][meas]["mid"] = row[0].to_i if row[0] and row[0].length > 0
      data[row[1]][row[2]][meas]["port"] = row[10].to_i if row[10] and row[10].length > 0

      data_slug[row[1].slug] = {} unless data_slug.has_key? row[1].slug
      data_slug[row[1].slug][row[2].slug] = {} unless data_slug[row[1].slug].has_key? row[2].slug
      meas = row[3].slug
      if row[9] and row[9].length > 0 
        if not ["enum","scale"].include?(row[4])
          meas = "#{row[9].slug}-#{row[3].slug}"
        elsif row[4] == "binary" and row[9].split("|").length != 2
          meas = "#{row[9].slug}-#{row[3].slug}"
        elsif row[4] == "trinary" and row[9].split("|").length != 3
          meas = "#{row[9].slug}-#{row[3].slug}"
        end
      end
      #p ind,row if data_slug[row[1].slug][row[2].slug].has_key? meas
      data_slug[row[1].slug][row[2].slug][meas] = { "unit" => row[4] }
      data_slug[row[1].slug][row[2].slug][meas]["min"] = row[5] if row[5] and row[5].length > 0
      data_slug[row[1].slug][row[2].slug][meas]["max"] = row[6] if row[6] and row[6].length > 0
      data_slug[row[1].slug][row[2].slug][meas]["opt"] = row[7] if row[7] and row[7].length > 0
      data_slug[row[1].slug][row[2].slug][meas]["notes"] = row[8] if row[8] and row[8].length > 0
      data_slug[row[1].slug][row[2].slug][meas]["data"] = row[9] if row[9] and row[9].length > 0
      data_slug[row[1].slug][row[2].slug][meas]["mid"] = row[0].to_i if row[0] and row[0].length > 0
      data_slug[row[1].slug][row[2].slug][meas]["port"] = row[10].to_i if row[10] and row[10].length > 0
    end

    File.open("#{Dir.pwd}/lib/mappings/lubrication.json","w") {|f| f << JSON.pretty_generate(lube)}
    File.open("#{Dir.pwd}/lib/mappings/mapping.json","w") {|f| f << JSON.pretty_generate(data)}
    File.open("#{Dir.pwd}/lib/mappings/mapping_slug.json","w") {|f| f << JSON.pretty_generate(data_slug)}

    $mapping = JSON.parse(File.read("#{Dir.pwd}/lib/mappings/mapping.json"))
    $mapping_slug = JSON.parse(File.read("#{Dir.pwd}/lib/mappings/mapping_slug.json"))
    $lubrication = JSON.parse(File.read("#{Dir.pwd}/lib/mappings/lubrication.json"))

  rescue => e
    return e
  end
  true
end

def find_id id
  $mapping.each do |k,v|
    v.each do |kk,vv|
      vv.each do |kkk,vvv|
        if vvv["mid"] === id
          return [k,kk,kkk]
        end
      end
    end
  end
  []
end

def parse_csv types
  types = [types] unless types.is_a?(Array)
  types.map! {|t| t.to_i }
  result = {}
  dates = []
  csv = CSV.read("#{Dir.pwd}/public/output/engine_log.csv")
  total = csv.length
  csv.reverse.each do |row|
    begin
      date = Date.parse(row[1])
    rescue => e
      p row
      puts e.to_s
      next
    end
    if dates.include?(date)
      next
    elsif dates.any? and (dates.last - date).to_i > 1
      ((dates.last - date).to_i - 1).times do |d|
      end
      next
    end
    dates << date
    types.each_with_index do |type|
      val = row[type+2]
      if val and val.match /\A[-+]?[0-9]+\Z/
        val = val.to_i
      elsif val and  val.match /\A[-+]?[0-9]+\.?[0-9]*\Z/
        val = val.to_f
      end
      name = find_id(type)[-1] || "x"
      result[name] = [name] unless result.has_key?(name)
      result[name] << val
    end
  end

  {:data=>{:columns=>result.values},:line=>{:connect_null=>false}}
  if types[0] == -1
    last_day = Date.parse(result.values[0][1])
    [result.values[0],[(last_day-30).to_time.to_i*1000,last_day.to_time.to_i*1000]]
  else
    result.values
  end
end

def unit_sign u
  if ["C","deg","percent","cube"].include?(u)
    u = {"C"=>"°C","deg"=>"°","percent"=>"%","cube"=>"m³"}[u]
  end
  u
end

def get_dates
  dates = []
  Dir.foreach("#{Dir.pwd}/public/output") do |file|
    begin
      if file.match(/\.json$/)
        date = file.match(/^\d{8}/)[0]
        dates << "#{date[0..3]}-#{date[4..5]}-#{date[6..7]}"
      end
    rescue
      next
    end
  end
  dates
end

def get_edit_dates
  dates = {}
  CSV.read("#{Dir.pwd}/public/output/engine_log.csv").each do |row|
    begin
      if row[0] and row[0].length > 0 and row[0].match(/^\d+$/)
        time = Time.at(row[0].to_i)
        date = "#{time.year}-#{time.month.to_s.rjust(2,"0")}-#{time.day.to_s.rjust(2,"0")}"
        dates[date] = [] unless dates.has_key?(date)
        dates[date] << [row[0].to_i,"#{time.hour.to_s.rjust(2,"0")}:#{time.min.to_s.rjust(2,"0")}:#{time.sec.to_s.rjust(2,"0")}"]
      end
    rescue
      next
    end
  end
  dates
end

def get_edit_times stamp
  data = []
  CSV.read("#{Dir.pwd}/public/output/engine_log.csv").each do |row|
    begin
      if row[0] and row[0].length > 0 and row[0].match(/^\d+$/)
        next unless stamp == row[0].to_i
        data = row
        break
      end
    rescue
      next
    end
  end
  data
end

