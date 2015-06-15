class Lesson
  include Mongoid::Document
  field :content,    type: Hash
  field :source,     type: String
  field :created_at, type: Date
  field :username,   type: String
  field :user_id,    type: Integer
  field :kind,       type: String
  has_one :user


  def self.achievements(lng, calendar)
    lesson_count = 0

    lng['skills'].select{
      |o| o[:progress_percent] > 0
      }.map{ |s|
      {
        url_title:        s['url_title'],
        date:             shave_date(s['learned_ts'], calendar),
        title:            s['url_title'],
        num_lessons:      s['num_lessons'],
        progress_percent: s['progress_percent'],
        dates:            [],
        progress:         progress_complete(s)
      }
    }
  end

  def self.add_dates_to_achievments(achievements, calendar)
    achievements.each do |e|

      e[:progress].times do
        e[:dates].push calendar.pop()
      end
    end
    [achievements, calendar]
  end

  # Extend date three digits (0)
  def self.shave_date(date, calendar)
    if date.nil?
      if calendar.length > 0
        return calendar[0]['d']
      else
        return 0
      end
    else
      return date * 1000
    end

    # date.nil? ? 0 : date * 1000
  end

  def self.in_progress(progress_percent)
    return progress_percent > 0 && progress_percent < 100
  end

  def self.progress_complete(skill)
    ((skill['progress_percent'] * skill['num_lessons']).round)/100
  end

end
