User.destroy_all
Bicycle.destroy_all
Chain.destroy_all
Cassette.destroy_all
Chainring.destroy_all
Tire.destroy_all
Brakepad.destroy_all

users = [
  {
    name: "Shaun Macwilliam",
    email: "foo@bar.com",
    password: "password123",
    password_confirmation: "password123",
    bicycles: [
      {
        name: "Bike 1",
        brand: "Condor",
        model: "Super Accaiao",
        kilometres: 0,
        chain: { brand: "Campagnolo", kilometres: 0 },
        cassette: { brand: "Campagnolo", kilometres: 0 },
        chainring: { brand: "Campagnolo", kilometres: 0 },
        tires: [
          { brand: "Continental", kilometres: 0 },
          { brand: "Continental", kilometres: 0 }
        ],
        brakepads: [
          { brand: "Campagnolo", kilometres: 0 },
          { brand: "Campagnolo", kilometres: 0 }
        ]
      },
      {
        name: "Bike 2",
        brand: "Ritchey",
        model: "Swiss Cross",
        kilometres: 0
      }
    ]
  },
  {
    name: "Sasa Barnes",
    email: "bar@baz.com",
    password: "password123",
    password_confirmation: "password123",
    bicycles: [
      {
        name: "Bike 1",
        brand: "Cannondale",
        model: "Super Six",
        kilometres: 0
      }
    ]
  }
]

users.each do |user_data|
  user = User.create!(
    name: user_data[:name],
    email: user_data[:email],
    password: user_data[:password],
    password_confirmation: user_data[:password_confirmation]
  )

  next unless user_data[:bicycles] # Skip if no bicycles

  user_data[:bicycles].each do |bike_data|
    bike = user.bicycles.create!(
      name: bike_data[:name],
      brand: bike_data[:brand],
      model: bike_data[:model],
      kilometres: bike_data[:kilometres]
    )

    # Create individual components using their respective methods
    bike.create_chain(brand: bike_data.dig(:chain, :brand), kilometres: bike_data.dig(:chain, :kilometres)) if bike_data[:chain]
    bike.create_cassette(brand: bike_data.dig(:cassette, :brand), kilometres: bike_data.dig(:cassette, :kilometres)) if bike_data[:cassette]
    bike.create_chainring(brand: bike_data.dig(:chainring, :brand), kilometres: bike_data.dig(:chainring, :kilometres)) if bike_data[:chainring]

    # Create multiple tires and brakepads
    bike_data[:tires]&.each do |tire_data|
      bike.tires.create!(brand: tire_data[:brand], kilometres: tire_data[:kilometres])
    end

    bike_data[:brakepads]&.each do |brakepad_data|
      bike.brakepads.create!(brand: brakepad_data[:brand], kilometres: brakepad_data[:kilometres])
    end
  end
end

puts "Seeding complete! Created #{User.count} users, #{Bicycle.count} bicycles, #{Chain.count} chains, #{Cassette.count} cassettes, #{Chainring.count} chainrings, #{Tire.count} tires, and #{Brakepad.count} brakepads."
