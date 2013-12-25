SERF_MEMBERSHIP_EVENTS = %w(member-join member-leave member-failed)

namespace :serf do
  SERF_MEMBERSHIP_EVENTS.each do |event|
    task "on-#{event}", :name, :address, :role do |t, args|
      puts "Running the membership event handling task: on-#{event}"

      role_specific_task = "serf:on-#{args[:role]}-#{event}"
      puts "role: #{args[:role]}, task_defined?: #{Rake::Task.task_defined?(role_specific_task)}"
      unless args[:role].nil? || args[:role].size.zero? || !Rake::Task.task_defined?(role_specific_task)
        puts "role: #{args[:role]}"
        Rake::Task[role_specific_task].invoke(args.name, args.address, args[:role])
      end
    end
  end
  task "on-user", :event do |t, args|
    user_event = args[:event]
    extras = args.extras
    the_task = "serf:on-#{user_event}"
    if Rake::Task.task_defined? the_task
      Rake::Task[the_task].invoke(*extras)
    end
  end
end
