# frozen_string_literal: true

require 'lettermint'
require 'base64'

client = Lettermint::Client.new(api_token: ENV.fetch('LETTERMINT_API_TOKEN'))

pdf_content = Base64.strict_encode64(File.read('invoice.pdf'))

response = client.email
                 .from('billing@example.com')
                 .to('customer@example.com')
                 .subject('Your Invoice #1234')
                 .html('<p>Please find your invoice attached.</p>')
                 .attach('invoice.pdf', pdf_content)
                 .attach('logo.png', Base64.strict_encode64(File.read('logo.png')), content_id: 'logo@cid')
                 .deliver

puts "Sent: #{response.message_id} (#{response.status})"
