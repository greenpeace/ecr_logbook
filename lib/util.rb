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
  lube = {"rows"=>[]}
  wb = RubyXL::Parser.parse("#{Dir.pwd}/lib/layouts/layout.xlsx")
  ws = wb.worksheets[0]

  w,h = ws[-1][-1].row, ws[-1][-1].column

  (w+1).times do |row|
    (h+1).times do |col|
      if ws[row][col] and ws[row][col].datatype == 's' and ws[row][col].value.match(/^\$/)
        val = ws[row][col].value
        if val.match("|")[0].length > 0
          val.split("|").each do |v|
            ref[v] = [row,col]
          end
          ws[row][col].change_contents("-")
          p val
        elsif val.match(/^\$l.$/)
          lube["rows"] << row unless lube["rows"].include? row
          if val.match(/^\$lu$/)
            lube["unit"] = col
          elsif val.match(/^\$lt$/)
            lube["type"] = col
          elsif val.match(/^\$la$/)
            lube["amount"] = col
          end
          pp lube
          ws[row][col].change_contents("")
        else
          ref[val] = [row,col]
          ws[row][col].change_contents("-")
        end
      end
    end
  end

  pp lube


  map = JSON.parse(File.read("#{Dir.pwd}/lib/mappings/mapping_slug.json"))
  src = JSON.parse(File.read(srcfile))
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
            mes = map[room][system][measurement]
            mid = "$#{mes["mid"]}"
            r,c = *ref[mid]
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
    elsif ref.has_key?("$#{room}")
      r,c = *ref["$#{room}"]
      ws[r][c].change_contents(sys)
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
      meas = "#{row[9]} #{row[3]}" if row[9] and row[9].length > 0 and row[4] != "enum"
      p ind,row if data[row[1]][row[2]].has_key? meas
      data[row[1]][row[2]][meas] = { "unit" => row[4] }
      data[row[1]][row[2]][meas]["min"] = row[5] if row[5] and row[5].length > 0
      data[row[1]][row[2]][meas]["max"] = row[6] if row[6] and row[6].length > 0
      data[row[1]][row[2]][meas]["opt"] = row[7] if row[7] and row[7].length > 0
      data[row[1]][row[2]][meas]["notes"] = row[8] if row[8] and row[8].length > 0
      data[row[1]][row[2]][meas]["data"] = row[9] if row[9] and row[9].length > 0
      data[row[1]][row[2]][meas]["mid"] = row[0].to_i if row[0] and row[0].length > 0

      data_slug[row[1].slug] = {} unless data_slug.has_key? row[1].slug
      data_slug[row[1].slug][row[2].slug] = {} unless data_slug[row[1].slug].has_key? row[2].slug
      meas = row[3].slug
      meas = "#{row[9].slug}-#{row[3].slug}" if row[9] and row[9].length > 0 and row[4] != "enum"
      p ind,row if data_slug[row[1].slug][row[2].slug].has_key? meas
      data_slug[row[1].slug][row[2].slug][meas] = { "unit" => row[4] }
      data_slug[row[1].slug][row[2].slug][meas]["min"] = row[5] if row[5] and row[5].length > 0
      data_slug[row[1].slug][row[2].slug][meas]["max"] = row[6] if row[6] and row[6].length > 0
      data_slug[row[1].slug][row[2].slug][meas]["opt"] = row[7] if row[7] and row[7].length > 0
      data_slug[row[1].slug][row[2].slug][meas]["notes"] = row[8] if row[8] and row[8].length > 0
      data_slug[row[1].slug][row[2].slug][meas]["data"] = row[9] if row[9] and row[9].length > 0
      data_slug[row[1].slug][row[2].slug][meas]["mid"] = row[0].to_i if row[0] and row[0].length > 0
    end

    File.open("#{Dir.pwd}/lib/mappings/lubrication.json","w") {|f| f << JSON.pretty_generate(lube)}
    File.open("#{Dir.pwd}/lib/mappings/mapping.json","w") {|f| f << JSON.pretty_generate(data)}
    File.open("#{Dir.pwd}/lib/mappings/mapping_slug.json","w") {|f| f << JSON.pretty_generate(data_slug)}
  rescue
    return false
  end
  true
end

