# frozen_string_literal: true

module Vmpooler
  class API < Sinatra::Base
    not_found do
      content_type :json

      result = {
        ok: false
      }

      JSON.pretty_generate(result)
    end

    use Rack::Deflater
    use Prometheus::Middleware::Collector, metrics_prefix: 'vmpooler_http'
    use Prometheus::Middleware::Exporter, path: '/prometheus'

    # Load dashboard components
    begin
      require 'dashboard'
    rescue LoadError
      require File.expand_path(File.join(File.dirname(__FILE__), 'dashboard'))
    end

    use Vmpooler::Dashboard

    # Load API components
    %w[helpers dashboard reroute v1].each do |lib|
      begin
        require "api/#{lib}"
      rescue LoadError
        require File.expand_path(File.join(File.dirname(__FILE__), 'api', lib))
      end
    end

    use Vmpooler::API::Dashboard
    use Vmpooler::API::Reroute
    use Vmpooler::API::V1

    def self.execute(config, redis, metrics)
      self.settings.set :config, config
      self.settings.set :redis, redis
      self.settings.set :metrics, metrics
      self.settings.set :checkoutlock, Mutex.new
      # Initialise Prometheus Counters if required.
      metrics.setup_prometheus_metrics if metrics.respond_to?(:setup_prometheus_metrics)

      # Get thee started O WebServer
      self.run!
    end
  end
end
