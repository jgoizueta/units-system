# encoding: utf-8

require 'modalsupport'
require 'units/measure'
require 'units/prefixes'
require 'units/system'
require 'units/math'

module Units

  # This must be included in any module or class from which units expressions
  # are to be used in units or u blocks.
  # It is not needed in Ruby 1.9.1 due to they way constant look-up is done in that version,
  # but Ruby 1.9.2 has changed that an requires this again.
  module UseBlocks
    @@constants = nil # an instance variable would not work here because const_missing is executed on other modules (which include this one)
    def self.append_features(target)
      def target.const_missing(name)
        begin
          name = name.to_sym
          if name==:Const
            Units::Const
          else
            result = @@constants[name] if @@constants
            result || Units.Measure(name)
          end
        rescue ArgumentError
          super
        end
      end
    end

    def self.with_constants(*consts)
      prev = @@constants
      # @@constants = consts.map_hash{|c| Units.constant(c)}
      @@constants = {}
      consts.each do |c|
        c = c.to_sym
        @@constants[c] = Units.constant(c)
      end
      result = yield
      @@constants = prev
      result
    end

  end

  include UseBlocks

end # Units

require 'units/definitions'
