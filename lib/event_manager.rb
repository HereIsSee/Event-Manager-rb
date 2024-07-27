require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def clean_phone_number(phone_number)
  digit_count = digit_count_in_string(phone_number)
  if phone_number.nil? || digit_count > 11 || digit_count < 10
    return "The given number is invalid!"
  end
  if digit_count == 11 && phone_number[0] != 1
    return "The given number is invalid!"
  end
  if digit_count == 11 && phone_number[0] == 1
    return remove_first_digit_in_string(phone_number)
  end
  phone_number
end

def digit_count_in_string(string)
  string.chars.reduce(0) {|sum, value| sum+= 1 if value.=~ /\d/; sum}
end

def remove_first_digit_in_string(string)
  string.sub!(/\d/, "")
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

#Task: find out at which hours the most people registered
#Have for each hour of the day a count of how many people registered
#Take the 3 hours at which the most amount of people registered,
#those will be the peak hours that we will use for advertising

def format_string_to_datetime string
  date = DateTime.strptime(string, "%m/%d/%Y %k:%M").strftime("%Y/%m/%d %H:%M")
  date[0] = "2"
  date = DateTime.strptime(date, "%Y/%m/%d %H:%M")
end

def count_registration_number_at_hour array_of_days, day
  array_of_days[day] += 1
end

def peak_registration_hours array_of_hours
  array_of_hours.sort_by {|_key, value| value}.reverse.map {|key, value| key}[0..2]
end

def count_registration_number_at_hour array_of_hours, hour
  array_of_hours[hour] += 1
end



puts 'EventManager initialized.'


template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents = CSV.open(
  'event_attendees.csv',
   headers: true,
   header_converters: :symbol
)

hours_registration_counter = Hash[(0 .. 23).to_a.map { |hour| [hour, 0] }]
day_registration_counter = {
  "Monday"=> 0, "Tuesday"=> 0, "Wednesday"=> 0, "Thursday"=> 0, 
  "Friday"=> 0, "Saturday"=> 0, "Sunday"=> 0
}

contents.each do |row|
  
  id = row[0]
  name = row[:first_name]
  zipcode = row[:zipcode]
  phone_number = row[:homephone]
  registration_date = row[:regdate]
  
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  phone_number = clean_phone_number(phone_number)
  registration_date = format_string_to_datetime registration_date
  
  count_registration_number_at_hour(hours_registration_counter, registration_date.hour)
  
  count_registration_number_at_hour(day_registration_counter, registration_date.strftime( "%A" ))
  # save_thank_you_letter(id,form_letter)
end

p day_registration_counter

