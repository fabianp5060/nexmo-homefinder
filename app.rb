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
require_relative 'time_check'

class HomeFinderRoutes < Sinatra::Base

# Nexmo Specific Endpoints
	get '/answer_home' do
		root_url = request.base_url
		content_type :json		
		return $nexmo.home_finder_demo(params,root_url)
	end

	post '/event_home' do
		root_url = request.base_url
		puts "#{__method__} | My Params: #{params}"
		response = $nexmo.home_finder_event(params,root_url)
	end

# AWS Health Check
	get '/' do; 200; end

# App Endpoints

	get '/logout' do
		UserDB.destroy

		redirect '/login'
	end

	get '/login' do
		@title = "Login as Agent"
		if params.include?(:error)
			@title = "Please re-enter your Name and Number and only use Alphanumeric values."
		end
		erb :login
	end

	post '/login' do
		puts "#{__method__} | Params : #{params}"

		agent_name = $nexmo.sanitize(params[:agent_name])
		agent_number = $nexmo.sanitize(params[:agent_number])

		if agent_number
			db = UserDB.first_or_create(
				agent_name: agent_name,
				agent_number: agent_number
			)
			puts "#{__method__} | DB Result : #{db.inspect}"
		else	
			redirect "/login?error=true"
		end

		redirect "/homefinder?agent_number=#{agent_number}"
	end

	get '/homefinder' do
		puts "#{__method__} | Params : #{params}"

		@title = "Start Geo-Fence Demo"
		if params.include?(:error)
			@title = "Please re-enter the Buyers Phone Number and only use Alphanumeric values."
		end

		@agent_number = params[:agent_number]

		erb :homefinder
	end

	post '/homefinder' do
		puts "#{__method__} | Params : #{params}"

		buyer_number = $nexmo.sanitize(params[:buyer_number])

		if buyer_number
			db = UserDB.last(agent_number: params[:agent_number]).update(buyer_number: buyer_number)
			puts "#{__method__} | DB Result : #{db.inspect}"


			msg = "Hi there, we see you are close to a home that matches your search criteria.  Respond with SHOW to retrieve the MLS listing for the home or MAP to get directions sent to your phone"
			$nexmo.send_sms(msg,buyer_number)
		else
			redirect "/homefinder?error=true&agent_number=#{params[:agent_number]}"
		end

		redirect "/agent/#{params[:agent_number]}"
	end

	get '/agent/:agent_number' do
		@buyers_for_agent = UserDB.all(agent_number: params[:agent_number])
		erb :agent
	end

end


class HomeFinderNexmoController < NexmoBasicController

	def home_finder_demo(params,root_url)
		puts "#{__method__} | My Params : #{params}"	
		return ncco_answer
	end

	def home_finder_event(request_payload,root_url)
		puts "#{__method__} | #{request_payload}"
		keyword = request_payload['keyword'] || nil
		phone_number = request_payload['msisdn']	

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
			when "TIME", "WALTER"
				puts "Made it to Time"
				handle_time(phone_number)
			when "OMELET", "HOMELET"
				puts "Time till Omletes in Holmdel"
				handle_omelet(phone_number)				
			else
				puts "DID Not find matching KEYWORD"
				handle_error(phone_number,keyword)
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
		link = "https://www.njmls.com/listings/index.cfm?action=dsp.info&mlsnum=1840146"
		msg = "Here is the link to the house: #{link}.  Respond with SCHEDULE to reserve a time to see the house or SEE to get a live look with a Realtor right now"
		$nexmo.send_sms(msg,phone_number)
	end

	def handle_schedule(phone_number)
		msg = "I will schedule a call thank you!.  Respond with SCHEDULE to reserve a time to see the house or SEE to get a live look with a Realtor right now"
		$nexmo.send_sms(msg,phone_number)		
	end

	def handle_time(phone_number)
		minutes_until = TimeCheck.get_minutes
		msg = "I will see you in about #{minutes_until} minutes"
		$nexmo.send_sms(msg,phone_number)
	end

	def handle_omelet(phone_number)
		minutes_until = TimeCheck.get_omelets
		msg = "You will get your omelet in #{minutes_until} minutes"
		$nexmo.send_sms(msg,phone_number)
	end

	def handle_see(phone_number)
		db_info = UserDB.last(buyer_number: phone_number)

		buyer_msg = nil
		if db_info && db_info.agent_number
			agent_link = "#{$tokbox_url}#{phone_number}?userName=AGENT&skip=yes"
			msg = "Start virtul tour: #{agent_link}"
			$nexmo.send_sms(msg,db_info.agent_number)
		else
			buyer_msg = "Sorry, we could not find an agent associated with your phone number"
		end
		# Make sure messages are not throttled by Nexmo / Carrier
		sleep(1)

		#If agent exists for Buyer send message, otherwise send error message
		client_link = "#{$tokbox_url}#{phone_number}?userName=Buyer&skip=yes"
		buyer_msg = "Realtor: #{client_link}" unless buyer_msg
		$nexmo.send_sms(buyer_msg,phone_number)
		
	end

	def handle_map(phone_number)
		map = 'https://goo.gl/maps/aFsuwgrb3vy'
		msg = "Click on the link to get directions to the house: #{map}"
		$nexmo.send_sms(msg,phone_number)
	end

	def handle_error(phone_number,keyword)
		msg = "Did not understand your keyword of: #{keyword}"
		$nexmo.send_sms(msg,phone_number)
	end
end

################################################
# Database Specific Controls
################################################

# Configure in-memory DB
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/auth.db")

class UserDB
	include DataMapper::Resource
	property :id, Serial
	property :agent_name, String
	property :agent_number, String	
	property :buyer_number, String

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

	# Tokbox Base URL
	$tokbox_url = ENV['TOXBOX_URL']
	# Nexmo App Specific Details
	app_name = ENV['HOMEFINDER_APP_NAME']
	app_id = ENV['HOMEFINDER_APP_ID']
	$did = ENV['HOMEFINDER_DID']
	$web_server = ENV['LB_WEB_SERVER2'] || JSON.parse(Net::HTTP.get(URI('http://127.0.0.1:4040/api/tunnels')))['tunnels'][0]['public_url']

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

	UserDB.auto_migrate!
end
