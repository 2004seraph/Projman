# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

Sentry.init do |config|
  # Sentry is only enabled when the dsn is set.
  unless Rails.env.development? || Rails.env.test?
    config.dsn = "https://a55e1df80af680daea87ab985049fad3@sentry.shefcompsci.org.uk/402"
  end
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.before_send = lambda { |event, _hint|
    ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(event.to_hash)
  }
  config.excluded_exceptions += [
    "ActionController::BadRequest",
    "ActionController::UnknownFormat",
    "ActionController::UnknownHttpMethod",
    "ActionDispatch::Http::MimeNegotiation::InvalidType",
    "CanCan::AccessDenied",
    "Mime::Type::InvalidMimeType",
    "Rack::QueryParser::InvalidParameterError",
    "Rack::QueryParser::ParameterTypeError",
    "SystemExit",
    "URI::InvalidURIError"
  ]
end
