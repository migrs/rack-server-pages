require 'spec_helper'

Capybara.app, = Rack::Builder.parse_file(File.expand_path('../../config.ru', __FILE__))
Capybara.current_driver = :selenium

describe 'Integration', js: true do
  context 'root' do
    before do
      visit '/'
    end
    it 'loads homepage' do
      expect(page.find('h1')).to have_content 'rack-server-pages'
    end
    it 'loads markdown README' do
      click_link 'README'
      expect(page.first('h1')).to have_content 'Rack Server Pages'
    end
    it 'rendered ERB' do
      click_link 'sample.erb'
      expect(page).to have_content 'PartAPartB'
    end
    it 'rendered PHP' do
      click_link 'info.php'
      expect(page).to have_content 'CGI/1.1'
    end
  end
  it 'renders all tilt examples' do
    visit '/examples/'
    page.all('body ul li a').map { |a| a['href'] }.each do |href|
      puts href
      visit href
    end
  end
end
