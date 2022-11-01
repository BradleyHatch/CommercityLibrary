namespace :c do
  task import_scheduled_csv: :environment do
    C::DataTransfer.all.each do |dt|
      if dt.import_at && dt.import_at <= Time.now
        dt.import!
      end
    end
  end
end