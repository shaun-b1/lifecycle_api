module KilometreTrackable
  extend ActiveSupport::Concern

  included do
    has_many :kilometre_logs, as: :trackable, dependent: :destroy
    after_save :log_kilometre_changes, if: :saved_change_to_kilometres?
    attr_accessor :pending_notes
  end

  def add_kilometres(amount, notes = nil)
    return false if amount <= 0

    self.pending_notes = notes
    self.kilometres = (kilometres || 0) + amount
    saved = save
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

    notes_text = pending_notes || "Kilometres #{event_type}d from #{old_value || 0} to #{new_value || 0}"

    kilometre_logs.create(
      event_type: event_type,
      previous_value: old_value || 0,
      new_value: new_value || 0,
      notes: notes_text
    )

    self.pending_notes = nil
  end
end
