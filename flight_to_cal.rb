require 'sinatra'
# require 'sinatra/base'
# require 'sinatra/json'
require 'json'
require 'dotenv'
require 'bundler/setup'
require 'flightstats'

Dotenv.load
Bundler.require(:development)

# Set root folder
set :root, File.dirname(__FILE__)

set :server, 'thin'

# Set public folder location
set :public_folder, File.dirname(__FILE__) + '/public'


get '/' do
	erb :index
end

post '/get_flight' do
	content_type :json
	airline_code = params['airlineCode']
	flight_number = params['flightNumber']
	departure_date = params['departureDate']
	{airlineCode: airline_code, flightNumber: flight_number, departureDate: departure_date}.to_json
end

@all_airports = JSON.parse(File.read('airports.json'))

FlightStats.app_id = ENV['FLIGHTSTATS_APP_ID']
FlightStats.app_key = ENV['FLIGHTSTATS_APP_KEY']

def airport_code_to_city_name(airport_code)
	begin
		@all_airports.find { |a| a['code'] == airport_code.to_s.upcase }['city']
	rescue
		'City not found'
	end
end

def airport_code_to_address(airport_code)
	begin
		airport = @all_airports.find { |a| a['code'] == airport_code.to_s.upcase }
		return "#{airport['name']}, #{airport['city']}, #{airport['state']}, #{airport['country']}"
	rescue
		'Address not found'
	end
end

def flight_to_gcal(carrier_code, flight_number, departure_year, departure_month, departure_day)
	begin
		flight = (FlightStats::FlightStatus.departing_on carrier_code.to_s, flight_number.to_i, departure_year.to_i, departure_month.to_i, departure_day.to_i).first
		name_of_event = "Flight to #{airport_code_to_city_name(flight.arrival_airport_fs_code)} from #{airport_code_to_city_name(flight.departure_airport_fs_code)} (#{carrier_code} #{flight_number})"
		departure_time_for_url = flight.departure_date.date_utc.split(".").first.gsub('-','').gsub(':','')+'Z'
		arrival_time_for_url = flight.arrival_date.date_utc.split(".").first.gsub('-','').gsub(':','')+'Z'
		long_description = URI.escape("For status updates: https://www.google.com?#q=#{URI.escape(carrier_code.to_s + ' ' + flight_number.to_s)}")
		url = "https://www.google.com/calendar/render?action=TEMPLATE&text=#{URI.escape(name_of_event)}&dates=#{departure_time_for_url}/#{arrival_time_for_url}&details=#{long_description}&location=#{URI.escape(airport_code_to_address(flight.departure_airport_fs_code))}&trp=false"
		return url
	rescue
		return 'Flight not found'
	end
end



# puts flight_to_gcal('KL', 662, 2015, 6, 3)

