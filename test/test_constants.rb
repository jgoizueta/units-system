require 'helper'

class TestConstants < Test::Unit::TestCase

  include Units::UseBlocks

  should "have qualified constants" do
    assert_equal 299792458, Units::Const.c.magnitude
    assert_equal 6.67300E-11, Units::Const.G.magnitude
    assert_equal [:m, 1], Units::Const.c.units[:length]
    assert_equal 299792458**2, (Units::Const.c**2).magnitude
    assert_equal [:m, 2], (Units::Const.c**2).units[:length]
    assert_nil (Units::Const.c/Units.u{m}).units[:length]
  end

  should "have qualified constants in units blocks" do
    assert_equal 299792458, Units.units{Units::Const.c}.magnitude
    assert_equal 6.67300E-11, Units.units{Units::Const.G}.magnitude
    assert_equal [:m, 1], Units.units{Units::Const.c}.units[:length]
    assert_equal 299792458**2, Units.units{Units::Const.c**2}.magnitude
    assert_equal [:m, 2], Units.units{Units::Const.c**2}.units[:length]
    assert_nil Units.units{Units::Const.c/m}.units[:length]
  end

  should "not need qualification for Const inside a units block" do
    assert_equal 299792458, Units.units{Const.c}.magnitude
    assert_equal 6.67300E-11, Units.units{Const.G}.magnitude
    assert_equal [:m, 1], Units.units{Const.c}.units[:length]
    assert_equal 299792458**2, Units.units{Const.c**2}.magnitude
    assert_equal [:m, 2], Units.units{Const.c**2}.units[:length]
    assert_nil Units.units{Const.c/m}.units[:length]
  end

  should "provide constant values" do
    c = Units::Const.c
    assert_equal 299792458, Units.units{c}.magnitude
    assert_equal [:m, 1], Units.units{c}.units[:length]
    assert_equal 299792458**2, Units.units{c**2}.magnitude
    assert_equal [:m, 2], Units.units{c**2}.units[:length]
    assert_nil Units.units{c/m}.units[:length]
  end

  should "allow use of local unqualified declared constants" do
    assert_equal 299792458, Units.with_constants(:c){c}.magnitude
    assert_equal 299792458*6.67300E-11, Units.with_constants(:c,:G){G*c}.magnitude
    assert_nil Units.with_constants(:c){c/m}.units[:length]
    assert_in_delta 1.782661844855044e-27, Units.with_constants(:c){1*GeV/c**2}.to(:kg).magnitude, Float::EPSILON
  end

  should "not need qualification for Const inside a with_constants block" do
    assert_equal 299792458, Units.with_constants{Const.c}.magnitude
    assert_equal 6.67300E-11, Units.with_constants{Const.G}.magnitude
    assert_equal [:m, 1], Units.with_constants{Const.c}.units[:length]
    assert_equal 299792458**2, Units.with_constants{Const.c**2}.magnitude
    assert_equal [:m, 2], Units.with_constants{Const.c**2}.units[:length]
    assert_nil Units.with_constants{Const.c/m}.units[:length]
  end

  should "define new constants" do
    Units.constant :cc, "test constant c", Units::Const.c
    assert_equal Units::Const.c, Units::Const.cc
    assert_equal 299792458*6.67300E-11, Units.with_constants(:cc,:G){G*cc}.magnitude
    Units.constant :GG, "test constant G", Units::Const.G
    assert_equal Units::Const.G, Units::Const.GG
    assert_equal 299792458*6.67300E-11, Units.with_constants(:c,:GG){GG*c}.magnitude
  end

end
