class String
  def slug
    self.strip.to_ascii.downcase.gsub(/('|\([^\)]+\))+/,"").gsub(/\W+/,"-").sub(/(\d|\s|,)+$/,"").gsub(/(^-|-$)/,"")
  end
  def abbr
    self.strip.to_ascii.downcase.gsub(/('|\([^\)]+\))+/,"").gsub(/\W+/,"-").sub(/(\d|\s|,)+$/,"").gsub(/(^-|-$)/,"")
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

