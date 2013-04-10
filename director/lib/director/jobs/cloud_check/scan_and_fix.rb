module Bosh::Director
  module Jobs
    module CloudCheck
      class ScanAndFix < BaseJob
        include LockHelper

        @queue = :normal

        def initialize(deployment_name, jobs)
          super

          @deployment_manager = Api::DeploymentManager.new
          @deployment = @deployment_manager.find_by_name(deployment_name)
          @jobs = jobs # {j1 => [i1, i2, ...], j2 => [i1, i2, ...]}
        end

        def perform
          begin
            with_deployment_lock(@deployment, :timeout => 0) do

              scanner = ProblemScanner.new(@deployment.name)
              scanner.reset(@jobs)
              scanner.scan_vms(@jobs)

              resolver = ProblemResolver.new(@deployment.name)
              resolver.apply_resolutions(resolutions)

              "scan and fix complete"
            end
          rescue Lock::TimeoutError
            raise "Unable to get deployment lock, maybe a deployment is in progress. Try again later."
          end
        end

        def resolutions
          manager = Bosh::Director::Api::InstanceManager.new

          all_resolutions = {}
          @jobs.each do |job, indices|
            indices.each do |index|
              instance = manager.find_by_name(@deployment.name, job, index)

              problems = Models::DeploymentProblem.filter(deployment: @deployment, resource_id: instance.id, state: 'open')
              problems.each do |problem|
                if problem.type == 'unresponsive_agent' || problem.type == 'missing_vm'
                  all_resolutions[problem.resource_id] = :recreate_vm
                end
              end
            end
          end

          all_resolutions
        end
      end
    end
  end
end
