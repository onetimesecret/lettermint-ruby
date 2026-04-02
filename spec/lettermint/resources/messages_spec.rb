# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::Resources::Messages do
  let(:team_token) { 'lm_team_test123' }
  let(:base_url) { Lettermint::Configuration::DEFAULT_BASE_URL }
  let(:api) { Lettermint::TeamAPI.new(team_token: team_token) }
  let(:messages) { api.messages }

  describe '#list' do
    it 'sends GET request to /messages' do
      stub_request(:get, "#{base_url}/messages")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"data":[{"id":"msg_1","subject":"Hello","status":"delivered"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = messages.list
      expect(result['data']).to be_an(Array)
      expect(result['data'].first['subject']).to eq('Hello')
    end

    it 'sends GET request without params when none specified' do
      stub = stub_request(:get, "#{base_url}/messages")
             .to_return(
               status: 200,
               body: '{"data":[]}',
               headers: { 'Content-Type' => 'application/json' }
             )

      messages.list
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/messages")
        .with { |req| req.uri.query.nil? })
    end

    describe 'pagination parameters' do
      it 'passes page_size parameter' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'page[size]' => '50' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(page_size: 50)
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'page[size]' => '50' })
      end

      it 'passes page_cursor parameter' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'page[cursor]' => 'cursor_abc' })
          .to_return(
            status: 200,
            body: '{"data":[],"meta":{"next_cursor":"cursor_def"}}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = messages.list(page_cursor: 'cursor_abc')
        expect(result['meta']['next_cursor']).to eq('cursor_def')
      end

      it 'passes both pagination parameters' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'page[size]' => '25', 'page[cursor]' => 'xyz789' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(page_size: 25, page_cursor: 'xyz789')
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'page[size]' => '25', 'page[cursor]' => 'xyz789' })
      end
    end

    describe 'sort parameter' do
      it 'sorts by subject ascending' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'sort' => 'subject' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(sort: 'subject')
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'sort' => 'subject' })
      end

      it 'sorts by created_at descending' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'sort' => '-created_at' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(sort: '-created_at')
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'sort' => '-created_at' })
      end

      it 'sorts by status_changed_at' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'sort' => 'status_changed_at' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(sort: 'status_changed_at')
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'sort' => 'status_changed_at' })
      end
    end

    describe 'filter parameters' do
      it 'filters by type' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'filter[type]' => 'outbound' })
          .to_return(
            status: 200,
            body: '{"data":[{"type":"outbound"}]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = messages.list(type: 'outbound')
        expect(result['data'].first['type']).to eq('outbound')
      end

      it 'filters by status' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'filter[status]' => 'delivered' })
          .to_return(
            status: 200,
            body: '{"data":[{"status":"delivered"}]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = messages.list(status: 'delivered')
        expect(result['data'].first['status']).to eq('delivered')
      end

      it 'filters by route_id' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'filter[route_id]' => 'route_123' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(route_id: 'route_123')
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'filter[route_id]' => 'route_123' })
      end

      it 'filters by domain_id' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'filter[domain_id]' => 'dom_456' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(domain_id: 'dom_456')
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'filter[domain_id]' => 'dom_456' })
      end

      it 'filters by tag' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'filter[tag]' => 'newsletter' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(tag: 'newsletter')
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'filter[tag]' => 'newsletter' })
      end

      it 'filters by from_email' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'filter[from_email]' => 'sender@example.com' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(from_email: 'sender@example.com')
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'filter[from_email]' => 'sender@example.com' })
      end

      it 'filters by subject' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'filter[subject]' => 'Welcome' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(subject: 'Welcome')
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'filter[subject]' => 'Welcome' })
      end

      it 'filters by date range' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'filter[from_date]' => '2024-01-01', 'filter[to_date]' => '2024-01-31' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(from_date: '2024-01-01', to_date: '2024-01-31')
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'filter[from_date]' => '2024-01-01', 'filter[to_date]' => '2024-01-31' })
      end

      it 'filters by multiple criteria' do
        stub_request(:get, "#{base_url}/messages")
          .with(query: { 'filter[type]' => 'inbound', 'filter[status]' => 'received', 'filter[tag]' => 'support' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        messages.list(type: 'inbound', status: 'received', tag: 'support')
        expect(WebMock).to have_requested(:get, "#{base_url}/messages")
          .with(query: { 'filter[type]' => 'inbound', 'filter[status]' => 'received', 'filter[tag]' => 'support' })
      end
    end

    describe 'combined parameters' do
      it 'passes all parameters together' do
        stub = stub_request(:get, "#{base_url}/messages")
               .with(query: {
                       'page[size]' => '10',
                       'page[cursor]' => 'abc',
                       'sort' => '-created_at',
                       'filter[type]' => 'outbound',
                       'filter[status]' => 'delivered'
                     })
               .to_return(
                 status: 200,
                 body: '{"data":[]}',
                 headers: { 'Content-Type' => 'application/json' }
               )

        messages.list(page_size: 10, page_cursor: 'abc', sort: '-created_at', type: 'outbound', status: 'delivered')
        expect(stub).to have_been_requested
      end
    end
  end

  describe '#find' do
    let(:message_id) { 'msg_123' }

    it 'sends GET request to /messages/:id' do
      stub_request(:get, "#{base_url}/messages/#{message_id}")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"id":"msg_123","subject":"Hello World","from_email":"sender@example.com"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = messages.find(message_id)
      expect(result['id']).to eq('msg_123')
      expect(result['subject']).to eq('Hello World')
    end

    it 'raises HttpRequestError for non-existent message' do
      stub_request(:get, "#{base_url}/messages/nonexistent")
        .to_return(
          status: 404,
          body: '{"message":"Message not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { messages.find('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#events' do
    let(:message_id) { 'msg_123' }

    it 'sends GET request to /messages/:id/events' do
      stub_request(:get, "#{base_url}/messages/#{message_id}/events")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"data":[{"event":"delivered","timestamp":"2024-01-15T10:00:00Z"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = messages.events(message_id)
      expect(result['data']).to be_an(Array)
      expect(result['data'].first['event']).to eq('delivered')
    end

    it 'sends GET request without sort param when not specified' do
      stub = stub_request(:get, "#{base_url}/messages/#{message_id}/events")
             .to_return(
               status: 200,
               body: '{"data":[]}',
               headers: { 'Content-Type' => 'application/json' }
             )

      messages.events(message_id)
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/messages/#{message_id}/events")
        .with { |req| req.uri.query.nil? })
    end

    it 'passes sort parameter' do
      stub_request(:get, "#{base_url}/messages/#{message_id}/events")
        .with(query: { 'sort' => '-timestamp' })
        .to_return(
          status: 200,
          body: '{"data":[]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      messages.events(message_id, sort: '-timestamp')
      expect(WebMock).to have_requested(:get, "#{base_url}/messages/#{message_id}/events")
        .with(query: { 'sort' => '-timestamp' })
    end

    it 'sorts by event type' do
      stub_request(:get, "#{base_url}/messages/#{message_id}/events")
        .with(query: { 'sort' => 'event' })
        .to_return(
          status: 200,
          body: '{"data":[]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      messages.events(message_id, sort: 'event')
      expect(WebMock).to have_requested(:get, "#{base_url}/messages/#{message_id}/events")
        .with(query: { 'sort' => 'event' })
    end

    it 'raises HttpRequestError for non-existent message' do
      stub_request(:get, "#{base_url}/messages/nonexistent/events")
        .to_return(
          status: 404,
          body: '{"message":"Message not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { messages.events('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#source' do
    let(:message_id) { 'msg_123' }

    it 'sends GET request to /messages/:id/source' do
      raw_source = "From: sender@example.com\r\nTo: recipient@example.com\r\nSubject: Hello\r\n\r\nBody content"
      stub_request(:get, "#{base_url}/messages/#{message_id}/source")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: raw_source,
          headers: { 'Content-Type' => 'message/rfc822' }
        )

      result = messages.source(message_id)
      expect(result).to include('From: sender@example.com')
      expect(result).to include('Subject: Hello')
    end

    it 'returns plain text content' do
      stub_request(:get, "#{base_url}/messages/#{message_id}/source")
        .to_return(
          status: 200,
          body: 'Raw RFC822 message content',
          headers: { 'Content-Type' => 'message/rfc822' }
        )

      result = messages.source(message_id)
      expect(result).to eq('Raw RFC822 message content')
    end

    it 'raises HttpRequestError for non-existent message' do
      stub_request(:get, "#{base_url}/messages/nonexistent/source")
        .to_return(
          status: 404,
          body: '{"message":"Message not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { messages.source('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#html' do
    let(:message_id) { 'msg_123' }

    it 'sends GET request to /messages/:id/html' do
      html_content = '<html><body><h1>Hello World</h1></body></html>'
      stub_request(:get, "#{base_url}/messages/#{message_id}/html")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: html_content,
          headers: { 'Content-Type' => 'text/html' }
        )

      result = messages.html(message_id)
      expect(result).to include('<h1>Hello World</h1>')
    end

    it 'returns HTML content as string' do
      stub_request(:get, "#{base_url}/messages/#{message_id}/html")
        .to_return(
          status: 200,
          body: '<p>Email content</p>',
          headers: { 'Content-Type' => 'text/html' }
        )

      result = messages.html(message_id)
      expect(result).to eq('<p>Email content</p>')
    end

    it 'raises HttpRequestError for non-existent message' do
      stub_request(:get, "#{base_url}/messages/nonexistent/html")
        .to_return(
          status: 404,
          body: '{"message":"Message not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { messages.html('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end

    it 'raises HttpRequestError when message has no HTML body' do
      stub_request(:get, "#{base_url}/messages/#{message_id}/html")
        .to_return(
          status: 404,
          body: '{"message":"HTML body not available"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { messages.html(message_id) }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#text' do
    let(:message_id) { 'msg_123' }

    it 'sends GET request to /messages/:id/text' do
      text_content = 'Hello World\n\nThis is a plain text email.'
      stub_request(:get, "#{base_url}/messages/#{message_id}/text")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: text_content,
          headers: { 'Content-Type' => 'text/plain' }
        )

      result = messages.text(message_id)
      expect(result).to include('Hello World')
    end

    it 'returns plain text content as string' do
      stub_request(:get, "#{base_url}/messages/#{message_id}/text")
        .to_return(
          status: 200,
          body: 'Plain text email body',
          headers: { 'Content-Type' => 'text/plain' }
        )

      result = messages.text(message_id)
      expect(result).to eq('Plain text email body')
    end

    it 'raises HttpRequestError for non-existent message' do
      stub_request(:get, "#{base_url}/messages/nonexistent/text")
        .to_return(
          status: 404,
          body: '{"message":"Message not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { messages.text('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end

    it 'raises HttpRequestError when message has no text body' do
      stub_request(:get, "#{base_url}/messages/#{message_id}/text")
        .to_return(
          status: 404,
          body: '{"message":"Text body not available"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { messages.text(message_id) }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe 'error handling' do
    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/messages")
        .to_return(
          status: 401,
          body: '{"message":"Invalid token"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { messages.list }.to raise_error(Lettermint::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:get, "#{base_url}/messages")
        .to_return(
          status: 429,
          body: '{"message":"Too many requests"}',
          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '30' }
        )

      expect { messages.list }.to raise_error(Lettermint::RateLimitError) { |e|
        expect(e.retry_after).to eq(30)
      }
    end

    it 'raises TimeoutError on timeout' do
      stub_request(:get, "#{base_url}/messages").to_raise(Faraday::TimeoutError)

      expect { messages.list }.to raise_error(Lettermint::TimeoutError)
    end
  end
end
