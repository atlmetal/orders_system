class OrderChainBuilder
  def self.build_chain
    auth_handler = Handlers::AuthenticationHandler.new
    authz_handler = Handlers::AuthorizationHandler.new
    sanitization_handler = Handlers::SanitizationHandler.new
    brute_force_handler = Handlers::BruteForceHandler.new
    cache_handler = Handlers::CacheHandler.new

    auth_handler
      .set_next(authz_handler)
      .set_next(sanitization_handler)
      .set_next(brute_force_handler)
      .set_next(cache_handler)

    auth_handler
  end
end
