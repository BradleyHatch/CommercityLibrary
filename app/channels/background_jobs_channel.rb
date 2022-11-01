# frozen_string_literal: true

class BackgroundJobsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'background_jobs'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def fetch_jobs
    ActionCable.server.broadcast(
      'background_jobs',
      type: 'FETCH_JOBS_FULFILLED',
      payload: { jobs: C::BackgroundJob.all.order(:created_at).as_json }
    )
  end

  def self.update_all
    ActionCable.server.broadcast(
      'background_jobs',
      type: 'UPDATE_JOBS',
      payload: { jobs: C::BackgroundJob.all.order(:created_at).as_json }
    )
  end
end
