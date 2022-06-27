require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe MarketBot::Play::App do
  shared_context('parsing an app') do
    it 'should parse the category attribute' do
      expect(@parsed[:category]).to eq('Action').or eq(nil).or eq('Simulation')
    end

    it 'should parse the category_url attribute' do
      expect(@parsed[:category_url]).to eq('/store/apps/category/GAME_ACTION').or eq(nil).or eq('/store/apps/category/GAME_SIMULATION')
    end

    it 'should parse the categories attribute' do
      expect(@parsed[:categories]).to eq(['Action', 'IO game', 'Casual']).or eq([]).or eq(["Simulation", "Casual"])
    end

    it 'should parse the categories_urls attribute' do
      expect(@parsed[:categories_urls]).to eq(["/store/apps/category/GAME_ACTION", "/store/search?q=io+games&c=apps", "/store/apps/category/GAME_CASUAL"]).or eq([]).or eq(["/store/apps/category/GAME_SIMULATION", "/store/apps/category/GAME_CASUAL"])
    end

    it 'should parse the content_rating attribute' do
      expect(@parsed[:content_rating]).to eq('PEGI 7').or eq('PEGI 3').or eq('Everyone')
    end

    it 'should parse the cover_image_url attribute' do
      expect(@parsed[:cover_image_url]).to match(/\Ahttps:\/\//).or be nil
    end

    it 'should parse the description attribute' do
      expect(@parsed[:description]).to be_kind_of(String)
      expect(@parsed[:description].length).to be > 10
    end

    it 'should parse the developer attribute' do
      expect(@parsed[:developer]).to be_kind_of(String)
      expect(@parsed[:developer].length).to be > 5
    end

    it 'should parse the developer_id attribute' do
      expect(@parsed[:developer_id]).to be_kind_of(String)
    end

    it 'should parse the email attribute' do
      expect(@parsed[:email]).to \
        match(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
    end

    it 'should parse the html attribute' do
      expect(@parsed[:html]).to eq(@html)
    end

    it 'should parse the installs attribute' do
      expect(@parsed[:installs]).to match(/\d+(\.\d+)?[MK]/)
    end

    it 'should parse the more_from_developer attribute' do
      expect(@parsed[:more_from_developer]).to eq(nil).or be_kind_of(Array)
    end

    it 'should parse the price attribute' do
      expect(@parsed[:price]).to eq('0').or match(/\A\$\d+\.\d\d\z/)
    end

    it 'should parse the rating attribute' do
      expect(@parsed[:rating]).to be_kind_of(String).and match(/\d\.\d+/)
    end

    it 'should parse the screenshot_urls attribute' do
      expect(@parsed[:screenshot_urls]).to be_kind_of(Array)
      expect(@parsed[:screenshot_urls].length).to be >= 0
    end

    it 'should parse the title attribute' do
      expect(@parsed[:title]).to be_kind_of(String)
      expect(@parsed[:title].length).to be > 5
    end

    it 'should parse the updated attribute' do
      expect(@parsed[:updated]).to be_kind_of(String).and \
        match(/\A[A-Z][a-z]+ \d+, 20\d\d\z/)
    end

    it 'should parse the votes attribute' do
      expect(@parsed[:votes]).to be_kind_of(String).and \
        match(/\d+(\.\d+)?[MK]/)
    end

    it 'should parse the website_url attribute' do
      expect(@parsed[:website_url]).to be_kind_of(String).and \
        match(/\Ahttps?:\/\//)
      expect(@parsed[:website_url]).not_to match(/privacy/)
    end

    it 'should parse the privacy_url attribute' do
      if @parsed[:privacy_url]
        expect(@parsed[:privacy_url]).to match(/\Ahttps?:\/\//).and \
          be_kind_of(String)
      end
    end

    it 'should parse the whats_new attribute' do
      expect(@parsed[:whats_new]).to be_kind_of(String).or \
        be_kind_of(NilClass)
    end

    it 'should parse the contains_ads attribute' do
      expect(@parsed[:contains_ads]).to eq(true).or \
        eq(false)
    end

    it 'should parse the physical_address attribute' do
      expect(@parsed[:physical_address]).to eq(nil).or(
        be_kind_of(String)
      )
    end
  end

  context '(app-io.voodoo.holeio)' do
    include_context 'parsing an app'

    before(:all) do
      @package = 'com.bluefroggaming.popdat'
      @html = read_play_data('app-io.voodoo.holeio.txt')
      @parsed = MarketBot::Play::App.parse(@html)
    end
  end

  context '(app-com.mg.android)' do
    include_context 'parsing an app'

    before(:all) do
      @package = 'com.mg.android'
      @html = read_play_data('app-com.mg.android.txt')
      @parsed = MarketBot::Play::App.parse(@html)
    end
  end

  context '(app-com.hasbro.mlpcoreAPPSTORE)' do
    include_context 'parsing an app'

    before(:all) do
      @package = 'com.hasbro.mlpcoreAPPSTORE'
      @html = read_play_data('app-com.hasbro.mlpcoreAPPSTORE.txt')
      @parsed = MarketBot::Play::App.parse(@html)
    end
  end

  it 'should populate the attribute getters' do
    package = 'app-io.voodoo.holeio'
    html = read_play_data('app-io.voodoo.holeio.txt')
    code = 200

    app = MarketBot::Play::App.new(package)
    response = Typhoeus::Response.new(code: code, headers: '', body: html)
    Typhoeus.stub(app.store_url).and_return(response)
    app.update

    MarketBot::Play::App::ATTRIBUTES.each do |a|
      expect(app.send(a)).to eq(app.result[a]), "Attribute: #{a}"
    end
  end

  it 'should raise a NotFoundError for http code 404' do
    package = 'com.missing.app'
    code = 404

    app = MarketBot::Play::App.new(package)
    response = Typhoeus::Response.new(code: code)
    Typhoeus.stub(app.store_url).and_return(response)

    expect do
      app.update
    end.to raise_error(MarketBot::NotFoundError)
  end

  it 'should raise an UnavailableError for http code 403' do
    package = 'com.not.available.in.your.country.app'
    code = 403

    app = MarketBot::Play::App.new(package)
    response = Typhoeus::Response.new(code: code)
    Typhoeus.stub(app.store_url).and_return(response)

    expect do
      app.update
    end.to raise_error(MarketBot::UnavailableError)
  end

  it 'should raise a ResponseError for unknown http codes' do
    package = 'com.my.internet.may.be.dead'
    code = 0

    app = MarketBot::Play::App.new(package)
    response = Typhoeus::Response.new(code: code)
    Typhoeus.stub(app.store_url).and_return(response)

    expect do
      app.update
    end.to raise_error(MarketBot::ResponseError)
  end
end
