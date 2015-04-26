require_relative 'google_play/version.rb'
require_relative 'google_play/measure.rb'
require_relative 'google_play/gmail_service.rb'
require_relative 'google_play/scraper.rb'
require 'logger'

module GooglePlay

  @logger ||= Logger.new(STDOUT)

  def self.run
    account1, account2 = YAML.load_file('assets/accounts.yml')

    play1 = GooglePlay::Scraper.new(account1)
    play2 = GooglePlay::Scraper.new(account2)

    @logger.info 'Fetching recommendations, before'
    before1 = play1.get_movie_recommendations
    before2 = play2.get_movie_recommendations

    @logger.info 'Sending emails'
    simulate_emails(account1, account2)

    minutes = 30
    @logger.info "Sleeping #{minutes} minutes"
    # sleep(60 * minutes)

    @logger.info 'Fetching recommendations, after'
    after1 = play1.get_movie_recommendations
    after2 = play2.get_movie_recommendations

    @logger.info 'Checking variance'
    check_variance account1, before1, after1
    check_variance account2, before2, after2
  end

  EMAIL_CONFIG_PATH = 'assets/emails.yml'
  def self.simulate_emails(account1, account2)
    emails = YAML.load_file(EMAIL_CONFIG_PATH)
    finance_emails = emails['finance']
    travel_emails = emails['travel']

    gmail1 = GmailService.new(account1)
    gmail2 = GmailService.new(account2)

    finance_emails.each do |email|
      gmail1.send(account2['login'], email['subject'], email['content'])
    end

    travel_emails.each do |email|
      gmail2.send(account1['login'], email['subject'], email['content'])
    end

    gmail1.read_emails
    gmail2.read_emails
  end

  def self.check_variance account, before, after
    if collections_equal? before, after
      @logger.info "For #{account['login']}, recommendations stayed the same"
    else
      @logger.info "For #{account['login']}, recommendations varied!"
    end
    @logger.info "Before: #{before.inspect}"
    @logger.info "After: #{after.inspect}"
  end

  private

    def self.collections_equal?(c1, c2)
      c1.size == c2.size && c1.lazy.zip(c2).all? { |x, y| x == y }
    end
end
