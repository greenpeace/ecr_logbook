require 'json'
require 'csv'

data = {}
CSV.read("#{Dir.pwd}/lib/template.csv").each_with_index do |row,ind|
  next if ind == 0
  data[row[0]] = {} unless data.has_key? row[0]
  data[row[0]][row[1]] = {} unless data[row[0]].has_key? row[1]
  meas = row[2]
  meas = "#{row[8]} #{row[2]}" if row[8] and row[8].length > 0 and row[3] != "enum"
  p ind,row if data[row[0]][row[1]].has_key? meas
  data[row[0]][row[1]][meas] = { "unit" => row[3] }
  data[row[0]][row[1]][meas]["min"] = row[4] if row[4] and row[4].length > 0
  data[row[0]][row[1]][meas]["max"] = row[5] if row[5] and row[5].length > 0
  data[row[0]][row[1]][meas]["opt"] = row[6] if row[6] and row[6].length > 0
  data[row[0]][row[1]][meas]["notes"] = row[7] if row[7] and row[7].length > 0
  data[row[0]][row[1]][meas]["data"] = row[8] if row[8] and row[8].length > 0
end

File.open("#{Dir.pwd}/lib/mapping.json","w") {|f| f << JSON.pretty_generate(data)}
