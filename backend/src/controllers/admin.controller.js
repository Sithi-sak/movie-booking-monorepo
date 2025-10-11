import { PrismaClient } from '../../generated/prisma/index.js';
import { generateToken } from '../utils/jwt.js';

const prisma = new PrismaClient();

/**
 * Admin Login - Verify passcode
 * POST /api/admin/login
 */
export const adminLogin = async (req, res) => {
  try {
    const { password } = req.body;

    // Verify admin password from environment variable
    if (password !== process.env.ADMIN_PASSWORD) {
      return res.status(401).json({
        success: false,
        message: 'Invalid admin password',
      });
    }

    // Generate admin token
    const token = generateToken({ role: 'admin', id: 'admin' });

    res.status(200).json({
      success: true,
      message: 'Admin login successful',
      data: {
        token,
        role: 'admin',
      },
    });
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred during admin login',
    });
  }
};

/**
 * GET /api/admin/movies?status=streaming_now&search=Mantis
 */
export const getAllMovies = async (req, res) => {
  try {
    const { status, search, page = 1, limit = 30 } = req.query;

    const where = {};

    // Filter by status
    if (status && ['streaming_now', 'coming_soon'].includes(status)) {
      where.status = status;
    }

    // Search by title
    if (search) {
      where.title = {
        contains: search,
        mode: 'insensitive',
      };
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    // Fetch movies (including inactive ones for admin)
    const [movies, totalCount] = await Promise.all([
      prisma.movie.findMany({
        where,
        orderBy: {
          createdAt: 'desc',
        },
        skip,
        take,
        include: {
          showtimes: {
            where: {
              showTime: {
                gte: new Date(),
              },
            },
            select: {
              id: true,
              showTime: true,
              availableSeats: true,
              totalSeats: true,
            },
            take: 3,
          },
        },
      }),
      prisma.movie.count({ where }),
    ]);

    res.status(200).json({
      success: true,
      count: movies.length,
      totalCount,
      page: parseInt(page),
      totalPages: Math.ceil(totalCount / take),
      data: {
        movies,
      },
    });
  } catch (error) {
    console.error('Admin get all movies error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching movies',
    });
  }
};

/**
 * Get single movie by ID
 * GET /api/admin/movies/:id
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
          include: {
            theater: true,
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

    res.status(200).json({
      success: true,
      data: {
        movie,
      },
    });
  } catch (error) {
    console.error('Admin get movie by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching movie details',
    });
  }
};

/**
 * Create new movie
 * POST /api/admin/movies
 */
export const createMovie = async (req, res) => {
  try {
    const {
      title,
      description,
      genre,
      duration,
      rating,
      score,
      posterUrl,
      backdropUrl,
      trailerUrl,
      language,
      director,
      cast,
      releaseDate,
      status,
    } = req.body;

    // Validate required fields
    if (!title) {
      return res.status(400).json({
        success: false,
        message: 'Title is required',
      });
    }

    // Create movie
    const movie = await prisma.movie.create({
      data: {
        title,
        description,
        genre,
        duration: duration ? parseInt(duration) : null,
        rating,
        score: score ? parseFloat(score) : null,
        posterUrl,
        backdropUrl,
        trailerUrl,
        language,
        director,
        cast: cast || null,
        releaseDate: releaseDate ? new Date(releaseDate) : null,
        status: status || 'coming_soon',
        isActive: true,
      },
    });

    // Auto-create showtimes if movie is "streaming_now"
    if ((status || 'coming_soon') === 'streaming_now') {
      // Get first available theater
      const theater = await prisma.theater.findFirst({
        where: { isActive: true },
      });

      if (theater) {
        // Create showtimes for next 7 days at 2pm, 5pm, and 8pm
        const showtimesToCreate = [];
        const today = new Date();

        for (let day = 0; day < 7; day++) {
          const showDate = new Date(today);
          showDate.setDate(today.getDate() + day);

          // 2:00 PM
          const afternoon = new Date(showDate);
          afternoon.setHours(14, 0, 0, 0);
          showtimesToCreate.push({
            movieId: movie.id,
            theaterId: theater.id,
            screenNumber: 1,
            showTime: afternoon,
            availableSeats: 96,
            totalSeats: 96,
            price: 12.50,
            isActive: true,
          });

          // 5:00 PM
          const evening = new Date(showDate);
          evening.setHours(17, 0, 0, 0);
          showtimesToCreate.push({
            movieId: movie.id,
            theaterId: theater.id,
            screenNumber: 1,
            showTime: evening,
            availableSeats: 96,
            totalSeats: 96,
            price: 15.00,
            isActive: true,
          });

          // 8:00 PM
          const night = new Date(showDate);
          night.setHours(20, 0, 0, 0);
          showtimesToCreate.push({
            movieId: movie.id,
            theaterId: theater.id,
            screenNumber: 1,
            showTime: night,
            availableSeats: 96,
            totalSeats: 96,
            price: 15.00,
            isActive: true,
          });
        }

        // Create all showtimes
        await prisma.showtime.createMany({
          data: showtimesToCreate,
        });
      }
    }

    res.status(201).json({
      success: true,
      message: movie.status === 'streaming_now'
        ? 'Movie created successfully with showtimes'
        : 'Movie created successfully',
      data: {
        movie,
      },
    });
  } catch (error) {
    console.error('Admin create movie error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while creating movie',
    });
  }
};

