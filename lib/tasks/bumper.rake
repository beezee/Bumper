namespace :bumper do
  desc "starts server and sidekiq"
  task :start, [:port] => :environment do |t, args|
    port = args[:port] || 3000
    `rails s -p #{port} thin -d`
    `bundle exec sidekiq -d -l log/sidekiq.log`
  end

  desc "stops server and sidekiq, harshly"
  task stop: :environment do
    pidfile = 'tmp/pids/server.pid'
    if (File.exists? pidfile)
      Process.kill 9, File.read(pidfile).to_i
      File.delete pidfile
    end
    `ps -ef | grep sidekiq | grep -v grep | awk '{print $2}' | xargs kill -9`
  end

end
