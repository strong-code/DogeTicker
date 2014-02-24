#! /usr/bin/env ruby

require 'cinch'

$bot = Cinch::Bot.new do
  configure do |c|
    c.server = 'irc.freenode.net'
    c.user = 'MoonBound'
    c.nick = 'MoonBound'
    c.realname = 'Doge headed for the moon'
    c.channels = ['#dctest']
  end
  
  on :message do |msg|
    if msg.user == "BraddPitt"
      #User('BraddPitt').send("[#{Time.now.asctime}]<#{msg.user}>: #{msg.params[1]}")
      begin
        File.open('test.txt', 'w')
        file.write("[#{Time.now.asctime}]<#{msg.user}>: #{msg.params[1]}\n")
      rescue IOError => e
        #
      ensure
        file.close unless file == nil
      end

    end
  end
end

$bot.start
