require 'rails_helper'

RSpec.describe KilometreTrackable do
  let(:trackable) { create(:bicycle, kilometres: 100) }

  describe "when included" do
    it "adds kilometre_logs association" do
      association = trackable.class.reflect_on_association(:kilometre_logs)
      expect(association.options[:as]).to eq(:trackable)
      expect(association.options[:dependent]).to eq(:destroy)

      log = trackable.kilometre_logs.create!(
        event_type: 'increase',
        previous_value: trackable.kilometres,
        new_value: trackable.kilometres + 50,
        notes: 'Test log'
      )

      expect(log.trackable).to eq(trackable)
      expect(log.trackable_type).to eq(trackable.class.name)
      expect(trackable.kilometre_logs).to include(log)
    end

    it "adds after_save callback for log_kilometre_changes" do
      initial_log_count = trackable.kilometre_logs.count

      trackable.update(brand: "Colnago")
      expect(trackable.kilometre_logs.count).to eq(initial_log_count)

      trackable.update(kilometres: 150)
      expect(trackable.kilometre_logs.count).to eq(initial_log_count + 1)
    end
  end

  describe "#add_kilometres" do
    it "increases kilometres and creates increase log" do
      result = nil

      expect {
        result = trackable.add_kilometres(50, "Test ride")
      }.to change { trackable.reload.kilometres }.from(100).to(150)
      .and change { trackable.kilometre_logs.count }.by(1)

      latest_log = trackable.kilometre_logs.last
      expect(latest_log).to have_attributes(
        event_type: "increase",
        previous_value: 100,
        new_value: 150,
        notes: "Test ride"
      )

      expect(result).to be true
    end

    it "handles nil starting kilometres" do
      trackable.update_column(:kilometres, nil)
      result = nil

      expect {
        result = trackable.add_kilometres(25, "Nil ride")
      }.to change { trackable.reload.kilometres }.from(nil).to(25)

      latest_log = trackable.kilometre_logs.last
      expect(latest_log).to have_attributes(
        event_type: "increase",
        previous_value: 0.0,
        new_value: 25.0,
        notes: "Nil ride"
        )

      expect(result).to be true
    end

    it "rejects negative amounts" do
      initial_kilometres = trackable.kilometres
      initial_log_count = trackable.kilometre_logs.count

      result = trackable.add_kilometres(-10, "Backwards ride")

      expect(trackable.reload.kilometres).to eq(initial_kilometres)
      expect(trackable.kilometre_logs.count).to eq(initial_log_count)
      expect(result).to be false
    end

    it "rejects zero amounts" do
      initial_kilometres = trackable.kilometres
      initial_log_count = trackable.kilometre_logs.count

      result = trackable.add_kilometres(0, "Did you even ride?")

      expect(trackable.reload.kilometres).to eq(initial_kilometres)
      expect(trackable.kilometre_logs.count).to eq(initial_log_count)
      expect(result).to be false
    end

    it "sets pending_notes for logging" do
      expect(trackable.pending_notes).to be_nil

      trackable.add_kilometres(25, "Custom notes")

      expect(trackable.pending_notes).to be_nil

      latest_log = trackable.kilometre_logs.last
      expect(latest_log).to have_attributes(
        event_type: "increase",
        previous_value: 100.0,
        new_value: 125.0,
        notes: "Custom notes"
      )
    end

    it "uses default notes when none provided" do
      expect(trackable.pending_notes).to be_nil

      trackable.add_kilometres(30)

      expect(trackable.pending_notes).to be_nil

      latest_log = trackable.kilometre_logs.last
      expect(latest_log).to have_attributes(
        event_type: "increase",
        previous_value: 100.0,
        new_value: 130.0,
        notes: "Kilometres increased from 100.0 to 130.0"
      )
    end

    it "handles save failures gracefully" do
      allow(trackable).to receive(:save).and_return(false)
      initial_kilometres = trackable.reload.kilometres
      initial_log_count = trackable.kilometre_logs.count

      result = trackable.add_kilometres(50)

      expect(result).to be false
      expect(trackable.kilometres).to eq(150)
      expect(trackable.reload.kilometres).to eq(initial_kilometres)
      expect(trackable.kilometre_logs.count).to eq(initial_log_count)
    end
  end

  describe "#record_maintenance" do
    it "resets kilometres to zero and creates maintenance log" do
      expect {
        result = trackable.record_maintenance("Regular service")
        expect(result).to be true
      }. to change { trackable.reload.kilometres }.from(100).to(0)
      .and change { trackable.kilometre_logs.count }.by(1)

      latest_log = trackable.kilometre_logs.last
      expect(latest_log).to have_attributes(
        event_type: "maintenance",
        previous_value: 100,
        new_value: 0,
        notes: "Regular service"
      )
    end

    it "handles save failures" do
      allow(trackable).to receive(:save).and_return(false)
      initial_kilometres = trackable.reload.kilometres
      initial_log_count = trackable.kilometre_logs.count

      result = trackable.record_maintenance("Service")

      expect(result).to be false
      expect(trackable.reload.kilometres).to eq(initial_kilometres)
      expect(trackable.kilometre_logs.count).to eq(initial_log_count)
    end

    it "uses default notes when none provided" do
      expect {
        result = trackable.record_maintenance
        expect(result).to be true
      }.to change { trackable.kilometre_logs.count }.by(1)

      latest_log = trackable.kilometre_logs.last
      expect(latest_log).to have_attributes(
        event_type: "maintenance",
        previous_value: 100,
        new_value: 0,
        notes: "Maintenance performed"
      )
    end

    it "handles zero starting kilometres" do
      trackable.update(kilometres: 0)

      expect {
        result = trackable.record_maintenance("Service")
        expect(result).to be true
      }.to change { trackable.kilometre_logs.count }.by(1)

      latest_log = trackable.kilometre_logs.last
      expect(latest_log).to have_attributes(
        previous_value: 0,
        new_value: 0
      )
    end
  end

  describe "#lifetime_kilometres" do
    it "sums all ride kilometres correctly" do
      trackable.add_kilometres(50.0)
      trackable.record_maintenance
      trackable.add_kilometres(30.0)
      trackable.record_maintenance
      trackable.add_kilometres(20.0)

      expect(trackable.lifetime_kilometres).to eq(200.0)

      expect(trackable.kilometre_logs.maintenance.count).to eq(2)
      expect(trackable.kilometre_logs.rides.count).to eq(4)
    end

    it "handles no ride logs" do
      trackable = create(:bicycle)

      expect(trackable.kilometre_logs.rides).to be_empty
      expect(trackable.lifetime_kilometres).to eq(0)
    end
  end

  describe "#maintenance_history" do
  it "returns maintenance logs ordered by date desc" do
    oldest_log = travel_to(3.days.ago) do
      trackable.record_maintenance("Old service")
      trackable.kilometre_logs.maintenance.last
    end

    middle_log = travel_to(1.day.ago) do
      trackable.record_maintenance("Recent service")
      trackable.kilometre_logs.maintenance.last
    end

    trackable.add_kilometres(50.0, "Ride between maintenance")

    newest_log = travel_to(Time.current) do
      trackable.record_maintenance("Latest service")
      trackable.kilometre_logs.maintenance.last
    end

    history = trackable.maintenance_history

    expect(history).to contain_exactly(newest_log, middle_log, oldest_log)
    expect(history.first).to eq(newest_log)
    expect(history.last).to eq(oldest_log)
    expect(history.map(&:event_type)).to all(eq("maintenance"))
  end

    it "returns empty when no maintenance logs" do
      trackable.add_kilometres(50)
      trackable.add_kilometres(30)
      trackable.add_kilometres(20)

      expect(trackable.kilometre_logs.count).to be > 0
      expect(trackable.maintenance_history).to be_empty
    end
  end

  describe "#last_maintenance_date" do
    it "returns date of most recent maintenance" do
      travel_to(1.month.ago) do
        trackable.record_maintenance("Old service")
        trackable.kilometre_logs.maintenance.last
      end

      travel_to(1.week.ago) do
        trackable.record_maintenance("Recent service")
        trackable.kilometre_logs.maintenance.last
      end

      some_time = 2.days.ago

      travel_to(some_time) do
        trackable.record_maintenance("Latest service")
        trackable.kilometre_logs.maintenance.last
      end

      expect(trackable.kilometre_logs.maintenance.count).to eq(3)
      expect(trackable.last_maintenance_date).to be_within(1.second).of(some_time)
    end

    it "returns nil when no maintenance performed" do
      trackable.add_kilometres(50)
      trackable.add_kilometres(30)
      trackable.add_kilometres(20)

      expect(trackable.kilometre_logs.count).to be > 0
      expect(trackable.last_maintenance_date).to be_nil
    end
  end

  describe "integration with multiple models" do
    it "works with Bicycle model" do
      # bicycle = create bicycle with concern
      bicycle = create(:bicycle)
      expect(bicycle.kilometre_logs).to be_empty
      expect(bicycle.maintenance_logs)
      # test basic functionality on bicycle
      bicycle.add_kilometres
      skip ("Waiting for the planets to align")
    end

    it "works with Component models" do
      # chain = create chain with concern
      # test basic functionality on chain
      skip ("Waiting for the planets to align")
    end

    it "maintains separate logs per trackable" do
      # bicycle and chain both include concern
      # add kilometres to both

      # expect each has separate kilometre_logs
      # expect no cross-contamination
      skip ("Waiting for the planets to align")
    end
  end

  describe "edge cases" do
    it "handles very large kilometre values" do
      # add_kilometres(999999.99)

      # expect handles correctly without overflow
      skip ("Waiting for the planets to align")
    end

    it "handles decimal kilometre values" do
      # add_kilometres(10.5)

      # expect precise decimal handling
      skip ("Waiting for the planets to align")
    end

    it "handles concurrent updates gracefully" do
      # simulate concurrent kilometres updates

      # expect no data corruption or duplicate logs
      skip ("Waiting for the planets to align")
    end
  end
end
