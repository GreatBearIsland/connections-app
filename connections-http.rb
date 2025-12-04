#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'dotenv/load'

puts "\n" + "="*70
puts "Running: HTTP connections"
puts "="*70
puts


# Create a hash with the connection parameters from the URL
uri = URI.parse ENV['BROKER_URL']
puts "host: #{uri.host}"
puts "user: #{uri.user}"

ports = [
    { port: 443, protocol: 'HTTP', ssl: false},
    { port: 15671, protocol: 'HTTPS', ssl: true},
]

ports.each do |port|
  begin
    http_uri = if port[:ssl]
      URI::HTTPS.build(
        host: uri.host,
        port: port[:port],
        path: '/api/overview'
      )
    else
      URI::HTTP.build(
        host: uri.host,
        port: port[:port],
        path: '/api/overview'
      )
    end

    puts "\nTesting #{port[:protocol]} port #{port[:port]}"

    # Create HTTP client
    http = Net::HTTP.new(http_uri.host, http_uri.port)
    http.use_ssl = port[:ssl]
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if port[:ssl] # For self-signed certs

    # Create request with basic auth
    request = Net::HTTP::Get.new(http_uri.path)
    request.basic_auth(uri.user, uri.password)
    
    # Send request
    response = http.request(request)

    puts "✓ Successfully connected to port #{port[:port]} responded: #{response.code}"
    port[:status] = :success
    port[:message] = "✓ Successfully connected"
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
