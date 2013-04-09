require 'spec_helper'

describe Bhm::Plugins::Resurrector do
  before(:all) do
    Bhm.logger = Logging.logger(StringIO.new)
  end

  let(:options) {
    {
        'director' => {
            'endpoint' => 'http://foo.bar.com:25555',
            'user' => 'user',
            'password' => 'password'
        }
    }
  }
  let(:plugin) { described_class.new(options) }
  let(:uri) { 'http://foo.bar.com:25555' }

  it 'should construct a usable url' do
    plugin.url.to_s.should == uri
  end

  context 'alerts with deployment, job and index' do
    let(:alert) { Bhm::Events::Base.create!(:alert, alert_payload(deployment: 'd', job: 'j', index: 'i')) }

    it 'should be delivered' do
      EM.run do
        plugin.run

        request_url = "#{uri}/deployments/d/jobs/j/i?state=recreate"
        request_data = {body: '{}'}
        plugin.should_receive(:send_http_put_request).with(request_url, request_data)

        plugin.process(alert)
        EM.stop
      end
    end
  end

  context 'alerts with deployment, job and index' do
    let(:alert) { Bhm::Events::Base.create!(:alert, alert_payload) }

    it 'should not be delivered' do
      EM.run do
        plugin.run

        plugin.should_not_receive(:send_http_put_request)

        plugin.process(alert)
        EM.stop
      end
    end
  end
end
