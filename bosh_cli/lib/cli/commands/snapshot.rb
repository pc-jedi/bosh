# Copyright (c) 2009-2013 VMware, Inc.

module Bosh::Cli::Command
  class Snapshot < Base
    include Bosh::Cli::DeploymentHelper

    usage "snapshots"
    desc "List all snapshots in a deployment"
    def list(job = nil, index = nil)
      auth_required

      deployment_name = prepare_deployment_manifest["name"]
      say("Deployment `#{deployment_name.green}'")

      snapshots = director.list_snapshots(deployment_name, job, index)

      sorted = snapshots.sort do |a, b|
        s = a["job"].to_s <=> b["job"].to_s
        s = a["index"].to_i <=> b["index"].to_i if s == 0
        s = a["created_at"].to_s <=> b["created_at"].to_s if s == 0
        s
      end

      snapshots_table = table do |t|
        t.headings = ["Job/index", "Snapshot ID", "Created at", "Clean"]

        sorted.each do |snapshot|
          job = "#{snapshot["job"] || "unknown"}/#{snapshot["index"] || "unknown"}"
          t << [job, snapshot["snapshot_id"], snapshot["created_at"], snapshot["clean"]]
        end
      end

      nl
      say(snapshots_table)
      nl
      say("Snapshots total: %d" % snapshots.size)
    end

    usage "take snapshot"
    desc "Takes a snapshot"
    def take(job, index)
      auth_required

      deployment_name = prepare_deployment_manifest["name"]
      say("Deployment `#{deployment_name.green}'")

      status, task_id = director.take_snapshot(deployment_name, job, index)

      task_report(status, task_id, "Snapshot toked")
    end

    usage "delete snapshot"
    desc "Deletes a snapshot"
    def delete(snapshot_cid)
      auth_required

      deployment_name = prepare_deployment_manifest["name"]
      say("Deployment `#{deployment_name.green}'")

      unless confirmed?("Are you sure you want to delete snapshot `#{snapshot_cid}'?")
        say("Canceled deleting snapshot".green)
        return
      end

      status, task_id = director.delete_snapshot(deployment_name, snapshot_cid)

      task_report(status, task_id, "Deleted Snapshot `#{snapshot_cid}'")
    end
  end
end