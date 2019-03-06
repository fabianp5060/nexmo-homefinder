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
		puts "#{__method__} | My Params: #{params}"
		response = $nexmo.home_finder_event(params,root_url)
	end

	get '/' do; 200; end

	get '/login' do
		@title = "Login as Agent"
		erb :login
	end

	post '/login' do
		puts "#{__method__} | Params : #{params}"

		agent_name = params[:agent_name]
		agent_number = params[:agent_number]

		db = UserDB.first_or_create(
			agent_name: agent_name,
			agent_number: agent_number
		)
		puts "#{__method__} | DB Result : #{db.inspect}"

		redirect "/homefinder?agent_number=#{agent_number}"
	end

	get '/homefinder' do
		puts "#{__method__} | Params : #{params}"

		@title = "Start Geo-Fence Demo"
		@agent_number = params[:agent_number]

		erb :homefinder
	end

	post '/homefinder' do
		puts "#{__method__} | Params : #{params}"

		buyer_number = params[:buyer_number]
		db = UserDB.last(agent_number: params[:agent_number]).update(buyer_number: buyer_number)
		puts "#{__method__} | DB Result : #{db.inspect}"

		msg = "Hi there, we see you are close to a home that matches your search criteria.  Respond with SHOW to retrieve the MLS listing for the home or MAP to get directions sent to your phone"
		$nexmo.send_sms(msg,buyer_number)

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
		link = "https://www.njmls.com/listings/index.cfm?action=dsp.info&mlsnum=1840146"
		msg = "Here is the link to the house: #{link}.  Respond with SCHEDULE to reserve a time to see the house or SEE to get a live look with a Realtor right now"
		$nexmo.send_sms(msg,phone_number)
	end

	def handle_schedule(phone_number)
		msg = "I will schedule a call thank you!.  Respond with SCHEDULE to reserve a time to see the house or SEE to get a live look with a Realtor right now"
		$nexmo.send_sms(msg,phone_number)		
	end

	def handle_see(phone_number)
		db_info = UserDB.last(buyer_number: phone_number)

		buyer_msg = nil
		if db_info && db_info.agent_number
			agent_link = "#{$tokbox_url}#{phone_number}?userName=AGENT&skip=yes"
			msg = "A buyer would like a virtul tour: #{agent_link}"
			# $nexmo.send_sms(msg,db_info.agent_number)
			puts "I would send SMS to: #{db_info.agent_number} with msg: #{msg}"
		else
			buyer_msg = "Sorry, we could not find an agent associated with your phone number"
		end
		# Make sure messages are not throttled by Nexmo / Carrier
		sleep(1)

		#If agent exists for Buyer send message, otherwise send error message
		client_link = "#{$tokbox_url}#{phone_number}?userName=Buyer&skip=yes"
		buyer_msg = "Please click on the link to initiate a live virtual tour with the Realtor: #{client_link}" unless buyer_msg
		# $nexmo.send_sms(buyer_msg,phone_number)
		puts "I would send SMS to: #{phone_number} with msg: #{buyer_msg}"
	end

	def handle_map(phone_number)
		map = 'https://goo.gl/maps/aFsuwgrb3vy'
		msg = "Click on the link to get directions to the house: #{map}"
		$nexmo.send_sms(msg,phone_number)
	end

	def handle_error(phone_number)
	end

	def validate(input)
		alpha_nums = ('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a
		return alpha_nums unless input.chars.all? {|ch| alpha_nums.include?(ch)}
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
