module KilometreTrackable
  extend ActiveSupport::Concern

  included do
    has_many :kilometre_logs, as: :trackable, dependent: :destroy
    after_save :log_kilometre_changes, if: :saved_change_to_kilometres?
  end

  def add_kilometres(amount, notes = nil)
    return false if amount <= 0

    self.kilometres = (kilometres || 0) + amount
    saved = save

    if saved
      kilometre_logs.create(
        event_type: "increase",
        previous_value: kilometres - amount,
        new_value: kilometres,
        notes: notes || "Added #{amount} km"
      )
    end
    saved
  end

  def record_maintenance(notes = nil)
    old_value = kilometres

    self.kilometres = 0
    saved = save

    if saved
      kilometre_logs.create(
        event_type: "maintenance",
        previous_value: old_value,
        new_value: 0,
        notes: notes || "Maintenance performed"
      )
    end

    saved
  end

  def lifetime_kilometres
    kilometre_logs.rides.sum("new_value - previous_value")
  end

  def maintenance_history
    kilometre_logs.maintenance.order(created_at: :desc)
  end

  def last_maintenance_date
    kilometre_logs.maintenance.order(created_at: :desc).first&.created_at
  end

  private

  def log_kilometre_changes
    return unless saved_change_to_kilometres?

    old_value, new_value = saved_change_to_kilometres
    return if old_value == new_value

    last_log = kilometre_logs.order(created_at: :desc).first
    return if last_log && last_log.created_at > 1.second.ago && last_log.previous_value == old_value && last_log.new_value == new_value

    event_type = if new_value == 0 && old_value && old_value > 0
      "reset"
    elsif new_value > (old_value || 0)
      "increase"
    else
      "decrease"
    end

    kilometre_logs.create(
      event_type: event_type,
      previous_value: old_value || 0,
      new_value: new_value || 0,
      notes: "Kilometres #{event_type}d from #{old_value || 0} to #{new_value || 0}"
    )
  end
end
