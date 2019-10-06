

class TimeCheck

	def self.get_minutes
		require 'time'
		t1 = Time.now
		t2 = Time.new(2019, 8, 04, 21, 00, 00)
		seconds_until = t2 - t1
		minutes_until = seconds_until/60

		return minutes_until.round(0)
	end

	def self.get_omelets
		require 'time'
		t1 = Time.now
		t2 = Time.new(2019, 8, 05, 13, 00, 00)
		seconds_until = t2 - t1
		minutes_until = seconds_until/60

		return minutes_until.round(0)
	end	

	def make_request
		require 'httparty'
		url = "http://quotes.rest/qod.json?category=management"

		response = nil
		begin
			response = HTTParty.get(url)
			# return JSON.parse(response.body, symbolize_names: true)
		rescue => e
			puts "#{__method__} | Error Fetching Data: #{e}"
			return e
		else
			puts "#{__method__} | My response: #{response}"
			return JSON.parse(response.body, symbolize_names: true)
		end			

	end
end

class GetQuote
	def self.get_quote
		quote = make_request
		q = nil
		if quote[:success] && quote[:success][:total] > 0
			q = quote[:contents][:quotes][0][:quote]
			puts "#{q}"
		else
			puts "DID not get successful response with at least one quote"
		end
		return q
	end	

	

	def self.make_request
		require 'httparty'
		url = "http://quotes.rest/qod.json?category=management"

		response = nil
		begin
			response = HTTParty.get(url)
			# return JSON.parse(response.body, symbolize_names: true)
		rescue => e
			puts "#{__method__} | Error Fetching Data: #{e}"
			return e
		else
			puts "#{__method__} | My response: #{response}"
			return JSON.parse(response.body, symbolize_names: true)
		end			

	end
end
