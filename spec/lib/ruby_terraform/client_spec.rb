require 'ruby_terraform/client'

module RubyTerraform
  describe Client do
    before do
      @options = {
        terraform_path: '/usr/bin/terraform'
      }
      @client = Client.new('directory', @options)
    end

    describe '#initialize' do
      it 'return instance without exception' do
        expect(@client).to be
      end

      it 'keep directory' do
        expect(@client.instance_variable_get(:@directory)).to eq('directory')
      end

      it 'keep options' do
        expect(@client.instance_variable_get(:@options)).to eq(@options)
      end
    end

    describe '#get' do
      before do
        status = double(:status, success?: true)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
      end

      it 'call #run with get subcommand' do
        expect(@client).to receive(:run).with('get', kind_of(Hash), kind_of(Hash))
        @client.get
      end

      it 'raise error when terraform status code indicates failed' do
        status = double(:status, success?: false)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
        expect { @client.get }.to raise_error(RuntimeError)
      end

      it 'return true when execute terraform successfully' do
        expect(@client.get).to be_truthy
      end
    end

    describe '#plan' do
      before do
        status = double(:status, exitstatus: 0)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
      end

      it 'call #run with plan subcommand and -input option' do
        expect(@client).to receive(:run).with('plan', kind_of(Hash), hash_including(:input))
        @client.plan
      end

      it 'call #run with plan subcommand and -no-color option' do
        expect(@client).to receive(:run).with('plan', kind_of(Hash), hash_including('no-color'))
        @client.plan
      end

      it 'raise error when terraform status code indicates failed' do
        status = double(:status, exitstatus: 1)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
        expect { @client.plan }.to raise_error(RuntimeError)
      end

      it 'return resources and outputs when execute successfully' do
        status = double(:status, exitstatus: 0)
        stdout = File.read('spec/fixtures/plan/correct.txt')
        allow(@client).to receive(:run).and_return([status, stdout, ''])
        result = @client.plan

        expect(result).to be_is_a(Hash)
        expect(result.keys).to match_array(%w(module null_resource))
        expect(result['module'].keys).to match_array(%w(cloud_conductor_init zabbix tomcat))
        expect(result['module']['zabbix'].keys).to match_array(%w(aws_instance aws_security_group))
      end
    end

    describe '#apply' do
      before do
        status = double(:status, success?: true)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
      end

      it 'call #run with apply subcommand and -input option' do
        expect(@client).to receive(:run).with('apply', kind_of(Hash), hash_including(:input))
        @client.apply
      end

      it 'call #run with apply subcommand and -no-color option' do
        expect(@client).to receive(:run).with('apply', kind_of(Hash), hash_including('no-color'))
        @client.apply
      end

      it 'raise error when terraform status code indicates failed' do
        status = double(:status, success?: false)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
        expect { @client.apply }.to raise_error(RuntimeError)
      end

      it 'return true when execute terraform successfully' do
        expect(@client.apply).to be_truthy
      end
    end

    describe '#show' do
      before do
        status = double(:status, exitstatus: 0)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
      end

      it 'call #run with show subcommand and -no-color option' do
        expect(@client).to receive(:run).with('show', kind_of(Hash), hash_including('no-color'))
        @client.show
      end

      it 'raise error when terraform status code indicates failed' do
        status = double(:status, exitstatus: 1)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
        expect { @client.show }.to raise_error(RuntimeError)
      end

      it 'return resources and outputs when execute successfully' do
        status = double(:status, exitstatus: 0)
        stdout = File.read('spec/fixtures/show/correct.txt')
        allow(@client).to receive(:run).and_return([status, stdout, ''])
        result = @client.show

        expect(result).to be_is_a(Hash)
        expect(result.keys).to match_array(%w(module null_resource))
        expect(result['module'].keys).to match_array(%w(common_network tomcat_cluster_pattern))
        expect(result['module']['tomcat_cluster_pattern'].keys).to match_array(%w(openstack_compute_floatingip_v2 openstack_compute_instance_v2 openstack_compute_secgroup_v2))
      end
    end

    describe '#output' do
      before do
        status = double(:status, success?: true)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
      end

      it 'call #run with output subcommand and -no-color option' do
        expect(@client).to receive(:run).with('output', kind_of(Hash), hash_including('no-color'))
        @client.output
      end

      it 'raise error when terraform status code indicates failed' do
        status = double(:status, success?: false)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
        expect { @client.output }.to raise_error(RuntimeError)
      end

      it 'return output hash when execute terraform successfully' do
        stdout = <<-EOS
