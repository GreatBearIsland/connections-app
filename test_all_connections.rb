#!/usr/bin/env ruby
require 'io/console'

puts
puts "="*70
puts "RUNNING ALL CONNECTION TESTS"
puts "="*70

# List of all connection test scripts
scripts = [
  { file: 'connections-amqp.rb', name: 'AMQP' },
  { file: 'connections-mqtt.rb', name: 'MQTT' },
  { file: 'connections-stomp.rb', name: 'STOMP' },
  { file: 'connections-http.rb', name: 'HTTP Management' },
  { file: 'connections-http-api.rb', name: 'HTTP Management API' }
]

results = []
all_outputs = []

scripts.each do |script_info|
  script_path = File.join(__dir__, script_info[:file])

  unless File.exist?(script_path)
    puts "⚠ Skipping #{script_info[:file]} (file not found)"
    results << {
      script: script_info[:name],
      status: :skipped,
      ports: []
    }
    next
  end

  start_time = Time.now

  # Run script with SUPPRESS_SUMMARY environment variable
  output = `SUPPRESS_SUMMARY=1 ruby #{script_path} 2>&1`
  success = $?.success?
  duration = Time.now - start_time

  # Print the output (without individual summaries)
  puts output

  # Parse output to extract connection results
  ports = []
  output.each_line do |line|
    if line.match(/✓ Successfully connected to port (\d+)/)
      ports << { port: $1, status: :success }
    elsif line.match(/✗ Connection failed.*port (\d+)/)
      ports << { port: $1, status: :failed }
    elsif line.match(/✓ Response received: (\d+)/)
      # For HTTP endpoints
      ports << { endpoint: 'HTTP API', status: :success, code: $1 }
    elsif line.match(/✗.*Timeout/)
      ports << { endpoint: 'HTTP API', status: :failed, error: 'Timeout' }
    end
  end

  results << {
    script: script_info[:name],
    status: success ? :success : :failed,
    duration: duration,
    ports: ports
  }

  all_outputs << output
end

# Final Summary
puts "\n" + "="*70
puts "OVERALL SUMMARY"
puts "="*70

results.each do |result|
  status_icon = case result[:status]
  when :success then "✓"
  when :failed then "✗"
  when :skipped then "⚠"
  end

  duration_text = result[:duration] ? " (#{result[:duration].round(2)}s)" : ""
  puts "\n#{status_icon} #{result[:script]}#{duration_text}"

  # Show port-level details
  if result[:ports].any?
    result[:ports].each do |port_info|
      port_status = port_info[:status] == :success ? "✓" : "✗"
      if port_info[:port]
        puts "  #{port_status} Port #{port_info[:port]}"
      elsif port_info[:endpoint]
        detail = port_info[:code] ? "Response: #{port_info[:code]}" : port_info[:error]
        puts "  #{port_status} #{port_info[:endpoint]} - #{detail}" if detail
      end
    end
  end
end

successful = results.count { |r| r[:status] == :success }
failed = results.count { |r| r[:status] == :failed }
skipped = results.count { |r| r[:status] == :skipped }

puts "\n" + "="*70
puts "Results: #{successful} succeeded, #{failed} failed, #{skipped} skipped"
puts "="*70
