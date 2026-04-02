# frozen_string_literal: true

module Lettermint
  class EmailMessage # rubocop:disable Metrics/ClassLength
    def initialize(http_client:)
      @http_client = http_client
      reset
    end

    def from(email)
      @payload[:from] = email
      self
    end
    alias from_addr from

    def to(*emails)
      @payload[:to] = emails.flatten
      self
    end

    def subject(str)
      @payload[:subject] = str
      self
    end

    def html(str)
      @payload[:html] = str if str
      self
    end

    def text(str)
      @payload[:text] = str if str
      self
    end

    def cc(*emails)
      @payload[:cc] = emails.flatten
      self
    end

    def bcc(*emails)
      @payload[:bcc] = emails.flatten
      self
    end

    def reply_to(*emails)
      @payload[:reply_to] = emails.flatten
      self
    end

    def route(str)
      @payload[:route] = str
      self
    end

    def tag(str)
      @payload[:tag] = str
      self
    end

    def headers(hash)
      @payload[:headers] = hash
      self
    end

    def metadata(hash)
      @payload[:metadata] = hash
      self
    end

    def attach(filename_or_attachment, content = nil, content_id: nil)
      attachment = case filename_or_attachment
                   when EmailAttachment
                     filename_or_attachment.to_h
                   else
                     h = { filename: filename_or_attachment, content: content }
                     h[:content_id] = content_id if content_id
                     h
                   end
      @payload[:attachments] ||= []
      @payload[:attachments] << attachment
      self
    end

    def idempotency_key(key)
      @idempotency_key = key
      self
    end

    def deliver
      validate_required_fields

      request_headers = {}
      request_headers['Idempotency-Key'] = @idempotency_key if @idempotency_key

      result = @http_client.post(
        path: '/send',
        data: @payload,
        headers: request_headers.empty? ? nil : request_headers
      )
      SendEmailResponse.from_hash(result)
    ensure
      reset
    end
    alias deliver! deliver

    private

    def validate_required_fields
      missing = %i[from subject].select { |f| blank?(f) }
      missing << :to unless valid_recipients?
      missing << :body unless body?
      return if missing.empty?

      raise ArgumentError, "Missing required field(s): #{missing.join(', ')}"
    end

    def blank?(field)
      @payload[field].nil? || @payload[field].to_s.strip.empty?
    end

    def valid_recipients?
      @payload[:to]&.any? { |e| e.is_a?(String) && !e.strip.empty? }
    end

    def body?
      !blank?(:html) || !blank?(:text)
    end

    def reset
      @payload = {}
      @idempotency_key = nil
    end
  end
end
