require 'helper'

class TestUnitsSystem < Test::Unit::TestCase
  
  include Units::UseBlocks

  should "be possible to define Measures with a units block" do
    assert_equal Units::Measure, Units.units{m}.class
    assert_equal 1.0, Units.units{m}.magnitude
    assert_equal [:m, 1], Units.units{m}.units[:length]
  end

  should "be possible to define Measures with a shorthand u block" do
    assert_equal Units::Measure, Units.u{m}.class
    assert_equal 1.0, Units.u{m}.magnitude
    assert_equal [:m, 1], Units.u{m}.units[:length]
  end

  should "determine units dimension correctly" do
    assert_equal :length, Units.u{m}.dimension
    assert_equal :length, Units.u{mi}.dimension
    assert_equal :mass, Units.u{g}.dimension
    assert_equal :time, Units.u{s}.dimension
    assert_equal :electric_current, Units.u{A}.dimension
    assert_equal :temperature, Units.u{K}.dimension
    assert_equal :luminous_intensity, Units.u{cd}.dimension
    assert_equal :amount_of_substance, Units.u{mol}.dimension
    assert_equal :power, Units.u{W}.dimension
    assert_equal :pressure, Units.u{Pa}.dimension
    assert_equal :mass, Units.u{kg}.dimension
    assert_equal :length, Units.u{km}.dimension
    assert_equal :length, Units.u{mm}.dimension
    assert_equal :length, Units.u{Mm}.dimension
  end

  should "allow unit arithmetic" do
    assert_equal :speed, Units.u{m/s}.dimension
    assert_equal :length, Units.u{m**2/m}.dimension
    assert_equal :length, Units.u{(m*m)/m}.dimension
    assert_equal :volume, Units.u{m*m**2}.dimension
    assert_equal :force, Units.u{m*kg/s**2}.dimension
  end

  should "convert simple units correctly" do
    assert_equal 1E5, Units.u{100*km.in(m)}
    assert_equal 10, Units.u{10000*m.in(km)}
    assert_equal 254, Units.u{100*self.in.in(cm)}
  end

  should "convert compound units correctly" do
    assert_equal 75, Units.u{(270*km/h).in(m/s)}
    assert_equal 270, Units.u{(75*m/s).in(km/h)}
    assert_in_delta Units.u{g*cm/s**2}.magnitude, Units.u{dyn.to(g*cm/s**2)}.magnitude, Float::EPSILON
  end

  should "add units correctly" do
    assert_equal 5, Units.u{3*m+2*m}.magnitude
    assert_equal 5, Units.u{3*kg+2*kg}.magnitude
  end

  should "add units correctly with implied conversions" do
    assert_equal 5, Units.u{3*m+200*cm}.magnitude
    assert_equal [:m,1],Units.u{3*m+200*cm}.units[:length]
    assert_equal 85, Units.u{10*m/s +  270*km/h}.magnitude
  end

  should "choke on inconsistent units" do
    assert_raise(RuntimeError){Units.units{m+kg}}
    assert_raise(RuntimeError){Units.units{m/s+m/s**2}}
    assert_raise(RuntimeError){Units.units{(m).to(kg)}}
    assert_raise(RuntimeError){Units.units{(m/s).to(m/s**2)}}
  end

end
