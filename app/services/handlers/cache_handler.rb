module Handlers
  class CacheHandler < BaseHandler
    CACHE_EXPIRY = 10.minutes

    protected

    def process(request)
      cache_key = "order_cache:#{request.cache_key}"
      cached_response = Rails.cache.read(cache_key)

      if cached_response
        Rails.logger.info "Cache hit for key: #{cache_key}"
        success_response('Cached response found', { cached_data: cached_response, from_cache: true })
      else
        Rails.logger.info "Cache miss for key: #{cache_key}"
        success_response('No cached response, proceeding to process')
      end
    end

    def self.cache_response(cache_key, response_data)
      full_cache_key = "order_cache:#{cache_key}"
      Rails.cache.write(full_cache_key, response_data, expires_in: CACHE_EXPIRY)
    end
  end
end
