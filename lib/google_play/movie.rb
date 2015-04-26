module GooglePlay
  class Movie
    attr_accessor :title, :genre, :price

    def ==(o)
      self.title == o.title && self.genre == o.genre && self.price == o.price
    end

    def hash
      self.title.hash ^ self.genre.hash ^ self.price.hash
    end
  end
end