class Api::StudentsController < ApplicationController
  respond_to :json

  def index
    students = []
    User.all.each do |u|
      students << {
        username: u.username,
        name:     u.name,
        langs:    u.last_lang_lesson[:langs],
        calendar: u.last_lang_lesson[:calendar],
        achievement_dates: u.last_lang_lesson[:achievement_dates],
        khan_exercises: u.last_khan_exercise

      }
    end
    render json: students
  end
end