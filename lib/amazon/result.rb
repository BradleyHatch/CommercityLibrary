# frozen_string_literal: true

module Amazon
  class Result
    # Methods may look sparse and easy to make abstract, but they are
    # placeholders for more logic to be moved in later.
    def initialize(result_response)
      @result_hash = result_response
    end

    def error_count
      @result_hash['ProcessingReport']['ProcessingSummary']['MessagesWithError'].to_i
    end

    def success_count
      @result_hash['ProcessingReport']['ProcessingSummary']['MessagesSuccessful'].to_i
    end

    def to_json
      @result_hash.to_json
    end
  end
end
