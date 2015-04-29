require_relative 'scraper.rb'
require_relative 'movie.rb'

module GooglePlay
  class PlayScraper < Scraper

    MOVIE_ENDPOINT = 'https://play.google.com/store/movies/category/MOVIE'

    def get_movie_recommendations
      logger.info "Will go to the movie endpoint for #{account['login']}"
      login_and_redirect!(MOVIE_ENDPOINT)
      sleep 3
      logger.info 'Will click on Recommended for You'
      session.find(:link, 'Recommended for You').click
      sleep 3
      logger.info 'Will parse movies'
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
  end
end

