#!/usr/bin/env ruby

require 'socket'
require 'rubygems'
require 'json'
require 'net/http'

class IRCBot

	def initialize(name, server, port, channel)
		@channel = channel
		@socket = TCPSocket.open(server, port)
		say "USER #{name} 0 * #{name}"
		say "NICK #{name}"
		say "JOIN ##{@channel}"
	end

	def say(msg)
		@socket.puts msg + "\n"
	end

	def say_to_channel(msg)
		say "PRIVMSG ##{@channel} :#{msg}\n"
	end

	def parse_line(line)
		parts = line.split
		if parts.length == 4
			msg = parts[3..-1].join(" ")[1..-1]
			get_price if /^(\!doge)/ =~ msg
			convert_price(msg.match(/\!c\s(\d+)/)[1]) if /\!c\s(\d+)/ =~ msg
		end
	end

	def get_price
		url = "http://pubapi.cryptsy.com/api.php?method=singlemarketdata&marketid=132"
		response = Net::HTTP.get_response(URI(url))
		begin 
			data = JSON.parse(response.read_body)
			latest_trade = data["return"]["markets"]["DOGE"]["recenttrades"][0]
			quantity = latest_trade["quantity"].slice(0..(latest_trade["quantity"].index('.')+2))
			price = latest_trade["price"]
			time = latest_trade["time"].slice(latest_trade["time"].index(" ")+1..-1)

			say_to_channel "Last trade executed: \x02#{quantity}\x02 Doges at \x02BTC #{price}\x02 executed at \x02#{time}\x02."
		rescue JSON::ParserError
			say_to_channel "Much error, such 502 Bad Gateway (try again in a minute, Shibe is many sorry)"
		end

	end

	def convert_price(amount)
		url = "https://api.bitcoinaverage.com/exchanges/USD"
		response = Net::HTTP.get_response(URI(url))
		begin
			data = JSON.parse(response.read_body)
			last_btc_price = data["mtgox"]["rates"]["last"]
		rescue
			say_to_channel "Many error, such sorry. Contact head shibe for troubleshooting!"
		end
	end

	def run
		until @socket.eof? do
			message = @socket.gets
			puts 'SERV << ' + message
			parse_line(message)

			if message.include?("PING")
				say 'PONG :pingis'
			end
		end
	end
end

bot = IRCBot.new('DogeBot', 'irc.rizon.net', 6667, 'do/g/ecoin')
bot.run