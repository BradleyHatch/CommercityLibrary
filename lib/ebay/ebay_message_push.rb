# frozen_string_literal: true

module EbayMessagePush
  extend ActiveSupport::Concern

  def send_answer(answer, options = {})
    if options[:force] || (!answer.sent && answer.question.source == 'ebay')
      request = EbayTrader::Request.new('AddMemberMessageRTQ') do
        ErrorLanguage 'en_GB'
        WarningLevel 'High'
        DetailLevel 'ReturnAll'
        MemberMessage do
          Body answer.body
          RecipientID answer.question.sender_id
          ParentMessageID answer.question.message_id
        end
      end

      puts request.response_hash

      answer.update(sent: true) if request.response_hash[:ack] == 'Success'
    end
  end
end
