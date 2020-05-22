# frozen_string_literal: true

module Vmpooler
  class API < Sinatra::Base
    # Load API components
    %w[helpers dashboard reroute v1].each do |lib|
      begin
        require "api/#{lib}"
      rescue LoadError
        require File.expand_path(File.join(File.dirname(__FILE__), 'api', lib))
      end
    end
    # Load dashboard components
    begin
      require 'dashboard'
    rescue LoadError
      require File.expand_path(File.join(File.dirname(__FILE__), 'dashboard'))
    end

    def self.execute(torun, config, redis, metrics)
      self.settings.set :config, config
      self.settings.set :redis, redis unless redis.nil?
      self.settings.set :metrics, metrics
      self.settings.set :checkoutlock, Mutex.new

      # Deflating in all situations
      # https://www.schneems.com/2017/11/08/80-smaller-rails-footprint-with-rack-deflate/
      use Rack::Deflater

      # not_found clause placed here to fix rspec test issue.
      not_found do
        content_type :json

        result = {
          ok: false
        }

        JSON.pretty_generate(result)
      end

      if metrics.respond_to?(:setup_prometheus_metrics)
        # Prometheus metrics are only setup if actually specified
        # in the config file.
        metrics.setup_prometheus_metrics

        use Prometheus::Middleware::Collector, metrics_prefix: "#{metrics.metrics_prefix}_http"
        use Prometheus::Middleware::Exporter, path: metrics.endpoint
      end

      if torun.include? 'api'
        use Vmpooler::Dashboard
        use Vmpooler::API::Dashboard
        use Vmpooler::API::Reroute
        use Vmpooler::API::V1
      end

      # Get thee started O WebServer
      self.run!
    end
  end
end
