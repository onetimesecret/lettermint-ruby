# frozen_string_literal: true

require 'lettermint'

client = Lettermint::Client.new(api_token: ENV.fetch('LETTERMINT_API_TOKEN'))

response = client.email
                 .from('sender@example.com')
                 .to('recipient@example.com')
                 .subject('Welcome aboard')
                 .html('<h1>Welcome</h1><p>Thanks for signing up.</p>')
                 .text('Welcome! Thanks for signing up.')
                 .tag('welcome')
                 .metadata({ 'user_id' => '42' })
                 .deliver

puts "Sent: #{response.message_id} (#{response.status})"
