class User
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  devise :omniauthable, :omniauth_providers => [:google_oauth2, :facebook, :twitter]

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""
  field :uid, type: String
  field :provider, type: String
  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String
  has_many :lessons, :foreign_key => 'username'
  has_many :badges, :foreign_key => 'username'
  def last_activity_date
    l = self.last_lesson # Khan lesson
    l.nil? ? Date.new(1900,1,1) : Date.parse(self.last_lesson.exercises.last['date'])
    
  end

  # Use email handle a username to access other services
  def username
    self.email.split('@')[0]
  end

  def last_lesson
    l = Lesson.where(
      username: self.username,
      source:   'khan'
      )

    l.nil? ? nil : l.last
  end


  def codecademy_badges
    b = Badge.where(username: self.username).last
    return b.nil? ? 0 : b.badges
  end


  # Return number of exercise names in user's completed history and in lesson index
  def self.exercises_topic_level(level, topic, user_exercises)
    exercises = Exercise.all.where(level: level, topic: topic).map(&:title)
    (user_exercises.map{|o| o[:exercise_name]} & exercises).count
  end

  def last_khan_exercise
    lesson    = self.last_lesson
    points    = lesson['points'].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    exercises = lesson.exercises.reverse.map{
        |e| 
        {
          date:          e['date'].to_date, 
          exercise_name: e['exercise_name']
        }
      }

    # Percentage of lessons per level:topic complete
    # {"Early Math"=>[{"Counting"=>[4, 4]}, {"Counting objects"=>[5, 5]} ....}
    levels = {}
    MATH_UNIQUE_EXERCISES.each{
        |level| levels[level] = LEVELS[level].map{
          |topic, v| {topic: topic,  lessons: [v.count, User.exercises_topic_level(level, topic, exercises )]}
        }
      }

    # Get subject and percent complete
    level_progress_percents = []
    levels.keys.each{
      |level|
      total = 0
      done  = 0
      levels[level].each do |e|
        total += e[:lessons][0];
        done  += e[:lessons][1]; 
        e[:percent] = ((e[:lessons][1].to_f/e[:lessons][0].to_f) * 100).to_i
      end
      perc = ((done.to_f/total.to_f)* 100).to_i
      if perc > 0
        level_progress_percents << { subject: level, perc: perc, lessons: levels[level]} 
      end
    }


    # Remove topics that have not been started yet
    levels.keys.each do |key|
      indexes_to_delete = []
      # levels[key] -> [{:topic=>"Counting", :lessons=>[12, 12], :percent=>100}, {:topic=>"Geometry", :lessons=>[9, 5],...] 
      levels[key].each_with_index do |k, index|

        if k[k.keys[1]][1] == 0
          indexes_to_delete << index
        end
      end
        indexes_to_delete.reverse.each{|i| levels[key].delete_at(i)}
        levels.delete(key) if levels[key].empty?
    end  

    videos = lesson['videos'].select{
                |v| v['completed'] == true
              }.reverse.map{
                |v| {
                      date:  v['last_watched'],
                      title: v['video']['translated_title']
                    }
                  }.sort_by{|v| v['last_watched']}.reverse


      {points: points, exercises: exercises, videos: videos, khan_percents: levels, math_progress: level_progress_percents}
  end

  def last_lang_lesson
    # Current language being learned
    current_lng    = ''
    current_hash   = {}
    achievements   = []

    # Get most recent lesson. C
    lesson = Lesson.where(
      username: self.username,
      source:   'duolingo'
    ).last.content

    lesson['language_data'].each do |lng|
      current_lng  = lng[0]
      # Hash of date and lesson name

      achievements = Lesson.achievements(lng[1], lesson['calendar']).sort_by{|o| o[:date]}.reverse
      completion_percent = ((achievements.count.to_f/lng[1]['skills'].length.to_f ) * 100).round(1)
      current_hash = {
        fluency_score:      (lng[1]['fluency_score'].to_f * 100).to_i,
        streak:             lng[1]['streak'],
        completion_percent: completion_percent
      }
    end

    langs = {}
    # Add only languages that have been studied so far
    lesson['languages'].each do |l|
      if l['points'] > 0
        langs[l['language']] = {
                                lang:        l['language'],
                                lang_string: l['language_string'],
                                points:      l['points']
                              }
        if l['language'] == current_lng
          langs[l['language']].merge!(current_hash)
        end
      end
    end

    {achievement_dates: achievements, langs: langs, calendar: lesson['calendar']}
  end

  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |user|
      user.provider = auth.provider 
      user.uid = auth.uid
      user.name = auth.info.name
      user.oauth_token = auth.credentials.oauth_token 
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.save
     end
  end 

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
      data = access_token.info
      user = User.where(:email => data["email"]).first

      # Uncomment the section below if you want users to be created if they don't exist
      unless user
        user = User.create(name: data['name'],
           email: data['email'],
           password: Devise.friendly_token[0,20]
        )
      end
      user
  end
end
