namespace :tellum do
  namespace :server do
    desc "stop server"
    task :stop => :environment do
      puts "-----------------Stoping Server----------------"
      pid_file = "tmp/pids/server.pid"
      pid = File.read(pid_file).to_i
      puts "************pid = #{pid}"
      Process.kill 9, pid
      File.delete pid_file
      puts "-----------------Server Stopped----------------"
    end
    desc "start server"
    task :start => :environment do
      puts "-----------------Starting Server----------------"
      `bundle exec rails s -d -p 6900 -e production`
      puts "-----------------Server Started----------------"
    end
    desc "start server"
    task :restart => :environment do
      puts "-----------------Restarting Server----------------"
      Rake::Task["tellum:server:stop"].invoke rescue puts "server is already stopped"
      Rake::Task["tellum:server:start"].invoke rescue puts "server is already runing"
      puts "-----------------Server Restarted----------------"
    end
  end
end