/**
 * Update movie
 * PUT /api/admin/movies/:id
 */
export const updateMovie = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title,
      description,
      genre,
      duration,
      rating,
      score,
      posterUrl,
      backdropUrl,
      trailerUrl,
      language,
      director,
      cast,
      releaseDate,
      status,
      isActive,
    } = req.body;

    // Check if movie exists
    const existingMovie = await prisma.movie.findUnique({
      where: { id: parseInt(id) },
    });

    if (!existingMovie) {
      return res.status(404).json({
        success: false,
        message: 'Movie not found',
      });
    }

    // Update movie
    const movie = await prisma.movie.update({
      where: {
        id: parseInt(id),
      },
      data: {
        ...(title !== undefined && { title }),
        ...(description !== undefined && { description }),
        ...(genre !== undefined && { genre }),
        ...(duration !== undefined && { duration: parseInt(duration) }),
        ...(rating !== undefined && { rating }),
        ...(score !== undefined && { score: parseFloat(score) }),
        ...(posterUrl !== undefined && { posterUrl }),
        ...(backdropUrl !== undefined && { backdropUrl }),
        ...(trailerUrl !== undefined && { trailerUrl }),
        ...(language !== undefined && { language }),
        ...(director !== undefined && { director }),
        ...(cast !== undefined && { cast }),
        ...(releaseDate !== undefined && {
          releaseDate: new Date(releaseDate),
        }),
        ...(status !== undefined && { status }),
        ...(isActive !== undefined && { isActive }),
        updatedAt: new Date(),
      },
    });

    res.status(200).json({
      success: true,
      message: 'Movie updated successfully',
      data: {
        movie,
      },
    });
  } catch (error) {
    console.error('Admin update movie error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating movie',
    });
  }
};

/**
 * Delete movie (hard delete - permanently removes from database)
 * DELETE /api/admin/movies/:id
 */
export const deleteMovie = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if movie exists
    const existingMovie = await prisma.movie.findUnique({
      where: { id: parseInt(id) },
    });

    if (!existingMovie) {
      return res.status(404).json({
        success: false,
        message: 'Movie not found',
      });
    }

    // Hard delete - permanently remove from database
    const movie = await prisma.movie.delete({
      where: {
        id: parseInt(id),
      },
    });

    res.status(200).json({
      success: true,
      message: 'Movie permanently deleted from database',
      data: {
        movie,
      },
    });
  } catch (error) {
    console.error('Admin delete movie error:', error);

    // Check if error is due to foreign key constraint (movie has showtimes/bookings)
    if (error.code === 'P2003' || error.code === 'P2014') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete movie. It has related showtimes or bookings. Please delete those first or use soft delete.',
      });
    }

    res.status(500).json({
      success: false,
      message: 'An error occurred while deleting movie',
    });
  }
};

/**
 * Toggle movie status (streaming_now <-> coming_soon)
 * PATCH /api/admin/movies/:id/status
 */
