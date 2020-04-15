require 'spec_helper'
require 'vmpooler/statsd'

describe 'statsd' do

  let(:providers) do
    Vmpooler::Providers.new
  end

end


# for reference, all the metrics calls - all of these need to be tested.

# metrics.increment("checkout.nonresponsive.#{template_backend}")
# metrics.increment('checkout.empty.' + requested)
# metrics.increment('checkout.success.' + vmtemplate)
# metrics.increment('checkout.invalid.' + bad_template)
# metrics.increment('checkout.invalid.unknown') # Special Case
# metrics.increment("config.invalid.#{bad_template}")
# metrics.increment('config.invalid.unknown')
# metrics.increment("poolreset.invalid.#{bad_pool}")
# metrics.increment('poolreset.invalid.unknown')
# metrics.increment("errors.markedasfailed.#{pool}")
# metrics.increment("errors.duplicatehostname.#{pool_name}")
# metrics.increment("usage.#{user}.#{poolname}")
# metrics.increment(:user, :instance, :value_stream, :branch, :project, :job_name, :component_to_test, :poolname) - showing labels here
# metrics.increment('connect.open')
# metrics.increment('connect.fail')
# metrics.increment("migrate_from.#{vm_hash['host_name']}")
# metrics.increment("migrate_to.#{dest_host_name}")
# metrics.gauge("ready.#{pool_name}", $redis.scard("vmpooler__ready__#{pool_name}"))
# metrics.gauge("running.#{pool_name}", $redis.scard("vmpooler__running__#{pool_name}"))
# metrics.timing("time_to_ready_state.#{pool}", finish)
# metrics.timing("clone.#{pool_name}", finish)
# metrics.timing("destroy.#{pool}", finish)
# metrics.timing("destroy.#{pool}", finish)
# metrics.timing("migrate.#{pool_name}", finish)
