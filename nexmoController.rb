class NexmoBasicController

	def update_webserver(app_id,web_server,app_name)
		puts "My vars: ID: #{app_id}, WS: #{web_server}, NAME: #{app_name}"
		application = $client.applications.update(
			app_id,
			{
				type: "voice",
				name: app_name,
				answer_url: "#{$web_server}/answer_home", 
				event_url: "#{$web_server}/event_home"
			}
		)
		puts "Updated nexmo application name:\n  #{application.name}\nwith webhooks:\n  #{application.voice.webhooks[0].endpoint}\n  #{application.voice.webhooks[1].endpoint}"
	end

	def update_number(country,msisdn,update_params)
		puts "#{__method__} | My vars: Country Code: #{country}, Number: #{msisdn}, Params: #{update_params}"
		update_params.merge!({country: country, msisdn: msisdn})

		number = $client.numbers.update(update_params)
	end


	def send_sms(msg,to=nil,from=nil)
		from = $did unless from
		puts "#{__method__}; SMS from: #{from} to: #{to} msg: #{msg}"
		return $client.sms.send(from: from, to: to, text: msg)
	end	

	def normalize_numbers(num)
		if num.to_s =~ /^\d{10}$/
			puts "#{__method__} | Normalizing number: #{num}"
			num = "1#{num}"
		end	
		return num	
	end	

	def validate(input)
		alpha_nums = ('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a + ("0".."9").to_a
		return true if input.chars.all? {|ch| alpha_nums.include?(ch)}
	end

	def sanitize(input)
		clean_input = input.to_s.gsub(/\s/,"")
		is_valid = validate(clean_input)

		return normalize_numbers(clean_input) if is_valid
	end

end