::Search
class Search
  def get_filter_q_arr(url = nil)
    fqa = []
    self[:filter_q].each do |v|
      Rails.logger.debug("v: #{v} CGI-escaped: #{CGI.escape(v)}")
      uri = (url)? url.gsub(/#{Regexp.quote("&filter_q[]=#{CGI.escape(v)}")}(&|$)/, "\\1") : ''
      fqa.push({'v' => v, 'uri' => uri})
    end
    fqa
  end
end
