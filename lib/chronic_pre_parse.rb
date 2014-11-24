module ChronicPreParse

  MONTHS = %W{
    january february march april may june july
    august september november december
  }

  DURATIONS = %W{week day month hour minute}.map {|d| "#{d}(s?)"}

  DURATION_MATCH = "(\\d+)(#{DURATIONS.join('|')})"
    
  PATTERNS = {
    /^tomorrow$/ => ' 24 hours from now ',
    # july14 -> july 14
    /(#{MONTHS.join('|')})(\d+)/ => ' \1 \2 ',
    # -3.50pm -> at 3.50pm
    /-([\d\.]+(am|pm))$/ => ' at \1 ',
    #1week2days -> 1 week and 2 days
    /#{DURATION_MATCH}#{DURATION_MATCH}/ => ' \1 \2 and \8 \9 from now ',
    #1week -> 1 week
    /#{DURATION_MATCH}/ => ' \1 \2 from now '
  }

  def self.token_is_time?(token)
    token.match(/^\d(\d)?(\.\d\d)?(am|pm)$/)
  end

  def self.parse(token)
    r = token.to_s.clone
    PATTERNS.each do |match, replace|
      r.gsub!(match, replace)
    end
    r == token.to_s && !self.token_is_time?(token.to_s) ? nil : r
  end
end
