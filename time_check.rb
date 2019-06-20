

class TimeCheck

	def self.get_minutes
		require 'time'
		t1 = Time.now
		t2 = Time.new(2019, 06, 25, 14, 20, 00)
		seconds_until = t2 - t1
		minutes_until = seconds_until/60

		return minutes_until.round(0)
	end


end
