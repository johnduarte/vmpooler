# frozen_string_literal: true

require 'spec_helper'

describe 'prometheus' do
  params = { 'prefix': 'test', 'metrics_prefix': 'mtest', 'endpoint': 'eptest' }
  subject = Vmpooler::Promstats.new(params)
  let(:logger) { MockLogger.new }
  before { subject.instance_variable_set(:@logger, logger) }

  describe '#initialise' do
    it 'returns a Metrics object' do
      expect(Vmpooler::Promstats.new).to be_a(Vmpooler::Metrics)
    end
  end

  describe '#find_metric' do
    let!(:foo_metrics) do
      { metric_suffixes: { bar: 'baz' },
        param_labels: { first: 1, second: 2, last: 3 } }
    end
    let!(:labels_hash) { { labels: { [:last, 3] => nil, [:second, 2] => nil, [:first, 1] => nil } } }
    before { subject.instance_variable_set(:@p_metrics, { foo: foo_metrics }) }

    it 'returns the metric for a given label including parsed labels' do
      expect(subject.find_metric('foo.bar')).to include(metric_name: '_bar')
      expect(subject.find_metric('foo.bar')).to include(foo_metrics)
      expect(subject.find_metric('foo.bar')).to include(labels_hash)
      # I would expect this to fail because 'bar' is not a direct subkey of 'foo'.
      # This also returns the full value of foo as the value of the _bar metric.
    end

    it 'raises an error when the given label is not present in metrics' do
      expect { subject.find_metric('bogus') }.to raise_error(RuntimeError, 'Invalid Metric bogus for bogus')
    end

    it 'raises an error when the given label specifies metric_suffixes but the following suffix not present in metrics' do
      expect { subject.find_metric('foo.metric_suffixes.bogus') }.to raise_error(RuntimeError, 'Invalid Metric foo_metric_suffixes for foo.metric_suffixes.bogus')
    end
  end

  context 'setup_prometheus_metrics' do
    before(:all) do
      Prometheus::Client.config.data_store = Prometheus::Client::DataStores::Synchronized.new
      subject.setup_prometheus_metrics
    end
    let(:MCOUNTER) { 1 }

    describe '#setup_prometheus_metrics' do
      it 'calls add_prometheus_metric for each item in list' do
        Prometheus::Client.config.data_store = Prometheus::Client::DataStores::Synchronized.new
        expect(subject).to receive(:add_prometheus_metric).at_least(subject.vmpooler_metrics_table.size).times
        subject.setup_prometheus_metrics
      end
    end

    describe '#increment' do
      it 'Increments checkout.nonresponsive.#{template_backend}' do
        template_backend = 'test'
        expect { subject.increment("checkout.nonresponsive.#{template_backend}") }.to change {
          metric, po = subject.get("checkout.nonresponsive.#{template_backend}")
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments checkout.empty. + requested' do
        requested = 'test'
        expect { subject.increment('checkout.empty.' + requested) }.to change {
          metric, po = subject.get('checkout.empty.' + requested)
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments checkout.success. + vmtemplate' do
        vmtemplate = 'test-template'
        expect { subject.increment('checkout.success.' + vmtemplate) }.to change {
          metric, po = subject.get('checkout.success.' + vmtemplate)
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments checkout.invalid. + bad_template' do
        bad_template = 'test-template'
        expect { subject.increment('checkout.invalid.' + bad_template) }.to change {
          metric, po = subject.get('checkout.invalid.' + bad_template)
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments checkout.invalid.unknown' do
        expect { subject.increment('checkout.invalid.unknown') }.to change {
          metric, po = subject.get('checkout.invalid.unknown')
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments config.invalid.#{bad_template}' do
        bad_template = 'test-template'
        expect { subject.increment("config.invalid.#{bad_template}") }.to change {
          metric, po = subject.get("config.invalid.#{bad_template}")
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments config.invalid.unknown' do
        expect { subject.increment('config.invalid.unknown') }.to change {
          metric, po = subject.get('config.invalid.unknown')
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments poolreset.invalid.#{bad_pool}' do
        bad_pool = 'test-pool'
        expect { subject.increment("poolreset.invalid.#{bad_pool}") }.to change {
          metric, po = subject.get("poolreset.invalid.#{bad_pool}")
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments poolreset.invalid.unknown' do
        expect { subject.increment('poolreset.invalid.unknown') }.to change {
          metric, po = subject.get('poolreset.invalid.unknown')
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments errors.markedasfailed.#{pool}' do
        pool = 'test-pool'
        expect { subject.increment("errors.markedasfailed.#{pool}") }.to change {
          metric, po = subject.get("errors.markedasfailed.#{pool}")
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments errors.duplicatehostname.#{pool_name}' do
        pool_name = 'test-pool'
        expect { subject.increment("errors.duplicatehostname.#{pool_name}") }.to change {
          metric, po = subject.get("errors.duplicatehostname.#{pool_name}")
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments usage.#{user}.#{poolname}' do
        user = 'myuser'
        poolname = 'test-pool'
        expect { subject.increment("usage.#{user}.#{poolname}") }.to change {
          metric, po = subject.get("usage.#{user}.#{poolname}")
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments label :user' do
        # subject.increment(:user, :instance, :value_stream, :branch, :project, :job_name, :component_to_test, :poolname) - showing labels here
        pending 'increment only supports a string containing a dot separator'
        expect { subject.increment(:user) }.to change {
          metric, po = subject.get(:user)
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments connect.open' do
        expect { subject.increment('connect.open') }.to change {
          metric, po = subject.get('connect.open')
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments connect.fail' do
        expect { subject.increment('connect.fail') }.to change {
          metric, po = subject.get('connect.fail')
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments migrate_from.#{vm_hash[\'host_name\']}' do
        vm_hash = { 'host_name': 'testhost.testdomain' }
        expect { subject.increment("migrate_from.#{vm_hash['host_name']}") }.to change {
          metric, po = subject.get("migrate_from.#{vm_hash['host_name']}")
          po.get(labels: metric[:labels])
        }.by(1)
      end
      it 'Increments "migrate_to.#{dest_host_name}"' do
        dest_host_name = 'testhost.testdomain'
        expect { subject.increment("migrate_to.#{dest_host_name}") }.to change {
          metric, po = subject.get("migrate_to.#{dest_host_name}")
          po.get(labels: metric[:labels])
        }.by(1)
      end
    end

    describe '#gauge' do
      # metrics.gauge("ready.#{pool_name}", $redis.scard("vmpooler__ready__#{pool_name}"))
      it 'sets value of ready.#{pool_name} to $redis.scard("vmpooler__ready__#{pool_name}"))' do
        # is there a specific redis value that should be tested?
        pool_name = 'test-pool'
        test_value = 42
        expect { subject.gauge("ready.#{pool_name}", test_value) }.to change {
          metric, po = subject.get("ready.#{pool_name}")
          po.get(labels: metric[:labels])
        }.from(0).to(42)
      end
      # metrics.gauge("running.#{pool_name}", $redis.scard("vmpooler__running__#{pool_name}"))
      it 'sets value of running.#{pool_name} to $redis.scard("vmpooler__running__#{pool_name}"))' do
        # is there a specific redis value that should be tested?
        pool_name = 'test-pool'
        test_value = 42
        expect { subject.gauge("running.#{pool_name}", test_value) }.to change {
          metric, po = subject.get("running.#{pool_name}")
          po.get(labels: metric[:labels])
        }.from(0).to(42)
      end
    end

    describe '#timing' do
      it 'sets histogram value of time_to_ready_state.#{pool} to finish' do
        pool = 'test-pool'
        finish = 42
        expect { subject.timing("time_to_ready_state.#{pool}", finish) }.to change {
          metric, po = subject.get("time_to_ready_state.#{pool}")
          po.get(labels: metric[:labels])
        }
      end
      it 'sets histogram value of clone.#{pool} to finish' do
        pool = 'test-pool'
        finish = 42
        expect { subject.timing("clone.#{pool}", finish) }.to change {
          metric, po = subject.get("clone.#{pool}")
          po.get(labels: metric[:labels])
        }
      end
      it 'sets histogram value of migrate.#{pool} to finish' do
        pool = 'test-pool'
        finish = 42
        expect { subject.timing("migrate.#{pool}", finish) }.to change {
          metric, po = subject.get("migrate.#{pool}")
          po.get(labels: metric[:labels])
        }
      end
      it 'sets histogram value of destroy.#{pool} to finish' do
        pool = 'test-pool'
        finish = 42
        expect { subject.timing("destroy.#{pool}", finish) }.to change {
          metric, po = subject.get("destroy.#{pool}")
          po.get(labels: metric[:labels])
        }
      end
    end
  end
end
