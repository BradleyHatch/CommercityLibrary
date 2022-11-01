# frozen_string_literal: true

class LoggerJob
  include SuckerPunch::Job

  def perform
    raise NotImplementedError
  end
end
