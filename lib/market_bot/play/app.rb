module MarketBot
  module Play
    class App
      attr_reader(*ATTRIBUTES)
      attr_reader :package
      attr_reader :lang
      attr_reader :result

      def self.parse(html, _opts = {})
        result = {}

        doc = Nokogiri::HTML(html)

        top_cover = doc.css('div.hnnXjf')
        if top_cover
          cover_title = top_cover.children[0]
          result[:contains_ads] = !!cover_title.at('span:contains("Contains ads")')

          node = cover_title.xpath('//h1[@itemprop="name"]/span')
          result[:name] = node.text

          node = cover_title.xpath('//a[starts-with(@href, "/store/apps/dev")]').first
          result[:developer]     = node.children[0].text if node
          result[:developer_url] = node.attr('href')
          result[:developer_id]  = result[:developer_url].split('?id=').last.strip
          
          cover_metadata = top_cover.children[1]
          result[:content_rating] = cover_metadata.xpath('//span[@itemprop="contentRating"]').text
          result[:installs] = cover_metadata.xpath('//div[contains(text(), "Downloads")]/..').children.first.text
          
          node = cover_metadata.at_css('div[itemprop="starRating"]')
          if node
            result[:rating] = node.children.first.children.first.text
            node = node.parent.parent.children.last
            result[:votes] = node.text.split(' ').first
          end
        end

        poster_url = doc.at('video').attr('poster') if doc.at('video')
        if(poster_url)
          result[:cover_image_url] = MarketBot::Util.fix_content_url(poster_url) 
        else
          node = doc.at('img[class="oiEt0d"]')
          result[:cover_image_url] = node.attr('src') if node
        end

        result[:title] = doc.at_css('h1[itemprop="name"]').text

        node = doc.at_css('meta[itemprop="price"]')
        result[:price]  = node.attr('content') if node

        nodes = doc.search('img[alt="Screenshot image"]')
        result[:screenshot_urls] = []
        unless nodes.nil?
          result[:screenshot_urls] = nodes.map do |n|
            MarketBot::Util.fix_content_url(n[:src])
          end
        end

        node = doc.xpath('//h2[contains(text(), "What\'s new")]/ancestor::section')
        result[:whats_new] = node.children.last.text if node

        node = doc.at_css('meta[itemprop="description"]')
        result[:description]  = node.parent.children[1].text.strip if node

        a_genres = doc.search('div[itemprop="genre"]')
        result[:categories] = a_genres.map {|c| c.xpath('span').text.strip}
        result[:categories_urls] = a_genres.map {|c| c.xpath('a').attr('href').value}

        result[:category]     = result[:categories].first
        result[:category_url] = result[:categories_urls].first

        node = doc.xpath('//div[contains(text(), "Updated on")]/..')
        result[:updated] = node.children.last.text if node

        developer_div = doc.at_css('[id="developer-contacts"]')
        if developer_div
          node = developer_div.at('a:contains("@")')
          result[:email] = node.attr('href').split(':').last if node
          
          node = developer_div.xpath('//div[contains(text(), "Website")]/..')
          result[:website_url] = MarketBot::Util.sanitize_developer_url(node.children.last.text) if node

          node = developer_div.xpath('//div[contains(text(), "Privacy policy")]/..')
          result[:privacy_url] = MarketBot::Util.sanitize_developer_url(node.children.last.text) if node

          node = developer_div.xpath('//div[contains(text(), "Address")]/..')
          result[:physical_address] = node.children.last.text if node
        end

        result[:html] = html

        result
      end

      def initialize(package, opts = {})
        @package      = package
        @lang         = opts[:lang] || MarketBot::Play::DEFAULT_LANG
        @country      = opts[:country] || MarketBot::Play::DEFAULT_COUNTRY
        @request_opts = MarketBot::Util.build_request_opts(opts[:request_opts])
      end

      def store_url
        "https://play.google.com/store/apps/details?id=#{@package}&hl=#{@lang}&gl=#{@country}"
      end

      def update
        req = Typhoeus::Request.new(store_url, @request_opts)
        req.run
        response_handler(req.response)

        self
      end

      private

      def response_handler(response)
        if response.success?
          @result = self.class.parse(response.body)

          ATTRIBUTES.each do |a|
            attr_name  = "@#{a}"
            attr_value = @result[a]
            instance_variable_set(attr_name, attr_value)
          end
        else
          codes = "code=#{response.code}, return_code=#{response.return_code}"
          case response.code
            when 404
              raise MarketBot::NotFoundError, "Unable to find app in store: #{codes}"
            when 403
              raise MarketBot::UnavailableError, "Unavailable app (country restriction?): #{codes}"
            else
              raise MarketBot::ResponseError, "Unhandled response: #{codes}"
          end
        end
      end
    end
  end
end
