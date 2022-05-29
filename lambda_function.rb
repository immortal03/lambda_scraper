require 'net/http'

def lambda_handler(event:, context:)
  # Options within event
  # event = {
  #   "url" => "https://www.google.com",
  #   "mobile" => true
  # }
  url = event.dig("url")
  is_mobile = event.dig("mobile") || false
  return { code: "400", message: "URL is required" } if url.nil?

  # Begin rescue block to handle invalid URLs
  begin
    response = fetch(url, mobile: is_mobile) # Begin initial fetch
  rescue => e
    return { code: "400", message: e.message }
  end

  redirection_limit = 10 # Number of redirects allowed
  is_redirection = response.code == "302"

  while is_redirection && redirection_limit.positive?
    redirection_limit -= 1 # Decrement redirection limit
    response = fetch(response["location"], mobile: is_mobile) # Fetch redirection url until limit is reached
    is_redirection = response.code == "302"
  end

  response_code = response.code
  # body = response.body.encode!("UTF-8", invalid: :replace, undef: :replace)
  body = response.body.force_encoding("UTF-8")

  if !redirection_limit.positive? && response_code == "302"
    response_code = "400" # Set to 400 if redirection limit is reached
  end

  {
    code: response_code,
    body: body
  }
end

def fetch(url, mobile: false)
  uri = URI(url)
  request = Net::HTTP::Get.new(uri)

  # Set headers
  if mobile
    request["User-Agent"] = "Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.41 Mobile Safari/537.36"
  end

  # Response body might contain content of other encoding than UTF-8
  Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http|
    http.request(request)
  }
end
