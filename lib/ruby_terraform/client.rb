require 'systemu'

module RubyTerraform
  class Client
    def initialize(directory, options)
      @directory = directory
      @options = options
    end

    def get(variables = {}, options = {})
      status, _stdout, stderr = run('get', variables, options)
      fail "Execute terraform get has been failed\n#{stderr}" unless status.success?
      true
    end

    def plan(variables = {}, options = {})
      options = { input: false, 'no-color' => nil }.merge(options)

      status, stdout, stderr = run('plan', variables, options)
      fail "Execute terraform plan has been failed\n#{stderr}" unless [0, 2].include?(status.exitstatus)

      { add: {}, destroy: {}, change: {} }.tap do |hash|
        stdout.split("\n").each do |line|
          case line
          when /^\-\/\+ (.*)/
            build_hash(hash[:add], Regexp.last_match(1))
            build_hash(hash[:destroy], Regexp.last_match(1))
          when /^\+ (.*)/
            build_hash(hash[:add], Regexp.last_match(1))
          when /^\- (.*)/
            build_hash(hash[:destroy], Regexp.last_match(1))
          when /^\~ (.*)/
            build_hash(hash[:change], Regexp.last_match(1))
          end
        end
      end
    end

    def apply(variables = {}, options = {})
      options = { input: false, 'no-color' => nil }.merge(options)

      status, _stdout, stderr = run('apply', variables, options)
      fail "Execute terraform apply has been failed\n#{stderr}" unless status.success?
      true
    end

    def show(variables = {}, options = {})
      options = { 'no-color' => nil }.merge(options)

      status, stdout, stderr = run('show', variables, options)
      fail "Execute terraform show has been failed\n#{stderr}" unless [0, 2].include?(status.exitstatus)

      # Remove outputs
      stdout = stdout.gsub(/^Outputs:$.*/m, '')

      {}.tap do |hash|
        stdout.split("\n").each do |line|
          next unless (match = line.match(/^(\S*):$/))
          build_hash(hash, match[1])
        end
      end
    end

    def output(variables = {}, options = {})
      options = { 'no-color' => nil }.merge(options)

      status, stdout, stderr = run('output', variables, options)
      fail "Execute terraform output has been failed\n#{stderr}" unless status.success?

      Hash[stdout.split("\n").map { |line| line.split(' = ') }]
    end

    def destroy(variables = {}, options = {})
      options = { force: nil, 'no-color' => nil }.merge(options)

      status, _stdout, stderr = run('destroy', variables, options)
      fail "Execute terraform destroy has been failed\n#{stderr}" unless status.success?
      true
    end

    private

    def run(subcommand, variables = {}, options = {})
      terraform_path = @options[:terraform_path] || 'terraform'
      command = "#{terraform_path} #{subcommand} #{options2command(options)} #{vars2command(variables)}"
      systemu(command, cwd: @directory).tap do |args|
        yield(*args) if block_given?
      end
    end

    def vars2command(variables)
      variables.map { |key, value| "-var #{key.to_s.shellescape}=#{value.to_s.shellescape}" }.join(' ')
    end

    def options2command(options)
      commands = options.map do |key, value|
        if value.nil?
          "-#{key.to_s.shellescape}"
        else
          "-#{key.to_s.shellescape}=#{value.to_s.shellescape}"
        end
      end
      commands.join(' ')
    end

    def build_hash(hash, dotted_string)
      dotted_string.split('.').inject(hash) do |h, key|
        h[key] ||= {}
      end
      hash
    end
  end
end
