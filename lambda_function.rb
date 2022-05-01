require 'net/http'

def lambda_handler(event:, context:)
  # Options within event
  # event = {
  #   "url" => "https://www.google.com",
  #   "mobile" => true
  # }
  url = event.dig("url")
  uri = URI(url)
  is_mobile = event.dig("mobile") || false
  return { code: "400", message: "URL is required" } if url.nil?

  request = Net::HTTP::Get.new(uri)

  # Set headers
  if is_mobile
    request["User-Agent"] = "Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.41 Mobile Safari/537.36"
  end

  # Response body might contain content of other encoding than UTF-8
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http|
    http.request(request)
  }

  body = response.body.encode!("UTF-8", invalid: :replace, undef: :replace)

  {
    code: response.code,
    body: body
  }
end
