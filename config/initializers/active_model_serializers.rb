Rails.application.config.after_initialize do
  Dir[Rails.root.join("app", "serializers", "**", "*.rb")].each do |file|
    require_dependency file
  end
end