cluster_addresses = 10.0.1.71, 10.0.1.218, 10.0.1.217, 10.0.1.126
frontend_addresses = 52.90.146.75, 52.90.150.49, 52.23.223.222, 52.90.144.144
        EOS

        status = double(:status, success?: true)
        allow(@client).to receive(:run).and_return([status, stdout, 'stderr'])

        expect(@client.output).to eq(
          'cluster_addresses' => '10.0.1.71, 10.0.1.218, 10.0.1.217, 10.0.1.126',
          'frontend_addresses' => '52.90.146.75, 52.90.150.49, 52.23.223.222, 52.90.144.144'
        )
      end
    end

    describe '#destroy' do
      before do
        status = double(:status, success?: true)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
      end

      it 'call #run with destroy subcommand and -force option' do
        expect(@client).to receive(:run).with('destroy', kind_of(Hash), hash_including(:force))
        @client.destroy
      end

      it 'call #run with destroy subcommand and -no-color option' do
        expect(@client).to receive(:run).with('destroy', kind_of(Hash), hash_including('no-color'))
        @client.destroy
      end

      it 'raise error when terraform status code indicates failed' do
        status = double(:status, success?: false)
        allow(@client).to receive(:run).and_return([status, 'stdout', 'stderr'])
        expect { @client.destroy }.to raise_error(RuntimeError)
      end

      it 'return true when execute terraform successfully' do
        expect(@client.destroy).to be_truthy
      end
    end

    describe '#run' do
      describe 'without block' do
        it 'will execute terraform with plan subcommand' do
          variables = {
            key1: 'value1',
            key2: 'value2'
          }
          options = {
            backup: 'directory',
            destroy: nil
          }

          expected_command = '/usr/bin/terraform plan -backup=directory -destroy -var key1=value1 -var key2=value2'
          expected_options = { cwd: 'directory' }
          expect(@client).to receive(:systemu).with(expected_command, expected_options)
          @client.send(:run, 'plan', variables, options)
        end
      end

      describe 'with block' do
        it 'will execute terraform with plan subcommand' do
          variables = {
            key1: 'value1',
            key2: 'value2'
          }
          options = {
            backup: 'directory',
            destroy: nil
          }

          expected_command = '/usr/bin/terraform plan -backup=directory -destroy -var key1=value1 -var key2=value2'
          expected_options = { cwd: 'directory' }
          expect(@client).to receive(:systemu).with(expected_command, expected_options)
          @client.send(:run, 'plan', variables, options)
        end

        it 'yield block after execute terraform' do
          status = double(:status, exitstatus: 0)
          allow(@client).to receive(:systemu).and_return([status, 'stdout', 'stderr'])
          expect { |b| @client.send(:run, 'plan', {}, {}, &b) }.to yield_with_args(status, 'stdout', 'stderr')
        end
      end
    end

    describe '#vars2command' do
      it 'convert variable hash to command option' do
        variables = {
          key1: 'value1',
          key2: 'value2'
        }

        expect(@client.send(:vars2command, variables)).to eq('-var key1=value1 -var key2=value2')
      end

      it 'escape key and value to execute safely in shell' do
        variables = {
          'key1; sleep 1000' => 'value1',
          key2: 'value2; sleep 1000'
        }

        expect(@client.send(:vars2command, variables)).to eq(%q(-var key1\;\ sleep\ 1000=value1 -var key2=value2\;\ sleep\ 1000))
      end
    end

    describe '#options2command' do
      it 'convert options hash to command option' do
        options = {
          backup: 'directory',
          destroy: nil
        }

        expect(@client.send(:options2command, options)).to eq('-backup=directory -destroy')
      end

      it 'escape key and value to execute safely in shell' do
        options = {
          backup: 'directory; sleep 1000',
          'destroy; sleep 1000' => nil
        }

        expect(@client.send(:options2command, options)).to eq(%q(-backup=directory\;\ sleep\ 1000 -destroy\;\ sleep\ 1000))
      end
    end

    describe '#build_hash' do
      it 'convert dotted string to hash' do
        expected_hash = {
          'key' => {}
        }

        expect(@client.send(:build_hash, {}, 'key')).to eq(expected_hash)
      end

      it 'convert dotted string to hash with multiple hierarchy' do
        expected_hash = {
          'module' => {
            'zabbix' => {
              'aws_instance' => {
                'monitoring_server' => {}
              }
            }
          }
        }

        expect(@client.send(:build_hash, {}, 'module.zabbix.aws_instance.monitoring_server')).to eq(expected_hash)
      end

      it 'merge exist resources and converted resources' do
        hash = {
          'null_resource' => {},
          'module' => {
            'zabbix' => {
              'aws_security_group' => {}
            }
          }
        }
        expected_hash = {
          'null_resource' => {},
          'module' => {
            'zabbix' => {
              'aws_security_group' => {},
              'aws_instance' => {
                'monitoring_server' => {}
              }
            }
          }
        }

        expect(@client.send(:build_hash, hash, 'module.zabbix.aws_instance.monitoring_server')).to eq(expected_hash)
      end
    end
  end
end
