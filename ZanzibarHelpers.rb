class Hash
  # {'x'=>{'y'=>{'z'=>1,'a'=>2}}}.leaves == [1,2]
  def leaves
    leaves = []

    each_value do |value|
      value.is_a?(Hash) ? value.leaves.each{|l| leaves << l } : leaves << value
    end

    leaves
  end
end

$zanzibar_couchdb = CouchRest.database("http://localhost:5984/zanzibar")

class ZanzibarHelpers
  def self.error_message_unless_match(name,list)
    return nil if list.include? name
    closest_match = FuzzyMatch.new(list).find(name)
    return "#{name} is not valid. Do you mean #{closest_match}?"
  end

  def self.shehia_list 
    $zanzibar_couchdb.get("Geo Hierarchy")["hierarchy"].leaves.flatten 
  end 

  def self.error_message_unless_valid_shehia(shehia)
    ZanzibarHelpers.error_message_unless_match shehia, ZanzibarHelpers.shehia_list
  end

  def self.date_format(date)
    date.match(/(\d{1,2}).(\d{1,2}).(\d\d\d\d)/)
  end

  def self.error_message_unless_valid_date(date)
    date_format = ZanzibarHelpers.date_format(date)
    if date_format
      (day,month,year) = date_format.captures.map{|value|value.to_i}
      puts day
      puts month
      puts year
      if day > 31
        return "Day value '#{day}' must not be more than 31."
      elsif month > 12
        return "Month value '#{month}' must not be more than 12."
      elsif year < 1900 or year > 2200
        return "Year value '#{year}' must be between 1900 and 2200."
      else 
        begin
         Date.new(year,month,day)
        rescue
         return "Invalid date: #{day}-#{month}-#{year}."
        end
        return nil
      end
    else
      return "Invalid date '#{date}'."
    end
  end

  def self.error_message_unless_date_on_or_before_today(date)
    error_message_unless_valid_date = ZanzibarHelpers.error_message_unless_valid_date(date)
    if error_message_unless_valid_date(date)
      error_message_unless_valid_date
    else
      (day,month,year) = ZanzibarHelpers.date_format(date).captures.map{|value|value.to_i}
       if Date.new(year,month,day) > Date.today
         return "Invalid date - must be on or before today (#{Date.today.day}-#{Date.today.month}-#{Date.today.year})."
       else
         return nil
       end
    end
  end

  def self.year_week_format_match(text)
    # 4 numbers followed by at least one non-number followed by 1-2 numbers, e.g. 2013 12
    text.match(/^(\d{4})[^\d]+(\d{1,2})$/)
  end

  def self.extract_year_week_from_match(match)
    match.captures.map{|number|number.to_i}
  end

  def self.extract_year_week(text)
    self.extract_year_week_from_match ZanzibarHelpers.year_week_format_match(text)
  end

  def self.error_message_unless_year_week_on_or_before_today(text)
    correct_format = ZanzibarHelpers.year_week_format_match(text)

    return "Invalid format." unless correct_format
    
    (year,week) = self.extract_year_week_from_match(correct_format)

    maximum_number_of_weeks_in_any_year = 52
    start_year = 2014

    if (year < start_year or year > Date.today.year)
      "#{year} is not a valid year, must be a number between 2014 and #{Date.today.year}."
    elsif (week > maximum_number_of_weeks_in_any_year)
      "Week, #{week}, must be less than #{maximum_number_of_weeks_in_any_year}."
    elsif (Date.commercial(year,week) > Date.today)
      "Year week, #{year} #{week}, must be the same or earlier than today's year and week: #{Date.today.year} #{Date.today.cweek}."
    else
      nil
    end
  end

  def self.opd_format_match(text)
    text.match(/^(\d+)[^\d]+(\d+)[^\d]+(\d+)$/)
  end

  def self.extract_total_visits_malaria_positive_malaria_negative_from_match(match)
    match.captures.map{|number|number.to_i}
  end

  def self.extract_total_visits_malaria_positive_malaria_negative(text)
    self.extract_total_visits_malaria_positive_malaria_negative_from_match self.opd_format_match(text)
  end

  def self.error_message_unless_valid_opd(text)
    correct_format = self.opd_format_match(text)

    return "Invalid format, expecting 3 numbers separated by spaces." unless correct_format

    (total_visits, malaria_positive, malaria_negative) = self.extract_total_visits_malaria_positive_malaria_negative_from_match correct_format

    total_visits_limit = 1000

    if total_visits.nil? or malaria_positive.nil? or malaria_negative.nil?
      "At least three numbers are required."
    elsif total_visits > total_visits_limit
      "Total visits '#{total_visits}' is not valid, must be less than #{total_visits_limit}"
    elsif malaria_positive + malaria_negative > total_visits
      "The sum of malaria positive and malaria negative (#{malaria_positive}+#{malaria_negative} = #{malaria_positive+malaria_negative}) must not exceed the total visits (#{total_visits})."
    else
      nil
    end
  end

  def self.opd_complete_message(message)
    (year,week) = ZanzibarHelpers.extract_year_week(message.result_for_question_name("year_week"))
    (under_5_total, under_5_malaria_positive, under_5_malaria_negative) = ZanzibarHelpers.extract_total_visits_malaria_positive_malaria_negative(message.result_for_question_name "under_5")
    (over_5_total, over_5_malaria_positive, over_5_malaria_negative) = ZanzibarHelpers.extract_total_visits_malaria_positive_malaria_negative(message.result_for_question_name "over_5")
    facility= ZanzibarHelpers.health_facility_name_for_number(message.from)

    "Thanks. #{facility}, y#{year}, w#{week}: <5: [#{under_5_total}, +#{under_5_malaria_positive}, -#{under_5_malaria_negative} ] >5: [#{over_5_total} , +#{over_5_malaria_positive}, -#{over_5_malaria_negative}]"

  end


  def self.weekly_report_from_results(message)
    (year,week) = ZanzibarHelpers.extract_year_week(message.result_for_question_name("year_week"))
    (under_5_total, under_5_malaria_positive, under_5_malaria_negative) = ZanzibarHelpers.extract_total_visits_malaria_positive_malaria_negative(message.result_for_question_name "under_5")
    (over_5_total, over_5_malaria_positive, over_5_malaria_negative) = ZanzibarHelpers.extract_total_visits_malaria_positive_malaria_negative(message.result_for_question_name "over_5")
    facility_information = ZanzibarHelpers.health_facility_for_number(message.from)
    {
      "type" => "weekly_report",
      "source" => "gooseberry sms",
      "source_phone" => message.from,
      "date" => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
      "year" => year,
      "week" => week,
      "under 5 opd" => under_5_total,
      "under 5 positive" => under_5_malaria_positive,
      "under 5 negative" => under_5_malaria_negative,
      "over 5 opd" => over_5_total,
      "over 5 positive" => over_5_malaria_positive,
      "over 5 negative" => over_5_malaria_negative,
      "hf" => facility_information["facility"],
      "facility_district" => facility_information["facility_district"],
    }
  end

  def self.post_weekly_report(message)
    puts $zanzibar_couchdb.save_doc(weekly_report_from_results(message))
  end

