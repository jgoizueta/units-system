# encoding: utf-8

module Units

  PREFIXES = {
    :y=>[1E-24, 'yocto'],
    :z=>[1E-21, 'zepto'],
    :a=>[1E-18, 'atto'],
    :f=>[1E-15, 'femto'],
    :p=>[1E-12, 'pico'],
    :n=>[1E-09, 'nano'],
    :"\302\265"=>[1E-06, 'micro'],
    :"u"=>[1E-06, 'micro'],
    :m=>[1E-03, 'milli'],
    :c=>[1E-02, 'centi'],
    :d=>[1E-01, 'deci'],
    :da=>[1E1, 'deca'],
    :h=>[1E02, 'hecto'],
    :k=>[1E03, 'kilo'],
    :M=>[1E06, 'mega'],
    :G=>[1E09, 'giga'],
    :T=>[1E12, 'tera'],
    :P=>[1E15, 'peta'],
    :E=>[1E18, 'exa'],
    :Z=>[1E21, 'zetta'],
    :Y=>[1E24, 'yotta']
  }

  def self.prefix_factor(prefix)
    pd = PREFIXES[prefix.to_sym]
    pd && pd.first
  end

  def self.prefix_name(prefix)
    pd = PREFIXES[prefix.to_sym]
    pd && pd.last
  end

  def self.prefix_factor_and_name(prefix)
    PREFIXES[prefix]
  end

end # Units
