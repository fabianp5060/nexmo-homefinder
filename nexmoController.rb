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

	def send_sms(msg,to=nil)
		puts "#{__method__}; SMS from: #{$did} to: #{to} msg: #{msg}"
		return $client.sms.send(from: $did, to: to, text: msg)
	end	

end