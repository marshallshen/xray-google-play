require 'capybara/poltergeist'
require 'yaml'
require_relative 'movie.rb'

module GooglePlay
  class Scraper
    include Capybara::DSL

    attr_accessor :session, :account

    MOVIE_ENDPOINT = 'https://play.google.com/store/movies/category/MOVIE'
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
        c.default_wait_time = 10
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
        session.fill_in('Email', with: account['login']) if session.has_field?('Email')
        session.fill_in('Passwd', with: account['password'])
      end

      session.click_on 'Sign in'
    end

    def endpoint redirection_page
      if redirection_page.empty?
        LOGIN_ENDPOINT
      else
        LOGIN_ENDPOINT + '?continue=' + redirection_page
      end
    end

    def get_movie_recommendations
      login_and_redirect!(MOVIE_ENDPOINT)
      sleep 3
      session.find(:link, 'Recommended for You').click
      sleep 3
      movies_from_selector('.details')
    end

    def movies_from_selector klass
      session.all(:css, klass).map do |element|
        parse_movie_from_element(element)
      end
    end

    def parse_movie_from_element element
      GooglePlay::Movie.new.tap do |m|
        m.title = find_text(element, '.title')
        m.genre = find_text(element, '.subtitle')
        m.price = find_text(element, '.display-price')
      end
    end

    def find_text(element, attr)
      begin
        element.find(attr).text
      rescue
        ''
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
end

