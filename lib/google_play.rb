require_relative 'google_play/version.rb'
require_relative 'google_play/gmail_service.rb'
require_relative 'google_play/play_scraper.rb'
require_relative 'google_play/log.rb'
require 'yaml'

module GooglePlay
  class << self
    include GooglePlay::Log

    LOG_FILE = File.expand_path('../../recommendations.log', __FILE__)

    def run
      account1, account2, account3 = YAML.load_file('assets/accounts.yml')

      emails = YAML.load_file(EMAIL_CONFIG_PATH)
      action_movie_emails = emails['action']
      family_movie_emails = emails['family']

      # for holding the recommendations
      data = Hash.new
      data['recommendations'] = [[],[]]

      # the next round number
      round = last_round_in_log(LOG_FILE) + 1

      action_movie_emails.zip(family_movie_emails).cycle do |email_pair|
        email1 = email_pair.first
        email2 = email_pair.last

        logger.info 'Fetching new recommendations'

        play1 = GooglePlay::PlayScraper.new(account1)
        play2 = GooglePlay::PlayScraper.new(account2)

        new_recommendations1 = play1.get_movie_recommendations
        new_recommendations2 = play2.get_movie_recommendations

        last_recommendations = data['recommendations']

        File.open(LOG_FILE, 'a') do |file|
          file.puts "Round # #{round}"
          file.puts "#{Time.now}"

          logger.info "Checking variance for account #{account1['login']} against last round"
          file.puts "Account: #{account1['login']}"

          acc1_variance = collections_equal? last_recommendations.first, new_recommendations1
          if acc1_variance
            str = '  Compared to last round: SAME'
            logger.info str
            file.puts str
          else
            str = '  Compared to last round: DIFFERENT'
            logger.info str
            file.puts str
          end
          file.puts "  Will now send email about #{email1['subject']}"

          logger.info "Checking variance for account #{account2['login']} against last round"
          file.puts "Account: #{account2['login']}"

          acc2_variance = collections_equal? last_recommendations.last, new_recommendations2
          if acc2_variance
            str = '  Compared to last round: SAME'
            logger.info str
            file.puts str
          else
            str = '  Compared to last round: DIFFERENT'
            logger.info str
            file.puts str
          end
          file.puts "  Will now send email about #{email2['subject']}"

          logger.info 'Checking variance across the two accounts in this round'
          cross_acc_variance = collections_equal? new_recommendations1, new_recommendations2
          if cross_acc_variance
            str = "#{account1['login']} compared to #{account2['login']} in this round: SAME"
            logger.info str
            file.puts str
          else
            str = "#{account1['login']} compared to #{account2['login']} in this round: DIFFERENT"
            logger.info str
            file.puts str
          end

          if acc1_variance || acc2_variance || cross_acc_variance
            r1 = "#{account1['login']}: #{new_recommendations1.join(', ')}"
            r2 = "#{account2['login']}: #{new_recommendations2.join(', ')}"
            logger.info r1
            file.puts r1
            logger.info r2
            file.puts r2
          end
          logger.info '*' * 81
          file.puts '*' * 81
        end

        data['recommendations'] = [new_recommendations1, new_recommendations2]

        logger.info 'Sending emails'
        simulate_emails(account1, email1, account2, email2, account3)

        minutes = 30
        logger.info "Sleeping #{minutes} minutes"
        sleep(60 * minutes)
        round += 1
      end
    end

    def simulate_emails(account1, email1, account2, email2, account3)
      action_movie_fan  = GmailService.new(account1)
      family_movie_fan  = GmailService.new(account2)
      supportive_friend = GmailService.new(account3)

      logger.info 'Sending action emails'
      action_movie_fan.read_emails
      action_movie_fan.send(account3['login'], email1['subject'], email1['content'])
      action_movie_fan.logout

      logger.info 'Sending family emails'
      family_movie_fan.read_emails
      family_movie_fan.send(account3['login'], email2['subject'], email2['content'])
      family_movie_fan.logout

      logger.info 'Support friend reads emails'
      supportive_friend.read_emails
      logger.info 'Replying action emails'
      supportive_friend.send(account1['login'], email1['subject'], email1['reply'])
      logger.info 'Replying family emails'
      supportive_friend.send(account2['login'], email2['subject'], email2['reply'])
      supportive_friend.logout
    end

    EMAIL_CONFIG_PATH = 'assets/emails.yml'
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

    private

    def collections_equal?(c1, c2)
      c1.size == c2.size && c1.lazy.zip(c2).all? { |x, y| x == y }
    end

    def last_round_in_log file
      `tail -n 20 #{file} | grep 'Round #'`.strip.scan(/[0-9]+$/).last.to_i
    end
  end
end
