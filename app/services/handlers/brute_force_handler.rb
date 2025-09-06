module Handlers
  class BruteForceHandler < BaseHandler
    MAX_ATTEMPTS = 5
    LOCKOUT_TIME = 15.minutes

    protected

    def process(request)
      ip_address = request.ip_address

      if blocked_ip?(ip_address)
        Rails.logger.warn "Blocked request from IP: #{ip_address}"
        error_response('IP temporarily blocked due to multiple failed attempts', 'IP_BLOCKED')
      else
        success_response('Brute force check passed')
      end
    end

    private

    def blocked_ip?(ip_address)
      cache_key = "failed_attempts:#{ip_address}"
      attempts = Rails.cache.read(cache_key) || 0
      attempts >= MAX_ATTEMPTS
    end

    def record_failed_attempt(ip_address)
      cache_key = "failed_attempts:#{ip_address}"
      attempts = Rails.cache.read(cache_key) || 0
      Rails.cache.write(cache_key, attempts + 1, expires_in: LOCKOUT_TIME)
    end
  end
end
