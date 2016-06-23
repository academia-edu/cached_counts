module CachedCounts
  def self.logger
    @logger ||= begin
      if Rails.logger.nil?
        require 'logger'
        Logger.new($stderr)
      else
        Rails.logger
      end
    end
  end
end
