# frozen_string_literal: true

module Lettermint
  SendEmailResponse = Data.define(:message_id, :status) do
    def self.from_hash(hash)
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
