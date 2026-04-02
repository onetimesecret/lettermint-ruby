# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::Resources::Routes do
  let(:team_token) { 'lm_team_test123' }
  let(:base_url) { Lettermint::Configuration::DEFAULT_BASE_URL }
  let(:api) { Lettermint::TeamAPI.new(team_token: team_token) }
  let(:project_id) { 'proj_123' }

  describe 'project-scoped operations' do
    let(:routes) { api.projects.routes(project_id) }

    describe '#list' do
      it 'sends GET request to /projects/:project_id/routes' do
        stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
          .with(headers: { 'Authorization' => "Bearer #{team_token}" })
          .to_return(
            status: 200,
            body: '{"data":[{"id":"route_1","name":"Transactional","route_type":"transactional"}]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.list
        expect(result['data']).to be_an(Array)
        expect(result['data'].first['name']).to eq('Transactional')
      end

      it 'sends GET request without params when none specified' do
        stub = stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
               .to_return(
                 status: 200,
                 body: '{"data":[]}',
                 headers: { 'Content-Type' => 'application/json' }
               )

        routes.list
        expect(stub).to have_been_requested
        expect(WebMock).to(have_requested(:get, "#{base_url}/projects/#{project_id}/routes")
          .with { |req| req.uri.query.nil? })
      end

      describe 'pagination parameters' do
        it 'passes page_size parameter' do
          stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'page[size]' => '50' })
            .to_return(
              status: 200,
              body: '{"data":[]}',
              headers: { 'Content-Type' => 'application/json' }
            )

          routes.list(page_size: 50)
          expect(WebMock).to have_requested(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'page[size]' => '50' })
        end

        it 'passes page_cursor parameter' do
          stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'page[cursor]' => 'cursor_abc' })
            .to_return(
              status: 200,
              body: '{"data":[],"meta":{"next_cursor":"cursor_def"}}',
              headers: { 'Content-Type' => 'application/json' }
            )

          result = routes.list(page_cursor: 'cursor_abc')
          expect(result['meta']['next_cursor']).to eq('cursor_def')
        end
      end

      describe 'sort parameter' do
        it 'sorts by name ascending' do
          stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'sort' => 'name' })
            .to_return(
              status: 200,
              body: '{"data":[]}',
              headers: { 'Content-Type' => 'application/json' }
            )

          routes.list(sort: 'name')
          expect(WebMock).to have_requested(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'sort' => 'name' })
        end

        it 'sorts by created_at descending' do
          stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'sort' => '-created_at' })
            .to_return(
              status: 200,
              body: '{"data":[]}',
              headers: { 'Content-Type' => 'application/json' }
            )

          routes.list(sort: '-created_at')
          expect(WebMock).to have_requested(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'sort' => '-created_at' })
        end
      end

      describe 'filter parameters' do
        it 'filters by route_type' do
          stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'filter[route_type]' => 'transactional' })
            .to_return(
              status: 200,
              body: '{"data":[{"route_type":"transactional"}]}',
              headers: { 'Content-Type' => 'application/json' }
            )

          result = routes.list(route_type: 'transactional')
          expect(result['data'].first['route_type']).to eq('transactional')
        end

        it 'filters by is_default' do
          stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'filter[is_default]' => 'true' })
            .to_return(
              status: 200,
              body: '{"data":[{"is_default":true}]}',
              headers: { 'Content-Type' => 'application/json' }
            )

          routes.list(is_default: true)
          expect(WebMock).to have_requested(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'filter[is_default]' => 'true' })
        end

        it 'filters by search' do
          stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'filter[search]' => 'marketing' })
            .to_return(
              status: 200,
              body: '{"data":[{"name":"Marketing Route"}]}',
              headers: { 'Content-Type' => 'application/json' }
            )

          routes.list(search: 'marketing')
          expect(WebMock).to have_requested(:get, "#{base_url}/projects/#{project_id}/routes")
            .with(query: { 'filter[search]' => 'marketing' })
        end
      end
    end

    describe '#create' do
      it 'sends POST request to /projects/:project_id/routes' do
        stub_request(:post, "#{base_url}/projects/#{project_id}/routes")
          .with(
            body: { name: 'New Route', route_type: 'transactional' },
            headers: { 'Authorization' => "Bearer #{team_token}" }
          )
          .to_return(
            status: 201,
            body: '{"id":"route_new","name":"New Route","route_type":"transactional"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.create(name: 'New Route', route_type: 'transactional')
        expect(result['id']).to eq('route_new')
        expect(result['name']).to eq('New Route')
        expect(result['route_type']).to eq('transactional')
      end

      it 'sends POST request with optional slug' do
        stub_request(:post, "#{base_url}/projects/#{project_id}/routes")
          .with(body: { name: 'Marketing', route_type: 'broadcast', slug: 'marketing-emails' })
          .to_return(
            status: 201,
            body: '{"id":"route_mkt","name":"Marketing","slug":"marketing-emails"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.create(name: 'Marketing', route_type: 'broadcast', slug: 'marketing-emails')
        expect(result['slug']).to eq('marketing-emails')
      end

      it 'raises ValidationError for invalid route_type' do
        stub_request(:post, "#{base_url}/projects/#{project_id}/routes")
          .with(body: { name: 'Invalid', route_type: 'invalid' })
          .to_return(
            status: 422,
            body: '{"message":"Invalid route_type","error":"validation_error"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        expect { routes.create(name: 'Invalid', route_type: 'invalid') }
          .to raise_error(Lettermint::ValidationError)
      end
    end
  end

  describe 'project_id required guard' do
    let(:routes_without_project) { api.routes }

    describe '#list' do
      it 'raises ArgumentError when project_id is not set' do
        expect { routes_without_project.list }
          .to raise_error(ArgumentError, 'project_id required for listing routes')
      end
    end

    describe '#create' do
      it 'raises ArgumentError when project_id is not set' do
        expect { routes_without_project.create(name: 'Test', route_type: 'transactional') }
          .to raise_error(ArgumentError, 'project_id required for creating routes')
      end
    end
  end

  describe 'direct route operations' do
    let(:routes) { api.routes }
    let(:route_id) { 'route_456' }

    describe '#find' do
      it 'sends GET request to /routes/:id' do
        stub_request(:get, "#{base_url}/routes/#{route_id}")
          .with(headers: { 'Authorization' => "Bearer #{team_token}" })
          .to_return(
            status: 200,
            body: '{"id":"route_456","name":"My Route","route_type":"transactional"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.find(route_id)
        expect(result['id']).to eq('route_456')
        expect(result['name']).to eq('My Route')
      end

      it 'sends GET request without include param when not specified' do
        stub = stub_request(:get, "#{base_url}/routes/#{route_id}")
               .to_return(
                 status: 200,
                 body: '{"id":"route_456"}',
                 headers: { 'Content-Type' => 'application/json' }
               )

        routes.find(route_id)
        expect(stub).to have_been_requested
        expect(WebMock).to(have_requested(:get, "#{base_url}/routes/#{route_id}")
          .with { |req| req.uri.query.nil? })
      end

      it 'includes project when requested' do
        stub_request(:get, "#{base_url}/routes/#{route_id}?include=project")
          .to_return(
            status: 200,
            body: '{"id":"route_456","project":{"id":"proj_123","name":"My Project"}}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.find(route_id, include: 'project')
        expect(result['project']).to be_a(Hash)
        expect(result['project']['id']).to eq('proj_123')
      end

      it 'includes statistics when requested' do
        stub_request(:get, "#{base_url}/routes/#{route_id}?include=statistics")
          .to_return(
            status: 200,
            body: '{"id":"route_456","statistics":{"sent":100,"delivered":95}}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.find(route_id, include: 'statistics')
        expect(result['statistics']['sent']).to eq(100)
      end

      it 'raises HttpRequestError for non-existent route' do
        stub_request(:get, "#{base_url}/routes/nonexistent")
          .to_return(
            status: 404,
            body: '{"message":"Route not found"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        expect { routes.find('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
      end
    end

    describe '#update' do
      it 'sends PUT request to /routes/:id with name' do
        stub_request(:put, "#{base_url}/routes/#{route_id}")
          .with(
            body: { name: 'Updated Route' },
            headers: { 'Authorization' => "Bearer #{team_token}" }
          )
          .to_return(
            status: 200,
            body: '{"id":"route_456","name":"Updated Route"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.update(route_id, name: 'Updated Route')
        expect(result['name']).to eq('Updated Route')
      end

      it 'sends PUT request with settings' do
        settings = { track_opens: true, track_clicks: false }
        stub_request(:put, "#{base_url}/routes/#{route_id}")
          .with(body: { settings: settings })
          .to_return(
            status: 200,
            body: '{"id":"route_456","settings":{"track_opens":true,"track_clicks":false}}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.update(route_id, settings: settings)
        expect(result['settings']['track_opens']).to eq(true)
        expect(result['settings']['track_clicks']).to eq(false)
      end

      it 'sends PUT request with inbound_settings' do
        inbound_settings = { inbound_domain: 'inbound.example.com', spam_threshold: 5 }
        stub_request(:put, "#{base_url}/routes/#{route_id}")
          .with(body: { inbound_settings: inbound_settings })
          .to_return(
            status: 200,
            body: '{"id":"route_456","inbound_settings":{"inbound_domain":"inbound.example.com"}}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.update(route_id, inbound_settings: inbound_settings)
        expect(result['inbound_settings']['inbound_domain']).to eq('inbound.example.com')
      end

      it 'raises HttpRequestError for non-existent route' do
        stub_request(:put, "#{base_url}/routes/nonexistent")
          .with(body: { name: 'Test' })
          .to_return(
            status: 404,
            body: '{"message":"Route not found"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        expect { routes.update('nonexistent', name: 'Test') }
          .to raise_error(Lettermint::HttpRequestError)
      end
    end

    describe '#delete' do
      it 'sends DELETE request to /routes/:id' do
        stub_request(:delete, "#{base_url}/routes/#{route_id}")
          .with(headers: { 'Authorization' => "Bearer #{team_token}" })
          .to_return(
            status: 200,
            body: '{"message":"Route deleted"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.delete(route_id)
        expect(result['message']).to eq('Route deleted')
      end

      it 'handles 204 No Content response' do
        stub_request(:delete, "#{base_url}/routes/#{route_id}")
          .to_return(status: 204, body: '')

        result = routes.delete(route_id)
        expect(result).to eq('')
      end

      it 'raises HttpRequestError for non-existent route' do
        stub_request(:delete, "#{base_url}/routes/nonexistent")
          .to_return(
            status: 404,
            body: '{"message":"Route not found"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        expect { routes.delete('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
      end
    end

    describe '#verify_inbound_domain' do
      it 'sends POST request to /routes/:id/verify-inbound-domain' do
        stub_request(:post, "#{base_url}/routes/#{route_id}/verify-inbound-domain")
          .with(headers: { 'Authorization' => "Bearer #{team_token}" })
          .to_return(
            status: 200,
            body: '{"verified":true,"domain":"inbound.example.com"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.verify_inbound_domain(route_id)
        expect(result['verified']).to eq(true)
        expect(result['domain']).to eq('inbound.example.com')
      end

      it 'returns unverified status when domain is not configured' do
        stub_request(:post, "#{base_url}/routes/#{route_id}/verify-inbound-domain")
          .to_return(
            status: 200,
            body: '{"verified":false,"error":"DNS records not found"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = routes.verify_inbound_domain(route_id)
        expect(result['verified']).to eq(false)
        expect(result['error']).to include('DNS records not found')
      end

      it 'raises HttpRequestError for non-existent route' do
        stub_request(:post, "#{base_url}/routes/nonexistent/verify-inbound-domain")
          .to_return(
            status: 404,
            body: '{"message":"Route not found"}',
            headers: { 'Content-Type' => 'application/json' }
          )

        expect { routes.verify_inbound_domain('nonexistent') }
          .to raise_error(Lettermint::HttpRequestError)
      end
    end
  end

  describe 'error handling' do
    let(:routes) { api.projects.routes(project_id) }

    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
        .to_return(
          status: 401,
          body: '{"message":"Invalid token"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { routes.list }.to raise_error(Lettermint::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
        .to_return(
          status: 429,
          body: '{"message":"Too many requests"}',
          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '30' }
        )

      expect { routes.list }.to raise_error(Lettermint::RateLimitError) { |e|
        expect(e.retry_after).to eq(30)
      }
    end

    it 'raises TimeoutError on timeout' do
      stub_request(:get, "#{base_url}/projects/#{project_id}/routes").to_raise(Faraday::TimeoutError)

      expect { routes.list }.to raise_error(Lettermint::TimeoutError)
    end
  end
end
