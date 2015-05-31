Rails.application.config.middleware.use OmniAuth::Builder do
#  provider :facebook, ENV["FACEBOOK_ID"], ENV["FACEBOOK_SECRET"]
  provider :google_oauth2, ENV["GOOGLE_ID"], ENV["GOOGLE_SECRET"]
  provider :khan_academy, 'rsGM6MKBBMGeTy9d', 'T6WEf7x9D3a5TPQL'
end