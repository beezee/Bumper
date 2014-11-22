class BumperMailer < ActionMailer::Base

  default from: "#{Bumper.config.settings.from_address}@" <<
    Bumper::Application.config.settings.from_host

  def body_from(email)
    email.raw_html.blank? ? email.raw_text : email.raw_html
  end

  def return_reminder(email)
    mail(to: email.from[:email], subject: email.subject, 
      content_type: 'text/html', body: body_from(email))
  end

  def how_to(recipient)
    mail(to: recipient, 
      subject: "Bumper error: Couldn't determine reminder schedule")
  end
end
