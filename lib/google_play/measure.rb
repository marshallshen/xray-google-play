module GooglePlay
  class Measure
    attr_reader :gmail

    def initialize(username, password)
      @gmail = GooglePlay::GmailService.new(username, password)
    end
  end
end
