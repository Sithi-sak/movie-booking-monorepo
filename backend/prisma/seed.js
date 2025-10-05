import { PrismaClient } from '../generated/prisma/index.js';
import axios from 'axios';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();

const TMDB_API_KEY = process.env.TMDB_API_KEY;
const TMDB_BASE_URL = 'https://api.themoviedb.org/3';
const TMDB_IMAGE_BASE_URL = 'https://image.tmdb.org/t/p/w500';

// Fetch now playing movies from TMDB
async function fetchMoviesFromTMDB() {
  try {
    const response = await axios.get(`${TMDB_BASE_URL}/movie/now_playing`, {
      params: {
        api_key: TMDB_API_KEY,
        language: 'en-US',
        page: 1,
      },
    });

    // Get top 20 movies
    const movies = response.data.results.slice(0, 20);

    // Fetch additional details for each movie
    const detailedMovies = await Promise.all(
      movies.map(async (movie) => {
        const details = await axios.get(`${TMDB_BASE_URL}/movie/${movie.id}`, {
          params: {
            api_key: TMDB_API_KEY,
            append_to_response: 'credits,videos',
          },
        });

        const credits = details.data.credits;
        const director = credits.crew.find((person) => person.job === 'Director');
        const cast = credits.cast.slice(0, 10).map((actor) => actor.name);

        // Get trailer URL from videos
        const videos = details.data.videos?.results || [];
        const trailer = videos.find(
          (video) => video.type === 'Trailer' && video.site === 'YouTube'
        );
        const trailerUrl = trailer ? `https://www.youtube.com/watch?v=${trailer.key}` : null;

        return {
          title: movie.title,
          description: movie.overview,
          genre: details.data.genres.map((g) => g.name).join(', '),
          duration: details.data.runtime,
          rating: getRating(details.data),
          score: movie.vote_average,
          posterUrl: movie.poster_path ? `${TMDB_IMAGE_BASE_URL}${movie.poster_path}` : null,
          backdropUrl: movie.backdrop_path ? `${TMDB_IMAGE_BASE_URL}${movie.backdrop_path}` : null,
          trailerUrl: trailerUrl,
          language: details.data.original_language,
          director: director ? director.name : null,
          cast: cast,
          releaseDate: new Date(movie.release_date),
          status: new Date(movie.release_date) <= new Date() ? 'streaming_now' : 'coming_soon',
        };
      })
    );

    return detailedMovies;
  } catch (error) {
    console.error('Error fetching movies from TMDB:', error.message);
    throw error;
  }
}

// Helper function to determine rating from TMDB data
function getRating(movieDetails) {
  // TMDB doesn't provide certification directly in all regions
  // We'll use a simple mapping based on vote_average
  if (movieDetails.adult) return 'R';
  if (movieDetails.vote_average >= 7) return 'PG-13';
  return 'PG';
}

// Create theaters
async function createTheaters() {
  const theaters = [
    {
      name: 'CinemaXX Downtown',
      address: '123 Main Street',
      city: 'New York',
      state: 'NY',
      zipCode: '10001',
      phone: '(555) 123-4567',
      screens: 5,
    },
    {
      name: 'Mega Movies Complex',
      address: '456 Park Avenue',
      city: 'Los Angeles',
      state: 'CA',
      zipCode: '90001',
      phone: '(555) 987-6543',
      screens: 8,
    },
    {
      name: 'Star Cinema Plaza',
      address: '789 Lake Drive',
      city: 'Chicago',
      state: 'IL',
      zipCode: '60601',
      phone: '(555) 456-7890',
      screens: 6,
    },
  ];

  return await Promise.all(
    theaters.map((theater) => prisma.theater.create({ data: theater }))
  );
}

// Create seats for a theater screen
async function createSeatsForTheater(theaterId, screenNumber) {
  const rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
  const seatsPerRow = 12;
  const seats = [];

  for (const row of rows) {
    for (let col = 1; col <= seatsPerRow; col++) {
      // Premium seats in the middle rows (D, E, F)
      const seatType = ['D', 'E', 'F'].includes(row) && col >= 4 && col <= 9 ? 'premium' : 'regular';
      const price = seatType === 'premium' ? 15.0 : 10.0;

      seats.push({
        theaterId,
        screenNumber,
        seatNumber: `${row}${col}`,
        rowName: row,
        seatColumn: col,
        seatType,
        price,
      });
    }
  }

  await prisma.seat.createMany({ data: seats });
}

// Create showtimes for movies
async function createShowtimes(movies, theaters) {
  const showtimes = [];
  const today = new Date();

  for (const movie of movies) {
    // Only create showtimes for "streaming_now" movies
    if (movie.status === 'streaming_now') {
      // Create 3-5 showtimes per movie across different theaters
      const numShowtimes = Math.floor(Math.random() * 3) + 3;

      for (let i = 0; i < numShowtimes; i++) {
        const theater = theaters[Math.floor(Math.random() * theaters.length)];
        const screenNumber = Math.floor(Math.random() * theater.screens) + 1;
        const daysFromNow = Math.floor(Math.random() * 7);
        const hour = 10 + Math.floor(Math.random() * 10); // 10 AM to 8 PM

        const showTime = new Date(today);
        showTime.setDate(today.getDate() + daysFromNow);
        showTime.setHours(hour, 0, 0, 0);

        showtimes.push({
          movieId: movie.id,
          theaterId: theater.id,
          screenNumber,
          showTime,
          availableSeats: 96, // 8 rows × 12 seats
          totalSeats: 96,
          price: 12.0,
        });
      }
    }
  }

  await prisma.showtime.createMany({ data: showtimes });
}

// Main seed function
async function main() {
  console.log('🌱 Starting database seeding...');

  // Clear existing data
  console.log('🗑️  Clearing existing data...');
  await prisma.bookingSeat.deleteMany();
  await prisma.booking.deleteMany();
  await prisma.seat.deleteMany();
  await prisma.showtime.deleteMany();
  await prisma.movie.deleteMany();
  await prisma.theater.deleteMany();
  await prisma.user.deleteMany();

  // Fetch movies from TMDB
  console.log('🎬 Fetching movies from TMDB...');
  const tmdbMovies = await fetchMoviesFromTMDB();

  // Create movies
  console.log('📽️  Creating movies in database...');
  const movies = await Promise.all(
    tmdbMovies.map((movie) => prisma.movie.create({ data: movie }))
  );
  console.log(`✅ Created ${movies.length} movies`);

  // Create theaters
  console.log('🏢 Creating theaters...');
  const theaters = await createTheaters();
  console.log(`✅ Created ${theaters.length} theaters`);

  // Create seats for each theater screen
  console.log('💺 Creating seats...');
  for (const theater of theaters) {
    for (let screen = 1; screen <= theater.screens; screen++) {
      await createSeatsForTheater(theater.id, screen);
    }
  }
  const totalSeats = await prisma.seat.count();
  console.log(`✅ Created ${totalSeats} seats`);

  // Create showtimes
  console.log('⏰ Creating showtimes...');
  await createShowtimes(movies, theaters);
  const totalShowtimes = await prisma.showtime.count();
  console.log(`✅ Created ${totalShowtimes} showtimes`);

  // Create a test user
  console.log('👤 Creating test user...');
  const hashedPassword = await bcrypt.hash('password123', 10);
  await prisma.user.create({
    data: {
      email: 'test@example.com',
      password: hashedPassword,
      name: 'Test User',
      phone: '1234567890',
    },
  });
  console.log('✅ Created test user (email: test@example.com, password: password123)');

  console.log('🎉 Database seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });