class EmailProcessor
  
  def initialize(email)
    @email = email
  end

  def from_authorized?
    Bumper::Application.config.settings.
      authorized_emails.include?(@email.from[:email])
  end

  def zone
    @zone ||= ActiveSupport::TimeZone.new(
      (Bumper::Application.config.settings.timezone || 'UTC'))
  end

  def time_from_token(token)
    Chronic.time_class = zone
    Chronic.parse(ChronicPreParse.parse(token))
  end

  def bumper_addresses
    r = {supported: [], unsupported: []}
    @email.to.each do |to|
      next unless to[:host] == Bumper::Application.config.settings.from_host
      time = time_from_token(to[:token])
      if time
        r[:supported].push([to[:token], time])
      else
        r[:unsupported].push(to[:token])
      end
    end
    r
  end

  def email_params
    {from: @email.from[:email], subject: @email.subject,
      text: @email.raw_text, html: @email.raw_html}
  end

  def process
    return unless from_authorized?
    addrs = bumper_addresses
    Rails.logger.info { "processing incoming email with following " <<
      "bumper addresses #{bumper_addresses.to_s.inspect}" }
    addrs[:supported].each do |(token, time)|
      # Passing in the email token as a unique id
      # to prevent dupes when multiple reminders are in to field
      BumperWorker.perform_at(time, token, email_params)
    end
    if addrs[:unsupported].any?
      HowToUseBumperWorker.
        perform_async(@email.from[:email], addrs[:unsupported])
    end
  end
end
