require 'capybara/poltergeist'
require 'yaml'

class GooglePlayScraper
  include Capybara::DSL

  attr_accessor :google, :account

  GOOGLE_PLAY_MOVIE_ENDPOINT = 'https://play.google.com/store/movies'
  LOGIN_ENDPOINT             = 'https://accounts.google.com/ServiceLogin'

  def initialize(account)
    initialize_capybara
    @account = account
    @google = Capybara::Session.new(:poltergeist)
  end

  def initialize_capybara
    Capybara.configure do |c|
      c.run_server = false
      c.default_driver = :poltergeist
      c.app_host = 'http://www.google.com'
    end

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app,
                                        phantomjs_options: [ '--debug=no',
                                                             '--load-images=no',
                                                             '--ignore-ssl-errors=yes',
                                                             '--ssl-protocol=TLSv1'],
                                        :debug => false)
  end

  end

  def login!
    google.visit(LOGIN_ENDPOINT)

    google.within("form#gaia_loginform") do
      google.fill_in('Email', with: account[:login])
      google.fill_in('Passwd', with: account[:passwd])
    end

    google.uncheck 'Stay signed in'
    google.click_on 'Sign in'
  end

  class Movie
    attr_accessor :title, :genre, :price
  end

  # TODO: dump movies somewhere
  def get_movie_recommendations
    google.visit(GOOGLE_PLAY_MOVIE_ENDPOINT)

    sleep(2)

    recommendation_xpath = '//*[@id="body-content"]/div[2]/div/div[4]/div/h1/a[1]'
    google.find(:xpath, recommendation_xpath).click

    sleep(1)

    parse_movies_from_enclosing_path('details')
  end

  # TODO: this doesn't account for pagination
  def parse_movies_from_enclosing_path path
    google.all(path).map do |dom|
      parse_movie_from_dom(dom)
    end
  end

  def parse_movie_from_dom dom
    Movie.new.tap do |m|
      m.title = google.find('a title')
      m.genre = google.find('')
      m.price = google.find('')
    end
  end

  def clean!
    google.driver.clear_cookies
    google.reset!
  end
end

