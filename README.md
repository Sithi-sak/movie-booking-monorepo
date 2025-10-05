# 🎬 SabayBook - Movie Booking System

A full-stack movie booking application built with **Node.js/Express** backend and **Flutter** frontend. This monorepo contains both the backend API and the mobile application for a complete movie ticket booking experience.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [API Documentation](#api-documentation)
- [Database Schema](#database-schema)
- [Environment Variables](#environment-variables)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

SabayBook is a modern movie booking platform that allows users to browse movies, check showtimes, select seats, and book tickets seamlessly. The application features a RESTful API backend with PostgreSQL database and a beautiful Flutter mobile app with a dark theme UI.

## ✨ Features

### User Features
- 🔐 **User Authentication** - Secure registration and login with JWT tokens
- 🎥 **Movie Browsing** - Browse streaming now and coming soon movies
- 🔍 **Search & Filter** - Search movies by title, genre, and status
- 📅 **Showtime Management** - View available showtimes across different theaters
- 💺 **Seat Selection** - Interactive seat selection interface
- 🎫 **Booking Management** - Create and view booking history
- 👤 **User Profile** - Manage user account and preferences
- 🎬 **Trailer Viewing** - Watch movie trailers with YouTube integration
- 📱 **Responsive UI** - Beautiful dark-themed mobile interface

## 🛠 Tech Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js (v5.1.0)
- **Database**: PostgreSQL
- **ORM**: Prisma (v6.16.3)
- **Authentication**: JWT (jsonwebtoken)
- **Password Hashing**: bcryptjs
- **Validation**: Joi
- **API Integration**: Axios (TMDB API)
- **Development**: ESLint, Morgan (logging)

### Frontend
- **Framework**: Flutter (SDK ^3.8.1)
- **Language**: Dart
- **State Management**: Flutter Controllers
- **HTTP Client**: http package
- **Local Storage**: shared_preferences
- **UI Components**:
  - carousel_slider - Movie carousels
  - youtube_player_flutter - Trailer playback
  - lottie - Animations

## 📁 Project Structure

```
movie-booking-monorepo/
├── backend/                    # Node.js Express API
│   ├── prisma/
│   │   ├── schema.prisma      # Database schema
│   │   ├── migrations/        # Database migrations
│   │   ├── seed.js           # Database seeder
│   │   └── add-upcoming-movies.js
│   ├── src/
│   │   ├── controllers/       # Business logic
│   │   │   ├── auth.controller.js
│   │   │   ├── movies.controller.js
│   │   │   ├── showtimes.controller.js
│   │   │   ├── bookings.controller.js
│   │   │   ├── seats.controller.js
│   │   │   ├── tickets.controller.js
│   │   │   └── payment.controller.js
│   │   ├── routes/           # API routes
│   │   │   ├── auth.routes.js
│   │   │   ├── movies.routes.js
│   │   │   ├── showtimes.routes.js
│   │   │   ├── bookings.routes.js
│   │   │   ├── tickets.routes.js
│   │   │   └── user.routes.js
│   │   ├── middlewares/      # Custom middleware
│   │   │   └── auth.middleware.js
│   │   ├── utils/            # Helper functions
│   │   └── config/           # Configuration files
│   ├── app.js                # Express app entry point
│   ├── package.json
│   └── .env                  # Environment variables
│
└── frontend/                 # Flutter mobile app
    ├── lib/
    │   ├── core/
    │   │   └── theme/        # App theme configuration
    │   ├── data/
    │   │   ├── models/       # Data models
    │   │   │   ├── movie_model.dart
    │   │   │   ├── showtime_model.dart
    │   │   │   ├── booking_model.dart
    │   │   │   ├── seat_model.dart
    │   │   │   └── ticket_model.dart
    │   │   └── developer_data.dart
    │   ├── services/         # API services
    │   │   ├── api_service.dart
    │   │   ├── auth_service.dart
    │   │   ├── movie_service.dart
    │   │   └── booking_service.dart
    │   ├── controllers/      # UI controllers
    │   │   └── screen_controller.dart
    │   ├── presentation/     # UI screens
    │   │   ├── auth/         # Authentication screens
    │   │   ├── screens/
    │   │   │   ├── home/     # Home screen
    │   │   │   ├── movie_detail/
    │   │   │   ├── booking/  # Seat selection & booking
    │   │   │   ├── profile/  # User profile
    │   │   │   ├── trailer/  # Trailer viewing
    │   │   │   └── about/    # About page
    │   │   └── widgets/      # Reusable widgets
    │   └── main.dart         # App entry point
    ├── assets/
    │   ├── animation/        # Lottie animations
    │   └── developer_pf/     # Developer profiles
    ├── pubspec.yaml
    └── README.md
```

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (v16 or higher)
- **npm** or **yarn**
- **PostgreSQL** (v12 or higher)
- **Flutter SDK** (v3.8.1 or higher)
- **Dart SDK** (included with Flutter)
- **Git**

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd movie-booking-monorepo/backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**

   Create a `.env` file in the `backend` directory:
   ```env
   # Database Configuration
   DATABASE_URL="postgresql://username:password@localhost:5432/moviebooking?schema=public"

   # Server Configuration
   PORT=3000
   NODE_ENV=development

   # JWT Configuration
   JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
   JWT_EXPIRES_IN=7d

   # TMDB API (for movie data)
   TMDB_API_KEY=your-tmdb-api-key
   ```

4. **Setup PostgreSQL database**
   ```bash
   # Create database
   createdb moviebooking

   # Or using PostgreSQL CLI
   psql -U postgres
   CREATE DATABASE moviebooking;
   ```

5. **Run Prisma migrations**
   ```bash
   npx prisma migrate dev
   ```

6. **Seed the database** (optional)
   ```bash
   npm run prisma db seed
   ```

7. **Start the development server**
   ```bash
   npm run dev
   ```

   The API will be available at `http://localhost:3000`

8. **Verify installation**
   ```bash
   curl http://localhost:3000
   ```
   You should see:
   ```json
   {
     "message": "Welcome to the Movie Booking API!",
     "version": "1.0.0",
     "status": "running"
   }
   ```

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd ../frontend
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**

   Update the API base URL in [lib/services/api_service.dart](frontend/lib/services/api_service.dart):
   ```dart
   static const String baseUrl = 'http://localhost:3000/api';
   // For Android emulator: 'http://10.0.2.2:3000/api'
   // For iOS simulator: 'http://localhost:3000/api'
   // For physical device: 'http://YOUR_LOCAL_IP:3000/api'
   ```

4. **Run the app**
   ```bash
   # Check connected devices
   flutter devices

   # Run on specific device
   flutter run -d <device-id>

   # Or run on Chrome (web)
   flutter run -d chrome
   ```

5. **Build for production**
   ```bash
   # Android
   flutter build apk

   # iOS
   flutter build ios

   # Web
   flutter build web
   ```

## 📡 API Documentation

### Base URL
```
http://localhost:3000/api
```

### Authentication Endpoints

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "phone": "1234567890"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### Get Profile
```http
GET /api/auth/me
Authorization: Bearer <token>
```

### Movie Endpoints

#### Get All Movies
```http
GET /api/movies?status=streaming_now&genre=Action&search=inception
```

#### Get Movie by ID
```http
GET /api/movies/:id
```

#### Get Movies by Status
```http
GET /api/movies/status/:status
```
Status values: `streaming_now` | `coming_soon`

### Showtime Endpoints

#### Get Showtimes for Movie
```http
GET /api/showtimes/movie/:movieId
```

#### Get Available Seats
```http
GET /api/showtimes/:showtimeId/seats
```

### Booking Endpoints

#### Create Booking
```http
POST /api/bookings
Authorization: Bearer <token>
Content-Type: application/json

{
  "showtimeId": 1,
  "seatIds": [1, 2, 3]
}
```

#### Get User Bookings
```http
GET /api/bookings
Authorization: Bearer <token>
```

#### Get Booking by Reference
```http
GET /api/bookings/:reference
Authorization: Bearer <token>
```

### Ticket Endpoints

#### Get User Tickets
```http
GET /api/tickets
Authorization: Bearer <token>
```

## 🗄 Database Schema

### Core Models

- **User** - User accounts and authentication
- **Movie** - Movie information (title, genre, cast, etc.)
- **Theater** - Theater locations and details
- **Showtime** - Movie showtimes at theaters
- **Seat** - Theater seat configuration
- **Booking** - User ticket bookings
- **BookingSeat** - Junction table for bookings and seats

### Key Relationships

- User has many Bookings
- Movie has many Showtimes
- Theater has many Showtimes and Seats
- Showtime belongs to Movie and Theater
- Booking belongs to User and Showtime
- BookingSeat connects Booking and Seat

For detailed schema, see [backend/prisma/schema.prisma](backend/prisma/schema.prisma)

## 🔐 Environment Variables

### Backend (.env)

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection string | Yes |
| `PORT` | Server port (default: 3000) | No |
| `NODE_ENV` | Environment (development/production) | No |
| `JWT_SECRET` | Secret key for JWT tokens | Yes |
| `JWT_EXPIRES_IN` | Token expiration time | No |
| `TMDB_API_KEY` | The Movie Database API key | Optional |

### Frontend

Configure API endpoints in the service files:
- [lib/services/api_service.dart](frontend/lib/services/api_service.dart)

## 💻 Development

### Backend Development

```bash
# Start development server with auto-reload
npm run dev

# Run production server
npm start

# Generate Prisma client
npx prisma generate

# Create new migration
npx prisma migrate dev --name migration_name

# Open Prisma Studio (Database GUI)
npx prisma studio

# Run linter
npm run lint
```

### Frontend Development

```bash
# Run in debug mode
flutter run

# Run with hot reload
flutter run --hot

# Format code
flutter format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Clear build cache
flutter clean
```

### Prisma Commands

```bash
# Reset database (WARNING: deletes all data)
npx prisma migrate reset

# Deploy migrations to production
npx prisma migrate deploy

# Pull schema from existing database
npx prisma db pull

# Push schema without migrations
npx prisma db push
```

## 🎨 Features in Detail

### Authentication System
- JWT-based authentication
- Secure password hashing with bcryptjs
- Protected routes with middleware
- Token expiration and refresh

### Movie Management
- Integration with TMDB API for movie data
- Support for streaming now and coming soon movies
- Movie search and filtering by genre
- Rich movie details (cast, director, trailer, etc.)

### Booking System
- Real-time seat availability
- Interactive seat selection UI
- Booking reference generation
- Payment status tracking
- Booking history for users

### Seat Management
- Flexible seat configuration per theater
- Support for different seat types (regular, premium, VIP)
- Seat hold mechanism during booking
- Row and column-based seat layout

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Copyright (c) 2025 Sithisak**

## 👥 Authors

- **Leak Sithisak** - [@github](https://github.com/Sithi-sak)
- **Song Kimvisal** - [@github](https://github.com/songKimvisal)
- **Sim Kimchhun** - [@github](https://github.com/kimchhunnn2912)

## 🙏 Acknowledgments

- [The Movie Database (TMDB)](https://www.themoviedb.org/) for movie data API
- [Prisma](https://www.prisma.io/) for the excellent ORM
- [Flutter](https://flutter.dev/) for the amazing cross-platform framework

---

**Made with ❤️ using Node.js, Express, PostgreSQL, and Flutter**
