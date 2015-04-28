require_relative 'google_play/version.rb'
require_relative 'google_play/measure.rb'
require_relative 'google_play/gmail_service.rb'
require_relative 'google_play/scraper.rb'
require_relative 'google_play/log.rb'

module GooglePlay
  class << self
    include GooglePlay::Log

    def run
      account1, account2, account3 = YAML.load_file('assets/accounts.yml')

      play1 = GooglePlay::Scraper.new(account1)
      play2 = GooglePlay::Scraper.new(account2)

      emails = YAML.load_file(EMAIL_CONFIG_PATH)

      action_movie_emails = emails['action']
      family_movie_emails = emails['family']

      data = Hash.new
      data['recommendations'] = [[],[]]

      action_movie_emails.zip(family_movie_emails).cycle do |email_pair|
        logger.info 'Fetching new recommendations'
        new_recommendations1 = play1.get_movie_recommendations
        new_recommendations2 = play2.get_movie_recommendations

        last_recommendations = data['recommendations']

        logger.info "Checking variance for account #{account1['login']} against last round"
        check_variance account1, last_recommendations.first, account1, new_recommendations1
        logger.info "Checking variance for account #{account2['login']} against last round"
        check_variance account2, last_recommendations.last, account2, new_recommendations2
        logger.info 'Checking variance across the two accounts in this round'
        check_variance account1, new_recommendations1, account2, new_recommendations2

        data['recommendations'] = [new_recommendations1, new_recommendations2]

        logger.info 'Sending emails'
        simulate_emails(account1, email_pair.first, account2, email_pair.last, account3)

        minutes = 5
        logger.info "Sleeping #{minutes} minutes"
        # # sleep(60 * minutes)
      end
    end
      action_movie_fan  = GmailService.new(account1)
      family_movie_fan  = GmailService.new(account2)
      supportive_friend = GmailService.new(account2)

      logger.info 'Sending action emails'
      action_movie_emails.each do |email|
        action_movie_fan.send(account3['login'], email['subject'], email['content'])
      end

      logger.info 'Sending family emails'
      family_movie_emails.each do |email|
        family_movie_fan.send(account3['login'], email['subject'], email['content'])
      end

      logger.info 'Support friend reads emails'
      supportive_friend.read_emails

      logger.info 'Replying action emails'
      action_movie_emails.each do |email|
        supportive_friend.send(account1['login'], email['subject'], email['reply'])
      end

      logger.info 'Replying family emails'
      family_movie_emails.each do |email|
        supportive_friend.send(account2['login'], email['subject'], email['reply'])
      end
    end

    def dry_emails
      account1, account2, account3 = YAML.load_file('assets/accounts.yml')
      emails = YAML.load_file(EMAIL_CONFIG_PATH)
      action_movie_emails = emails['test']
      family_movie_emails = emails['test']

      action_movie_fan  = GmailService.new(account1)
      family_movie_fan  = GmailService.new(account2)
      supportive_friend = GmailService.new(account2)

      logger.info 'Sending action emails'
      action_movie_emails.each do |email|
        action_movie_fan.send(account3['login'], email['subject'], email['content'])
      end

      logger.info 'Sending family emails'
      family_movie_emails.each do |email|
        family_movie_fan.send(account3['login'], email['subject'], email['content'])
      end

      logger.info 'Support friend reads emails'
      supportive_friend.read_emails

      logger.info 'Replying action emails'
      action_movie_emails.each do |email|
        supportive_friend.send(account1['login'], email['subject'], email['reply'])
      end

      logger.info 'Replying family emails'
      family_movie_emails.each do |email|
        supportive_friend.send(account2['login'], email['subject'], email['reply'])
      end
    end

    def check_variance account, before, after
      if collections_equal? before, after
        logger.info "For #{account['login']}, recommendations stayed the same"
      else
        logger.info "For #{account['login']}, recommendations varied!"
      end
      logger.info "Before: #{before.inspect}"
      logger.info "After: #{after.inspect}"
    end

    private

    def collections_equal?(c1, c2)
      c1.size == c2.size && c1.lazy.zip(c2).all? { |x, y| x == y }
    end
  end
end
