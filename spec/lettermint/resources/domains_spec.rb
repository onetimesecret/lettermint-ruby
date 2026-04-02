# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::Resources::Domains do
  let(:team_token) { 'lm_team_test123' }
  let(:base_url) { Lettermint::Configuration::DEFAULT_BASE_URL }
  let(:api) { Lettermint::TeamAPI.new(team_token: team_token) }
  let(:domains) { api.domains }

  describe '#list' do
    it 'sends GET request to /domains' do
      stub_request(:get, "#{base_url}/domains")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"data":[{"id":"dom_1","domain":"example.com","status":"verified"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.list
      expect(result['data']).to be_an(Array)
      expect(result['data'].first['domain']).to eq('example.com')
    end

    it 'sends GET request without params when none specified' do
      stub = stub_request(:get, "#{base_url}/domains")
             .to_return(
               status: 200,
               body: '{"data":[]}',
               headers: { 'Content-Type' => 'application/json' }
             )

      domains.list
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/domains")
        .with { |req| req.uri.query.nil? })
    end

    describe 'pagination parameters' do
      it 'passes page_size parameter' do
        stub_request(:get, "#{base_url}/domains")
          .with(query: { 'page[size]' => '50' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        domains.list(page_size: 50)
        expect(WebMock).to have_requested(:get, "#{base_url}/domains")
          .with(query: { 'page[size]' => '50' })
      end

      it 'passes page_cursor parameter' do
        stub_request(:get, "#{base_url}/domains")
          .with(query: { 'page[cursor]' => 'cursor_abc' })
          .to_return(
            status: 200,
            body: '{"data":[],"meta":{"next_cursor":"cursor_def"}}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = domains.list(page_cursor: 'cursor_abc')
        expect(result['meta']['next_cursor']).to eq('cursor_def')
      end

      it 'passes both pagination parameters' do
        stub_request(:get, "#{base_url}/domains")
          .with(query: { 'page[size]' => '25', 'page[cursor]' => 'xyz789' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        domains.list(page_size: 25, page_cursor: 'xyz789')
        expect(WebMock).to have_requested(:get, "#{base_url}/domains")
          .with(query: { 'page[size]' => '25', 'page[cursor]' => 'xyz789' })
      end
    end

    describe 'sort parameter' do
      it 'sorts by domain ascending' do
        stub_request(:get, "#{base_url}/domains")
          .with(query: { 'sort' => 'domain' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        domains.list(sort: 'domain')
        expect(WebMock).to have_requested(:get, "#{base_url}/domains")
          .with(query: { 'sort' => 'domain' })
      end

      it 'sorts by created_at descending' do
        stub_request(:get, "#{base_url}/domains")
          .with(query: { 'sort' => '-created_at' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        domains.list(sort: '-created_at')
        expect(WebMock).to have_requested(:get, "#{base_url}/domains")
          .with(query: { 'sort' => '-created_at' })
      end

      it 'sorts by status_changed_at' do
        stub_request(:get, "#{base_url}/domains")
          .with(query: { 'sort' => 'status_changed_at' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        domains.list(sort: 'status_changed_at')
        expect(WebMock).to have_requested(:get, "#{base_url}/domains")
          .with(query: { 'sort' => 'status_changed_at' })
      end
    end

    describe 'filter parameters' do
      it 'filters by status' do
        stub_request(:get, "#{base_url}/domains")
          .with(query: { 'filter[status]' => 'verified' })
          .to_return(
            status: 200,
            body: '{"data":[{"status":"verified"}]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = domains.list(status: 'verified')
        expect(result['data'].first['status']).to eq('verified')
      end

      it 'filters by domain (partial match)' do
        stub_request(:get, "#{base_url}/domains")
          .with(query: { 'filter[domain]' => 'example' })
          .to_return(
            status: 200,
            body: '{"data":[{"domain":"example.com"},{"domain":"mail.example.org"}]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        result = domains.list(domain: 'example')
        expect(result['data'].length).to eq(2)
      end

      it 'filters by multiple criteria' do
        stub_request(:get, "#{base_url}/domains")
          .with(query: { 'filter[status]' => 'partially_verified', 'filter[domain]' => 'test' })
          .to_return(
            status: 200,
            body: '{"data":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )

        domains.list(status: 'partially_verified', domain: 'test')
        expect(WebMock).to have_requested(:get, "#{base_url}/domains")
          .with(query: { 'filter[status]' => 'partially_verified', 'filter[domain]' => 'test' })
      end
    end

    describe 'combined parameters' do
      it 'passes all parameters together' do
        stub = stub_request(:get, "#{base_url}/domains")
               .with(query: {
                       'page[size]' => '10',
                       'page[cursor]' => 'abc',
                       'sort' => '-created_at',
                       'filter[status]' => 'verified'
                     })
               .to_return(
                 status: 200,
                 body: '{"data":[]}',
                 headers: { 'Content-Type' => 'application/json' }
               )

        domains.list(page_size: 10, page_cursor: 'abc', sort: '-created_at', status: 'verified')
        expect(stub).to have_been_requested
      end
    end
  end

  describe '#create' do
    it 'sends POST request to /domains with domain name' do
      stub_request(:post, "#{base_url}/domains")
        .with(
          body: { domain: 'newdomain.com' },
          headers: { 'Authorization' => "Bearer #{team_token}" }
        )
        .to_return(
          status: 201,
          body: '{"id":"dom_new","domain":"newdomain.com","status":"pending"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.create(domain: 'newdomain.com')
      expect(result['id']).to eq('dom_new')
      expect(result['domain']).to eq('newdomain.com')
      expect(result['status']).to eq('pending')
    end

    it 'raises ValidationError for invalid domain' do
      stub_request(:post, "#{base_url}/domains")
        .with(body: { domain: 'invalid' })
        .to_return(
          status: 422,
          body: '{"message":"Invalid domain format","error":"validation_error"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { domains.create(domain: 'invalid') }.to raise_error(Lettermint::ValidationError)
    end

    it 'raises ValidationError for duplicate domain' do
      stub_request(:post, "#{base_url}/domains")
        .with(body: { domain: 'existing.com' })
        .to_return(
          status: 422,
          body: '{"message":"Domain already exists","error":"validation_error"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { domains.create(domain: 'existing.com') }
        .to raise_error(Lettermint::ValidationError, /Domain already exists/)
    end
  end

  describe '#find' do
    let(:domain_id) { 'dom_123' }

    it 'sends GET request to /domains/:id' do
      stub_request(:get, "#{base_url}/domains/#{domain_id}")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"id":"dom_123","domain":"example.com","status":"verified"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.find(domain_id)
      expect(result['id']).to eq('dom_123')
      expect(result['domain']).to eq('example.com')
    end

    it 'sends GET request without include param when not specified' do
      stub = stub_request(:get, "#{base_url}/domains/#{domain_id}")
             .to_return(
               status: 200,
               body: '{"id":"dom_123"}',
               headers: { 'Content-Type' => 'application/json' }
             )

      domains.find(domain_id)
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/domains/#{domain_id}")
        .with { |req| req.uri.query.nil? })
    end

    it 'includes dnsRecords when requested' do
      stub_request(:get, "#{base_url}/domains/#{domain_id}?include=dnsRecords")
        .to_return(
          status: 200,
          body: '{"id":"dom_123","dnsRecords":[{"type":"TXT","value":"v=spf1"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.find(domain_id, include: 'dnsRecords')
      expect(result['dnsRecords']).to be_an(Array)
      expect(result['dnsRecords'].first['type']).to eq('TXT')
    end

    it 'includes dnsRecordsCount when requested' do
      stub_request(:get, "#{base_url}/domains/#{domain_id}?include=dnsRecordsCount")
        .to_return(
          status: 200,
          body: '{"id":"dom_123","dnsRecordsCount":3}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.find(domain_id, include: 'dnsRecordsCount')
      expect(result['dnsRecordsCount']).to eq(3)
    end

    it 'includes dnsRecordsExists when requested' do
      stub_request(:get, "#{base_url}/domains/#{domain_id}?include=dnsRecordsExists")
        .to_return(
          status: 200,
          body: '{"id":"dom_123","dnsRecordsExists":true}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.find(domain_id, include: 'dnsRecordsExists')
      expect(result['dnsRecordsExists']).to eq(true)
    end

    it 'raises HttpRequestError for non-existent domain' do
      stub_request(:get, "#{base_url}/domains/nonexistent")
        .to_return(
          status: 404,
          body: '{"message":"Domain not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { domains.find('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#delete' do
    let(:domain_id) { 'dom_123' }

    it 'sends DELETE request to /domains/:id' do
      stub_request(:delete, "#{base_url}/domains/#{domain_id}")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"message":"Domain deleted"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.delete(domain_id)
      expect(result['message']).to eq('Domain deleted')
    end

    it 'handles 204 No Content response' do
      stub_request(:delete, "#{base_url}/domains/#{domain_id}")
        .to_return(status: 204, body: '')

      result = domains.delete(domain_id)
      expect(result).to eq('')
    end

    it 'raises HttpRequestError for non-existent domain' do
      stub_request(:delete, "#{base_url}/domains/nonexistent")
        .to_return(
          status: 404,
          body: '{"message":"Domain not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { domains.delete('nonexistent') }.to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#verify_dns' do
    let(:domain_id) { 'dom_123' }

    it 'sends POST request to /domains/:id/dns-records/verify' do
      stub_request(:post, "#{base_url}/domains/#{domain_id}/dns-records/verify")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"verified":true,"records":[{"type":"TXT","verified":true}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.verify_dns(domain_id)
      expect(result['verified']).to eq(true)
      expect(result['records'].first['verified']).to eq(true)
    end

    it 'returns partial verification results' do
      stub_request(:post, "#{base_url}/domains/#{domain_id}/dns-records/verify")
        .to_return(
          status: 200,
          body: '{"verified":false,"records":[{"type":"TXT","verified":true},{"type":"DKIM","verified":false}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.verify_dns(domain_id)
      expect(result['verified']).to eq(false)
      expect(result['records'].count { |r| r['verified'] }).to eq(1)
    end
  end

  describe '#verify_dns_record' do
    let(:domain_id) { 'dom_123' }
    let(:record_id) { 'rec_456' }

    it 'sends POST request to /domains/:domain_id/dns-records/:record_id/verify' do
      stub_request(:post, "#{base_url}/domains/#{domain_id}/dns-records/#{record_id}/verify")
        .with(headers: { 'Authorization' => "Bearer #{team_token}" })
        .to_return(
          status: 200,
          body: '{"id":"rec_456","type":"TXT","verified":true}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.verify_dns_record(domain_id, record_id)
      expect(result['id']).to eq('rec_456')
      expect(result['verified']).to eq(true)
    end

    it 'returns unverified status when DNS record not found' do
      stub_request(:post, "#{base_url}/domains/#{domain_id}/dns-records/#{record_id}/verify")
        .to_return(
          status: 200,
          body: '{"id":"rec_456","type":"DKIM","verified":false,"error":"Record not found in DNS"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.verify_dns_record(domain_id, record_id)
      expect(result['verified']).to eq(false)
      expect(result['error']).to include('not found')
    end

    it 'raises HttpRequestError for non-existent record' do
      stub_request(:post, "#{base_url}/domains/#{domain_id}/dns-records/nonexistent/verify")
        .to_return(
          status: 404,
          body: '{"message":"DNS record not found"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { domains.verify_dns_record(domain_id, 'nonexistent') }
        .to raise_error(Lettermint::HttpRequestError)
    end
  end

  describe '#update_projects' do
    let(:domain_id) { 'dom_123' }
    let(:project_ids) { %w[proj_1 proj_2 proj_3] }

    it 'sends PUT request to /domains/:id/projects with project_ids' do
      stub_request(:put, "#{base_url}/domains/#{domain_id}/projects")
        .with(
          body: { project_ids: project_ids },
          headers: { 'Authorization' => "Bearer #{team_token}" }
        )
        .to_return(
          status: 200,
          body: '{"id":"dom_123","projects":["proj_1","proj_2","proj_3"]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.update_projects(domain_id, project_ids: project_ids)
      expect(result['projects']).to eq(project_ids)
    end

    it 'accepts empty project_ids array to remove all associations' do
      stub_request(:put, "#{base_url}/domains/#{domain_id}/projects")
        .with(body: { project_ids: [] })
        .to_return(
          status: 200,
          body: '{"id":"dom_123","projects":[]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = domains.update_projects(domain_id, project_ids: [])
      expect(result['projects']).to eq([])
    end

    it 'raises ValidationError for invalid project_id' do
      stub_request(:put, "#{base_url}/domains/#{domain_id}/projects")
        .with(body: { project_ids: ['invalid_proj'] })
        .to_return(
          status: 422,
          body: '{"message":"Invalid project ID: invalid_proj","error":"validation_error"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { domains.update_projects(domain_id, project_ids: ['invalid_proj']) }
        .to raise_error(Lettermint::ValidationError)
    end
  end

  describe 'error handling' do
    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/domains")
        .to_return(
          status: 401,
          body: '{"message":"Invalid token"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { domains.list }.to raise_error(Lettermint::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:get, "#{base_url}/domains")
        .to_return(
          status: 429,
          body: '{"message":"Too many requests"}',
          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '30' }
        )

      expect { domains.list }.to raise_error(Lettermint::RateLimitError) { |e|
        expect(e.retry_after).to eq(30)
      }
    end

    it 'raises TimeoutError on timeout' do
      stub_request(:get, "#{base_url}/domains").to_raise(Faraday::TimeoutError)

      expect { domains.list }.to raise_error(Lettermint::TimeoutError)
    end
  end
end
