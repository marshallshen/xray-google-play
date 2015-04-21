require 'capybara/poltergeist'
require 'yaml'

class GooglePlayScraper
  include Capybara::DSL

  attr_accessor :session, :account

  MOVIE_ENDPOINT = 'https://play.google.com/store/movies'
  LOGIN_ENDPOINT = 'https://accounts.google.com/ServiceLogin'

  def initialize(account)
    initialize_capybara
    @account = account
    @session = Capybara::Session.new(:poltergeist)
  end

  def initialize_capybara
    Capybara.configure do |c|
      c.run_server = false
      c.default_driver = :poltergeist
      c.app_host = 'http://www.google.com'
      c.default_wait_time = 5
    end

    phantom_opts = %w(--debug=no --load-images=no --ignore-ssl-errors=yes --ssl-protocol=TLSv1)

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, phantomjs_options: phantom_opts, debug: false)
    end
  end

  def login_and_redirect! redirection_page = ''
    endpoint = endpoint(redirection_page)

    session.visit(endpoint)

    session.within('form#gaia_loginform') do
      session.fill_in('Email', with: account[:login])
      session.fill_in('Passwd', with: account[:password])
    end

    session.check 'Stay signed in'
    session.click_on 'Sign in'
  end

  def endpoint redirection_page
    if redirection_page.empty?
      LOGIN_ENDPOINT + '?continue=' + redirection_page
    else
      LOGIN_ENDPOINT
    end
  end

  class Movie
    attr_accessor :title, :genre, :price

    def ==(o)
      self.title == o.title && self.genre == o.genre && self.price == o.price
    end

    def hash
      self.title.hash ^ self.genre.hash ^ self.price.hash
    end
  end

  def get_movie_recommendations
    login_and_redirect!(MOVIE_ENDPOINT) unless logged_in?
    session.find(:link, 'Recommended for You').click
    screenshot!
    movies_from_selector('.details')
  end

  def movies_from_selector klass
    session.all(:css, klass).map do |element|
      parse_movie_from_element(element)
    end
  end

  def logged_in?
    session.has_link?('Sign in')
  end

  def parse_movie_from_element element
    Movie.new.tap do |m|
      m.title = element.find('.title').text
      m.genre = element.find('.subtitle').text
      m.price = element.find('.display-price').text
    end
  end

  def screenshot!
    session.save_screenshot("#{Time.now}.png", full: true)
  end

  def clean!
    session.driver.clear_cookies
    session.reset!
  end
end

