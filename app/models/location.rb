class Location < ActiveRecord::Base
  include LufthansaHelper

  geocoded_by :address
  after_validation :geocode

  validates :type, inclusion: { in: %w(address airport), message: '%{value} is an invalid type' }
  validates :address, presence: true, if: :is_address?
  validates :gate, presence: true, if: :is_airport?
  validates :airport, presence: true, if: :is_airport?

  def is_address?
    self.type == 'address'
  end

  def is_airport?
    self.type == 'airport'
  end

  def close_by_city_codes
    close_by_airports.collect { |airport|
      airport['CityCode']
    }.uniq
  end

  def close_by_airport_codes
    close_by_airports.collect { |airport| airport['AirportCode'] }
  end

  def close_by_airports
    if latitude.nil? or longitude.nil?
      geocode
    end

    Rails.cache.fetch("airports/nearest/#{latitude},#{longitude}", expires_in: 3600*24) do
      response = Typhoeus::Request.new("https://api.lufthansa.com/v1/references/airports/nearest/#{latitude},#{longitude}", method: :get, headers: { 'Authorization' => "Bearer #{lufthansa_api_key}", 'Accept' => 'application/json' }).run
      if response.code != 200
        raise 'Lufthansa nearest airports request failed'
      end
      json = JSON.parse(response.body)
      json['NearestAirportResource']['Airports']['Airport'].find_all { |airport|
        airport['Distance']['Value'] < 80
      }
    end
  end
end
