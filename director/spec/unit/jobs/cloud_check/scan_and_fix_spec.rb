require 'spec_helper'

describe Bosh::Director::Jobs::CloudCheck::ScanAndFix do
  before do
    deployment = BDM::Deployment.make(name: 'deployment')

    instance = BDM::Instance.make(deployment: deployment, job: 'j1', index: 0)
    BDM::DeploymentProblem.make(deployment: deployment, resource_id: instance.id, type: 'unresponsive_agent')

    instance = BDM::Instance.make(deployment: deployment, job: 'j1', index: 1)
    BDM::DeploymentProblem.make(deployment: deployment, resource_id: instance.id, type: 'missing_vm')

    instance = BDM::Instance.make(deployment: deployment, job: 'j2', index: 0)
    BDM::DeploymentProblem.make(deployment: deployment, resource_id: instance.id, type: 'unbound')
  end

  let(:deployment) { BDM::Deployment[1] }
  let(:jobs) { {'j1' => [0, 1], 'j2' => [0]} }


  it 'should call the problem scanner'
  it 'should call the problem resolver'

  it 'should create a list of resolutions' do
    scan_and_fix = described_class.new('deployment', jobs)

    scan_and_fix.resolutions.should == {1 => :recreate_vm, 2 => :recreate_vm}
  end
end
