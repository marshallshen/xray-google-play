require_relative 'google_play/version.rb'
require_relative 'google_play/measure.rb'
require_relative 'google_play/gmail_service.rb'
require_relative 'google_play/scraper.rb'

module GooglePlay
  def self.experiment(account)
    # account = {login: 'foo', password: 'bar'}
    scraper = GooglePlayScraper.new(account)
    scraper.login!
  end
end
