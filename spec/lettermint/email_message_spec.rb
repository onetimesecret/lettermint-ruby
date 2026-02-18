# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::EmailMessage do
  let(:base_url) { 'https://api.lettermint.co/v1' }
  let(:api_token) { 'test_token' }
  let(:http_client) { Lettermint::HttpClient.new(api_token: api_token, base_url: base_url, timeout: 30) }

  subject(:message) { described_class.new(http_client: http_client) }

  describe 'builder methods' do
    it 'supports fluent chaining' do
      result = message.from('a@b.com').to('c@d.com').subject('Hi')
      expect(result).to be(message)
    end

    it 'from_addr is an alias for from' do
      result = message.from_addr('a@b.com')
      expect(result).to be(message)
    end

    it 'to accepts multiple arguments' do
      stub_send(base_url, expected_body: hash_including('to' => ['a@b.com', 'c@d.com']))

      message.from('x@y.com').to('a@b.com', 'c@d.com').subject('Hi').html('<p>Hi</p>').deliver
    end

    it 'to accepts an array' do
      stub_send(base_url, expected_body: hash_including('to' => ['a@b.com', 'c@d.com']))

      message.from('x@y.com').to(['a@b.com', 'c@d.com']).subject('Hi').html('<p>Hi</p>').deliver
    end

    it 'cc sets cc recipients' do
      stub_send(base_url, expected_body: hash_including('cc' => ['cc@b.com']))

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>').cc('cc@b.com').deliver
    end

    it 'bcc sets bcc recipients' do
      stub_send(base_url, expected_body: hash_including('bcc' => ['bcc@b.com']))

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>').bcc('bcc@b.com').deliver
    end

    it 'reply_to sets reply-to addresses' do
      stub_send(base_url, expected_body: hash_including('reply_to' => ['reply@b.com']))

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>').reply_to('reply@b.com').deliver
    end

    it 'skips html when nil' do
      stub_send(base_url)

      message.from('a@b.com').to('c@d.com').subject('Hi').html(nil).text('plain').deliver

      body = JSON.parse(WebMock::RequestRegistry.instance.requested_signatures
                           .hash.keys.first.body)
      expect(body).not_to have_key('html')
      expect(body['text']).to eq('plain')
    end

    it 'skips text when nil' do
      stub_send(base_url)

      message.from('a@b.com').to('c@d.com').subject('Hi').text(nil).html('<p>Hi</p>').deliver

      body = JSON.parse(WebMock::RequestRegistry.instance.requested_signatures
                           .hash.keys.first.body)
      expect(body).not_to have_key('text')
    end

    it 'sets route' do
      stub_send(base_url, expected_body: hash_including('route' => 'transactional'))

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>').route('transactional').deliver
    end

    it 'sets tag' do
      stub_send(base_url, expected_body: hash_including('tag' => 'welcome'))

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>').tag('welcome').deliver
    end

    it 'sets custom headers' do
      stub_send(base_url, expected_body: hash_including('headers' => { 'X-Custom' => 'value' }))

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>')
             .headers({ 'X-Custom' => 'value' }).deliver
    end

    it 'sets metadata' do
      stub_send(base_url, expected_body: hash_including('metadata' => { 'user_id' => '42' }))

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>')
             .metadata({ 'user_id' => '42' }).deliver
    end
  end

  describe '#attach' do
    it 'accumulates attachments' do
      stub_send(base_url, expected_body: hash_including(
        'attachments' => [
          { 'filename' => 'a.pdf', 'content' => 'data1' },
          { 'filename' => 'b.pdf', 'content' => 'data2' }
        ]
      ))

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>')
             .attach('a.pdf', 'data1')
             .attach('b.pdf', 'data2')
             .deliver
    end

    it 'includes content_id when provided' do
      stub_send(base_url, expected_body: hash_including(
        'attachments' => [{ 'filename' => 'logo.png', 'content' => 'data', 'content_id' => 'logo@cid' }]
      ))

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>')
             .attach('logo.png', 'data', content_id: 'logo@cid')
             .deliver
    end

    it 'accepts EmailAttachment objects' do
      att = Lettermint::EmailAttachment.new(filename: 'doc.pdf', content: 'base64')
      stub_send(base_url, expected_body: hash_including(
        'attachments' => [{ 'filename' => 'doc.pdf', 'content' => 'base64' }]
      ))

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>')
             .attach(att)
             .deliver
    end
  end

  describe '#idempotency_key' do
    it 'sends Idempotency-Key header' do
      stub = stub_request(:post, "#{base_url}/send")
             .with(headers: { 'Idempotency-Key' => 'idem-123' })
             .to_return(status: 202, body: '{"message_id":"msg_1","status":"queued"}',
                        headers: { 'Content-Type' => 'application/json' })

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>')
             .idempotency_key('idem-123')
             .deliver

      expect(stub).to have_been_requested
    end
  end

  describe '#deliver' do
    it 'returns a SendEmailResponse' do
      stub_send(base_url)

      result = message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>').deliver
      expect(result).to be_a(Lettermint::SendEmailResponse)
      expect(result.message_id).to eq('msg_1')
      expect(result.status).to eq('queued')
    end

    it 'resets state after successful delivery' do
      stub_send(base_url)
      stub_send(base_url)

      message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>').deliver

      # Second deliver should not carry over previous fields
      message.from('x@y.com').to('z@w.com').subject('Bye').html('<p>Bye</p>').deliver
    end

    it 'resets state after failed delivery' do
      stub_request(:post, "#{base_url}/send")
        .to_return(status: 422, body: '{"message":"bad","error":"validation_error"}',
                   headers: { 'Content-Type' => 'application/json' })
        .then
        .to_return(status: 202, body: '{"message_id":"msg_2","status":"queued"}',
                   headers: { 'Content-Type' => 'application/json' })

      expect do
        message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>').deliver
      end.to raise_error(Lettermint::ValidationError)

      result = message.from('x@y.com').to('z@w.com').subject('Retry').html('<p>ok</p>').deliver
      expect(result.message_id).to eq('msg_2')
    end

    it 'propagates errors from http_client' do
      stub_request(:post, "#{base_url}/send").to_raise(Faraday::TimeoutError)

      expect do
        message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>').deliver
      end.to raise_error(Lettermint::TimeoutError)
    end
  end

  describe '#deliver!' do
    it 'is an alias for deliver' do
      stub_send(base_url)

      result = message.from('a@b.com').to('c@d.com').subject('Hi').html('<p>Hi</p>').deliver!
      expect(result).to be_a(Lettermint::SendEmailResponse)
    end
  end

  def stub_send(base_url, expected_body: anything)
    stub_request(:post, "#{base_url}/send")
      .with(body: expected_body)
      .to_return(
        status: 202,
        body: '{"message_id":"msg_1","status":"queued"}',
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
