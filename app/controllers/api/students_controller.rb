class Api::StudentsController < ApplicationController
  respond_to :json

  def index
    students = []
    if Rails.cache.exist?('students')
      puts "\n\nBBBBBB!!!!\n\n"
      students = Rails.cache.read('students')
    else
      puts "AAAAAA!!!!\n\n"
      User.all.sort_by{|u| u.last_activity_date}.reverse.each do |u|
        students << {
          username:           u.username,
          name:               u.name,
          langs:              u.last_lang_lesson[:langs],
          calendar:           u.last_lang_lesson[:calendar],
          achievement_dates:  u.last_lang_lesson[:achievement_dates],
          khan_exercises:     u.last_khan_exercise,
          codecademy_badges:  u.codecademy_badges,
          profile_image:      ActionController::Base.helpers.asset_path("assets/#{u.username}.jpg")
        }
      end
      Rails.cache.fetch('students', :expires_in => 1.month){students}
    end
    render json: students
  end
end