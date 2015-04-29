require 'capybara/poltergeist'
require_relative 'log.rb'

module GooglePlay
  class Scraper
    include Capybara::DSL
    include GooglePlay::Log

    attr_accessor :session, :account

    LOGIN_ENDPOINT = 'https://accounts.google.com/ServiceLogin'

    def initialize account
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

    def login_and_redirect! redirection_url = ''
      endpoint = endpoint(redirection_url)

      session.visit(endpoint)

      session.within('form#gaia_loginform') do
        session.fill_in('Email', with: account['login']) if session.has_field?('Email')
        session.fill_in('Passwd', with: account['password'])
      end

      session.click_on 'Sign in'
      check_expected_url redirection_url
    end

    def endpoint redirection_page
      if redirection_page.empty?
        LOGIN_ENDPOINT
      else
        LOGIN_ENDPOINT + '?continue=' + redirection_page
      end
    end

    def check_expected_url expected
      unless session.current_url == expected
        screenshot!
        logger.error "Expected: #{expected} but actual is #{session.current_url}"
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
