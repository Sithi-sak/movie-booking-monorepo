import { PrismaClient } from '../../generated/prisma/index.js';

const prisma = new PrismaClient();

/**
 * Get all movies with optional filtering
 * GET /api/movies?status=streaming_now&genre=Action
 */
export const getAllMovies = async (req, res) => {
  try {
    const { status, genre, search } = req.query;

    const where = {
      isActive: true,
    };

    // Filter by status (streaming_now or coming_soon)
    if (status) {
      where.status = status;
    }

    // Filter by genre
    if (genre) {
      where.genre = {
        contains: genre,
      };
    }

    // Search by title
    if (search) {
      where.title = {
        contains: search,
        mode: 'insensitive',
      };
    }

    // Fetch movies from database
    const movies = await prisma.movie.findMany({
      where,
      orderBy: {
        releaseDate: 'desc',
      },
      include: {
        showtimes: {
          where: {
            isActive: true,
            showTime: {
              gte: new Date(),
            },
          },
          select: {
            id: true,
            showTime: true,
            price: true,
            availableSeats: true,
            theater: {
              select: {
                id: true,
                name: true,
                city: true,
              },
            },
          },
          take: 5,
        },
      },
    });

    const moviesWithShowtimes = movies.map((movie) => ({
      ...movie,
      showtimes: movie.showtimes.map((showtime) =>
        showtime.showTime.toISOString()
      ),
      showtimesDetails: movie.showtimes,
    }));

    res.status(200).json({
      success: true,
      count: moviesWithShowtimes.length,
      data: {
        movies: moviesWithShowtimes,
      },
    });
  } catch (error) {
    console.error('Get all movies error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching movies',
    });
  }
};

/**
 * Get a single movie by ID
 * GET /api/movies/:id
 */
export const getMovieById = async (req, res) => {
  try {
    const { id } = req.params;

    const movie = await prisma.movie.findUnique({
      where: {
        id: parseInt(id),
      },
      include: {
        showtimes: {
          where: {
            isActive: true,
            showTime: {
              gte: new Date(),
            },
          },
          include: {
            theater: {
              select: {
                id: true,
                name: true,
                address: true,
                city: true,
                state: true,
                phone: true,
              },
            },
          },
          orderBy: {
            showTime: 'asc',
          },
        },
      },
    });

    if (!movie) {
      return res.status(404).json({
        success: false,
        message: 'Movie not found',
      });
    }

    // Transform showtimes for frontend
    const movieWithShowtimes = {
      ...movie,
      showtimes: movie.showtimes.map((showtime) =>
        showtime.showTime.toISOString()
      ),
      showtimesDetails: movie.showtimes,
    };

    res.status(200).json({
      success: true,
      data: {
        movie: movieWithShowtimes,
      },
    });
  } catch (error) {
    console.error('Get movie by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching movie details',
    });
  }
};

/**
 * Get movies by status (streaming_now or coming_soon)
 * GET /api/movies/status/:status
 */
export const getMoviesByStatus = async (req, res) => {
  try {
    const { status } = req.params;

    // Validate status
    if (!['streaming_now', 'coming_soon'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Use "streaming_now" or "coming_soon"',
      });
    }

    const movies = await prisma.movie.findMany({
      where: {
        status,
        isActive: true,
      },
      orderBy: {
        releaseDate: 'desc',
      },
      include: {
        showtimes: {
          where: {
            isActive: true,
            showTime: {
              gte: new Date(),
            },
          },
          select: {
            id: true,
            showTime: true,
            price: true,
            availableSeats: true,
            theater: {
              select: {
                id: true,
                name: true,
                city: true,
              },
            },
          },
          take: 3,
        },
      },
    });

    // Transform showtimes to match frontend expectations
    const moviesWithShowtimes = movies.map((movie) => ({
      ...movie,
      showtimes: movie.showtimes.map((showtime) =>
        showtime.showTime.toISOString()
      ),
      showtimesDetails: movie.showtimes,
    }));

    res.status(200).json({
      success: true,
      count: moviesWithShowtimes.length,
      data: {
        movies: moviesWithShowtimes,
      },
    });
  } catch (error) {
    console.error('Get movies by status error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching movies',
    });
  }
};