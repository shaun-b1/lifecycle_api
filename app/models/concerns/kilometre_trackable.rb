module KilometreTrackable
  extend ActiveSupport::Concern

  included do
    has_many :kilometre_logs, as: :trackable, dependent: :destroy
    after_save :log_kilometre_changes, if: -> { saved_change_to_kilometres? || maintenance_mode }
    attr_accessor :pending_notes
    attr_accessor :maintenance_mode
  end

  def add_kilometres(amount, notes = nil)
    return false if amount <= 0

    self.pending_notes = notes
    self.kilometres = (kilometres || 0) + amount
    save
  end

  def record_maintenance(notes = nil)
    self.pending_notes = notes || "Maintenance performed"
    self.maintenance_mode = true
    self.kilometres = 0
    save
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
    old_value, new_value = extract_kilometre_values
    return if should_skip_logging?(old_value, new_value)

    event_type = maintenance_mode ? "maintenance" : determine_kilometre_event_type(old_value, new_value)
    notes_text = pending_notes || default_notes_for(event_type, old_value, new_value)

    create_kilometre_log(event_type, old_value, new_value, notes_text)
    reset_tracking_flags
  end

  def extract_kilometre_values
    if maintenance_mode && !saved_change_to_kilometres?
      [kilometres, kilometres]
    else
      old_value, new_value = saved_change_to_kilometres
      [(old_value || 0), (new_value || 0)]
    end
  end

  def duplicate_recent_log?(last_log, old_value, new_value)
    return false unless last_log
    return false if maintenance_mode

    last_log.created_at > 1.second.ago &&
      last_log.previous_value == old_value &&
      last_log.new_value == new_value &&
      last_log.event_type == determine_kilometre_event_type(old_value, new_value)
  end

  def should_skip_logging?(old_value, new_value)
    return true if old_value == new_value && !maintenance_mode
    duplicate_recent_log?(kilometre_logs.last, old_value, new_value)
  end

  def create_kilometre_log(event_type, old_value, new_value, notes)
    kilometre_logs.create(
      event_type: event_type,
      previous_value: old_value || 0,
      new_value: new_value || 0,
      notes: notes
    )
  end

  def reset_tracking_flags
    self.maintenance_mode = false
    self.pending_notes = nil
  end

  def determine_kilometre_event_type(old_value, new_value)
    old_val = old_value&.to_f || 0.0
    new_val = new_value&.to_f || 0.0

    if new_val > old_val
      "increase"
    else
      Rails.logger.warn "Unexpected kilometre change: #{old_val} → #{new_val}"
      "increase"
    end
  end

  def default_notes_for(event_type, old_value, new_value)
    "Kilometres #{event_type}d from #{old_value || 0} to #{new_value || 0}"
  end
end
