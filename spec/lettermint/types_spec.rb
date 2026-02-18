# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::SendEmailResponse do
  describe '.from_hash' do
    it 'creates from a hash with string keys' do
      resp = described_class.from_hash('message_id' => 'msg_123', 'status' => 'queued')
      expect(resp.message_id).to eq('msg_123')
      expect(resp.status).to eq('queued')
    end

    it 'raises Lettermint::Error when hash is nil' do
      expect { described_class.from_hash(nil) }.to raise_error(Lettermint::Error, 'Empty response body from API')
    end

    it 'raises Lettermint::Error when hash is not a Hash' do
      expect { described_class.from_hash('not a hash') }.to raise_error(Lettermint::Error, /Unexpected response type/)
    end
  end

  describe 'immutability' do
    it 'is frozen' do
      resp = described_class.new(message_id: 'msg_1', status: 'pending')
      expect(resp).to be_frozen
    end
  end

  describe 'equality' do
    it 'compares by value' do
      a = described_class.new(message_id: 'msg_1', status: 'pending')
      b = described_class.new(message_id: 'msg_1', status: 'pending')
      expect(a).to eq(b)
    end
  end
end

RSpec.describe Lettermint::EmailAttachment do
  describe '#initialize' do
    it 'defaults content_id to nil' do
      att = described_class.new(filename: 'file.pdf', content: 'base64data')
      expect(att.content_id).to be_nil
    end

    it 'accepts content_id' do
      att = described_class.new(filename: 'logo.png', content: 'base64data', content_id: 'logo@cid')
      expect(att.content_id).to eq('logo@cid')
    end
  end

  describe '#to_h' do
    it 'excludes content_id when nil' do
      att = described_class.new(filename: 'file.pdf', content: 'base64data')
      expect(att.to_h).to eq({ filename: 'file.pdf', content: 'base64data' })
    end

    it 'includes content_id when present' do
      att = described_class.new(filename: 'logo.png', content: 'base64data', content_id: 'logo@cid')
      expect(att.to_h).to eq({ filename: 'logo.png', content: 'base64data', content_id: 'logo@cid' })
    end
  end

  describe 'immutability' do
    it 'is frozen' do
      att = described_class.new(filename: 'f.txt', content: 'data')
      expect(att).to be_frozen
    end
  end
end
