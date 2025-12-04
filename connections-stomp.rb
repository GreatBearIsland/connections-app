#!/usr/bin/env ruby
require 'stomp'
require 'uri'
require 'dotenv/load'

puts "\n" + "="*70
puts "Running: STOMP connections"
puts "="*70
puts


# Create a hash with the connection parameters from the URL
uri = URI.parse ENV['BROKER_URL']
puts "host: #{uri.host}"
puts "user: #{uri.user}"
puts

ports = [
    { port: 61613, protocol: 'STOMP', ssl: false},
    { port: 61614, protocol: 'STOMPS', ssl: true}
]

ports.each do |port|
  begin
    conn_hash = {
      hosts: [{
        login: uri.user,
        passcode: uri.password,
        host: uri.host,
        port: port[:port],
        ssl: port[:ssl]
      }]
    }

    puts "\nTesting #{port[:protocol]} port #{port[:port]}"
    client = Stomp::Client.new(conn_hash)

    if client.open?
      puts "✓ Successfully connected to port #{port[:port]}"
      port[:status] = :success
      port[:message] = "✓ Successfully connected"
    end

    sleep 0.5
    puts "Closing..."
    client.close
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
