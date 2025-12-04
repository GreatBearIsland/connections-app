#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'dotenv/load'

puts "\n" + "="*70
puts "Running: HTTP Management API connections"
puts "="*70
puts


# Parse the AMQP URL
amqp_uri = URI.parse ENV['BROKER_URL']
puts "AMQP host: #{amqp_uri.host}"
puts "AMQP user: #{amqp_uri.user}"
puts

# CloudAMQP Management API endpoints to test
endpoints = [
  {
    name: 'Management API via HTTPS (port 443)',
    url: "https://#{amqp_uri.host}:443/api/overview",
    use_ssl: true
  },
  {
    name: 'Management API via standard HTTPS',
    url: "https://#{amqp_uri.host}/api/overview",
    use_ssl: true
  },
  {
    name: 'Management API port 15672 (HTTP)',
    url: "http://#{amqp_uri.host}:15672/api/overview",
    use_ssl: false
  }
]

results = []

endpoints.each do |endpoint|
  result = { name: endpoint[:name], url: endpoint[:url] }

  begin
    http_uri = URI.parse(endpoint[:url])

    puts "\nTesting: #{endpoint[:name]}"
    puts "URL: #{endpoint[:url]}"

    # Create HTTP client with timeout
    http = Net::HTTP.new(http_uri.host, http_uri.port)
    http.use_ssl = endpoint[:use_ssl]
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if endpoint[:use_ssl]
    http.open_timeout = 5
    http.read_timeout = 5

    # Create request with basic auth
    request = Net::HTTP::Get.new(http_uri.request_uri)
    request.basic_auth(amqp_uri.user, amqp_uri.password)

    # Send request
    response = http.request(request)

    puts "✓ Response received: #{response.code} #{response.message}"
    result[:status] = :success
    result[:response_code] = response.code
    result[:message] = "✓ Successfully connected"

  rescue Net::OpenTimeout => e
    puts "✗ Timeout: #{e.message}"
    result[:status] = :timeout
    result[:message] = "✗ Connection timeout"
    result[:error] = e.message

  rescue => e
    puts "✗ Connection failed: #{e.class} - #{e.message}"
    result[:status] = :failed
    result[:message] = "✗ Connection failed"
    result[:error] = "#{e.class} - #{e.message}"
  end

  results << result
end

unless ENV['SUPPRESS_SUMMARY']
  puts "\n" + "="*70
  puts "SUMMARY"
  puts "="*70

  results.each do |result|
    status_indicator = result[:status] == :success ? "✓" : "✗"
    puts "#{status_indicator} #{result[:name]}"
    puts "   URL: #{result[:url]}"
    if result[:response_code]
      puts "   Response: #{result[:response_code]}"
    elsif result[:error]
      puts "   Error: #{result[:error]}"
    end
    puts
  end

  successful = results.count { |r| r[:status] == :success }
  puts "Success: #{successful}/#{results.length} endpoints"
end
