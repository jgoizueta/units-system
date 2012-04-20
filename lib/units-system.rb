# encoding: utf-8

require 'modalsupport'
require 'units/measure'
require 'units/prefixes'
require 'units/system'
require 'units/math'

module Units

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

end # Units

require 'units/definitions'