export const toggleMovieStatus = async (req, res) => {
  try {
    const { id } = req.params;

    // Get current movie
    const existingMovie = await prisma.movie.findUnique({
      where: { id: parseInt(id) },
    });

    if (!existingMovie) {
      return res.status(404).json({
        success: false,
        message: 'Movie not found',
      });
    }

    // Toggle status
    const newStatus =
      existingMovie.status === 'streaming_now'
        ? 'coming_soon'
        : 'streaming_now';

    const movie = await prisma.movie.update({
      where: {
        id: parseInt(id),
      },
      data: {
        status: newStatus,
        updatedAt: new Date(),
      },
    });

    // Auto-create showtimes if changing to "streaming_now" and no showtimes exist
    let showtimesCreated = false;
    if (newStatus === 'streaming_now') {
      const existingShowtimes = await prisma.showtime.count({
        where: {
          movieId: parseInt(id),
          showTime: {
            gte: new Date(),
          },
        },
      });

      if (existingShowtimes === 0) {
        showtimesCreated = true;
        // Get first available theater
        const theater = await prisma.theater.findFirst({
          where: { isActive: true },
        });

        if (theater) {
          // Create showtimes for next 7 days at 2pm, 5pm, and 8pm
          const showtimesToCreate = [];
          const today = new Date();

          for (let day = 0; day < 7; day++) {
            const showDate = new Date(today);
            showDate.setDate(today.getDate() + day);

            // 2:00 PM
            const afternoon = new Date(showDate);
            afternoon.setHours(14, 0, 0, 0);
            showtimesToCreate.push({
              movieId: parseInt(id),
              theaterId: theater.id,
              screenNumber: 1,
              showTime: afternoon,
              availableSeats: 96,
              totalSeats: 96,
              price: 12.50,
              isActive: true,
            });

            // 5:00 PM
            const evening = new Date(showDate);
            evening.setHours(17, 0, 0, 0);
            showtimesToCreate.push({
              movieId: parseInt(id),
              theaterId: theater.id,
              screenNumber: 1,
              showTime: evening,
              availableSeats: 96,
              totalSeats: 96,
              price: 15.00,
              isActive: true,
            });

            // 8:00 PM
            const night = new Date(showDate);
            night.setHours(20, 0, 0, 0);
            showtimesToCreate.push({
              movieId: parseInt(id),
              theaterId: theater.id,
              screenNumber: 1,
              showTime: night,
              availableSeats: 96,
              totalSeats: 96,
              price: 15.00,
              isActive: true,
            });
          }

          // Create all showtimes
          await prisma.showtime.createMany({
            data: showtimesToCreate,
          });
        }
      }
    }

    res.status(200).json({
      success: true,
      message: showtimesCreated
        ? `Movie status changed to ${newStatus} with showtimes created`
        : `Movie status changed to ${newStatus}`,
      data: {
        movie,
      },
    });
  } catch (error) {
    console.error('Admin toggle movie status error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while toggling movie status',
    });
  }
};

/**
 * Restore deleted movie
 * PATCH /api/admin/movies/:id/restore
 */
export const restoreMovie = async (req, res) => {
  try {
    const { id } = req.params;

    const movie = await prisma.movie.update({
      where: {
        id: parseInt(id),
      },
      data: {
        isActive: true,
        updatedAt: new Date(),
      },
    });

    res.status(200).json({
      success: true,
      message: 'Movie restored successfully',
      data: {
        movie,
      },
    });
  } catch (error) {
    console.error('Admin restore movie error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while restoring movie',
    });
  }
};

/**
 * Get dashboard statistics
 * GET /api/admin/stats
 */
export const getDashboardStats = async (req, res) => {
  try {
    const [
      totalMovies,
      activeMovies,
      streamingNow,
      comingSoon,
      totalBookings,
      totalRevenue,
    ] = await Promise.all([
      prisma.movie.count(),
      prisma.movie.count({ where: { isActive: true } }),
      prisma.movie.count({
        where: { status: 'streaming_now', isActive: true },
      }),
      prisma.movie.count({
        where: { status: 'coming_soon', isActive: true },
      }),
      prisma.booking.count(),
      prisma.booking.aggregate({
        _sum: {
          totalAmount: true,
        },
        where: {
          paymentStatus: 'completed',
        },
      }),
    ]);

    res.status(200).json({
      success: true,
      data: {
        stats: {
          totalMovies,
          activeMovies,
          inactiveMovies: totalMovies - activeMovies,
          streamingNow,
          comingSoon,
          totalBookings,
          totalRevenue: totalRevenue._sum.totalAmount || 0,
        },
      },
    });
  } catch (error) {
    console.error('Admin get stats error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching statistics',
    });
  }
};
