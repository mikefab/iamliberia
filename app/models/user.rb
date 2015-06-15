class User
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  devise :omniauthable, :omniauth_providers => [:google_oauth2]

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
  # Use email handle a username to access other services
  def username
    self.email.split('@')[0]
  end

  def last_khan_exercise
    lesson = Lesson.where(
      username: self.username,
      source:   'khan'
      ).last

    exercises = lesson.content.reverse.map{
        |e| {
          date:          e['date'].to_date, 
          exercise_name: e['exercise_name']
        }
      }
      {points: lesson['points'], exercises: exercises}
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

      current_hash = {fluency_score: lng[1]['fluency_score'], streak: lng[1]['streak']}
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

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
      data = access_token.info
      user = User.where(:email => data["email"]).first

      # Uncomment the section below if you want users to be created if they don't exist
      unless user
          user = User.create(name: data["name"],
             email: data["email"],
             password: Devise.friendly_token[0,20]
          )
      end
      user
  end
end
