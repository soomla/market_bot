require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

include MarketBot::Play

describe MarketBot::Play::Chart do
  shared_context('parsing a chart') do
    it 'should have entries with a valid length' do
      expect(@parsed.length).to be > 1
    end

    it 'should have entries with valid attribute keys' do
      expect(@parsed).to all(have_key(:package)).and all(have_key(:rank)).and \
        all(have_key(:title)).and all(have_key(:store_url)).and \
        all(have_key(:developer)).and all(have_key(:icon_url))

    end

    it 'should have entries with valid packages' do
      @parsed.each_with_index do |v, i|
        msg = "i=#{i}, v=#{v.inspect}"
        expect(v[:package]).to be_kind_of(String), msg
        expect(v[:package]).to match(/[a-zA-Z0-9]+/), msg
      end
    end

    it 'should have entries with valid ranks' do
      @parsed.each_with_index do |v, i|
        msg = "i=#{i}, v=#{v.inspect}"
        expect(v[:rank]).to be_kind_of(Fixnum).and(be > 0), msg
      end

      ranks = @parsed.map { |e| e[:rank] }
      expect(ranks).to eq((ranks[0]..ranks[-1]).to_a)
    end

    it 'should have entries with valid titles' do
      @parsed.each_with_index do |v, i|
        msg = "i=#{i}, v=#{v.inspect}"
        expect(v[:title]).to be_kind_of(String), msg
        expect(v[:title].length).to (be > 1), msg
      end
    end

    it 'should have entries with valid store_urls' do
      @parsed.each_with_index do |v, i|
        msg = "i=#{i}, v=#{v.inspect}"
        expect(v[:store_url]).to be_kind_of(String), msg
        expect(v[:store_url]).to match(/\Ahttps:\/\/play.google.com\/store\/apps\/details\?id=.+&hl=en\z/), msg
      end
    end

    it 'should have entries with valid developers' do
      @parsed.each_with_index do |v, i|
        msg = "i=#{i}, v=#{v.inspect}"
        expect(v[:developer]).to be_kind_of(String), msg
        expect(v[:developer].length).to (be > 1), msg
      end
    end

    it 'should have entries with valid icon_urls' do
      @parsed.each_with_index do |v, i|
        msg = "i=#{i}, v=#{v.inspect}"
        expect(v[:icon_url]).to be_kind_of(String), msg
        expect(v[:icon_url]).to match(/\Ahttps:\/\/.+\z/), msg
      end
    end
  end

  describe "(topselling_paid - GAME_ARCADE)" do
    include_context 'parsing a chart'

    before(:all) do
      @collection = 'topselling_paid'
      @category ='GAME_ARCADE'
      @html = read_play_data('chart-topselling_paid-GAME_ARCADE-0.txt')
      @parsed = MarketBot::Play::Chart.parse(@html)
    end
  end
end
