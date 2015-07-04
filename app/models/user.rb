class User < ActiveRecord::Base
  validates :token, presence: true
end
