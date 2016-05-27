class ValidationHelpers

  def self.closest_animal(animal)
    FuzzyMatch.new(JSON.parse(IO.read("animals.json"))).find(animal)
  end

  def self.closest_city(city)
    FuzzyMatch.new(JSON.parse(IO.read("countriesToCities.json")).values.flatten).find(city)
  end
    
  def self.valid_counties
    [
      "MOMBASA",
      "KWALE",
      "KILIFI",
      "TANA RIVER",
      "LAMU",
      "TAITA-TAVETA",
      "GARISSA",
      "WAJIR",
      "MANDERA",
      "MARSABIT",
      "ISIOLO",
      "MERU",
      "THARAKA-NITHI",
      "EMBU",
      "KITUI",
      "MACHAKOS",
      "MAKUENI",
      "NYANDARUA",
      "NYERI",
      "KIRINYAGA",
      "MURANG'A",
      "KIAMBU",
      "TURKANA",
      "WEST POKOT",
      "SAMBURU",
      "TRANS NZOIA",
      "UASIN GISHU",
      "ELGEYO-MARAKWET",
      "NANDI",
      "BARINGO",
      "LAIKIPIA",
      "NAKURU",
      "NAROK",
      "KAJIADO",
      "KERICHO",
      "BOMET",
      "KAKAMEGA",
      "VIHIGA",
      "BUNGOMA",
      "BUSIA",
      "SIAYA",
      "KISUMU",
      "HOMA BAY",
      "MIGORI",
      "KISII",
      "NYAMIRA",
      "NAIROBI CITY"
    ]
  end

  def self.closest_valid_county_match(county_name)
    return county_name.upcase if self.valid_counties.include? county_name.upcase
    return FuzzyMatch.new(self.valid_counties).find(county_name.upcase)
  end

  # Poorly named, but leaving for legacy purposes
  def self.closest_match(county_name)
    self.closest_valid_county_match(county_name)
  end

  def self.error_from_invalid_kenya_county(county_name)
    return nil if self.valid_counties.include? county_name.upcase
    closest_match = FuzzyMatch.new(valid_counties).find(county_name.upcase)
    return "#{county_name} is not a valid county. Do you mean #{closest_match}?"

  end
end
