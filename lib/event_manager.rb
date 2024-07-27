require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

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


puts 'EventManager initialized.'


template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents = CSV.open(
  'event_attendees.csv',
   headers: true,
   header_converters: :symbol
)

contents.each do |row|
  
  id = row[0]
  name = row[:first_name]
  zipcode = row[:zipcode]
  phone_number = row[:homephone]
  


  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  phone_number = clean_phone_number(phone_number)
  
  puts phone_number
  # save_thank_you_letter(id,form_letter)
end


