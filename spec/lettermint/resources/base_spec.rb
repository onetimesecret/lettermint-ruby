# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::Resources::Base do
  # Create a test subclass to expose the private build_params method
  let(:test_resource_class) do
    Class.new(described_class) do
      def test_build_params(**args)
        build_params(**args)
      end
    end
  end

  let(:http_client) { instance_double(Lettermint::HttpClient) }
  let(:resource) { test_resource_class.new(http_client: http_client) }

  describe '#initialize' do
    it 'stores the http_client' do
      base = described_class.new(http_client: http_client)
      expect(base.instance_variable_get(:@http_client)).to eq(http_client)
    end
  end

  describe '#build_params (private)' do
    describe 'pagination parameters' do
      it 'returns nil when no parameters are provided' do
        expect(resource.test_build_params).to be_nil
      end

      it 'builds page[size] parameter' do
        result = resource.test_build_params(page_size: 50)
        expect(result).to eq({ 'page[size]' => 50 })
      end

      it 'builds page[cursor] parameter' do
        result = resource.test_build_params(page_cursor: 'abc123')
        expect(result).to eq({ 'page[cursor]' => 'abc123' })
      end

      it 'builds both pagination parameters together' do
        result = resource.test_build_params(page_size: 25, page_cursor: 'xyz789')
        expect(result).to eq({
                               'page[size]' => 25,
                               'page[cursor]' => 'xyz789'
                             })
      end
    end

    describe 'sort parameter' do
      it 'builds sort parameter for ascending order' do
        result = resource.test_build_params(sort: 'created_at')
        expect(result).to eq({ 'sort' => 'created_at' })
      end

      it 'builds sort parameter for descending order' do
        result = resource.test_build_params(sort: '-created_at')
        expect(result).to eq({ 'sort' => '-created_at' })
      end
    end

    describe 'include parameter' do
      it 'builds include parameter' do
        result = resource.test_build_params(include: 'dnsRecords')
        expect(result).to eq({ 'include' => 'dnsRecords' })
      end

      it 'builds include parameter with multiple values' do
        result = resource.test_build_params(include: 'dnsRecords,features')
        expect(result).to eq({ 'include' => 'dnsRecords,features' })
      end
    end

    describe 'filter parameters' do
      it 'builds single filter parameter' do
        result = resource.test_build_params(status: 'verified')
        expect(result).to eq({ 'filter[status]' => 'verified' })
      end

      it 'builds multiple filter parameters' do
        result = resource.test_build_params(status: 'verified', domain: 'example.com')
        expect(result).to eq({
                               'filter[status]' => 'verified',
                               'filter[domain]' => 'example.com'
                             })
      end

      it 'ignores nil filter values' do
        result = resource.test_build_params(status: 'verified', domain: nil)
        expect(result).to eq({ 'filter[status]' => 'verified' })
      end

      it 'returns nil when all filters are nil' do
        expect(resource.test_build_params(status: nil, domain: nil)).to be_nil
      end
    end

    describe 'combined parameters' do
      it 'builds all parameter types together' do
        result = resource.test_build_params(
          page_size: 30,
          page_cursor: 'cursor123',
          sort: '-created_at',
          include: 'dnsRecords',
          status: 'verified',
          domain: 'example.com'
        )

        expect(result).to eq({
                               'page[size]' => 30,
                               'page[cursor]' => 'cursor123',
                               'sort' => '-created_at',
                               'include' => 'dnsRecords',
                               'filter[status]' => 'verified',
                               'filter[domain]' => 'example.com'
                             })
      end

      it 'omits nil values from combined params' do
        result = resource.test_build_params(
          page_size: 30,
          page_cursor: nil,
          sort: 'name',
          include: nil,
          status: 'active',
          domain: nil
        )

        expect(result).to eq({
                               'page[size]' => 30,
                               'sort' => 'name',
                               'filter[status]' => 'active'
                             })
      end
    end
  end
end
