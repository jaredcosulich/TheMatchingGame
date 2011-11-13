require 'net/http'
require 'uri'

def safely
  yield
rescue => e
  HoptoadNotifier.notify(e)
end



task :cron => :environment do

  safely { Combinator.restock_all }

  safely { User.fix_fb_emails }

  safely { Response.reveal_some }

  if (Time.new.hour % 6 == 0)
    safely { PhotoPair.reveal_other_photo_matches }
  elsif  (Time.new.hour % 2 == 0)
    safely { PhotoPair.reveal_other_photo_matches(true) }
  end

  if (Time.new.hour % 12 == 0)
    safely { ResponseReminder.send_other_photo_match_reminders }
    safely { Photo.notify_unconfirmed }
  end

  if (Time.new.hour % 2 == 0)
    safely { ResponseReminder.send_reminders }
  end

  if (Time.now.wday == 3 && Time.now.hour == 6) || (Time.now.wday == 6 && Time.now.hour == 18)
    safely { PredictionsProgress.send_progress_report(3.5) }
  end

end
