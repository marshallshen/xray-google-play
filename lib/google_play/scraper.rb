require 'capybara/poltergeist'
require 'yaml'

class GooglePlayScraper
  include Capybara::DSL

  attr_accessor :google, :account

  PREFERENCES_ENDPOINT = 'https://www.google.com/settings/ads'
  LOGIN_ENDPOINT       = 'https://accounts.google.com/ServiceLogin'

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
  end

  def login!
    google.visit(LOGIN_ENDPOINT)

    google.within("form#gaia_loginform") do
      google.fill_in 'Email', with: account[:login]
      google.fill_in 'Passwd', with: account[:passwd]
    end

    google.uncheck 'Stay signed in'
    google.click_on 'Sign in'
  end

  GOOGLE_PLAY_MOVIE_URL = "https://play.google.com/store/movies"

  def get_google_play_recommendations
    google.visit(GOOGLE_PLAY_MOVIE_URL)
    sleep(2)
    recommendation_xpath = '//*[@id="body-content"]/div[2]/div/div[4]/div/h1/a[1]'
    google.find(:xpath, recommendation_xpath).click

    all_movies = google.all('details') # 'details' class better?

    all_movies.map do |movie_dom|
      get_movie_attributes(movie_dom)
    end
  end

  # Mark this as TODO, I have to leave soon..
  # COmmit this and push, I"ll work on it now
  # https://github.com/marshallshen/xray-google-play/commit/a30aa39f172077a521025825925846a61f42d7c2#diff-ed538b511af23f4531fe39245d8fcc0bR60
  def get_movies(movie)
    Movie.new.tap do |m|
      m.title = google.find('a title') # this won't work because google does not know the scope, yeah, we have to pass the xpath to the title, etc
      m.genre = google.find('')
      m.price = google.find('')
    end
  end

  class Movie
    attr_accessor :title, :genre, :price
  end
  # 3 dump current state of recommendations somewhere
  #

  def clean!
    google.driver.clear_cookies
    google.reset!
  end
end

