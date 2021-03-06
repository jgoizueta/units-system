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

  should "define measures with bracket constructor" do
    assert_equal Units::Measure, Units::Measure[1.0, :m].class
    assert_equal 1.0, Units::Measure[1.0, :m].magnitude
    assert_equal [:m, 1], Units::Measure[1.0, :m].units[:length]
  end

  should "be flexible with constructor arguments" do
    assert_equal Units::Measure[1.0, :m], Units::Measure[:m]
    assert_equal Units::Measure[2.0, {}], Units::Measure[2.0]
    assert_equal Units::Measure[1.0, {}], Units::Measure[]
  end

  should "define measures with method constructor" do
    assert_equal Units::Measure, Units.Measure(1.0, :m).class
    assert_equal 1.0, Units.Measure(1.0, :m).magnitude
    assert_equal [:m, 1], Units.Measure(1.0, :m).units[:length]
  end

  should "compare measure objects" do
    assert_equal Units::Measure[1.0, :m], Units::Measure[1.0, :m]
    assert_not_equal Units::Measure[1.0, :m], Units::Measure[2.0, :m]
    assert_not_equal Units::Measure[1.0, :m], Units::Measure[1.0, :s]
    assert_equal Units.u{m}, Units::Measure[1.0, :m]
    assert_not_equal Units.u{m}, Units.u{s}
    assert_not_equal Units.u{2*m}, Units.u{3*m}
    assert_equal Units.u{2*m}, Units.u{2*m}
    assert_equal Units.u{2*m/s}, Units.u{2*m/s}
    assert_not_equal Units.u{2*m/s}, Units.u{2*m/h}
    assert_not_equal Units.u{2*m/s}, Units.u{2*m/kg}
    assert_not_equal Units.u{2*m/s}, Units.u{3*m/s}
  end

  should "admit units defined as text string" do
    assert_equal Units::Measure, Units.units('m').class
    assert_equal 1.0, Units.units('m').magnitude
    assert_equal [:m, 1], Units.units('m').units[:length]
    assert_equal :speed, Units.u('m/s').dimension
    assert_equal Units.u{m}, Units.u("m")
    assert_equal 5, Units.u("3*m+2*m").magnitude
    assert_equal Units.u{3*m+2*m}, Units.u("3*m+2*m")
    assert_equal 5, Units.units("3*m+2*m").magnitude
    assert_equal Units.u{3*m+2*m}, Units.units("3*m+2*m")
    assert_raise(ArgumentError){Units.u("m"){m}}
  end

  should "admit units defined as text for conversion arguments" do
    assert_equal 75, Units.u{(270*km/h)}.in('m/s')
    assert_equal 270, Units.u{(75*m/s)}.in('km/h')
    assert_in_delta Units.u{g*cm/s**2}.magnitude, Units.u{dyn}.to('g*cm/s**2').magnitude, Float::EPSILON
  end

  should "handle well capitalized units names" do
    assert_nothing_raised{Units.units{W}}
    assert_nothing_raised{Units.units{3*W}}
    assert_nothing_raised{Units.units{3*N}}
    assert_nothing_raised{Units.units{3*A}}
  end

  should "render valid code when inspecting measures" do
    assert_equal Units.u{m}, eval(Units.u{m}.inspect)
    assert_equal Units.u{3*m/s}, eval(Units.u{3*m/s}.inspect)
    assert_in_delta Units.u{3*m/s+2*km/h}.magnitude, eval(Units.u{3*m/s+2*km/h}.inspect).magnitude, 1E-12
    assert_equal Units.u{3*m/s+2*km/h}.units, eval(Units.u{3*m/s+2*km/h}.inspect).units
  end

  should "allow arithmetic between measures and text" do
    assert_equal Units.u{m/s}, Units.u{m}/'s'
    assert_equal Units.u{m*s}, Units.u{m}*'s'
    assert_equal Units.u{m+km}, Units.u{m}+'km'
    assert_equal Units.u{m-km}, Units.u{m}-'km'
  end

  should "represent abbreviated units" do
    assert_equal "1.0 m", Units.u{m}.abr
    assert_equal "3.0 m", Units.u{3*m}.abr
    assert_equal "3.0 m/s", Units.u{3*m/s}.abr
    assert_match /\A3\.555555555555\d+ m\/s\Z/, Units.u{3*m/s + 2*km/h}.abr
    assert_equal "1,5 m/s", Units.units{3*m/(2*s)}.abr{|v| v.to_s.tr('.',',') }
  end

end
