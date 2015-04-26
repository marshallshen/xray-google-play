require_relative 'lib/google_play'

namespace :xray do
  desc 'Run a simple experiment to valid Google Play'
  task :dry_run do
    GooglePlay.run
  end

  desc 'Run a simple email exchange to valid Google Play'
  task :dry_mail do
    GooglePlay.dry_emails
  end
end
