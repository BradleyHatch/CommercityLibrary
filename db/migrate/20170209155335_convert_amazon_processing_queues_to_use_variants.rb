# frozen_string_literal: true
class ConvertAmazonProcessingQueuesToUseVariants < ActiveRecord::Migration[5.0]
  def print_info(total, i, padding, msg)
    # Status
    print (' ' * 80) + "\r"
    print " (#{(i + 1).to_s.rjust(padding)}/#{total}) #{msg}...\r"
    $stdout.flush
  end

  def up
    puts 'Destroying all from before given date...'
    C::AmazonProcessingQueue.where('created_at < ?', 3.days.ago).destroy_all

    puts 'Migrating'
    query = C::AmazonProcessingQueue.all
    total = query.count
    padding = [Math.log10(total), 0].max.to_i + 1

    cache_hash = {}

    query.each_with_index do |apq, i|
      print_info(total, i, padding, apq.id.to_s)

      variant_ids = apq.product_ids.map do |id|
        cached_id = cache_hash[id]
        if cached_id.nil?
          print_info(total, i, padding, "#{apq.id}: #{id} Cache miss")
          new_id = C::Product::Variant.where(master_id: id, main_variant: true).first.id
          cache_hash[id] = new_id
          new_id
        else
          print_info(total, i, padding, "#{apq.id}: #{id}")
          cached_id
        end
      end

      print_info(total, i, padding, "#{apq.id}: Saving")
      apq.product_ids = variant_ids
    end
  end

  def down
    puts 'Destroying all from before given date...'
    C::AmazonProcessingQueue.where('created_at < ?', 1.week.ago).destroy_all

    puts 'Rolling back...'
    query = C::AmazonProcessingQueue.all
    total = query.count
    padding = [Math.log10(total), 0].max.to_i + 1

    cache_hash = {}

    query.each_with_index do |apq, i|
      print_info(total, i, padding, apq.id.to_s)

      variant_ids = apq.product_ids.map do |id|
        cached_id = cache_hash[id]
        if cached_id.nil?
          print_info(total, i, padding, "#{apq.id}: #{id} Cache miss")
          new_id = C::Product::Variant.find(id).master_id
          cache_hash[id] = new_id
          new_id
        else
          print_info(total, i, padding, "#{apq.id}: #{id}")
          cached_id
        end
      end

      print_info(total, i, padding, "#{apq.id}: Saving")
      apq.product_ids = variant_ids
    end
  end
end
