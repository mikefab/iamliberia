class Lesson
  include Mongoid::Document
  field :content,    type: Hash
  field :source,     type: String
  field :created_at, type: Date
  field :username,   type: String
  field :user_id,    type: Integer
  field :kind,       type: String
  has_one :user


  def self.achievement_dates(achievement_dates, lng)
    lng['skills'].each{
      |s|
      achievement_dates[s['learned_ts']] = s['url_title'] unless s['learned_ts'].nil?
    }
    achievement_dates.sort.reverse
  end


end
