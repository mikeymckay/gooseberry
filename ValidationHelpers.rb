class ValidationHelpers
  def self.error_from_invalid_kenya_county(county_name)
    valid_counties = "Mombasa
Kwale
Kilifi
Tana River
Lamu
Taita-Taveta
Garissa
wajir
Mandera
Marsabit
Isiolo
Meru
Tharaka-Nithi
Embu
Kitui
Machakos
Makueni
Nyandarua
Nyeri
Kirinyaga
Murang'a
Kiambu
Turkana
West Pokot
Samburu
Trans Nzoia
Uasin Gishu
Elgeyo-Marakwet
Nandi
Baringo
Laikipia
Nakuru
Narok
Kajiado
Kericho
Bomet
Kakamega
Vihiga
Bungoma
Busia
Siaya
Kisumu
Homa Bay
Migori
Kisii
Nyamira
Nairobi City
    ".split(/\n/).map{|county|county.upcase}

    return nil if valid_counties.include? county_name.upcase
    closest_match = FuzzyMatch.new(valid_counties).find(county_name.upcase)
    return "#{county_name} is not a valid county. Do you mean #{closest_match}?"

  end
end
