require 'unidecoder'
require "#{Dir.pwd}/lib/util.rb"
require 'rubyXL'
require 'json'
require 'pp'

ref = {}
wb = RubyXL::Parser.parse("#{Dir.pwd}/lib/target.xlsx")
ws = wb.worksheets[0]

w,h = ws[-1][-1].row, ws[-1][-1].column

(w+1).times do |row|
  (h+1).times do |col|
    if ws[row][col] and ws[row][col].datatype == 's' and ws[row][col].value.match(/^\$/)
      val = ws[row][col].value
      if val.match("|")
        val.split("|").each do |v|
          ref[v] = [row,col]
        end
      else
        ref[val] = [row,col]
      end
    end
  end
end


map = JSON.parse(File.read("#{Dir.pwd}/lib/mapping_slug.json"))
src = JSON.parse(File.read(ARGV[0]))
res = {}
sel = ""

src.each do |room,sys|
  if sys.is_a? Hash
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
          puts "error (#{e}) => #{mid} - #{room} / #{system} / #{measurement}" 
        end
      end
    end
  elsif ref.has_key?("$#{room}")
    r,c = *ref["$#{room}"]
    ws[r][c].change_contents(sys)
  end
end

wb.write("#{Dir.pwd}/public/output/#{ARGV[0].split("/")[-1].split(".")[0]}.xlsx")

