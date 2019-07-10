

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


end
