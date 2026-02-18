# frozen_string_literal: true

module Lettermint
  SendEmailResponse = Data.define(:message_id, :status) do
    def self.from_hash(hash)
      raise Lettermint::Error, 'Empty response body from API' if hash.nil?
      raise Lettermint::Error, "Unexpected response type: #{hash.class}" unless hash.is_a?(Hash)

      new(message_id: hash['message_id'], status: hash['status'])
    end
  end

  EmailAttachment = Data.define(:filename, :content, :content_id) do
    def initialize(filename:, content:, content_id: nil)
      super
    end

    def to_h
      h = { filename: filename, content: content }
      h[:content_id] = content_id if content_id
      h
    end
  end
end
