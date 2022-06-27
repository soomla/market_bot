module MarketBot
  class Util
    def self.fix_content_url(url)
      url =~ /\A\/\// ? "https:#{url}" : url
    end

    def self.sanitize_developer_url(url)
      encoding_options = {
        invalid: :replace, # Replace invalid byte sequences
        undef: :replace, # Replace anything not defined in ASCII
        replace: '', # Use a blank for those replacements
        universal_newline: true # Always break lines with \n
      }

      url   = url.encode(Encoding.find('ASCII'), encoding_options)
      url_q = URI(url).query
      if url_q
        q_param = url_q.split('&').select {|p| p =~ /q=/}.first
        url     = q_param.gsub('q=', '') if q_param
      end

      url
    end

    def self.build_request_opts(opts)
      opts ||= {}
      opts[:timeout] ||= MarketBot.timeout
      opts[:connecttimeout] ||= MarketBot.connect_timeout
      opts[:headers] ||= {}
      opts[:headers]['User-Agent'] ||= MarketBot.user_agent

      opts
    end
  end
end
