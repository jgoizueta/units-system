# encoding: utf-8

module Units

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

end # Units
