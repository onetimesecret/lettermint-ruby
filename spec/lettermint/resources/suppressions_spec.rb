# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::Resources::Suppressions do
  let(:team_token) { 'lm_team_test123' }
  let(:base_url) { Lettermint::Configuration::DEFAULT_BASE_URL }
  let(:api) { Lettermint::TeamAPI.new(team_token: team_token) }
  let(:suppressions) { api.suppressions }

  describe '#list' do
    it 'sends GET request to /suppressions' do
      stub_request(:get, "#{base_url}/suppressions")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"data":[{"id":"sup_1","value":"spam@example.com","reason":"spam_complaint"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = suppressions.list
      expect(result['data']).to be_an(Array)
      expect(result['data'].first['value']).to eq('spam@example.com')
    end

    it 'sends GET request without params when none specified' do
      stub = stub_request(:get, "#{base_url}/suppressions")
             .to_return(
               status: 200,
               body: '{"data":[]}',
               headers: { 'Content-Type' => 'application/json' }
             )

      suppressions.list
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/suppressions")
        .with { |req| req.uri.query.nil? })
    end

    describe 'pagination parameters' do
      it 'passes page_size parameter' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'page[size]' => '50' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        suppressions.list(page_size: 50)
        expect(WebMock).to have_requested(:get, "#{base_url}/suppressions")
          .with(query: { 'page[size]' => '50' })
      end

      it 'passes page_cursor parameter' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'page[cursor]' => 'cursor_abc' })
          .to_return(
            status: 200,
            body: '{"data":[],"meta":{"next_cursor":"cursor_def"}}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = suppressions.list(page_cursor: 'cursor_abc')
        expect(result['meta']['next_cursor']).to eq('cursor_def')
      end

      it 'passes both pagination parameters' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'page[size]' => '25', 'page[cursor]' => 'xyz789' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        suppressions.list(page_size: 25, page_cursor: 'xyz789')
        expect(WebMock).to have_requested(:get, "#{base_url}/suppressions")
          .with(query: { 'page[size]' => '25', 'page[cursor]' => 'xyz789' })
      end
    end

    describe 'sort parameter' do
      it 'sorts by value ascending' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'sort' => 'value' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        suppressions.list(sort: 'value')
        expect(WebMock).to have_requested(:get, "#{base_url}/suppressions")
          .with(query: { 'sort' => 'value' })
      end

      it 'sorts by created_at descending' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'sort' => '-created_at' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        suppressions.list(sort: '-created_at')
        expect(WebMock).to have_requested(:get, "#{base_url}/suppressions")
          .with(query: { 'sort' => '-created_at' })
      end

      it 'sorts by reason' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'sort' => 'reason' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        suppressions.list(sort: 'reason')
        expect(WebMock).to have_requested(:get, "#{base_url}/suppressions")
          .with(query: { 'sort' => 'reason' })
      end
    end

    describe 'filter parameters' do
      it 'filters by scope' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'filter[scope]' => 'team' })
          .to_return(
            status: 200,
            body: '{"data":[{"scope":"team"}]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = suppressions.list(scope: 'team')
        expect(result['data'].first['scope']).to eq('team')
      end

      it 'filters by route_id' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'filter[route_id]' => 'route_123' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        suppressions.list(route_id: 'route_123')
        expect(WebMock).to have_requested(:get, "#{base_url}/suppressions")
          .with(query: { 'filter[route_id]' => 'route_123' })
      end

      it 'filters by project_id' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'filter[project_id]' => 'proj_456' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        suppressions.list(project_id: 'proj_456')
        expect(WebMock).to have_requested(:get, "#{base_url}/suppressions")
          .with(query: { 'filter[project_id]' => 'proj_456' })
      end

      it 'filters by value' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'filter[value]' => 'spam@example.com' })
          .to_return(
            status: 200,
            body: '{"data":[{"value":"spam@example.com"}]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = suppressions.list(value: 'spam@example.com')
        expect(result['data'].first['value']).to eq('spam@example.com')
      end

      it 'filters by reason' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'filter[reason]' => 'hard_bounce' })
          .to_return(
            status: 200,
            body: '{"data":[{"reason":"hard_bounce"}]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = suppressions.list(reason: 'hard_bounce')
        expect(result['data'].first['reason']).to eq('hard_bounce')
      end

      it 'filters by multiple criteria' do
        stub_request(:get, "#{base_url}/suppressions")
          .with(query: { 'filter[scope]' => 'project', 'filter[reason]' => 'spam_complaint' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        suppressions.list(scope: 'project', reason: 'spam_complaint')
        expect(WebMock).to have_requested(:get, "#{base_url}/suppressions")
          .with(query: { 'filter[scope]' => 'project', 'filter[reason]' => 'spam_complaint' })
      end
    end

    describe 'combined parameters' do
      it 'passes all parameters together' do
        stub = stub_request(:get, "#{base_url}/suppressions")
               .with(query: {
                       'page[size]' => '10',
                       'page[cursor]' => 'abc',
                       'sort' => '-created_at',
                       'filter[scope]' => 'team',
                       'filter[reason]' => 'manual'
                     })
               .to_return(
                 status: 200,
                 body: '{"data":[]}',
                 headers: { 'Content-Type' => 'application/json' }
               )

        suppressions.list(page_size: 10, page_cursor: 'abc', sort: '-created_at', scope: 'team', reason: 'manual')
        expect(stub).to have_been_requested
      end
    end
  end

  describe '#create' do
    it 'sends POST request to /suppressions with single email' do
      stub_request(:post, "#{base_url}/suppressions")
        .with(
          body: { reason: 'manual', scope: 'team', email: 'blocked@example.com' },
          headers: { 'Authorization' => "Bearer #{team_token}" }
        )
        .to_return(
          status: 201,
          body: '{"id":"sup_new","value":"blocked@example.com","reason":"manual","scope":"team"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = suppressions.create(reason: 'manual', scope: 'team', email: 'blocked@example.com')
      expect(result['id']).to eq('sup_new')
      expect(result['value']).to eq('blocked@example.com')
      expect(result['reason']).to eq('manual')
    end

    it 'sends POST request with multiple emails' do
      emails = ['spam1@example.com', 'spam2@example.com']
      stub_request(:post, "#{base_url}/suppressions")
        .with(body: { reason: 'spam_complaint', scope: 'team', emails: emails })
        .to_return(
          status: 201,
          body: '{"count":2}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = suppressions.create(reason: 'spam_complaint', scope: 'team', emails: emails)
      expect(result['count']).to eq(2)
    end

    it 'sends POST request with project scope and project_id' do
      stub_request(:post, "#{base_url}/suppressions")
        .with(body: { reason: 'unsubscribe', scope: 'project', email: 'user@example.com', project_id: 'proj_123' })
        .to_return(
          status: 201,
          body: '{"id":"sup_proj","scope":"project","project_id":"proj_123"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = suppressions.create(reason: 'unsubscribe', scope: 'project', email: 'user@example.com',
                                   project_id: 'proj_123')
      expect(result['scope']).to eq('project')
      expect(result['project_id']).to eq('proj_123')
    end

    it 'sends POST request with route scope and route_id' do
      stub_request(:post, "#{base_url}/suppressions")
        .with(body: { reason: 'hard_bounce', scope: 'route', email: 'bounced@example.com', route_id: 'route_456' })
        .to_return(
          status: 201,
          body: '{"id":"sup_route","scope":"route","route_id":"route_456"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = suppressions.create(reason: 'hard_bounce', scope: 'route', email: 'bounced@example.com',
                                   route_id: 'route_456')
      expect(result['scope']).to eq('route')
      expect(result['route_id']).to eq('route_456')
    end

    it 'raises ValidationError for invalid reason' do
      stub_request(:post, "#{base_url}/suppressions")
        .with(body: { reason: 'invalid_reason', scope: 'team', email: 'test@example.com' })
        .to_return(
          status: 422,
          body: '{"message":"Invalid reason","error":"validation_error"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { suppressions.create(reason: 'invalid_reason', scope: 'team', email: 'test@example.com') }
        .to raise_error(Lettermint::ValidationError)
    end

    it 'raises ValidationError for missing scope identifier' do
      stub_request(:post, "#{base_url}/suppressions")
        .with(body: { reason: 'manual', scope: 'project', email: 'test@example.com' })
        .to_return(
          status: 422,
          body: '{"message":"project_id required when scope is project","error":"validation_error"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { suppressions.create(reason: 'manual', scope: 'project', email: 'test@example.com') }
        .to raise_error(Lettermint::ValidationError, /project_id required/)
    end
  end

  describe '#delete' do
    let(:suppression_id) { 'sup_123' }

    it 'sends DELETE request to /suppressions/:id' do
      stub_request(:delete, "#{base_url}/suppressions/#{suppression_id}")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"message":"Suppression deleted"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = suppressions.delete(suppression_id)
      expect(result['message']).to eq('Suppression deleted')
    end

    it 'handles 204 No Content response' do
      stub_request(:delete, "#{base_url}/suppressions/#{suppression_id}")
        .to_return(status: 204, body: '')

      result = suppressions.delete(suppression_id)
      expect(result).to eq('')
    end

    it 'raises HttpRequestError for non-existent suppression' do
      stub_request(:delete, "#{base_url}/suppressions/nonexistent")
        .to_return(
          status: 404,
          body: '{"message":"Suppression not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { suppressions.delete('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe 'error handling' do
    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/suppressions")
        .to_return(
          status: 401,
          body: '{"message":"Invalid token"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { suppressions.list }.to raise_error(Lettermint::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:get, "#{base_url}/suppressions")
        .to_return(
          status: 429,
          body: '{"message":"Too many requests"}',
          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '30' }
        )

      expect { suppressions.list }.to raise_error(Lettermint::RateLimitError) { |e|
        expect(e.retry_after).to eq(30)
      }
    end

    it 'raises TimeoutError on timeout' do
      stub_request(:get, "#{base_url}/suppressions").to_raise(Faraday::TimeoutError)

      expect { suppressions.list }.to raise_error(Lettermint::TimeoutError)
    end
  end
end
