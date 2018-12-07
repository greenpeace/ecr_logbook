require 'axlsx'
xls = Axlsx::Package.new
wb = xls.workbook
wb.styles do |s|
	gridstyle_border = s.add_style :border => { :style => :thin, :color =>"FFCDCDCD" }
end
wb.add_worksheet do |ws|
  # Excel does not currently follow the specification and will ignore paper_width and paper_height so if you need
  # to for a paper size, be sure to set :paper_size
	ws.sheet_view.show_grid_lines = false
  ws.page_setup.set :paper_width => "210mm", :paper_size => 10,  :paper_height => "297mm", :orientation => :landscape
	p wb.styles[@gridstyle_border]
  ws.add_row ["yakup",123], :style=> gridstyle_border
end
xls.serialize "page_setup.xlsx"
