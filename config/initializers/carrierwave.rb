CarrierWave.configure do |config|
  config.storage = :file
  config.asset_host = Rails.configuration.base_url
  # config.asset_host = "http://54.191.253.112"
end
