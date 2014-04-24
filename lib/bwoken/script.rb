require 'fileutils'
require 'open3'

require 'bwoken'
require 'bwoken/device'

module Bwoken
  class ScriptFailedError < RuntimeError; end

  class Script

    def self.trace_file_path
      File.join(Bwoken.tmp_path, 'trace')
    end

    attr_accessor :path
    attr_accessor :device_family
    attr_accessor :formatter
    attr_accessor :simulator
    attr_accessor :app_dir
    attr_accessor :language

    def initialize
      yield self if block_given?
    end

    def env_variables
      {
        'UIASCRIPT' => %Q|"#{path}"|,
        'UIARESULTSPATH' => %Q|"#{Bwoken.results_path(language)}"|
      }
    end

    def env_variables_for_cli
      env_variables.map{|key,val| "-e #{key} #{val}"}.join(' ')
    end

    def cmd
      %Q|"#{File.expand_path('../../../bin', __FILE__)}/unix_instruments.sh" \
        #{device_flag} \
        -D "#{self.class.trace_file_path}" \
        -t "#{Bwoken.path_to_automation_template}" \
        "#{app_dir}" \
        #{env_variables_for_cli} \
        -AppleLanguages "(#{language})"|
    end

    def device_flag
      simulator ? '' : "-w #{Bwoken::Device.uuid}"
    end

    def run
      formatter.before_script_run path

      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        exit_status = formatter.format stdout
        raise ScriptFailedError.new('Test Script Failed') unless exit_status == 0
      end
    end

  end
end
