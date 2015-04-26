require 'gmail'

module GooglePlay
  class GmailService
    attr_accessor :gmail
    def initialize(account)
      @gmail = Gmail.new(account['login'], account['password'])
    end

    def send(t, s, b)
      email = @gmail.generate_message do
        to t
        subject s
        body b
      end
      @gmail.deliver(email)
    end

    def read_emails
      unread_emails.each {|email| email.mark(:read)}
    end

    def unread_emails
      @gmail.inbox.emails(:unread)
    end

    def unread_emails?
      unread_count > 0
    end

    def unread_count
      @gmail.inbox.count(:unread)
    end

    def last_unread
      unread_emails.first.message if unread_emails
    end

    def receive
      unread_emails if unread_emails?
    end

    def logout
      @gmail.logout
    end
  end
end
