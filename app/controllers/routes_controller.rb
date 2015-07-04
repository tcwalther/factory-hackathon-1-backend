class RoutesController < ApplicationController
  def index
    @routes = []

    origin = Location.new(address: search_params[:origin_address])
    destination = Location.new(address: search_params[:destination_address])

    departure_time = DateTime.parse(search_params[:time])
    pieces_of_luggage = search_params[:pieces_of_luggage].to_i

    all_flights = flight_options(origin.close_by_airport_codes, destination.close_by_airport_codes, departure_time)

    # handle each origin airport differently
    @routes = origin.close_by_airport_codes.map { |departure_airport_code|
      # find time it takes to get to the origin airport
      time_and_distance_to_airport = drive_time_and_distance(origin.address,
                                                             "#{departure_airport_code} Airport",
                                                             departure_time,
                                                             'departure')
      time_to_airport = time_and_distance_to_airport[:time]

      time_to_check_in = 45.minutes
      time_to_get_luggage = pieces_of_luggage > 0 ? 20.minutes : 5.minutes

      # filter flights by that airport
      flights = flights_by_airport(all_flights, departure_airport_code)
      flights = flights_after(flights, departure_time + time_to_airport)

      flights[0..2].collect { |flight|
        if departure_airport_code.upcase != flight['Flights'][0]['org'].upcase
          raise "expected departure airport #{departure_airport_code}, but got #{flight['org']}"
        end

        arrival_airport_code = flight['Flights'][-1]['dst'].upcase
        flight_departure_time = time_at_airport(flight['Flights'][0]['dep'], departure_airport_code)
        flight_arrival_time = time_at_airport(flight['Flights'][-1]['arr'], arrival_airport_code)
        flight_price = flight['Price']['Total']['sum']
        number_of_connections = flight['Flights'].count

        # TODO: we need to find the latest ride TO the airport
        time_and_distance_to_airport = drive_time_and_distance(origin.address,
                                                               "#{departure_airport_code} Airport",
                                                               flight_departure_time - time_to_check_in,
                                                               'arrival')
        time_to_airport = time_and_distance_to_airport[:time]
        price_to_airport = berlin_taxi_fare(time_and_distance_to_airport[:distance])

        # let's find the first right from the arrival airport
        time_and_distance_to_destination = drive_time_and_distance("#{arrival_airport_code} Airport",
                                                                   destination.address,
                                                                   flight_arrival_time + time_to_get_luggage,
                                                                   'departure')
        time_to_destination = time_and_distance_to_destination[:time]
        price_to_destination = berlin_taxi_fare(time_and_distance_to_destination[:distance])

        # let's find the total price
        route_total_price = price_to_airport + flight_price + price_to_destination
        route_departure_time = flight_departure_time - time_to_check_in - time_to_airport
        route_arrival_time = flight_arrival_time + time_to_get_luggage + time_to_destination

        # let's assemble a list of steps. Like Car, Flight, Flight, Car
        steps = []
        steps << {
          type: 'drive',
          from: origin.address,
          from_type: 'address',
          to: departure_airport_code,
          to_type: 'airport',
          departure_time: route_departure_time,
          arrival_time: route_departure_time + time_to_airport
        }

        flight['Flights'].each do |flight_connection|
          steps << {
            type: 'flight',
            from: flight_connection['org'].upcase,
            from_type: 'airport',
            to: flight_connection['dst'].upcase,
            to_type: 'airport',
            departure_time: time_at_airport(flight_connection['dep'], flight_connection['org']),
            arrival_time: time_at_airport(flight_connection['arr'], flight_connection['dst'])
          }
        end

        steps << {
          type: 'drive',
          from: arrival_airport_code,
          from_type: 'airport',
          to: destination.address,
          to_type: 'address',
          departure_time: flight_arrival_time + time_to_get_luggage,
          arrival_time: route_arrival_time
        }

        {
          price: {
            total: route_total_price,
            to_airport: price_to_airport,
            flight: flight_price,
            to_destination: price_to_destination
          },
          departure_time: route_departure_time,
          arrival_time: route_arrival_time,
          steps: steps
        }
      }
    }.flatten

    # TODO: make sure we remove empty results from the final list
  end

  def flight_options(origin_iata, destination_iata, departure_time)
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
                                                        'DepartureFrom' => departure_time.strftime('%F'),
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

    # remove flights that are too early
    flights = flights_after(flights, departure_time)

    # sort in ascending order by departure time
    flights.sort { |x,y| DateTime.parse(x['Flights'][0]['dep']) <=> DateTime.parse(y['Flights'][0]['dep']) }
  end

  def flights_after(flights, departure_time)
    flights.find_all { |f| DateTime.parse("#{f['Flights'][0]['dep']} +0200") > departure_time }
  end

  def flights_by_airport(flights, airport_code)
    flights.find_all { |f| f['Flights'][0]['org'] == airport_code }
  end

  # those prices are just for Berlin, but they're okay enough for a mockup
  # Volkswagen, you guys need an Uber-like service here!
  def berlin_taxi_fare(distance)
    3.90 + [distance, 7.0].min*2.0 + [distance - 7, 0.0].max*1.5
  end

  def drive_time_and_distance(from, to, time, type)
    response = Typhoeus::Request.new("https://maps.googleapis.com/maps/api/distancematrix/json",
                                     params: { 'origins' => from,
                                               'destinations' => to,
                                               'mode' => 'driving',
                                               "#{type}_time" => time.strftime('%s'),
                                               'key' => GOOGLE_DISTANCE_MATRIX_API_KEY }).run
    if response.code != 200
      raise 'Invalid response from Google Directions'
    end
    json = JSON.parse(response.body)

    {
      time: json['rows'][0]['elements'][0]['duration']['value'].seconds,
      distance: json['rows'][0]['elements'][0]['distance']['value'] / 1000
    }
  end

  def time_at_airport(time_string, airport_code)
    DateTime.parse("#{time_string} #{AIRPORT_TIMEZONES[airport_code.upcase.to_sym]}")
  end

  def search_params
    params.require(:origin_address)
    params.require(:destination_address)
    params.require(:time)
    params.require(:pieces_of_luggage)
    params.permit(:origin_address, :destination_address, :time, :pieces_of_luggage)
  end
end
