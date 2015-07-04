class RoutesController < ApplicationController
  def show
    @routes = []

    origin = Location.new(address: show_params[:origin_address])
    destination = Location.new(address: show_params[:destination_address])

    departure_time = show_params[:time]

    routes_by_airports = origin.close_by_airport_codes.map do |airport_code|
      response = Typhoeus::Request.new("https://maps.googleapis.com/maps/api/distancematrix/json",
                                       params: { 'origins' => origin.address + '|Gneisenaustr. 19, 10119 Berlin',
                                                 'destinations' => airport_code + '+Airport|SFX+Airport',
                                                 'mode' => 'driving',
                                                 'departure_time' => departure_time.strftime('%s'),
                                                 'key' => GOOGLE_DISTANCE_MATRIX_API_KEY }).run
      if response.code != 200
        raise 'Invalid response from Google Directions'
      end
      json = JSON.parse(response.body)
      json['routes']
    end
  end

  def plane_options(origin_iata, destination_iata, departure_date)
    request = Typhoeus::Request.new('http://lh-fs-json.production.vayant.com',
                                    method: :post,
                                    headers: { 'Content-Type' => 'application/json' },
                                    accept_encoding: 'gzip',
                                    body: JSON.dump({
                                                        'User' => VAYANT_USER,
                                                        'Pass' => VAYANT_PASSWORD,
                                                        'Environment' => VAYANT_ENVIRONMENT,
                                                        'Origin' => origin_iata,
                                                        'Destination' => destination_iata,
                                                        'DepartureFrom' => departure_date.strftime('%F'),
                                                        'LengthOfStay' => ['7'],
                                                        'Passengers' => [{ 'Type' => 'ADT', 'Count' => 1}]
                                                      }))
    response = request.run
    if response.code != 200
      raise 'Invalid response from Vayant'
    end
    json = JSON.parse(response.body)
    flights = json['Journeys'].map { |j|
      journey = j[0]
      # Find only outbound flights. We identify them by segment == 1
      flights = journey['Flights'].find_all { |f| f['seg'] == 1 }
      # Return price and flights for outbound only
      { 'Price' => journey['OutboundPrice'], 'Flights' => flights }
    }.uniq  # don't forget to remove the duplicates
  end

  # those prices are just for Berlin, but they're okay enough for a mockup
  # Volkswagen, you guys need an Uber-like service here!
  def berlin_taxi_fare(distance)
    3.90 + [distance, 7.0].min*2.0 + [distance - 7, 0.0].max*1.5
  end

  def show_params
    params.permit(:origin_address, :destination_address, :time, :time_type)
  end
end
