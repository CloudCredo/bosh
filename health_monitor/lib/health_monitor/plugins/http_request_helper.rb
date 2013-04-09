module Bosh::HealthMonitor::Plugins
  module HttpRequestHelper
    def send_http_post_request(uri, request)
      send_http_request(:post, uri, request)
    end

    def send_http_put_request(uri, request)
      send_http_request(:put, uri, request)
    end

    def send_http_request(method, uri, request)
      name = self.class.name
      logger.debug("sending HTTP #{method.to_s.upcase} to: #{uri}")
      started = Time.now
      http = EM::HttpRequest.new(uri)
      http.method(method).call(request)
      # wrong number of arguments (1 for 0)
      # /var/vcap/packages/health_monitor/gem_home/gems/health_monitor-1.5.0.pre.3/lib/health_monitor/plugins/http_request_helper.rb:15:in `send_http_request'
      # /var/vcap/packages/health_monitor/gem_home/gems/health_monitor-1.5.0.pre.3/lib/health_monitor/plugins/http_request_helper.rb:8:in `send_http_put_request'
      # /var/vcap/packages/health_monitor/gem_home/gems/health_monitor-1.5.0.pre.3/lib/health_monitor/plugins/resurrector.rb:48:in `process'
      http.callback do
        logger.debug("#{name} event sent (took #{Time.now - started} seconds): #{http.response_header.status}")
      end

      http.errback do |e|
        logger.error("Failed to send #{name} event: #{e.error}")
      end
    end
  end
end
