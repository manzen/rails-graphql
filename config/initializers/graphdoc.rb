GraphdocRuby.configure do |config|
  config.schema_name = 'RailsGraphqlSchema'
  config.endpoint = Rails.root.join('tmp', 'graphql', 'schema.json')
  config.output_directory = Rails.root.join('tmp', 'graphdoc')
end