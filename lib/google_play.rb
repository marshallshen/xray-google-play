require_relative 'google_play/version.rb'
require_relative 'google_play/measure.rb'
require_relative 'google_play/gmail_service.rb'
require_relative 'google_play/scraper.rb'

module GooglePlay
  def self.run
    account1, account2 = YAML.load_file("assets/accounts.yml")

    play1 =  GooglePlayScraper.new(account1)
    play2 =  GooglePlayScraper.new(account2)

    recs_before1 = play1.get_movie_recommendations
    recs_before2 = play2.get_movie_recommendations

    simulate_send_emails(account1, account2)

  #  sleep(60 * 30) # 30 mins

    simulate_read_emails(account1, account2)

    recs_after1 = play1.get_movie_recommendations
    recs_after2 = play2.get_movie_recommendations

    unless collections_equal? recs_before1, recs_after1
      puts 'recommendations varied after email EMAIL for account ACCOUNT'
      puts recs_before1.inspect
      puts recs_after1.inspect
    end

    unless collections_equal? recs_before2, recs_after2
      puts 'recommendations varied after email EMAIL for account ACCOUNT'
      puts recs_before2.inspect
      puts recs_after2.inspect
    end
  end

  EMAIL_CONFIG_PATH = 'assets/emails.yml'
  def self.simulate_send_emails(account1, account2)
    require 'yaml'
    emails = YAML.load_file(EMAIL_CONFIG_PATH)
    finance_emails = emails['finance']
    travel_emails = emails['travel']

    GmailService.new(account1) do |gmail|
      finance_emails.each do |email|
        gmail.send(account2[:login], email['subject'], email['content'])
      end
    end

    GmailService.new(account2) do |gmail|
      travel_emails.each do |email|
        gmail.send(account1[:login], email['subject'], email['content'])
      end
    end
  end

  def self.simulate_read_emails(account1, account2)
    GmailService.new(account1) do |gmail|
      gmail.read_emails
    end

    GmailService.new(account2) do |gmail|
      gmail.read_emails
    end
  end

  def self.collections_equal?(c1, c2)
    c1.size == c2.size && c1.lazy.zip(c2).all? { |x, y| x == y }
  end
end
