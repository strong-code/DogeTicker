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
		if parts.length >= 4
			msg = parts[3..-1].join(" ")[1..-1]
			say_to_channel "woof" if msg.include?("DogeBot")
			if /^(\!doge)/ =~ msg
				get_price
			elsif /^\!c\s(\d+)/ =~ msg
				convert_price(Regexp.last_match(1))
			elsif msg == "!info"
				say_to_channel 'I am an IRC bot written in ruby to help with DogeCoin related tasks. PM BradPitt with feature requests.'\
				' I am using data from http://cryptsy.com (for DOGE) and http://vircurex.com (for BTC/USD conversion).'\
				' Source code available at http://github.com/clindsay107/Doge_ticker'
			elsif msg == "!thread"
				find_thread
			elsif msg == "!help"
				show_help
			elsif msg == "!tip"
				show_tip_addr
			end
		end
	end

	def find_thread
		url = "http://a.4cdn.org/g/catalog.json"
		thread_url = "http://boards.4chan.org/g/res/"
		response = Net::HTTP.get_response(URI(url))
		begin
			data = JSON.parse(response.read_body)
			(0..10).each do |page|
				data[page]["threads"].each do |thread|
					p thread["sub"]
					if !thread["sub"].nil? && thread["sub"].downcase == "general doge thread"
						return say_to_channel "Last bumped thread: \x02#{thread_url << thread["no"].to_s}\x02"
					end
				end
			end
		rescue JSON::ParserError
			say_to_channel "Such error fetching thread, many sorry"
		end

		say_to_channel "Shibe could not fetch current thread, try making a new one."
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

		#fetch current BTC price
		url = "http://api.bitcoinaverage.com/exchanges/USD"
		response = Net::HTTP.get_response(URI(url))
		begin
			data = JSON.parse(response.read_body)
			last_btc_price = data["vircurex"]["rates"]["last"]
		rescue
			say_to_channel "Many error when fetching BTC price, such sorry. Contact head shibe for troubleshooting!"
			return
		end

		#fetch current DOGE price
		url = "http://pubapi.cryptsy.com/api.php?method=singlemarketdata&marketid=132"
		response = Net::HTTP.get_response(URI(url))
		begin 
			data = JSON.parse(response.read_body)
			last_doge_price = data["return"]["markets"]["DOGE"]["recenttrades"][0]["price"]
		rescue JSON::ParserError
			say_to_channel "Much error, such 502 Bad Gateway when fetching DOGE price. Contact head shibe for troubleshooting!"
			return
		end

		puts ">>>BTC: #{last_btc_price}"
		puts ">>>DOGE: #{last_doge_price}"

		amount_usd = (last_btc_price.to_f * last_doge_price.to_f) * amount.to_f
		say_to_channel "$\x02#{amount_usd.round(2)}\x02 USD"
	end

	def show_help
		say_to_channel '!doge for current price | !c 80000 to convert specified amount of doges to USD | !thread to get link to current DogeCoin thread |'\
		' !info for information about this bot.'
	end

	def show_tip_addr
		say_to_channel "If you enjoy the utility this bot provides, please send a tip to DKtC5RUj1iC3FmXgJ7MvHgNivxG7t2tLNX"
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