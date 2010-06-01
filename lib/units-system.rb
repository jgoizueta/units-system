# encoding: utf-8

# Ruby Units-System experiments.

module Units
  
  class Measure

    def initialize(mag=1.0, units={})
      @magnitude = mag # rename to value?
      case units
      when Symbol
        uinfo = Units.unit(units)
        if uinfo
          if uinfo.dim
            @units = {uinfo.dim=>[units,1]}
          else
            @magnitude *= uinfo.factor
            @units = {}
          end
        else
          raise ArgumentError,"Invalid symbol for Measure definition: #{units.inspect} "
        end
      when Measure
        @magnitude *= units.magnitude
        @units = units.units
      else
        @units = units
      end
    end

    attr_reader :magnitude, :units

    # represent in text using Ruby notation
    def to_s
      return @magnitude.to_s if magnitude?
      u_descr = Units.units_descr(@units)
      "#{@magnitude}*#{u_descr}"
    end

    # more verbose description (not grammatically perfect)
    def describe
      return @magnitude.to_s if magnitude?
      u_descr = Units.units_descr(@units, true)
      "#{@magnitude} #{u_descr}"
    end

    # more natural concise text representation
    def abr
      self.to_s.gsub('**','^').tr('*',' ')
    end

    # decompose compound units
    def detailed_units(all_levels = false)
      mag = @magnitude
      prev_units = self.units
      units = {}
      loop do
        compound = false
        prev_units.each_pair do |dim, (unit,mul)|
          ud = Units.unit(unit)
          if ud.decomposition
            compound = true
            mag *= ud.decomposition.magnitude
            ud.decomposition.units.each_pair do |d, (u,m)|
              mag *= self.class.combine(units, d, u, m)
            end
          else
            mag *= self.class.combine(units, dim, unit, mul)
          end
        end
        if all_levels && compound
          prev_units = units
          units = {}
        else
          break
        end
      end
      Measure.new mag, units
    end

    # decompose to base units
    def base
      detailed_units true
    end

    def self.combine(units, dim, unit, mult)
      factor = 1
      if units[dim]
        u,m = units[dim]
        if u!=unit
          factor *= Units.conversion_factor(unit, u)**mult
        end
        units[dim] = [u, m+mult]
      else
        units[dim] = [unit, mult]
      end
      factor
    end

    def /(other)
      self * (other.kind_of?(Numeric) ? 1.0/other : other.inverse)
    end

    def inspect
      "Measure(#{@magnitude.inspect}, #{@units.inspect})"
    end

    def *(other)
      case other
      when Numeric
        mag = self.magnitude*other
        units = self.units
      else
        mag = self.magnitude*other.magnitude
        units = {}
        (self.units.keys | other.units.keys).each do |dim|
          other_u = other.units[dim] || [nil,0]
          this_u = self.units[dim] || [other_u.first,0]
          # mag *= Units.conversion_factor(this_u.first, other_u.first) if other_u.first
          mult = this_u.last+other_u.last
          mag *= Units.conversion_factor(other_u.first, this_u.first)**(other_u.last) if other_u.first
          units[dim] = [this_u.first, mult]
        end
      end
      units.reject!{|dim,(u,m)| m==0}
      Measure.new(mag, units)
    end

    def +(other)
      Measure.new self.magnitude+other.to(self.units).magnitude, self.units
    end

    def -(other)
      self + (-other)
    end

    def **(n)
      raise ArgumentError,"Only integer powers are allowed for magnitudes" unless n.kind_of?(Integer)
      units = @units.dup
      units.each_pair do |dim, (u, m)|
        units[dim] = [u, m*n]
      end
      Measure.new @magnitude, units
    end

    def inverse
      #Measure.new(1.0/@magnitude, @units.map_hash{|unit,mult| [unit, -mult]})
      units = {}
      @units.each_pair do |dim, (unit, mult)|
        units[dim] = [unit, -mult]
      end
      Measure.new(1.0/@magnitude, units)
    end

    def -@
      Measure.new(-@magnitude, units)
    end

    def in(other, mode=:absolute)
      other = Measure.new(1.0, other) unless other.kind_of?(Measure)
      other = other.base
      this = self.base
      dims = this.units.keys | other.units.keys
      mag = this.magnitude/other.magnitude
      dims.each do |dim|
        if !this.units[dim] || !other.units[dim] ||
           (this.units[dim].last != other.units[dim].last)
          raise "Inconsistent units #{Units.units_descr(this.units)} #{Units.units_descr(other.units)}"
        end
        this_u, mult = this.units[dim]
        other_u = other.units[dim].first
        mag *= Units.conversion_factor(this_u, other_u)**mult
      end
      if mode!=:relative && dims.size==1 && this.units[dims.first].last==1
        # consider "level" conversion for biased units (otherwise consider interval or difference values)
        mag += Units.conversion_bias(this.units[dims.first].first, other.units[dims.first].first)
      end
      mag
    end

    def to(units, mode=:absolute)
      units = units.u if units.kind_of?(Measure)
      Measure.new self.in(units, mode), units
    end

    def si_units
      units = {}
      @units.each_pair do |dim, (unit, mult)|
        si_unit = SI_UNITS[dim]
        if si_unit.kind_of?(Measure)
          si_unit.units.each_pair do |d, (u,m)|
            self.class.combine(units, d, u, m*mult)
          end
        else
          self.class.combine(units, dim, si_unit, mult)
        end
      end
      units
    end

    def to_si
      to(si_units)
    end

    def coerce(other)
      [Measure.new(other, {}), self]
    end

    def u # dimension? unit? only_units? strip_units? units_measure?
      Measure.new(1.0, self.units)
    end

    # dimension (quantity)
    def dimension
      q = nil
      u = self.base.si_units
      SI_UNITS.each_pair do |dim, unit|
        unit = Measure.new(1.0, unit) unless unit.kind_of?(Measure)
        if unit.base.si_units == u
          q = dim
          break
        end
      end
      q
    end

    def dimensionless?
      base.units.reject{|d,(u,m)| m==0}.empty?
    end

    # less strict dimensionless condition (e.g. an angle is not a pure magnitude in this sense)
    def magnitude?
      self.units.reject{|d,(u,m)| m==0}.empty?
    end

  end # Measure

  def Measure(*args)
    if args.size==1
      case args.first
      when Numeric
        m = args.first
        u = {}
      else
        m = 1.0
        u = args.first
      end
      args = [m,u]
    end
    Units::Measure.new(*args)
  end
  module_function :Measure

  PREFIXES = {
    :y=>[1E-24, 'yocto'],
    :z=>[1E-21, 'zepto'],
    :a=>[1E-18, 'atto'],
    :f=>[1E-15, 'femto'],
    :p=>[1E-12, 'pico'],
    :n=>[1E-09, 'nano'],
    :"\302\265"=>[1E-06, 'micro'], # ASCII alternative: u; define it?
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

  # mathematical functions available to unit blocks are defined here
  module Math
  end

  # unit methods and constants are defined here to be injected in units blocks
  module System

    extend Math

    def self.define(unit)
      define_var unit
      PREFIXES.each do |prefix, (factor, name)|
        define_var "#{prefix}#{unit}".to_sym
      end
    end

    class <<self
      private
      def define_var(name)
        name_initial = name.to_s[0,1]
        if name_initial==name_initial.upcase && name_initial!=name_initial.downcase
          # we could define a method with the requested name, but it would
          # no be usable without qualification (System.X) or brackets (X())
          # so we define a constant. But this requires Ruby 1.9 to be useful;
          # otherwise the constant is not accesible without qualification in units blocks.
          System.const_set name, Units.Measure(name)
        end
        self.class_eval do
          define_method name do
            Units.Measure(name)
          end
          module_function name
        end
      end
    end

  end # Units::System

  def units(&blk)
    Units::System.class_eval(&blk)
  end
  alias :u :units
  module_function :units, :u

  UnitDefinition = Struct.new(:dim, :factor, :name, :decomposition, :bias)

  UNITS = {} # Hash.new{|h,k| h[k]=UnitDefinition.new()}

  # get unit definition
  def self.unit(unit_symbol)
    ud = UNITS[unit_symbol]
    if ud.nil?
      factor = 1.0
      if factor_name = PREFIXES[unit_symbol]
        ud = UnitDefinition.new(nil, *factor_name)
      else
        u = unit_symbol.to_s
        PREFIXES.each_pair do |prefix, (f,name)|
          prefix = prefix.to_s
          if u[0...prefix.length] == prefix
            factor = f
            ud = UNITS[u[prefix.length..-1].to_sym]
            if ud              
              ud = ud.dup
              ud.name = "#{name}#{ud.name}"
              break
            end
          end
        end
      end
      ud.factor *= factor if ud
      ud.decomposition *= factor if ud && ud.decomposition
    end
    raise ArgumentError,"Invalid Units #{unit_symbol}" unless ud
    ud
  end

  # Define new units.
  # Define a base unit (with a factor for conversion to SI units)
  #   Units.define :unit_symbol, 'unit-name', :quantity, si_units_per_this_unit
  # Define a unit in terms or another (valid for base or derived units)
  #   Units.define :unit_symbol, 'unit-name', value, :in_units
  # Define a base unit as a measure-expression
  #   Units.define :unit_symbol, 'unit_name', u{...}
  # Define a derived unit as a measure-expression
  #   Units.define :unit_symbol, 'unit_name', :quantity, u{...}
  # For base dimensions the SI unit for a quantity must also be stablished with Unit.si_units;
  # for derived units, SI units are automatically taken to be the first define unit of the quantity
  # with unitary value in SI base units.
  def self.define(unit_symbol, name, *args)
    eqhivalence = nil
    si_unit = false
    bias = nil
    if args.first.kind_of?(Symbol)
      dim = args.shift
      if args.first.kind_of?(Numeric)
        # simple units
        factor = args.shift
        factor_units = args.shift
        if factor_units
          ud = unit(factor_units)
          if ud.dim != dim
            raise ArgumentError, "Inconsistent units #{factor_units} in definition of #{unit_symbol}"
          end
          # maybe it was not simple after all...
          equivalence = factor*ud.decomposition if ud.decomposition
          factor *= ud.factor
        end
        # si_unit = (factor==1.0) # to save si_units definitions # TODO: tolerance?
      else
        # compound unit
        equivalence = args.shift
        factor = equivalence.to_si.magnitude
        si_unit = (factor==1.0) # TODO: tolerance?
        if equivalence.units.empty?
          # dimensionless compound dimension... (special case for angular units)
          equivalence = nil
        end
      end
    elsif args.first.kind_of?(Numeric)
      # unit define in terms of other unit
      factor = args.shift
      factor_units = args.shift
      u = unit(factor_units)
      dim = u.dim
      equivalence = factor*u.decomposition if u.decomposition
      factor *= u.factor
      bias = args.shift
    else
      # unit defined from a measure expression; the dimension must be already known or defined
      # here (as as symbol preceding the expression).
      definition = args.shift
      dim = definition.dimension
      raise ArgumentError,"To define a new compound unit a dimension must be specified" unless dim
      equivalence = definition
      factor = definition.to_si.magnitude
      # si_unit = (factor==1.0) # to save si_units definitions # TODO: tolerance?
    end
    unit_def = UnitDefinition.new(dim, factor, name, equivalence, bias)
    if UNITS.has_key?(unit_symbol)
      raise "Redefinition of #{unit_symbol} as #{unit_def} (previously defined as #{UNITS[unit_symbol]})"
    end
    UNITS[unit_symbol] = unit_def
    System.define unit_symbol
    Units.si_units unit_def.dim, unit_symbol if si_unit && !SI_UNITS.has_key?(unit_def.dim)
  end

  SI_UNITS = {}

  def self.si_units(dim, unit)
    SI_UNITS[dim] = unit
  end

  def self.dimension(u)
    unit(u).dim
  end

  def self.conversion_factor(from, to)
    from_u = unit(from)
    to_u = unit(to)
    raise ArgumentError,"Inconsistent Units (#{from}, #{to})" if from_u.dim!=to_u.dim
    from_u.factor/to_u.factor
  end

  def self.conversion_bias(from, to)
    from_u = unit(from)
    to_u = unit(to)
    raise ArgumentError,"Inconsistent Units (#{from}, #{to})" if from_u.dim!=to_u.dim
    factor = from_u.factor/to_u.factor
    (from_u.bias||0)*factor - (to_u.bias||0)
  end

  # simple unit name
  def self.unit_name(u)
    uinfo = Units.unit(u)
    uinfo && uinfo.name
  end

  def self.unit_descr(u, long=false, mult=1)
    if long
      u = unit_name(u)
      if mult!=1
        case mult
        when 2
          "squared #{u}"
        when 3
          "cubed #{u}"
        else
          "#{u} to the #{mult} power"
        end
      else
        u
      end
    else
      if mult!=1
        "#{u}**#{mult}"
      else
        u.to_s
      end
    end
  end

  def self.units_descr(units, long=false)
    units = units.values.sort_by{|u,m| -m}
    pos_units = units.select{|u| u.last>0}
    neg_units = units.select{|u| u.last<0}
    times = long ? " " : "*"
    num = pos_units.map{|u,m| unit_descr(u,long,m)}.join(times)
    num = "(#{num})" if pos_units.size>1 && !neg_units.empty? && !long
    den = neg_units.map{|u,m| unit_descr(u,long,-m)}.join("*")
    den = "(#{den})" if neg_units.size>1 && !long
    if pos_units.empty?
      u_descr = "1/#{den}"
    elsif neg_units.empty?
      u_descr = num
    else
      connector = long ? " per " : "/"
      u_descr = "#{num}#{connector}#{den}"
    end
    u_descr
  end

  module Math

    [:sin, :cos, :tan].each do |fun|
      define_method fun do |x|
        x = Units.u{x.in(rad)} if x.kind_of?(Measure)
        ::Math.send(fun, x)
      end
      module_function fun
    end

    [:asin, :acos, :atan].each do |fun|
      define_method fun do |x|
        if x.kind_of?(Measure)
          raise ArgumentError,"Invalid dimensions for #{fun} argument" unless x.dimensionless?
          x = x.magnitude
        end
        Units.u{::Math.send(fun, x)*rad}
      end
      module_function fun
    end

    module_function
    def atan2(x,y)
      if x.kind_of?(Measure)
        if y.kind_of?(Measure)
          if x.base.to_si.units != y.base.to_si.units
            raise ArgumentError,"Inconsistent units for atan2 arguments #{x.u}, #{y.u}"
          end
          # or x = x.to_si.magnitude, y=y.to_si.magnitude
          y = y.in(x.units)
          x = x.magnitude
        else
          raise ArgumentError,"Invalid dimensions for atan2 argument #{x.u}" unless x.dimensionless?
          x = x.magnitude
        end
      elsif y.kind_of?(Measure)
        raise ArgumentError,"Invalid dimensions for atan2 argument #{y.u}" unless y.dimensionless?
        y = y.magnitude
      end
      Units.u{::Math.atan2(x,y)*rad}
    end

  end
  
  
  # This must be included in any module or class from which units expressions
  # are to be used in units or u blocks.
  # It is not needed in Ruby 1.9.1 due to they way constant loop-up is done in that version,
  # but Ruby 1.9.2 has changed that an requires this again.
  module UseBlocks
    def self.append_features(target)
      def target.const_missing(name)
        begin
          Units.Measure(name)
        rescue ArgumentError
          super
        end
      end
    end
  end
    
  include UseBlocks

  # Units definitions

  # declare SI base units
  si_units :mass,   :kg                  # m
  si_units :length, :m                   # l
  si_units :time,   :s                   # t
  si_units :electric_current, :A         # I
  si_units :temperature, :K              # T
  si_units :luminous_intensity, :cd      # Iv
  si_units :amount_of_substance, :mol    # n

  # define base units
  define :g, 'gram',   :mass, 1E-3
  define :m, 'meter',  :length, 1.0
  define :s, 'second', :time, 1.0
  define :A, 'ampere', :electric_current, 1.0
  define :K, 'kelvin', :temperature, 1.0
  define :cd,'candela',:luminous_intensity, 1.0
  define :mol,'mole',  :amount_of_substance, 1.0

  # declare derived quantities with no named units
  si_units :speed,        u{m/s}
  si_units :acceleration, u{m/s**2}
  si_units :area,         u{m**2}
  si_units :volume,       u{m**3}

  # derived quantities with named units
  define :W,   'Watt',      :power,                u{kg*m**2/s**3} # J/s
  define :Hz,  'herz',      :frequency,            u{1/s}
  define :N,   'newton',    :force,                u{m*kg/s**2}
  define :Pa,  'pascal',    :pressure,             u{N/m**2}
  define :J,   'joule',     :energy,               u{N*m}
  define :C,   'coulomb',   :electric_charge,      u{s*A}
  define :V,   'volt',      :voltage,              u{W/A}
  define :F,   'farad',     :electric_capacitance, u{C/V}
  define :Ω,   'ohm',       :electric_resistance,  u{V/A} # ohm: Ω  omega: Ω
  define :S,   'siemens',   :electric_condctance,  u{1/Ω}
  define :Wb,  'weber',     :magnetic_flux,        u{J/A}
  define :T,   'tesla',     :magnetic_field,       u{N/(A*m)}
  define :H,   'henry',     :inductance,           u{Wb/A}
  define :rad, 'radian',    :angle,                u{m/m}
  define :sr,  'steradian', :solid_angle,          u{m**2/m**2}
  define :lm,  'lumen',     :luminous_flux,        u{cd*sr}
  define :lx,  'lux',       :illuminance,          u{lm/m**2}
  define :Bq,  'bequerel',  :radioactivity,        u{1/s}
  define :Gy,  'gray',      :absorbed_dose,        u{J/kg}
  define :Sv,  'sievert',   :equivalent_dose,      u{J/kg}
  define :kat, 'katal',     :catalytic_activity,   u{mol/s}

  # Other units

  define :min,  'minute', 60, :s
  define :h,    'hour',   60, :min
  define :d,    'day',    24, :h
  define :mi,   'mile',    1.609344, :km
  define :in,   'inch',    2.54, :cm
  define :ft,   'foot',    0.3048, :m
  define :inch, 'inch',    1, :in # alternative to avoid having to use self.in (in is a Ruby keyword)
  define :lb,   'pound',   0.45359237, :kg

  define :°C, 'degree Celsius',          1, :K, +273.15
  define :°F, 'degree Fahrenheit', 5.0/9.0, :K, +459.67
  define :R,  'rankine',           5.0/9.0, :K

  define :l, 'litre', u{dm**3}
  define :L, 'litre', 1, :l

  define :°, 'degree',     ::Math::PI/180.0, :rad
  define :′, 'arc-minute', ::Math::PI/180.0/60.0, :rad
  define :″, 'arc-second', ::Math::PI/180.0/3600.0, :rad
  # not so cool, but easier to type alternatives:
  define :deg,    'degree',     1, :°
  define :arcmin, 'arc-minute', 1, :′
  define :arcsec, 'arc-second', 1, :″

  define :g0, 'standard gravity', u{9.80665*m/s**2}

  define :bar,  'bar',                    1E5, :Pa
  define :atm,  'atmosphere',             101325.0, :Pa
  define :mWC,  'meters of water column', u{1E3*kg*g0/m**2}
  define :Torr, 'torricelli',             u{atm/760}
  define :mHg,  'mHg',                    u{13.5951E3*kg*g0/m**2}

  # define :kp, 'kilopond', :force, u{kg*g0} # or define pond?
  define :gf,  'gram-force',  u{g*g0} # kilopond kp = kgf
  define :lbf, 'pound-force', u{lb*g0}

  define :dyn,   'dyne', 10, :µN # u{1*g*cm/s**2}
  define :galUS, 'U.S. liquid gallon', u{231*self.in**3}
  define :galUK, 'Imperial gallon', 4.546092, :l
  define :hp,    'horsepower', u{550*ft*lbf/s}

  define :psi, 'pounds-force per square inch', u{lbf/self.in**2}

end # Units
