require_relative 'google_play/version.rb'
require_relative 'google_play/measure.rb'
require_relative 'google_play/gmail_service.rb'
require_relative 'google_play/scraper.rb'

module GooglePlay
  def self.experiment(account)
    # account1 = {login: 'foo', password: 'bar'}
    # account2 = {login: 'nicky', password: 'anaconda'}
    play1 =  GooglePlayScraper.new(account1)
    play2 =  GooglePlayScraper.new(account2)

    gmail1 = GmailService.new(account1)
    gmail2 = GmailService.new(account2)

    recs_before1 = play1.get_movie_recommendations
    recs_before2 = play2.get_movie_recommendations

    # Load emails, send, etc.
    # gmail1.send(blah)
    # gmail2.send(blah)

    sleep(60 * 60 * 30) # 30 mins

    recs_after1 = play1.get_movie_recommendations
    recs_after2 = play2.get_movie_recommendations

    unless collections_equal? recs_before1 recs_after1
      puts "recommendations varied after email EMAIL for account ACCOUNT"
      puts recs_before1.inspect
      puts recs_after1.inspect
    end

    unless collections_equal? recs_before2 recs_after2
      puts "recommendations varied after email EMAIL for account ACCOUNT"
      puts recs_before2.inspect
      puts recs_after2.inspect
    end
  end

  def self.collections_equal? c1, c2
    c1.size == c2.size && c1.lazy.zip(c2).all? { |x, y| x == y }
  end

end
