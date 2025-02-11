# WearTest

WearTest is a Rails API designed to track the wear of bicycle components, helping cyclists monitor and manage the maintenance of their bikes.

## Features

- Component Management: Add, update, and delete bicycle components with comprehensive tracking of part details and specifications.

- Wear Tracking: Monitor the wear status of each component over time, including usage metrics and maintenance history.

- User Authentication: Secure user registration and login to manage personal bicycle data with JWT token-based authentication.

## Prerequisites

Before setting up the project, ensure you have the following installed:

- Ruby: Version 3.4.1
- Rails: Version 8.0.1
- PostgreSQL: Ensure the database service is running

## Installation

### Clone the Repository:

```bash
git clone https://github.com/shaun-b1/wear_test.git
cd wear_test
```

### Install Dependencies:

```bash
bundle install
```

### Configure the Database:

- Ensure PostgreSQL is running
- Set up the database configuration in config/database.yml if necessary

### Initialize the Database:

```bash
bin/rails db:create
bin/rails db:migrate
```

### Running the Application

To start the Rails server:

```bash
bin/rails server
```

The API will be accessible at http://localhost:3001.

## API Endpoints

The application provides the following API endpoints:

** Coming soon **

## Testing

To run the test suite:

```bash
bin/rails test
```

Ensure that the test database is prepared:

```bash
bin/rails db:test:prepare
```

## Deployment

For deployment instructions, please refer to the Rails Deployment Guide.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

**Note**: This README provides a general overview of the WearTest application. For detailed information, please refer to the project's documentation and source code.
