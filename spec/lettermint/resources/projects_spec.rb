# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::Resources::Projects do
  let(:team_token) { 'lm_team_test123' }
  let(:base_url) { Lettermint::Configuration::DEFAULT_BASE_URL }
  let(:api) { Lettermint::TeamAPI.new(team_token: team_token) }
  let(:projects) { api.projects }

  describe '#list' do
    it 'sends GET request to /projects' do
      stub_request(:get, "#{base_url}/projects")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"data":[{"id":"proj_1","name":"My Project"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.list
      expect(result['data']).to be_an(Array)
      expect(result['data'].first['name']).to eq('My Project')
    end

    it 'sends GET request without params when none specified' do
      stub = stub_request(:get, "#{base_url}/projects")
             .to_return(
               status: 200,
               body: '{"data":[]}',
               headers: { 'Content-Type' => 'application/json' }
             )

      projects.list
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/projects")
        .with { |req| req.uri.query.nil? })
    end

    describe 'pagination parameters' do
      it 'passes page_size parameter' do
        stub_request(:get, "#{base_url}/projects")
          .with(query: { 'page[size]' => '50' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        projects.list(page_size: 50)
        expect(WebMock).to have_requested(:get, "#{base_url}/projects")
          .with(query: { 'page[size]' => '50' })
      end

      it 'passes page_cursor parameter' do
        stub_request(:get, "#{base_url}/projects")
          .with(query: { 'page[cursor]' => 'cursor_abc' })
          .to_return(
            status: 200,
            body: '{"data":[],"meta":{"next_cursor":"cursor_def"}}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = projects.list(page_cursor: 'cursor_abc')
        expect(result['meta']['next_cursor']).to eq('cursor_def')
      end
    end

    describe 'sort parameter' do
      it 'sorts by name ascending' do
        stub_request(:get, "#{base_url}/projects")
          .with(query: { 'sort' => 'name' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        projects.list(sort: 'name')
        expect(WebMock).to have_requested(:get, "#{base_url}/projects")
          .with(query: { 'sort' => 'name' })
      end

      it 'sorts by created_at descending' do
        stub_request(:get, "#{base_url}/projects")
          .with(query: { 'sort' => '-created_at' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        projects.list(sort: '-created_at')
        expect(WebMock).to have_requested(:get, "#{base_url}/projects")
          .with(query: { 'sort' => '-created_at' })
      end
    end

    describe 'search parameter' do
      it 'passes search filter' do
        stub_request(:get, "#{base_url}/projects")
          .with(query: { 'filter[search]' => 'test' })
          .to_return(
            status: 200,
            body: '{"data":[{"name":"test project"}]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        projects.list(search: 'test')
        expect(WebMock).to have_requested(:get, "#{base_url}/projects")
          .with(query: { 'filter[search]' => 'test' })
      end
    end
  end

  describe '#create' do
    it 'sends POST request to /projects with name' do
      stub_request(:post, "#{base_url}/projects")
        .with(
          body: { name: 'New Project' },
          headers: { 'Authorization' => "Bearer #{team_token}" }
        )
        .to_return(
          status: 201,
          body: '{"id":"proj_new","name":"New Project","api_token":"lm_proj_xyz"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.create(name: 'New Project')
      expect(result['id']).to eq('proj_new')
      expect(result['name']).to eq('New Project')
      expect(result['api_token']).to eq('lm_proj_xyz')
    end

    it 'sends POST request with smtp_enabled option' do
      stub_request(:post, "#{base_url}/projects")
        .with(body: { name: 'SMTP Project', smtp_enabled: true })
        .to_return(
          status: 201,
          body: '{"id":"proj_smtp","name":"SMTP Project","smtp_enabled":true}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.create(name: 'SMTP Project', smtp_enabled: true)
      expect(result['smtp_enabled']).to eq(true)
    end

    it 'sends POST request with initial_routes option' do
      stub_request(:post, "#{base_url}/projects")
        .with(body: { name: 'Routes Project', initial_routes: 'transactional' })
        .to_return(
          status: 201,
          body: '{"id":"proj_routes","name":"Routes Project"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      projects.create(name: 'Routes Project', initial_routes: 'transactional')
      expect(WebMock).to have_requested(:post, "#{base_url}/projects")
        .with(body: { name: 'Routes Project', initial_routes: 'transactional' })
    end

    it 'raises ValidationError for invalid name' do
      stub_request(:post, "#{base_url}/projects")
        .with(body: { name: '' })
        .to_return(
          status: 422,
          body: '{"message":"Name is required","error":"validation_error"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { projects.create(name: '') }.to raise_error(Lettermint::ValidationError)
    end
  end

  describe '#find' do
    let(:project_id) { 'proj_123' }

    it 'sends GET request to /projects/:id' do
      stub_request(:get, "#{base_url}/projects/#{project_id}")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"id":"proj_123","name":"My Project"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.find(project_id)
      expect(result['id']).to eq('proj_123')
      expect(result['name']).to eq('My Project')
    end

    it 'sends GET request without include param when not specified' do
      stub = stub_request(:get, "#{base_url}/projects/#{project_id}")
             .to_return(
               status: 200,
               body: '{"id":"proj_123"}',
               headers: { 'Content-Type' => 'application/json' }
             )

      projects.find(project_id)
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/projects/#{project_id}")
        .with { |req| req.uri.query.nil? })
    end

    it 'includes routes when requested' do
      stub_request(:get, "#{base_url}/projects/#{project_id}?include=routes")
        .to_return(
          status: 200,
          body: '{"id":"proj_123","routes":[{"id":"route_1","name":"Default"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.find(project_id, include: 'routes')
      expect(result['routes']).to be_an(Array)
      expect(result['routes'].first['name']).to eq('Default')
    end

    it 'includes teamMembers when requested' do
      stub_request(:get, "#{base_url}/projects/#{project_id}?include=teamMembers")
        .to_return(
          status: 200,
          body: '{"id":"proj_123","teamMembers":[{"id":"mem_1","email":"test@example.com"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.find(project_id, include: 'teamMembers')
      expect(result['teamMembers']).to be_an(Array)
    end

    it 'raises HttpRequestError for non-existent project' do
      stub_request(:get, "#{base_url}/projects/nonexistent")
        .to_return(
          status: 404,
          body: '{"message":"Project not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { projects.find('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#update' do
    let(:project_id) { 'proj_123' }

    it 'sends PUT request to /projects/:id with name' do
      stub_request(:put, "#{base_url}/projects/#{project_id}")
        .with(
          body: { name: 'Updated Name' },
          headers: { 'Authorization' => "Bearer #{team_token}" }
        )
        .to_return(
          status: 200,
          body: '{"id":"proj_123","name":"Updated Name"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.update(project_id, name: 'Updated Name')
      expect(result['name']).to eq('Updated Name')
    end

    it 'sends PUT request with smtp_enabled' do
      stub_request(:put, "#{base_url}/projects/#{project_id}")
        .with(body: { smtp_enabled: true })
        .to_return(
          status: 200,
          body: '{"id":"proj_123","smtp_enabled":true}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.update(project_id, smtp_enabled: true)
      expect(result['smtp_enabled']).to eq(true)
    end

    it 'sends PUT request with default_route_id' do
      stub_request(:put, "#{base_url}/projects/#{project_id}")
        .with(body: { default_route_id: 'route_456' })
        .to_return(
          status: 200,
          body: '{"id":"proj_123","default_route_id":"route_456"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.update(project_id, default_route_id: 'route_456')
      expect(result['default_route_id']).to eq('route_456')
    end
  end

  describe '#delete' do
    let(:project_id) { 'proj_123' }

    it 'sends DELETE request to /projects/:id' do
      stub_request(:delete, "#{base_url}/projects/#{project_id}")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"message":"Project deleted"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.delete(project_id)
      expect(result['message']).to eq('Project deleted')
    end

    it 'handles 204 No Content response' do
      stub_request(:delete, "#{base_url}/projects/#{project_id}")
        .to_return(status: 204, body: '')

      result = projects.delete(project_id)
      expect(result).to eq('')
    end

    it 'raises HttpRequestError for non-existent project' do
      stub_request(:delete, "#{base_url}/projects/nonexistent")
        .to_return(
          status: 404,
          body: '{"message":"Project not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { projects.delete('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#rotate_token' do
    let(:project_id) { 'proj_123' }

    it 'sends POST request to /projects/:id/rotate-token' do
      stub_request(:post, "#{base_url}/projects/#{project_id}/rotate-token")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"new_token":"lm_proj_newtoken123"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.rotate_token(project_id)
      expect(result['new_token']).to eq('lm_proj_newtoken123')
    end

    it 'raises HttpRequestError for non-existent project' do
      stub_request(:post, "#{base_url}/projects/nonexistent/rotate-token")
        .to_return(
          status: 404,
          body: '{"message":"Project not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { projects.rotate_token('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#update_members' do
    let(:project_id) { 'proj_123' }
    let(:team_member_ids) { %w[mem_1 mem_2 mem_3] }

    it 'sends PUT request to /projects/:id/members with team_member_ids' do
      stub_request(:put, "#{base_url}/projects/#{project_id}/members")
        .with(
          body: { team_member_ids: team_member_ids },
          headers: { 'Authorization' => "Bearer #{team_token}" }
        )
        .to_return(
          status: 200,
          body: '{"message":"Members updated"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.update_members(project_id, team_member_ids: team_member_ids)
      expect(result['message']).to eq('Members updated')
    end

    it 'accepts empty team_member_ids array to remove all members' do
      stub_request(:put, "#{base_url}/projects/#{project_id}/members")
        .with(body: { team_member_ids: [] })
        .to_return(
          status: 200,
          body: '{"message":"Members updated"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.update_members(project_id, team_member_ids: [])
      expect(result['message']).to eq('Members updated')
    end
  end

  describe '#add_member' do
    let(:project_id) { 'proj_123' }
    let(:member_id) { 'mem_456' }

    it 'sends POST request to /projects/:project_id/members/:member_id' do
      stub_request(:post, "#{base_url}/projects/#{project_id}/members/#{member_id}")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"message":"Member added"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.add_member(project_id, member_id)
      expect(result['message']).to eq('Member added')
    end

    it 'raises HttpRequestError for non-existent member' do
      stub_request(:post, "#{base_url}/projects/#{project_id}/members/nonexistent")
        .to_return(
          status: 404,
          body: '{"message":"Member not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { projects.add_member(project_id, 'nonexistent') }
        .to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#remove_member' do
    let(:project_id) { 'proj_123' }
    let(:member_id) { 'mem_456' }

    it 'sends DELETE request to /projects/:project_id/members/:member_id' do
      stub_request(:delete, "#{base_url}/projects/#{project_id}/members/#{member_id}")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"message":"Member removed"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = projects.remove_member(project_id, member_id)
      expect(result['message']).to eq('Member removed')
    end

    it 'handles 204 No Content response' do
      stub_request(:delete, "#{base_url}/projects/#{project_id}/members/#{member_id}")
        .to_return(status: 204, body: '')

      result = projects.remove_member(project_id, member_id)
      expect(result).to eq('')
    end
  end

  describe '#routes' do
    let(:project_id) { 'proj_123' }

    it 'returns a Routes resource scoped to the project' do
      routes = projects.routes(project_id)
      expect(routes).to be_a(Lettermint::Resources::Routes)
    end

    it 'returns a Routes resource that can list project routes' do
      stub_request(:get, "#{base_url}/projects/#{project_id}/routes")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"data":[{"id":"route_1","name":"Transactional"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      routes = projects.routes(project_id)
      result = routes.list
      expect(result['data']).to be_an(Array)
      expect(result['data'].first['name']).to eq('Transactional')
    end

    it 'returns a Routes resource that can create project routes' do
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

      routes = projects.routes(project_id)
      result = routes.create(name: 'New Route', route_type: 'transactional')
      expect(result['id']).to eq('route_new')
    end
  end

  describe 'error handling' do
    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/projects")
        .to_return(
          status: 401,
          body: '{"message":"Invalid token"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { projects.list }.to raise_error(Lettermint::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:get, "#{base_url}/projects")
        .to_return(
          status: 429,
          body: '{"message":"Too many requests"}',
          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '30' }
        )

      expect { projects.list }.to raise_error(Lettermint::RateLimitError) { |e|
        expect(e.retry_after).to eq(30)
      }
    end

    it 'raises TimeoutError on timeout' do
      stub_request(:get, "#{base_url}/projects").to_raise(Faraday::TimeoutError)

      expect { projects.list }.to raise_error(Lettermint::TimeoutError)
    end
  end
end
