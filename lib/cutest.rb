require 'benchmark'
require 'ostruct'

class Cutest
  autoload :Database, 'database'

  unless defined?(VERSION)
    VERSION = "1.3.6"
    FILTER = %r[/(ruby|jruby|rbx)[-/]([0-9\.])+]
    CACHE = Hash.new { |h, k| h[k] = File.readlines(k) }
  end

  class AssertionFailed < StandardError; end

  class << self

    attr_accessor :config, :reset_config

    def setup
      yield config
    end

    def config
      @config || reset_config!
    end

    def reset_config!
      @config = OpenStruct.new database: {}
    end

    def load_envs env
      File.foreach env do |line|
        key, value = line.split "="
        ENV[key] = value.gsub('\n', '').strip
      end
    end

    def silence_warnings
      old_verbose, $VERBOSE = $VERBOSE, nil
      yield
    ensure
      $VERBOSE = old_verbose
    end

    def run(files)
      if !cutest[:warnings]
        Cutest.silence_warnings do
          Cutest.now_run files
        end
      else
        Cutest.now_run files
      end
    end

    def now_run files
      status = files.all? do |file|
        run_file(file)

        Process.wait2.last.success?
      end

      puts

      status
    end

    def run_file(file)
      fork do
        begin
          load(file)
        rescue LoadError, SyntaxError
          display_error
          exit 1

        rescue StandardError
          trace = $!.backtrace
          pivot = trace.index { |line| line.match(file) }

          puts "  \e[93mTest: \e[0m%s\e[31m✘\e[0m\n" % (cutest[:test] != '' ? "#{cutest[:test]} " : '')

          if pivot
            other = trace[0..pivot].select { |line| line !~ FILTER }
            other.reverse.each { |line| display_trace(line) }
          else
            display_trace(trace.first)
          end

          display_error

          if not cutest[:pry_rescue]
            exit 1
          else
            begin
              Process.waitall
            rescue ThreadError, Interrupt
              # Ignore this as it's caused by Process.waitall when using -p
            end
          end
        end
      end
    end

    def code(fn, ln)
      begin
        CACHE[fn][ln.to_i - 1].strip
      rescue
        "(Can't display line)"
      end
    end

    def display_error
      if cutest[:backtrace]
        bt = $!.backtrace
        bt.each do |line|
          display_trace line
        end
      end

      puts "  \033[93m#{$!.class}: \033[31m#{$!.message}"
      puts ""
    end

    def display_trace(line)
      fn, ln = line.split(":")

      puts "  → \033[0mfile: #{fn} ↪#{ln}\e[0m"
      puts "  → \033[90mline: #{code(fn, ln)}\e[0m"
    end
  end

  class Scope
    def initialize(&scope)
      @scope = scope
    end

    def call
      instance_eval(&@scope)
    end
  end
end

module Kernel

  private

  # Use Thread.current[:cutest] to store information about test preparation
  # and setup.
  Thread.current[:cutest] ||= { :prepare => [] }

  # Shortcut to access Thread.current[:cutest].
  def cutest
    Thread.current[:cutest]
  end

  # Create a class where the block will be evaluated. Recommended to improve
  # isolation between tests.
  def scope(name = nil, &block)
    if !cutest[:scope] || cutest[:scope] == name
      puts "\033[93mScope: \033[0m#{name}"
      puts ""
      Cutest::Scope.new(&block).call
    end
  end

  # Prepare the environment in order to run the tests. This method can be
  # called many times, and each new block is appended to a list of
  # preparation blocks. When a test is executed, all the preparation blocks
  # are ran in the order they were declared. If called without a block, it
  # returns the array of preparation blocks.
  def prepare(&block)
    cutest[:prepare] << block if block_given?
    cutest[:prepare]
  end

  # Setup parameters for the tests. The block passed to setup is evaluated
  # before running each test, and the result of the setup block is passed to
  # the test as a parameter. If the setup and the tests are declared at the
  # same level (in the global scope or in a sub scope), it is possible to use
  # instance variables, but the parameter passing pattern is recommended to
  # ensure there are no side effects.
  #
  # If the setup blocks are declared in the global scope and the tests are
  # declared in sub scopes, the parameter passing usage is required.
  #
  # Setup blocks can be defined many times, but each new definition overrides
  # the previous one. It is recommended to split the tests in many different
  # files (the report is per file, not per assertion). Usually one setup
  # block per file is enough, but nothing forbids having different scopes
  # with different setup blocks.
  def setup(&block)
    cutest[:setup] = block if block_given?
    cutest[:setup]
  end

  # Kernel includes a test method for performing tests on files.
  undef test if defined? test

  # Call the prepare and setup blocks before executing the test. Even
  # though the assertions can live anywhere (it's not mandatory to put them
  # inside test blocks), it is necessary to wrap them in test blocks in order
  # to execute preparation and setup blocks.
  def test(name = nil, &block)
    cutest[:test] = name

    if !cutest[:only] || cutest[:only] == name
      print '  '
      time_taken = Benchmark.measure do
        prepare.each { |blk| blk.call }
        block.call(setup && setup.call)
      end
      puts ''
      puts "  \033[93mTest: \033[0m#{cutest[:test]} \033[32m✔\033[0m"
      puts "\e[94m#{time_taken}\033[0m"
    end

    cutest[:test] = nil
  end

  # Assert that value is not nil or false.
  def assert(value)
    flunk("expression returned #{value.inspect}") unless value
    success
  end

  # Assert that two values are equal.
  def assert_equal(value, other)
    flunk("#{value.inspect} != #{other.inspect}") unless value == other
    success
  end

  # Assert that the block doesn't raise the expected exception.
  def assert_raise(expected = Exception)
    begin
      yield
    rescue => exception
    ensure
      flunk("got #{exception.inspect} instead") unless exception.kind_of?(expected)
      success
    end
  end

  # Stop the tests and raise an error where the message is the last line
  # executed before flunking.
  def flunk(message = nil)
    exception = Cutest::AssertionFailed.new(message)
    exception.set_backtrace([caller[1]])

    raise exception
  end

  # Executed when an assertion succeeds.
  def success
    print "•"
  end
end
