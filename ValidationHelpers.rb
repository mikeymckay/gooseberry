class ValidationHelpers

  def self.closest_animal(animal)
    FuzzyMatch.new(JSON.parse(IO.read("animals.json"))).find(animal)
  end

  def self.closest_city(city)
    FuzzyMatch.new(JSON.parse(IO.read("countriesToCities.json")).values.flatten).find(city)
  end
    
  def self.valid_counties
    [
      "BARINGO",
      "BOMET",
      "BUNGOMA",
      "BUSIA",
      "ELGEYO-MARAKWET",
      "EMBU",
      "GARISSA",
      "HOMA BAY",
      "ISIOLO",
      "KAJIADO",
      "KAKAMEGA",
      "KERICHO",
      "KIAMBU",
      "KILIFI",
      "KIRINYAGA",
      "KISII",
      "KISUMU",
      "KITUI",
      "KWALE",
      "LAIKIPIA",
      "LAMU",
      "MACHAKOS",
      "MAKUENI",
      "MANDERA",
      "MARSABIT",
      "MERU",
      "MIGORI",
      "MOMBASA",
      "MURANG'A",
      "NAIROBI CITY",
      "NAKURU",
      "NANDI",
      "NAROK",
      "NYAMIRA",
      "NYANDARUA",
      "NYERI",
      "SAMBURU",
      "SIAYA",
      "TAITA-TAVETA",
      "TANA RIVER",
      "THARAKA-NITHI",
      "TRANS NZOIA",
      "TURKANA",
      "UASIN GISHU",
      "VIHIGA",
      "WAJIR",
      "WEST POKOT"
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
