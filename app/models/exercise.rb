class Exercise
  include Mongoid::Document
  field :index,     type: Integer
  field :subject,   type: String
  field :level,     type: String
  field :title,     type: String
  field :name,      type: String
  field :tutorial,  type: String
  field :topic,     type: String
  field :content,   type: Hash

end
