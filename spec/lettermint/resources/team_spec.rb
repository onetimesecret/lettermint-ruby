# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::Resources::Team do
  let(:team_token) { 'lm_team_test123' }
  let(:base_url) { Lettermint::Configuration::DEFAULT_BASE_URL }
  let(:api) { Lettermint::TeamAPI.new(team_token: team_token) }
  let(:team) { api.team }

  describe '#get' do
    it 'sends GET request to /team' do
      stub_request(:get, "#{base_url}/team")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"id":"team_123","name":"Acme Corp","plan":"pro"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = team.get
      expect(result).to eq(
        {
          'id' => 'team_123',
          'name' => 'Acme Corp',
          'plan' => 'pro'
        }
      )
    end

    it 'sends GET request without include param when not specified' do
      stub = stub_request(:get, "#{base_url}/team")
             .to_return(
               status: 200,
               body: '{"id":"team_123"}',
               headers: { 'Content-Type' => 'application/json' }
             )

      team.get
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/team")
        .with { |req| req.uri.query.nil? })
    end

    it 'includes features when requested' do
      stub_request(:get, "#{base_url}/team?include=features")
        .to_return(
          status: 200,
          body: '{"id":"team_123","features":["custom_domains","webhooks"]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = team.get(include: 'features')
      expect(result['features']).to eq(%w[custom_domains webhooks])
    end

    it 'includes featuresCount when requested' do
      stub_request(:get, "#{base_url}/team?include=featuresCount")
        .to_return(
          status: 200,
          body: '{"id":"team_123","featuresCount":5}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = team.get(include: 'featuresCount')
      expect(result['featuresCount']).to eq(5)
    end

    it 'includes featuresExists when requested' do
      stub_request(:get, "#{base_url}/team?include=featuresExists")
        .to_return(
          status: 200,
          body: '{"id":"team_123","featuresExists":true}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = team.get(include: 'featuresExists')
      expect(result['featuresExists']).to eq(true)
    end
  end

  describe '#update' do
    it 'sends PUT request to /team with name' do
      stub_request(:put, "#{base_url}/team")
        .with(
          body: { name: 'New Team Name' },
          headers: { 'Authorization' => "Bearer #{team_token}" }
        )
        .to_return(
          status: 200,
          body: '{"id":"team_123","name":"New Team Name"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = team.update(name: 'New Team Name')
      expect(result['name']).to eq('New Team Name')
    end

    it 'raises ValidationError on invalid name' do
      stub_request(:put, "#{base_url}/team")
        .with(body: { name: '' })
        .to_return(
          status: 422,
          body: '{"message":"Name cannot be blank","error":"validation_error"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { team.update(name: '') }.to raise_error(Lettermint::ValidationError)
    end
  end

  describe '#usage' do
    it 'sends GET request to /team/usage' do
      stub_request(:get, "#{base_url}/team/usage")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{
            "current_period": {"emails_sent": 1000, "limit": 10000},
            "historical": [{"month": "2024-01", "emails_sent": 800}]
          }',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = team.usage
      expect(result['current_period']['emails_sent']).to eq(1000)
      expect(result['historical']).to be_an(Array)
    end
  end

  describe '#members' do
    it 'sends GET request to /team/members' do
      stub_request(:get, "#{base_url}/team/members")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"data":[{"id":"mem_1","email":"admin@example.com","role":"admin"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = team.members
      expect(result['data']).to be_an(Array)
      expect(result['data'].first['email']).to eq('admin@example.com')
    end

    it 'sends GET request without params when none specified' do
      stub = stub_request(:get, "#{base_url}/team/members")
             .to_return(
               status: 200,
               body: '{"data":[]}',
               headers: { 'Content-Type' => 'application/json' }
             )

      team.members
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/team/members")
        .with { |req| req.uri.query.nil? })
    end

    it 'passes page_size parameter' do
      stub_request(:get, "#{base_url}/team/members")
        .with(query: { 'page[size]' => '10' })
        .to_return(
          status: 200,
          body: '{"data":[]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      team.members(page_size: 10)
      expect(WebMock).to have_requested(:get, "#{base_url}/team/members")
        .with(query: { 'page[size]' => '10' })
    end

    it 'passes page_cursor parameter' do
      stub_request(:get, "#{base_url}/team/members")
        .with(query: { 'page[cursor]' => 'cursor_abc' })
        .to_return(
          status: 200,
          body: '{"data":[],"meta":{"next_cursor":"cursor_def"}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = team.members(page_cursor: 'cursor_abc')
      expect(result['meta']['next_cursor']).to eq('cursor_def')
    end

    it 'passes both pagination parameters' do
      stub_request(:get, "#{base_url}/team/members")
        .with(query: { 'page[size]' => '25', 'page[cursor]' => 'xyz789' })
        .to_return(
          status: 200,
          body: '{"data":[]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      team.members(page_size: 25, page_cursor: 'xyz789')
      expect(WebMock).to have_requested(:get, "#{base_url}/team/members")
        .with(query: { 'page[size]' => '25', 'page[cursor]' => 'xyz789' })
    end
  end

  describe 'error handling' do
    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/team")
        .to_return(
          status: 401,
          body: '{"message":"Invalid token"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { team.get }.to raise_error(Lettermint::AuthenticationError)
    end

    it 'raises AuthenticationError on 403' do
      stub_request(:get, "#{base_url}/team")
        .to_return(
          status: 403,
          body: '{"message":"Forbidden"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { team.get }.to raise_error(Lettermint::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:get, "#{base_url}/team/members")
        .to_return(
          status: 429,
          body: '{"message":"Too many requests"}',
          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '60' }
        )

      expect { team.members }.to raise_error(Lettermint::RateLimitError) { |e|
        expect(e.retry_after).to eq(60)
      }
    end
  end
end
