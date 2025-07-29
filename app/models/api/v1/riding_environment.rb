class Api::V1::RidingEnvironment
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :terrain, :string
  attribute :weather, :string
  attribute :particulate, :string

  validates :terrain, inclusion: { in: %w[flat hilly mountainous], allow_nil: true }
  validates :weather, inclusion: { in: %w[dry mixed wet], allow_nil: true }
  validates :particulate, inclusion: { in: %w[low medium high], allow_nil: true }

  def terrain_description
    case terrain
    when "flat" then "Flat terrain"
    when "hilly" then "Hilly terrain"
    when "mountainous" then "Mountainous terrain"
    else "Unknown terrain"
    end
  end

  def weather_description
    case weather
    when "dry" then "Dry conditions"
    when "mixed" then "Mixed weather conditions"
    when "wet" then "Wet conditions"
    else "Unknown weather conditions"
    end
  end

  def particulate_description
    case particulate
    when "low" then "Low particulate"
    when "medium" then "Medium particulate"
    when "high" then "High particulate"
    else "Unknown particulate level"
    end
  end

  def to_hash
    {
      terrain: terrain_description,
      weather: weather_description,
      particulate: particulate_description
    }
  end
end