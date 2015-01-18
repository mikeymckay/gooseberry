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

class ZanzibarHelpers
  def self.error_message_unless_match(name,list)
    return nil if list.include? name
    closest_match = FuzzyMatch.new(list).find(name)
    return "#{name} is not valid. Do you mean #{closest_match}?"
  end

  def self.shehia_list 
    @db = CouchRest.database("http://localhost:5984/zanzibar")
    #@db = CouchRest.database("http://coconut.zmcp.org:5984/zanzibar")
    @db.get("Geo Hierarchy")["hierarchy"].leaves.flatten 
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
    {
      "type" => "new_case",
      "source" => "gooseberry sms",
      "source_phone" => message.from,
      "caseid" => ZanzibarHelpers.new_case_id,
      "date" => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
      "name" => message.result_for_question_name("name"),
      "positive_test_date" => message.result_for_question_name("positive_test_date"),
      "shehia" => message.result_for_question_name("shehia"),
      "hf" => "TODO",
      "facility_district" => "TODO",
      "hasCaseNotification" => false
    } 
  end

  def self.post_case(message)
    puts notification_from_results(message)
  end

end
