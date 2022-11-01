# frozen_string_literal: true

module EbayMessagePull
  extend ActiveSupport::Concern

  def pull_messages
    C::BackgroundJob.process('Ebay: Retrieve Messages') do
      get_messages
    end
  end

  def pull_questions
    C::BackgroundJob.process('Ebay: Retrieve Questions') do
      get_questions
    end
  end

  def get_messages(ids = [], page_number = 1)
    request = EbayTrader::Request.new('GetMyMessages') do
      DetailLevel 'ReturnHeaders'
      StartTime (Time.now - 1.year).iso8601
      EndTime Time.now.iso8601
      Pagination do
        EntriesPerPage 200
        PageNumber page_number
      end
    end

    if request.response_hash[:messages]
      (to_array request.response_hash[:messages][:message]).each do |message|
        unless message[:message_type] == 'AskSellerQuestion' || message[:message_type] == 'ResponseToASQQuestion'
          ids << message[:message_id]
        end
      end
    end

    if request.response_hash[:pagination_result]
      total_pages = request.response_hash[:pagination_result][:total_number_of_pages]
      if page_number < total_pages
        get_messages(ids, page_number + 1)
      else
        get_message_contents(ids)
      end
    else
      get_message_contents(ids)
    end
    request.response_hash
  end

  def get_message_contents(ids, message_number = 0)
    request = EbayTrader::Request.new('GetMyMessages') do
      DetailLevel 'ReturnMessages'
      StartTime (Time.now - 1.year).iso8601
      EndTime Time.now.iso8601
      MessageIDs do
        ids[message_number..(message_number+9)].each do |id|
          MessageID id
        end
      end
    end

    if request.response_hash[:messages]
      (to_array request.response_hash[:messages][:message]).each do |message|
        next unless (c_message = C::Message.find_or_create_by(message_id: message[:message_id]))
        c_message.update!(
          sender_id: message[:sender],
          subject: message[:subject],
          body: message[:text],
          source: :ebay,
          read: (message[:read] || c_message.read),
          replied: message[:replied]
        )
      end
    end

    get_message_contents(ids, message_number + 10) if ids[message_number+10].present?

  end

  def get_questions(page_number = 1, start_time = (Time.now - 1.day) )
    request = EbayTrader::Request.new('GetMemberMessages') do
      WarningLevel 'High'
      StartCreationTime start_time.iso8601
      EndCreationTime Time.now.iso8601
      MailMessageType 'All'
      Pagination do
        EntriesPerPage 200
        PageNumber page_number
      end
    end

    if request.response_hash[:member_message]
      (to_array request.response_hash[:member_message][:member_message_exchange]).each do |message_container|
        message = message_container[:question]
        next unless message[:message_type] == 'AskSellerQuestion'
        next unless (variant = C::Product::Variant.find_by(item_id: message_container[:item][:item_id]))
        question = variant.questions.find_or_create_by!(message_id: message[:message_id], source: :ebay)
        question.update(
          sender_id: message[:sender_id],
          sender_email: message[:sender_email],
          subject: message[:subject],
          body: message[:body],
          answered: message_container[:message_status] == 'Answered',
          source: :ebay
        )
        if question.answered && question.answers.empty?
          question.answers.create!(body: 'You replied on Ebay', external: true)
        end
      end
    end

    if request.response_hash[:pagination_result]
      total_pages = request.response_hash[:pagination_result][:total_number_of_pages]
      get_questions(page_number + 1, start_time) if page_number < total_pages
    end
  end
end
