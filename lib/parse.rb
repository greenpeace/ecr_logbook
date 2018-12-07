require 'unidecoder'
require "#{Dir.pwd}/lib/util.rb"
require 'json'
require 'csv'

data = {}
data_slug = {}
CSV.read("#{Dir.pwd}/lib/template.csv").each_with_index do |row,ind|
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

File.open("#{Dir.pwd}/lib/mapping.json","w") {|f| f << JSON.pretty_generate(data)}
File.open("#{Dir.pwd}/lib/mapping_slug.json","w") {|f| f << JSON.pretty_generate(data_slug)}
