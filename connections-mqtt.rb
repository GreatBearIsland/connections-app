#!/usr/bin/env ruby
require 'mqtt'
require 'uri'
require 'dotenv/load'

puts "\n" + "="*70
puts "Running: MQTT connections"
puts "="*70
puts


# Create a hash with the connection parameters from the URL
uri = URI.parse ENV['BROKER_URL']
puts "host: #{uri.host}"
puts "user: #{uri.user}"

ports = [
    { port: 1883, protocol: 'MQTT', ssl: false},
    { port: 8883, protocol: 'MQTTS', ssl: true}
]

ports.each do |port|

  begin
      connection = MQTT::Client.new(
        host: uri.host,
        port: port[:port],
        username: uri.user,
        password: uri.password,
        ssl: port[:ssl]
      )
      puts "\nTesting #{port[:protocol]} port #{port[:port]}"
      connection.connect

    if connection.connected?
      puts "✓ Successfully connected to port #{port[:port]}"
      port[:status] = :success
      port[:message] = "✓ Successfully connected"
    end

    sleep 0.5
    puts "Closing..."
    connection.disconnect
  rescue => e
    puts 
    puts "✗ Connection failed. Connection error: #{e.class} - #{e.message}"
    port[:status] = :failed
    port[:message] = "✗ Connection failed"
    port[:error]= "#{e.class} - #{e.message}"  
  end
end

unless ENV['SUPPRESS_SUMMARY']
  puts "\n" + "="*70
  puts "SUMMARY"
  puts "="*70
  ports.each do |result|
    summary_line =  "#{result[:message]} to port #{result[:port]}"
    summary_line += "- #{result[:error]}" if result[:error]
    puts summary_line
  end
end