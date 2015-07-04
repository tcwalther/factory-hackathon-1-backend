module LufthansaHelper
  def lufthansa_api_key
    access_token = Rails.cache.read('lh_api_access_token')
    if access_token.nil?
      response = Typhoeus::Request.new('https://api.lufthansa.com/v1/oauth/token', method: :post, headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }, body: { client_secret: LH_API_CLIENT_SECRET, client_id: LH_API_CLIENT_ID, grant_type: 'client_credentials' }, ssl_verifypeer: false).run
      if response.code != 200
        raise 'Lufthansa API key request failed'
      end
      json = JSON.parse(response.body)
      access_token = json['access_token']
      expires_in = json['expires_in']

      Rails.cache.write('lh_api_access_token', access_token, expires_in: expires_in)
    end
    access_token
  end
end