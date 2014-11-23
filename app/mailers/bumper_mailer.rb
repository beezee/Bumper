class BumperMailer < ActionMailer::Base

  default from: "#{Bumper::Application.config.settings.from_address}@" <<
    Bumper::Application.config.settings.from_host

  def body_from(email)
    email[:html].blank? ? email[:text] : email[:html]
  end

  def return_reminder(email)
    Rails.logger.info "Mailing reminder for #{email.to_s.inspect}"
    mail(to: email[:from], content_type: 'text/html',
      subject: email[:subject]) do |format|
        format.html { render inline: body_from(email) } 
        format.text { render text: body_from(email) }
    end
  end

  def how_to(recipient)
    mail(to: recipient, 
      subject: "Bumper error: Couldn't determine reminder schedule")
  end
end
