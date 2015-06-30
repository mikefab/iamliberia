  class Badge
    include Mongoid::Document
    field :source,     type: String
    field :created_at, type: Date
    field :username,   type: String
    field :user_id,    type: Integer
    field :badges,     type: Integer
    field :max_streak, type: Integer
    has_one :user
  end
