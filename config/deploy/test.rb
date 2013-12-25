require_relative 'self'
require_relative 'serf'

SERF_COMMAND = '/home/vagrant/serf-capistrano3/serf'

namespace :serf do
  task 'on-load-balancer-member-join', :name, :address, :role do |t, args|
    on roles(:monitor) do |h|
      info "The monitor running at #{h} starts monitoring for #{args[:name]}(role=#{args[:role]}, address=#{args[:address]})"
    end
  end

  task 'on-web-member-join', :name, :address, :role do |t, args|
    on roles(:deployer) do |h|
      info "The deployer at #{h} is deploying to #{args[:name]}(role=#{args[:role]}, address=#{args[:address]})"
      execute "#{SERF_COMMAND} event -rpc-addr=#{h && h.properties.serf[:'rpc-addr'] || 'host_undefined'} web-deployed '#{args[:name]} #{args[:address]} #{args[:role]}'"
    end
  end

  task 'on-web-deployed', :name, :address, :role do |t, args|
    on roles(:monitor) do |h|
      info "The monitor running at #{h} starts monitoring for #{args[:name]}(role=#{args[:role]}, address=#{args[:address]})"
    end
    on roles(:'load_balancer') do |h|
      info "The load balancer at #{h} starts load balancing to #{args[:name]}(role=#{args[:role]}, address=#{args[:address]}"
    end
  end
end
