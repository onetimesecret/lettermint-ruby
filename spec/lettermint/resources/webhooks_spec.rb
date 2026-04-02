# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::Resources::Webhooks do
  let(:team_token) { 'lm_team_test123' }
  let(:base_url) { Lettermint::Configuration::DEFAULT_BASE_URL }
  let(:api) { Lettermint::TeamAPI.new(team_token: team_token) }
  let(:webhooks) { api.webhooks }

  describe '#list' do
    it 'sends GET request to /webhooks' do
      stub_request(:get, "#{base_url}/webhooks")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"data":[{"id":"wh_1","name":"My Webhook","url":"https://example.com/hook"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.list
      expect(result['data']).to be_an(Array)
      expect(result['data'].first['name']).to eq('My Webhook')
    end

    it 'sends GET request without params when none specified' do
      stub = stub_request(:get, "#{base_url}/webhooks")
             .to_return(
               status: 200,
               body: '{"data":[]}',
               headers: { 'Content-Type' => 'application/json' }
             )

      webhooks.list
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/webhooks")
        .with { |req| req.uri.query.nil? })
    end

    describe 'pagination parameters' do
      it 'passes page_size parameter' do
        stub_request(:get, "#{base_url}/webhooks")
          .with(query: { 'page[size]' => '50' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.list(page_size: 50)
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks")
          .with(query: { 'page[size]' => '50' })
      end

      it 'passes page_cursor parameter' do
        stub_request(:get, "#{base_url}/webhooks")
          .with(query: { 'page[cursor]' => 'cursor_abc' })
          .to_return(
            status: 200,
            body: '{"data":[],"meta":{"next_cursor":"cursor_def"}}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = webhooks.list(page_cursor: 'cursor_abc')
        expect(result['meta']['next_cursor']).to eq('cursor_def')
      end

      it 'passes both pagination parameters' do
        stub_request(:get, "#{base_url}/webhooks")
          .with(query: { 'page[size]' => '25', 'page[cursor]' => 'xyz789' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.list(page_size: 25, page_cursor: 'xyz789')
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks")
          .with(query: { 'page[size]' => '25', 'page[cursor]' => 'xyz789' })
      end
    end

    describe 'sort parameter' do
      it 'sorts by name ascending' do
        stub_request(:get, "#{base_url}/webhooks")
          .with(query: { 'sort' => 'name' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.list(sort: 'name')
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks")
          .with(query: { 'sort' => 'name' })
      end

      it 'sorts by created_at descending' do
        stub_request(:get, "#{base_url}/webhooks")
          .with(query: { 'sort' => '-created_at' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.list(sort: '-created_at')
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks")
          .with(query: { 'sort' => '-created_at' })
      end
    end

    describe 'filter parameters' do
      it 'filters by enabled status' do
        stub_request(:get, "#{base_url}/webhooks")
          .with(query: { 'filter[enabled]' => 'true' })
          .to_return(
            status: 200,
            body: '{"data":[{"enabled":true}]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = webhooks.list(enabled: true)
        expect(result['data'].first['enabled']).to eq(true)
      end

      it 'filters by event type' do
        stub_request(:get, "#{base_url}/webhooks")
          .with(query: { 'filter[event]' => 'message.sent' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.list(event: 'message.sent')
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks")
          .with(query: { 'filter[event]' => 'message.sent' })
      end

      it 'filters by route_id' do
        stub_request(:get, "#{base_url}/webhooks")
          .with(query: { 'filter[route_id]' => 'route_123' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.list(route_id: 'route_123')
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks")
          .with(query: { 'filter[route_id]' => 'route_123' })
      end

      it 'filters by search term' do
        stub_request(:get, "#{base_url}/webhooks")
          .with(query: { 'filter[search]' => 'production' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.list(search: 'production')
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks")
          .with(query: { 'filter[search]' => 'production' })
      end

      it 'filters by multiple criteria' do
        stub_request(:get, "#{base_url}/webhooks")
          .with(query: { 'filter[enabled]' => 'true', 'filter[event]' => 'message.delivered' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.list(enabled: true, event: 'message.delivered')
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks")
          .with(query: { 'filter[enabled]' => 'true', 'filter[event]' => 'message.delivered' })
      end
    end
  end

  describe '#create' do
    it 'sends POST request to /webhooks with required fields' do
      stub_request(:post, "#{base_url}/webhooks")
        .with(
          body: { route_id: 'route_123', name: 'My Webhook', url: 'https://example.com/hook',
                  events: ['message.sent'] },
          headers: { 'Authorization' => "Bearer #{team_token}" }
        )
        .to_return(
          status: 201,
          body: '{"id":"wh_new","name":"My Webhook","url":"https://example.com/hook","secret":"whsec_abc123"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.create(route_id: 'route_123', name: 'My Webhook', url: 'https://example.com/hook',
                               events: ['message.sent'])
      expect(result['id']).to eq('wh_new')
      expect(result['secret']).to eq('whsec_abc123')
    end

    it 'sends POST request with optional enabled field' do
      stub_request(:post, "#{base_url}/webhooks")
        .with(
          body: { route_id: 'route_123', name: 'My Webhook', url: 'https://example.com/hook', events: ['message.sent'], enabled: false }
        )
        .to_return(
          status: 201,
          body: '{"id":"wh_new","enabled":false}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.create(route_id: 'route_123', name: 'My Webhook', url: 'https://example.com/hook',
                               events: ['message.sent'], enabled: false)
      expect(result['enabled']).to eq(false)
    end

    it 'raises ValidationError for invalid URL' do
      stub_request(:post, "#{base_url}/webhooks")
        .to_return(
          status: 422,
          body: '{"message":"Invalid URL format","error":"validation_error"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { webhooks.create(route_id: 'route_123', name: 'Test', url: 'not-a-url', events: ['message.sent']) }
        .to raise_error(Lettermint::ValidationError)
    end

    it 'raises ValidationError for empty events array' do
      stub_request(:post, "#{base_url}/webhooks")
        .to_return(
          status: 422,
          body: '{"message":"Events must have at least 1 item","error":"validation_error"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { webhooks.create(route_id: 'route_123', name: 'Test', url: 'https://example.com', events: []) }
        .to raise_error(Lettermint::ValidationError, /at least 1 item/)
    end
  end

  describe '#find' do
    let(:webhook_id) { 'wh_123' }

    it 'sends GET request to /webhooks/:id' do
      stub_request(:get, "#{base_url}/webhooks/#{webhook_id}")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"id":"wh_123","name":"My Webhook","secret":"whsec_abc"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.find(webhook_id)
      expect(result['id']).to eq('wh_123')
      expect(result['secret']).to eq('whsec_abc')
    end

    it 'raises HttpRequestError for non-existent webhook' do
      stub_request(:get, "#{base_url}/webhooks/nonexistent")
        .to_return(
          status: 404,
          body: '{"message":"Webhook not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { webhooks.find('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#update' do
    let(:webhook_id) { 'wh_123' }

    it 'sends PUT request to /webhooks/:id with name' do
      stub_request(:put, "#{base_url}/webhooks/#{webhook_id}")
        .with(
          body: { name: 'Updated Webhook' },
          headers: { 'Authorization' => "Bearer #{team_token}" }
        )
        .to_return(
          status: 200,
          body: '{"id":"wh_123","name":"Updated Webhook"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.update(webhook_id, name: 'Updated Webhook')
      expect(result['name']).to eq('Updated Webhook')
    end

    it 'sends PUT request with url' do
      stub_request(:put, "#{base_url}/webhooks/#{webhook_id}")
        .with(body: { url: 'https://new-url.com/hook' })
        .to_return(
          status: 200,
          body: '{"id":"wh_123","url":"https://new-url.com/hook"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.update(webhook_id, url: 'https://new-url.com/hook')
      expect(result['url']).to eq('https://new-url.com/hook')
    end

    it 'sends PUT request with enabled status' do
      stub_request(:put, "#{base_url}/webhooks/#{webhook_id}")
        .with(body: { enabled: false })
        .to_return(
          status: 200,
          body: '{"id":"wh_123","enabled":false}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.update(webhook_id, enabled: false)
      expect(result['enabled']).to eq(false)
    end

    it 'sends PUT request with events array' do
      stub_request(:put, "#{base_url}/webhooks/#{webhook_id}")
        .with(body: { events: %w[message.sent message.delivered] })
        .to_return(
          status: 200,
          body: '{"id":"wh_123","events":["message.sent","message.delivered"]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.update(webhook_id, events: %w[message.sent message.delivered])
      expect(result['events']).to eq(%w[message.sent message.delivered])
    end

    it 'sends PUT request with multiple fields' do
      stub_request(:put, "#{base_url}/webhooks/#{webhook_id}")
        .with(body: { name: 'New Name', url: 'https://new.com', enabled: true })
        .to_return(
          status: 200,
          body: '{"id":"wh_123","name":"New Name","url":"https://new.com","enabled":true}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.update(webhook_id, name: 'New Name', url: 'https://new.com', enabled: true)
      expect(result['name']).to eq('New Name')
      expect(result['url']).to eq('https://new.com')
    end
  end

  describe '#delete' do
    let(:webhook_id) { 'wh_123' }

    it 'sends DELETE request to /webhooks/:id' do
      stub_request(:delete, "#{base_url}/webhooks/#{webhook_id}")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"message":"Webhook deleted"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.delete(webhook_id)
      expect(result['message']).to eq('Webhook deleted')
    end

    it 'handles 204 No Content response' do
      stub_request(:delete, "#{base_url}/webhooks/#{webhook_id}")
        .to_return(status: 204, body: '')

      result = webhooks.delete(webhook_id)
      expect(result).to eq('')
    end

    it 'raises HttpRequestError for non-existent webhook' do
      stub_request(:delete, "#{base_url}/webhooks/nonexistent")
        .to_return(
          status: 404,
          body: '{"message":"Webhook not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { webhooks.delete('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#test' do
    let(:webhook_id) { 'wh_123' }

    it 'sends POST request to /webhooks/:id/test' do
      stub_request(:post, "#{base_url}/webhooks/#{webhook_id}/test")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"delivery_id":"del_test123"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.test(webhook_id)
      expect(result['delivery_id']).to eq('del_test123')
    end

    it 'raises HttpRequestError for non-existent webhook' do
      stub_request(:post, "#{base_url}/webhooks/nonexistent/test")
        .to_return(
          status: 404,
          body: '{"message":"Webhook not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { webhooks.test('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#regenerate_secret' do
    let(:webhook_id) { 'wh_123' }

    it 'sends POST request to /webhooks/:id/regenerate-secret' do
      stub_request(:post, "#{base_url}/webhooks/#{webhook_id}/regenerate-secret")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"id":"wh_123","secret":"whsec_newsecret456"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.regenerate_secret(webhook_id)
      expect(result['secret']).to eq('whsec_newsecret456')
    end

    it 'raises HttpRequestError for non-existent webhook' do
      stub_request(:post, "#{base_url}/webhooks/nonexistent/regenerate-secret")
        .to_return(
          status: 404,
          body: '{"message":"Webhook not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { webhooks.regenerate_secret('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#deliveries' do
    let(:webhook_id) { 'wh_123' }

    it 'sends GET request to /webhooks/:id/deliveries' do
      stub_request(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"data":[{"id":"del_1","status":"success","event_type":"message.sent"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.deliveries(webhook_id)
      expect(result['data']).to be_an(Array)
      expect(result['data'].first['status']).to eq('success')
    end

    it 'sends GET request without params when none specified' do
      stub = stub_request(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
             .to_return(
               status: 200,
               body: '{"data":[]}',
               headers: { 'Content-Type' => 'application/json' }
             )

      webhooks.deliveries(webhook_id)
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
        .with { |req| req.uri.query.nil? })
    end

    describe 'pagination parameters' do
      it 'passes page_size parameter' do
        stub_request(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
          .with(query: { 'page[size]' => '20' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.deliveries(webhook_id, page_size: 20)
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
          .with(query: { 'page[size]' => '20' })
      end

      it 'passes page_cursor parameter' do
        stub_request(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
          .with(query: { 'page[cursor]' => 'cursor_xyz' })
          .to_return(
            status: 200,
            body: '{"data":[],"meta":{"next_cursor":"cursor_next"}}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = webhooks.deliveries(webhook_id, page_cursor: 'cursor_xyz')
        expect(result['meta']['next_cursor']).to eq('cursor_next')
      end
    end

    describe 'filter parameters' do
      it 'filters by status' do
        stub_request(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
          .with(query: { 'filter[status]' => 'failed' })
          .to_return(
            status: 200,
            body: '{"data":[{"status":"failed"}]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = webhooks.deliveries(webhook_id, status: 'failed')
        expect(result['data'].first['status']).to eq('failed')
      end

      it 'filters by event_type' do
        stub_request(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
          .with(query: { 'filter[event_type]' => 'message.bounced' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.deliveries(webhook_id, event_type: 'message.bounced')
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
          .with(query: { 'filter[event_type]' => 'message.bounced' })
      end

      it 'filters by date range' do
        stub_request(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
          .with(query: { 'filter[from_date]' => '2024-01-01', 'filter[to_date]' => '2024-01-31' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.deliveries(webhook_id, from_date: '2024-01-01', to_date: '2024-01-31')
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
          .with(query: { 'filter[from_date]' => '2024-01-01', 'filter[to_date]' => '2024-01-31' })
      end
    end

    describe 'sort parameter' do
      it 'sorts by created_at' do
        stub_request(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
          .with(query: { 'sort' => '-created_at' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        webhooks.deliveries(webhook_id, sort: '-created_at')
        expect(WebMock).to have_requested(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries")
          .with(query: { 'sort' => '-created_at' })
      end
    end
  end

  describe '#delivery' do
    let(:webhook_id) { 'wh_123' }
    let(:delivery_id) { 'del_456' }

    it 'sends GET request to /webhooks/:webhook_id/deliveries/:delivery_id' do
      stub_request(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries/#{delivery_id}")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"id":"del_456","status":"success","payload":{"event":"message.sent"},"response":{"status_code":200}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.delivery(webhook_id, delivery_id)
      expect(result['id']).to eq('del_456')
      expect(result['payload']['event']).to eq('message.sent')
      expect(result['response']['status_code']).to eq(200)
    end

    it 'raises HttpRequestError for non-existent delivery' do
      stub_request(:get, "#{base_url}/webhooks/#{webhook_id}/deliveries/nonexistent")
        .to_return(
          status: 404,
          body: '{"message":"Delivery not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { webhooks.delivery(webhook_id, 'nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe 'error handling' do
    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/webhooks")
        .to_return(
          status: 401,
          body: '{"message":"Invalid token"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { webhooks.list }.to raise_error(Lettermint::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:get, "#{base_url}/webhooks")
        .to_return(
          status: 429,
          body: '{"message":"Too many requests"}',
          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '30' }
        )

      expect { webhooks.list }.to raise_error(Lettermint::RateLimitError) { |e|
        expect(e.retry_after).to eq(30)
      }
    end

    it 'raises TimeoutError on timeout' do
      stub_request(:get, "#{base_url}/webhooks").to_raise(Faraday::TimeoutError)

      expect { webhooks.list }.to raise_error(Lettermint::TimeoutError)
    end
  end
end
