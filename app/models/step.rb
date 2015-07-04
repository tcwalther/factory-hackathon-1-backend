class Step < ActiveRecord::Base
  belongs_to :route
  belongs_to :departure, class_name: 'Location', foreign_key: 'departure_id'
  belongs_to :arrival, class_name: 'Location', foreign_key: 'arrival_id'

  validates :type, inclusion: { in: %w(Flight Drive), message: "%{value} is an invalid type" }
  validates :departure_id, presence: true
  validates :arrival_id, presence: true
end
