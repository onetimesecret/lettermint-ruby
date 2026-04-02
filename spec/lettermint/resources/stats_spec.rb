# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::Resources::Stats do
  let(:team_token) { 'lm_team_test123' }
  let(:base_url) { Lettermint::Configuration::DEFAULT_BASE_URL }
  let(:api) { Lettermint::TeamAPI.new(team_token: team_token) }
  let(:stats) { api.stats }

  describe '#get' do
    let(:from_date) { '2024-01-01' }
    let(:to_date) { '2024-01-31' }

    it 'sends GET request to /stats with required date params' do
      stub_request(:get, "#{base_url}/stats")
        .with(
          query: { 'from' => from_date, 'to' => to_date },
          headers: { 'Authorization' => "Bearer #{team_token}" }
        )
        .to_return(
          status: 200,
          body: '{"totals":{"sent":1000,"delivered":950},"daily":[]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = stats.get(from: from_date, to: to_date)
      expect(result['totals']['sent']).to eq(1000)
      expect(result['totals']['delivered']).to eq(950)
    end

    it 'returns daily breakdown data' do
      stub_request(:get, "#{base_url}/stats")
        .with(query: { 'from' => from_date, 'to' => to_date })
        .to_return(
          status: 200,
          body: '{"totals":{},"daily":[{"date":"2024-01-01","sent":100},{"date":"2024-01-02","sent":150}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = stats.get(from: from_date, to: to_date)
      expect(result['daily']).to be_an(Array)
      expect(result['daily'].length).to eq(2)
      expect(result['daily'].first['date']).to eq('2024-01-01')
    end

    describe 'optional project_id parameter' do
      it 'includes project_id when specified' do
        stub_request(:get, "#{base_url}/stats")
          .with(query: { 'from' => from_date, 'to' => to_date, 'project_id' => 'proj_123' })
          .to_return(
            status: 200,
            body: '{"totals":{"sent":500},"daily":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        stats.get(from: from_date, to: to_date, project_id: 'proj_123')
        expect(WebMock).to have_requested(:get, "#{base_url}/stats")
          .with(query: { 'from' => from_date, 'to' => to_date, 'project_id' => 'proj_123' })
      end

      it 'excludes project_id when nil' do
        stub = stub_request(:get, "#{base_url}/stats")
               .with(query: { 'from' => from_date, 'to' => to_date })
               .to_return(
                 status: 200,
                 body: '{"totals":{},"daily":[]}',
                 headers: { 'Content-Type' => 'application/json' }
               )

        stats.get(from: from_date, to: to_date, project_id: nil)
        expect(stub).to have_been_requested
        expect(WebMock).not_to have_requested(:get, "#{base_url}/stats")
          .with(query: hash_including('project_id'))
      end
    end

    describe 'route filtering parameters' do
      it 'includes route_id when specified' do
        stub_request(:get, "#{base_url}/stats")
          .with(query: { 'from' => from_date, 'to' => to_date, 'route_id' => 'route_456' })
          .to_return(
            status: 200,
            body: '{"totals":{"sent":200},"daily":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        stats.get(from: from_date, to: to_date, route_id: 'route_456')
        expect(WebMock).to have_requested(:get, "#{base_url}/stats")
          .with(query: { 'from' => from_date, 'to' => to_date, 'route_id' => 'route_456' })
      end

      it 'includes route_ids array when specified' do
        url = "#{base_url}/stats?from=#{from_date}&route_ids%5B%5D=route_1&route_ids%5B%5D=route_2&to=#{to_date}"
        stub_request(:get, url)
          .to_return(
            status: 200,
            body: '{"totals":{"sent":400},"daily":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = stats.get(from: from_date, to: to_date, route_ids: %w[route_1 route_2])
        expect(result['totals']['sent']).to eq(400)
      end

      it 'excludes route_id when nil' do
        stub = stub_request(:get, "#{base_url}/stats")
               .with(query: { 'from' => from_date, 'to' => to_date })
               .to_return(
                 status: 200,
                 body: '{"totals":{},"daily":[]}',
                 headers: { 'Content-Type' => 'application/json' }
               )

        stats.get(from: from_date, to: to_date, route_id: nil)
        expect(stub).to have_been_requested
      end
    end

    describe 'date validation' do
      it 'accepts dates at maximum range (90 days)' do
        stub_request(:get, "#{base_url}/stats")
          .with(query: { 'from' => '2024-01-01', 'to' => '2024-03-31' })
          .to_return(
            status: 200,
            body: '{"totals":{},"daily":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = stats.get(from: '2024-01-01', to: '2024-03-31')
        expect(result).to be_a(Hash)
      end

      it 'raises ValidationError when date range exceeds 90 days' do
        stub_request(:get, "#{base_url}/stats")
          .with(query: { 'from' => '2024-01-01', 'to' => '2024-06-01' })
          .to_return(
            status: 422,
            body: '{"message":"Date range cannot exceed 90 days","error":"validation_error"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        expect { stats.get(from: '2024-01-01', to: '2024-06-01') }
          .to raise_error(Lettermint::ValidationError, /90 days/)
      end

      it 'raises ValidationError for invalid date format' do
        stub_request(:get, "#{base_url}/stats")
          .with(query: { 'from' => 'invalid', 'to' => to_date })
          .to_return(
            status: 422,
            body: '{"message":"Invalid date format for from","error":"validation_error"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        expect { stats.get(from: 'invalid', to: to_date) }
          .to raise_error(Lettermint::ValidationError, /Invalid date format/)
      end

      it 'raises ValidationError when from is after to' do
        stub_request(:get, "#{base_url}/stats")
          .with(query: { 'from' => '2024-02-01', 'to' => '2024-01-01' })
          .to_return(
            status: 422,
            body: '{"message":"from date must be before to date","error":"validation_error"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        expect { stats.get(from: '2024-02-01', to: '2024-01-01') }
          .to raise_error(Lettermint::ValidationError)
      end
    end

    describe 'combined parameters' do
      it 'passes all parameters together' do
        stub = stub_request(:get, "#{base_url}/stats")
               .with(query: {
                       'from' => from_date,
                       'to' => to_date,
                       'project_id' => 'proj_789'
                     })
               .to_return(
                 status: 200,
                 body: '{"totals":{"sent":100,"delivered":95,"bounced":5},"daily":[]}',
                 headers: { 'Content-Type' => 'application/json' }
               )

        result = stats.get(from: from_date, to: to_date, project_id: 'proj_789')
        expect(stub).to have_been_requested
        expect(result['totals']['bounced']).to eq(5)
      end
    end
  end

  describe 'error handling' do
    let(:from_date) { '2024-01-01' }
    let(:to_date) { '2024-01-31' }

    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/stats")
        .with(query: { 'from' => from_date, 'to' => to_date })
        .to_return(
          status: 401,
          body: '{"message":"Invalid token"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { stats.get(from: from_date, to: to_date) }.to raise_error(Lettermint::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:get, "#{base_url}/stats")
        .with(query: { 'from' => from_date, 'to' => to_date })
        .to_return(
          status: 429,
          body: '{"message":"Too many requests"}',
          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '60' }
        )

      expect { stats.get(from: from_date, to: to_date) }.to raise_error(Lettermint::RateLimitError) { |e|
        expect(e.retry_after).to eq(60)
      }
    end

    it 'raises TimeoutError on timeout' do
      stub_request(:get, "#{base_url}/stats")
        .with(query: { 'from' => from_date, 'to' => to_date })
        .to_raise(Faraday::TimeoutError)

      expect { stats.get(from: from_date, to: to_date) }.to raise_error(Lettermint::TimeoutError)
    end

    it 'raises HttpRequestError on server error' do
      stub_request(:get, "#{base_url}/stats")
        .with(query: { 'from' => from_date, 'to' => to_date })
        .to_return(
          status: 500,
          body: '{"message":"Internal server error"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { stats.get(from: from_date, to: to_date) }.to raise_error(Lettermint::HttpRequestError)
    end
  end
end
