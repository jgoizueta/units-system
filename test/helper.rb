require 'rubygems'
require 'test/unit'
require 'shoulda'

$KCODE='UTF8' if RUBY_VERSION<"1.9"
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'units-system'

class Test::Unit::TestCase
end
