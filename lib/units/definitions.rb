# encoding: utf-8

module Units

  # Units definitions

  # declare SI base units
  si_units :mass,   :kg                  # m
  si_units :length, :m                   # l
  si_units :time,   :s                   # t
  si_units :electric_current, :A         # I
  si_units :temperature, :K              # T
  si_units :luminous_intensity, :cd      # Iv
  si_units :amount_of_substance, :mol    # n

  # define base units
  define :g, 'gram',   :mass, 1E-3
  define :m, 'meter',  :length, 1.0
  define :s, 'second', :time, 1.0
  define :A, 'ampere', :electric_current, 1.0
  define :K, 'kelvin', :temperature, 1.0
  define :cd,'candela',:luminous_intensity, 1.0
  define :mol,'mole',  :amount_of_substance, 1.0

  # declare derived quantities with no named units
  si_units :speed,        u{m/s}
  si_units :acceleration, u{m/s**2}
  si_units :area,         u{m**2}
  si_units :volume,       u{m**3}

  # derived quantities with named units
  define :W,   'Watt',      :power,                u{kg*m**2/s**3} # J/s
  define :Hz,  'herz',      :frequency,            u{1/s}
  define :N,   'newton',    :force,                u{m*kg/s**2}
  define :Pa,  'pascal',    :pressure,             u{N/m**2}
  define :J,   'joule',     :energy,               u{N*m}
  define :C,   'coulomb',   :electric_charge,      u{s*A}
  define :V,   'volt',      :voltage,              u{W/A}
  define :F,   'farad',     :electric_capacitance, u{C/V}
  define :Ω,   'ohm',       :electric_resistance,  u{V/A} # ohm: Ω  omega: Ω
  define :S,   'siemens',   :electric_condctance,  u{1/Ω}
  define :Wb,  'weber',     :magnetic_flux,        u{J/A}
  define :T,   'tesla',     :magnetic_field,       u{N/(A*m)}
  define :H,   'henry',     :inductance,           u{Wb/A}
  define :rad, 'radian',    :angle,                u{m/m}
  define :sr,  'steradian', :solid_angle,          u{m**2/m**2}
  define :lm,  'lumen',     :luminous_flux,        u{cd*sr}
  define :lx,  'lux',       :illuminance,          u{lm/m**2}
  define :nt,  'nit',       :luminance,            u{cd/m**2}
  define :Bq,  'bequerel',  :radioactivity,        u{1/s}
  define :Gy,  'gray',      :absorbed_dose,        u{J/kg}
  define :Sv,  'sievert',   :equivalent_dose,      u{J/kg}
  define :kat, 'katal',     :catalytic_activity,   u{mol/s}

  # Other units

  define :min,  'minute', 60, :s
  define :h,    'hour',   60, :min
  define :d,    'day',    24, :h
  define :mi,   'mile',    1.609344, :km
  define :in,   'inch',    2.54, :cm
  define :ft,   'foot',    0.3048, :m
  define :inch, 'inch',    1, :in # alternative to avoid having to use self.in (in is a Ruby keyword)
  define :lb,   'pound',   0.45359237, :kg

  define :°C, 'degree Celsius',          1, :K, +273.15
  define :°F, 'degree Fahrenheit', 5.0/9.0, :K, +459.67
  define :R,  'rankine',           5.0/9.0, :K

  define :l, 'litre', u{dm**3}
  define :L, 'litre', 1, :l

  define :°, 'degree',     ::Math::PI/180.0, :rad
  define :′, 'arc-minute', ::Math::PI/180.0/60.0, :rad
  define :″, 'arc-second', ::Math::PI/180.0/3600.0, :rad
  # not so cool, but easier to type alternatives:
  define :deg,    'degree',     1, :°
  define :arcmin, 'arc-minute', 1, :′
  define :arcsec, 'arc-second', 1, :″

  define :g0, 'standard gravity', u{9.80665*m/s**2}

  define :bar,  'bar',                    1E5, :Pa
  define :atm,  'atmosphere',             101325.0, :Pa
  define :mWC,  'meters of water column', u{1E3*kg*g0/m**2}
  define :Torr, 'torricelli',             u{atm/760}
  define :mHg,  'mHg',                    u{13.5951E3*kg*g0/m**2}

  # define :kp, 'kilopond', :force, u{kg*g0} # or define pond?
  define :gf,  'gram-force',  u{g*g0} # kilopond kp = kgf
  define :lbf, 'pound-force', u{lb*g0}

  define :dyn,   'dyne', 10, :µN # u{1*g*cm/s**2}
  define :galUS, 'U.S. liquid gallon', u{231*self.in**3}
  define :galUK, 'Imperial gallon', 4.546092, :l
  define :hp,    'horsepower', u{550*ft*lbf/s}

  define :psi, 'pounds-force per square inch', u{lbf/self.in**2}

end # Units
