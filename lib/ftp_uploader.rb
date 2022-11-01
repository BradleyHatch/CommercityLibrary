# frozen_string_literal: true

require 'net/ftp'
require 'tempfile'

module C
  class FtpUploader
    def initialize(host, port = 21, options = {})
      @host = host
      @port = port
      @user = options.delete(:user)
      @password = options.delete(:password)
    end

    def with_temp_file(filename, text)
      tempfile = Tempfile.new(filename)
      tempfile.write(text)
      tempfile.close

      value = yield(tempfile)

      tempfile.unlink
      value
    end

    def with_ftp_connection
      # Upload file
      ftp = Net::FTP.new
      ftp.connect(@host, @port)
      ftp.login(@user, @password) unless @user.nil? || @password.nil?
      yield(ftp)
      ftp.close
    end

    def upload_text_to_server(filename, text, options = {})
      target_dir = options.delete(:target_dir)
      with_temp_file(filename, text) do |tempfile|
        with_ftp_connection do |ftp|
          ftp.put(tempfile, target_filename(target_dir, filename))
        end
      end
    end

    def target_filename(target_dir, filename)
      return filename if target_dir.nil?
      File.join(target_dir, filename)
    end
  end
end
