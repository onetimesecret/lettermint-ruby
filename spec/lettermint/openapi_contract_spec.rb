# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe 'Lettermint Team OpenAPI error contract' do
  let(:document) { JSON.parse(fixture('openapi/error-schemas.json')) }
  let(:schemas) { document.fetch('components').fetch('schemas') }

  describe 'ApiError schema' do
    let(:error) { schemas.fetch('ApiError').fetch('properties').fetch('error') }

    it 'requires code and message' do
      expect(error.fetch('required')).to include('code', 'message')
    end

    it 'allows details to be an object, an array or null' do
      expect(error.dig('properties', 'details', 'type')).to include('object', 'array', 'null')
    end
  end

  describe 'ErrorMessage schema' do
    it 'requires only message' do
      expect(schemas.fetch('ErrorMessage').fetch('required')).to eq(['message'])
    end
  end

  describe 'ValidationError schema' do
    it 'requires message and errors' do
      expect(schemas.fetch('ValidationError').fetch('required')).to contain_exactly('message', 'errors')
    end
  end

  describe 'GET /domains/{domainId} 404 response' do
    let(:schema) do
      document.dig('paths', '/domains/{domainId}', 'get', 'responses', '404', 'content', 'application/json', 'schema')
    end

    it 'allows either ErrorMessage or ApiError' do
      refs = schema.fetch('anyOf').map { |entry| entry.fetch('$ref') }
      expect(refs).to contain_exactly('#/components/schemas/ErrorMessage', '#/components/schemas/ApiError')
    end
  end
end
