module Bosh::HealthMonitor
  module Plugins
    class Resurrector < Base
      include Bosh::HealthMonitor::Plugins::HttpRequestHelper

      attr_reader :url

      def initialize(options={})
        super(options)
        director = @options['director']
        raise ArgumentError 'director options not set' unless director
        @url = URI(director['endpoint'])
        @user = director['user']
        @password = director['password']
      end

      def run
        unless EM.reactor_running?
          logger.error("Resurrector plugin can only be started when event loop is running")
          return false
        end

        logger.info("Resurrector is running...")
      end

      def process(event)
        deployment = event.attributes['deployment']
        job = event.attributes['job']
        index = event.attributes['index']

        # only when the agent times out do we add deployment, job & index to the alert
        # attributes, so this won't trigger a recreate for other types of alerts
        if deployment && job && index
          request = {
              head: {
                  'Content-Type' => 'text/yaml',
                  'authorization' => [@user, @password]
              },
          }

          @url.path = "/deployments/#{deployment}/jobs/#{job}/#{index}"
          @url.query = 'state=recreate'

          # TODO may need to batch recreation, but this gets called once per event since this is async,
          # we will fail on a second call as there already is a deployment running

          logger.info("recreating unresponsive VM: #{deployment} #{job}/#{index}")
          send_http_put_request(url.to_s, request)
        else
          logger.warn("event did not have deployment, job and index: #{event}")
        end
      end

    end
  end
end

