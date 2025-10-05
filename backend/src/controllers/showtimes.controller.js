import { PrismaClient } from '../../generated/prisma/index.js';

const prisma = new PrismaClient();

/**
 * Get showtimes with filters
 * GET /api/showtimes?movieId=1&theaterId=2&date=2025-10-01
 *
 * Example use case: User clicks "Book Tickets" on Avengers → sees all showtimes
 */
export const getShowtimes = async (req, res) => {
  try {
    const { movieId, theaterId, date } = req.query;

    // Build filter object
    const where = {
      isActive: true, // Only show active showtimes
      showTime: {
        gte: new Date(), // Only future showtimes (can't book past shows!)
      },
    };

    // Filter by movie (e.g., show all times for "Avengers")
    if (movieId) {
      where.movieId = parseInt(movieId);
    }

    // Filter by theater (e.g., show all movies at "AMC Times Square")
    if (theaterId) {
      where.theaterId = parseInt(theaterId);
    }

    // Filter by date (e.g., show all showtimes for tomorrow)
    if (date) {
      const startDate = new Date(date);
      const endDate = new Date(date);
      endDate.setDate(endDate.getDate() + 1); // Next day at midnight

      where.showTime = {
        gte: startDate,
        lt: endDate,
      };
    }

    // Fetch showtimes from database
    const showtimes = await prisma.showtime.findMany({
      where,
      include: {
        // Include movie details (title, poster, duration)
        movie: {
          select: {
            id: true,
            title: true,
            posterUrl: true,
            duration: true,
            rating: true,
            genre: true,
          },
        },
        // Include theater details (name, address, location)
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
    });

    res.status(200).json({
      success: true,
      count: showtimes.length,
      data: {
        showtimes,
      },
    });
  } catch (error) {
    console.error('Get showtimes error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching showtimes',
    });
  }
};

/**
 * Get a single showtime by ID
 * GET /api/showtimes/:id
 *
 * Example: User clicks "7:00 PM" → sees theater info, available seats, price
 */
export const getShowtimeById = async (req, res) => {
  try {
    const { id } = req.params;

    const showtime = await prisma.showtime.findUnique({
      where: {
        id: parseInt(id),
      },
      include: {
        movie: {
          select: {
            id: true,
            title: true,
            description: true,
            posterUrl: true,
            backdropUrl: true,
            duration: true,
            rating: true,
            genre: true,
          },
        },
        theater: {
          select: {
            id: true,
            name: true,
            address: true,
            city: true,
            state: true,
            zipCode: true,
            phone: true,
            screens: true,
          },
        },
      },
    });

    if (!showtime) {
      return res.status(404).json({
        success: false,
        message: 'Showtime not found',
      });
    }

    if (new Date(showtime.showTime) < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'This showtime has already passed',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        showtime,
      },
    });
  } catch (error) {
    console.error('Get showtime by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching showtime details',
    });
  }
};

/**
 * Get showtimes grouped by date for a movie
 * GET /api/showtimes/movie/:movieId/dates
 *
 * Example: "Tomorrow (Oct 2) - 3 showtimes available"
 */
export const getShowtimesByMovieGroupedByDate = async (req, res) => {
  try {
    const { movieId } = req.params;

    const showtimes = await prisma.showtime.findMany({
      where: {
        movieId: parseInt(movieId),
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
            city: true,
          },
        },
      },
      orderBy: {
        showTime: 'asc',
      },
    });

    const groupedByDate = showtimes.reduce((acc, showtime) => {
      const date = showtime.showTime.toISOString().split('T')[0]; // Get YYYY-MM-DD

      if (!acc[date]) {
        acc[date] = [];
      }

      acc[date].push(showtime);
      return acc;
    }, {});

    const result = Object.keys(groupedByDate).map((date) => ({
      date,
      showtimes: groupedByDate[date],
      count: groupedByDate[date].length,
    }));

    res.status(200).json({
      success: true,
      data: {
        dates: result,
      },
    });
  } catch (error) {
    console.error('Get showtimes by movie grouped by date error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching showtimes',
    });
  }
};