# Convert a number to a more compact and easy to transcribe string
  def self.to_base(number,to_base = 30)
    # we are taking out the following letters B, I, O, Q, S, Z because the might be mistaken for 8, 1, 0, 0, 5, 2 respectively
    base_map = ["0","1","2","3","4","5","6","7","8","9","A","C","D","E","F","G","H","J","K","L","M","N","P","R","T","U","V","W","X","Y"]

    results = ''
    quotient = number.to_i

    while quotient > 0
      results = base_map[quotient % to_base] + results
      quotient = (quotient / to_base)
    end
    results
  end

  def self.new_case_id()
    # Milliseconds (not quite) since 2014,1,1 base 30 encoded
    ZanzibarHelpers.to_base((Time.now - Time.new(2014,1,1))*1000)
  end

  def self.notification_from_results(message)
    facility_information = ZanzibarHelpers.health_facility_for_number(message.from)
    
    {
      "type" => "new_case",
      "source" => "gooseberry sms",
      "source_phone" => message.from,
      "caseid" => ZanzibarHelpers.new_case_id,
      "date" => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
      "name" => message.result_for_question_name("name"),
      "positive_test_date" => message.result_for_question_name("positive_test_date"),
      "shehia" => message.result_for_question_name("shehia"),
      "hf" => facility_information["facility"],
      "facility_district" => facility_information["facility_district"],
      "hasCaseNotification" => false
    } 
  end

  def self.post_case(message)
    puts $zanzibar_couchdb.save_doc(notification_from_results(message))
  end

  def self.health_facility_name_for_number(number)
    health_facility = ZanzibarHelpers.health_facility_for_number(number)
    if health_facility
      health_facility["facility"]
    else
      nil
    end
  end


  def self.health_facility_for_number(number)
    # Get just the numbers, ignore leading zeroes
    number = number.gsub(/\D/, '').gsub(/^0/,"").gsub(/^+255/,"")

    facility_district = nil
    facility = nil

    facilityHierarchy = JSON.parse(RestClient.get "#{$zanzibar_couchdb}/Facility%20Hierarchy", {:accept => :json})["hierarchy"]
    facilityHierarchy.each do |district,facilityData|
      break if facility_district and facility
      facilityData.each do |data|
        if data["mobile_numbers"].map{|num| num.gsub(/\D/,'').gsub(/^0/,"") }.include? number
          facility_district = district
          facility = data["facility"]
          break
        end
      end
    end

    return {
      "facility" => facility,
      "facility_district" => facility_district
    }
  end

end
