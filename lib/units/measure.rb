# encoding: utf-8

module Units

  class Measure

    def initialize(*args)
      if args.size==0
        mag = 1.0
        units = {}
      elsif args.size==1
        case args.first
        when Numeric
          mag = args.first
          units = {}
        else
          mag = 1.0
          units = args.first
        end
      elsif args.size==2
        mag, units = args
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 0, 1 or 2)"
      end

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

    include ModalSupport::StateEquivalent
    include ModalSupport::BracketConstructor

    attr_reader :magnitude, :units

    # represent in text using Ruby notation
    def to_s
      return @magnitude.to_s if magnitude?
      u_descr = Units.units_descr(@units)
      "#{@magnitude}*#{u_descr}"
    end

    # more verbose description (not grammatically perfect)
    # If a block is passed, it is used to format the numeric magnitudes (Float numbers) (e.g., for localization)
    #   Units.units{3*m/(2*s)}.abr{|v| v.to_s.tr('.',',') } # => "1,5 meter per second"
    def describe
      return @magnitude.to_s if magnitude?
      u_descr = Units.units_descr(@units, true)
      m = @magnitude
      m = yield(m) if block_given?
      "#{m} #{u_descr}"
    end

    # more natural concise text representation
    # If a block is passed, it is used to format the numeric magnitudes (Float numbers) (e.g., for localization)
    #   Units.units{3*m/(2*s)}.abr{|v| v.to_s.tr('.',',') } # => "1,5 m/s"
    def abr
      txt = self.to_s.gsub('**','^').tr('*',' ')
      if block_given?
        txt.gsub!(/[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)([eE][+-]?(\d+_?)*\d+)?/) do
          v = $&.to_f
          yield v
        end
      end
      txt
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
      other = Units.units(other) if other.kind_of?(String)
      self * (other.kind_of?(Numeric) ? 1.0/other : other.inverse)
    end

    def inspect
      "Units::Measure[#{@magnitude.inspect}, #{@units.inspect}]"
    end

    def *(other)
      other = Units.units(other) if other.kind_of?(String)
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
      other = Units.units(other) if other.kind_of?(String)
      Measure.new self.magnitude+other.to(self.units).magnitude, self.units
    end

    def -(other)
      other = Units.units(other) if other.kind_of?(String)
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
      other = Units.units(other) if other.kind_of?(String)
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
      units = Units.units(units) if units.kind_of?(String)
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
      # other = Units.units(other) if other.kind_of?(String)
      [Measure[other], self]
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
    Measure[*args]
  end
  module_function :Measure

end # Units
