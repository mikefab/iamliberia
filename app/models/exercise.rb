class Exercise
  include Mongoid::Document
  field :subject,   type: String
  field :level,     type: String
  field :exercise,  type: String
  field :tutorial,  type: String
  field :topic,     type: String

end
