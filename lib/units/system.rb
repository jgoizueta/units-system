# encoding: utf-8

module Units

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

  def units(string=nil, &blk)
    if string
      if blk
        raise ArgumentError, "wrong number of arguments (1 for 0)"
      else
        Units::System.class_eval(string)
      end
    else
      Units::System.class_eval(&blk)
    end
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

  ConstantDefinition = Struct.new(:symbol, :description, :value)
  CONSTANTS = {}
  module Const
    def self.define(name, description, value)
      symbol = name.to_sym
      cd = ConstantDefinition.new(symbol, description, value)
      CONSTANTS[symbol] = cd
      class_eval do
        # Ruby 1.9.1 allows this nicer definition:
        #   define_singleton_method name do
        #     value
        #   end
        eigenclass = class<<self; self; end
        eigenclass.instance_eval{define_method(name){value}}
      end
    end
  end

  def self.constant(symbol, description=nil, value=nil)
    if description.nil? && value.nil?
      c = CONSTANTS[symbol]
      c && c.value
    else
      Const.define symbol, description, value
    end
  end

  def self.with_constants(*constants, &blk)
    m = Module.new
    m.extend Units::System
    m.extend Units::Math
    cap_constants = []
    constants.each do |const|
      m.instance_eval do
        # Ruby 1.9.1 allows this nicer definition:
        #   define_singleton_method(const){Units.constant(const)}
        eigenclass = class<<self; self; end
        eigenclass.instance_eval{define_method(const){Units.constant(const)}}
        name_initial = const.to_s[0,1]
        if name_initial==name_initial.upcase && name_initial!=name_initial.downcase
          cap_constants << const
        end
      end
    end
    UseBlocks.with_constants(*cap_constants) do
      m.instance_eval &blk
    end
  end

end # Units
