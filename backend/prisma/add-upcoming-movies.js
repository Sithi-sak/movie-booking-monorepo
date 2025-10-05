import { PrismaClient } from '../generated/prisma/index.js';
import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();

const TMDB_API_KEY = process.env.TMDB_API_KEY;
const TMDB_BASE_URL = 'https://api.themoviedb.org/3';
const TMDB_IMAGE_BASE_URL = 'https://image.tmdb.org/t/p/w500';

// Fetch upcoming movies from TMDB
async function fetchUpcomingMovies() {
  try {
    const response = await axios.get(`${TMDB_BASE_URL}/movie/upcoming`, {
      params: {
        api_key: TMDB_API_KEY,
        language: 'en-US',
        page: 1,
      },
    });

    // Get top 10 upcoming movies
    const movies = response.data.results.slice(0, 10);

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
          status: 'coming_soon', // Force coming_soon status
        };
      })
    );

    return detailedMovies;
  } catch (error) {
    console.error('Error fetching upcoming movies from TMDB:', error.message);
    throw error;
  }
}

// Helper function to determine rating from TMDB data
function getRating(movieDetails) {
  if (movieDetails.adult) return 'R';
  if (movieDetails.vote_average >= 7) return 'PG-13';
  return 'PG';
}

// Main function
async function main() {
  console.log('🌱 Adding upcoming movies to database...');

  // Fetch upcoming movies from TMDB
  console.log('🎬 Fetching upcoming movies from TMDB...');
  const upcomingMovies = await fetchUpcomingMovies();

  // Create movies with coming_soon status
  console.log('📽️  Creating upcoming movies in database...');
  const movies = await Promise.all(
    upcomingMovies.map((movie) => prisma.movie.create({ data: movie }))
  );
  console.log(`✅ Added ${movies.length} upcoming movies`);

  console.log('🎉 Successfully added upcoming movies!');
}

main()
  .catch((e) => {
    console.error('❌ Error adding upcoming movies:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
