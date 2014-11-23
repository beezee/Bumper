require 'email_processor'
require 'chronic_pre_parse'
Griddler.configure do |config|
  config.email_service = :mandrill
end
