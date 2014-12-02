class HowToUseBumperWorker
  include Sidekiq::Worker

  # If there are multiple reminders scheduled at once, we will get
  # the same email multiple times. Each time it is processed, we
  # will schedule all jobs, so to prevent dupes keep unique for
  # 20 min, scoped to from address and to token
  sidekiq_options unique: true, unique_job_expiration: 60 * 20

  def perform(to_address, unsupported_tokens)
    unsupported_addresses = unsupported_tokens.
      map {|token| "#{token}@#{Bumper::Application.config.settings.from_host}"}
    BumperMailer.how_to(to_address, unsupported_addresses).deliver
  end
end

