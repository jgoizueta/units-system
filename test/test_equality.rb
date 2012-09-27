# encoding: UTF-8

require 'helper'

class TestEquality < Test::Unit::TestCase

  include Units::UseBlocks

  should "regard measures with equivalent value equal" do
    assert Units.u{ohm}==Units.u{Ω}
    assert Units.u{inch}==Units.u{self.in}
    assert !(Units.u{ohm}!=Units.u{Ω})
    assert !(Units.u{inch}!=Units.u{self.in})
    assert Units.u{m}==Units.u{100*cm}
    assert !(Units.u{m}!=Units.u{100*cm})
    assert !(Units.u{m}==Units.u{cm})
    assert !(Units.u{m}==Units.u{10*cm})
    assert Units.u{m}!=Units.u{cm}
    assert !(Units.u{m}==Units.u{10*cm})
    assert Units.u{km/h}==Units.u{1000*m/h}
    assert Units.u{km/h}==Units.u{1000*m/(60*min)}
    assert Units.u{km/h}==Units.u{km/(60*min)}
    assert Units.u{km/h}==Units.u{km*s/(60*min*s)}
    assert Units.u{km/h}!=Units.u{km*s/(30*min*s)}
    assert Units.u{km/h}!=Units.u{km*s/(60*min)}
  end

  should "regard measures with same value and units identical" do
    assert !(Units.u{ohm}.eql?(Units.u{Ω}))
    assert !(Units.u{inch}.eql?(Units.u{self.in}))
    assert !(Units.u{m}.eql?(Units.u{100*cm}))
    assert Units.u{m}.eql?(Units.u{1*m})
    assert Units.u{m}.eql?(Units.u{1*m/s}*Units.u{s})
    assert !(Units.u{m}.eql?(Units.u{10*cm}))
    assert !(Units.u{km/h}.eql?(Units.u{1000*m/h}))
    assert !(Units.u{km/h}.eql?(Units.u{1000*m/(60*min)}))
    assert !(Units.u{km/h}.eql?(Units.u{km/(60*min)}))
    assert !(Units.u{km/h}.eql?(Units.u{km*s/(60*min*s)}))
    assert !(Units.u{km/h}.eql?(Units.u{km*s/(30*min*s)}))
    assert !(Units.u{km/h}.eql?(Units.u{km*s/(60*min)}))
    # assert Units.u{2*km/h}.eql?(Units.u{2000*m/(60*min)}.to(Units.u{km/h}))
  end

end
