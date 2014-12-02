class BumperMailer < ActionMailer::Base

  default from: "#{Bumper::Application.config.settings.from_address}@" <<
    Bumper::Application.config.settings.from_host

  def body_from(email)
    email[:html].blank? ? email[:text] : email[:html]
  end

  def return_reminder(email)
    email = email.with_indifferent_access
    Rails.logger.info "Mailing reminder for #{email.to_s.inspect}"
    @content = body_from(email)
    mail(to: email[:from], content_type: 'text/html',
      subject: email[:subject])
  end

  def how_to(recipient, unsupported_addresses=[])
    @unsupported_addresses = unsupported_addresses
    mail(to: recipient, 
      subject: "Bumper error: Couldn't determine reminder schedule")
  end
end
