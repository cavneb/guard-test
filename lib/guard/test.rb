# encoding: utf-8
require 'guard'
require 'guard/guard'
require 'guard/test/version'
require 'test/unit/version'

module Guard
  class Test < Guard

    autoload :Runner,    'guard/test/runner'
    autoload :Inspector, 'guard/test/inspector'

    def initialize(watchers=[], options={})
      super
      @options = {
        :all_on_start   => true,
        :all_after_pass => true,
        :keep_failed    => true,
        :rakes          => []
      }.update(options)
      @last_failed  = false
      @failed_paths = []

      @runner = Runner.new(options)
    end

    def start
      ::Guard::UI.info("Guard::Test #{TestVersion::VERSION} is running, with Test::Unit #{::Test::Unit::VERSION}!", :reset => true)
      
      unless @otions[:rakes].empty?
        ::Guard::UI.info("Executing provided rake tasks", :reset => true)
        @options[:rakes].each do |task_name|
          system("rake #{task_name}")
        end
      end
      
      run_all if @options[:all_on_start]
    end

    def run_all
      passed = @runner.run(Inspector.clean(['test']), :message => 'Running all tests')

      @failed_paths = [] if passed
      @last_failed  = !passed
    end

    def reload
      @failed_paths = []
    end

    def run_on_change(paths)
      paths += @failed_paths if @options[:keep_failed]
      paths  = Inspector.clean(paths)
      passed = @runner.run(paths)

      if passed
        # clean failed paths memory
        @failed_paths -= paths if @options[:keep_failed]

        # run all the tests if the changed tests failed, like autotest
        run_all if @last_failed && @options[:all_after_pass]
      else
        # remember failed paths for the next change
        @failed_paths += paths if @options[:keep_failed]

        # track whether the changed tests failed for the next change
        @last_failed = true
      end
    end

  end
end
