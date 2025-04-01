require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def validate_phone(phone)
  phone_number = phone.gsub(/\D/, '')
  #/\D/ is a regex pattern that matches any character that IS NOT a digit
  
  if    phone_number.length == 10
    phone_number
  elsif phone_number.length == 11
    phone_number[0] == '1' ? phone_number[1..] : 'Bad number'
  else
    'Bad number'
  end
end

def extract_hour(reg_date)
  DateTime.strptime(reg_date, '%d/%M/%Y %H:%M').hour
end

def extract_wday(reg_date)
  DateTime.strptime(reg_date, '%d/%M/%Y %H:%M').strftime("%A")
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

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
all_hours = []
all_wdays = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = validate_phone(row[:homephone])
  hour = extract_hour(row[:regdate])
  all_hours.push(hour)
  wday = extract_wday(row[:regdate])
  all_wdays.push(wday)

  puts "Name: #{name}, Phone Number: #{phone}"
  
  #legislators = legislators_by_zipcode(zipcode)
  #form_letter = erb_template.result(binding)
  #save_thank_you_letter(id,form_letter)
end

peak_hours = all_hours.tally.sort_by { |key, value| -value }.to_h
puts "Peak hours: #{peak_hours}"
peek_wdays = all_wdays.tally.sort_by { |key, value| -value }.to_h
puts "Peak week days: #{peek_wdays}"