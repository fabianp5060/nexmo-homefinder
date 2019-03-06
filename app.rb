#!/usr/bin/env ruby
#
STDOUT.sync = true

require 'nexmo'
require 'sinatra'
require 'json'
require 'dm-core'
require 'dm-migrations'
require 'json'

require_relative 'nexmoController'

class HomeFinderRoutes < Sinatra::Base

	get '/answer_home' do
		root_url = request.base_url
		content_type :json		
		return $nexmo.home_finder_demo(params,root_url)
	end

	post '/event_home' do
		root_url = request.base_url
		request_payload = JSON.parse(request.body.read, symbolize_names: true)
		response = $nexmo.home_finder_event(request_payload,root_url)
	end

	get '/' do; 200; end
	
	get '/homefinder' do; erb :homefinder; end

	post '/homefinder' do
		msg = "Hi there, we see you are close to a home that matches your search criteria.  Respond with SHOW to retrieve the MLS listing for the home or MAP to get directions sent to your phone"
		$nexmo.send_sms(msg,params['phone_number'])

		200
	end


end


class HomeFinderNexmoController < NexmoBasicController

	def home_finder_demo(params,root_url)
		puts "#{__method__} | My Params : #{params}"	
		return ncco_answer
	end

	def home_finder_event(request_payload,root_url)
		puts "#{__method__} | #{request_payload}"
		keyword = request_payload[:keyword] || nil
		phone_number = request_payload[:msisdn]	

		puts "Got my keyword: #{keyword}"
		if request_payload != nil
			puts "found the keyword: #{keyword}"
			case keyword
			when "SHOW"
				puts "Made it to SHOW"
				handle_show(phone_number)				
			when "SCHEDULE"
				puts "Made it to SCHEDULE"
				handle_schedule(phone_number)
			when "SEE"
				puts "Made it to SEE"
				handle_see(phone_number)
			when "MAP"
				puts "Made it to MAP"
				handle_map(phone_number)
			else
				puts "DID Not find matching KEYWORD"
				handle_error(phone_number)
			end
		end

		return 200
	end		

	def ncco_answer
		return [
			{
				"action": "talk",
				"text": "Sorry, the user you dialed is not registered for this application"
			}
		].to_json

	end	

	def handle_show(phone_number)
		msg = "Here is the link to the house.  Respond with SCHEDULE to reserve a time to see the house or SEE to get a live look with a Realtor right now"
		$nexmo.send_sms(msg,phone_number)
	end

	def handle_schedule(phone_number)
		msg = "I will schedule a call thank you!.  Respond with SCHEDULE to reserve a time to see the house or SEE to get a live look with a Realtor right now"
		$nexmo.send_sms(msg,phone_number)		
	end

	def handle_see(phone_number)
		msg = "Please click on the link to initiate a live virtual tour with the Realtor"
	end

	def handle_map(phone_number)
		map = 'https://goo.gl/maps/aFsuwgrb3vy'
		msg = "Click on the link to get directions to the house: #{map}"
		$nexmo.send_sms(msg,phone_number)
	end

	def handle_error(phone_number)
	end

end

class MyApp < Sinatra::Base
	
	configure do 
    	enable :sessions
    end

    # Set Root Directories
    $root_dir = File.dirname(__FILE__)
    $views_dir = Proc.new { File.join(root, "views") } 
	set :root, $root_dir
	set :views, $views_dir

	#Import App Specific Routes
    use HomeFinderRoutes  

	# Nexmo General Demo Environment
	key = ENV['NEXMO_API_KEY']
	sec = ENV['NEXMO_API_SECRET']
	app_key = ENV['NEXMO_APPLICATION_PRIVATE_KEY_PATH']

	# Nexmo App Specific Details
	app_name = ENV['HOMEFINDER_APP_NAME']
	app_id = ENV['HOMEFINDER_APP_ID']
	$did = ENV['HOMEFINDER_DID']
	$web_server = ENV['LB_WEB_SERVER'] || JSON.parse(Net::HTTP.get(URI('http://127.0.0.1:4040/api/tunnels')))['tunnels'][0]['public_url']

	# Create Nexmo Object
	logger = Logger.new(STDOUT)
	$client = Nexmo::Client.new(
	  logger: logger,	
	  api_key: key,
	  api_secret: sec,
	  application_id: app_id,
	  private_key: File.read("#{app_key}")
	)

	$nexmo = HomeFinderNexmoController.new  	
	$nexmo.update_webserver(app_id,$web_server,app_name)
end




