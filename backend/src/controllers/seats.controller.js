import { PrismaClient } from '../../generated/prisma/index.js';

const prisma = new PrismaClient();

/**
 * Get all seats for a specific showtime with booking status
 * GET /api/showtimes/:showtimeId/seats
 *
 * WHY: This is the core of seat selection!
 * - User picks a showtime → needs to see which seats are available
 * - Shows seat layout (rows A-H, columns 1-12)
 * - Marks which seats are already booked
 * - Shows pricing per seat type (regular vs premium)
 *
 * HOW IT WORKS:
 * 1. Get all seats for the theater/screen
 * 2. Check which seats are booked for THIS specific showtime
 * 3. Mark booked seats as unavailable
 * 4. Return organized data for easy rendering
 */
export const getSeatsByShowtime = async (req, res) => {
  try {
    const { showtimeId } = req.params;

    // Step 1: Verify showtime exists and get details
    const showtime = await prisma.showtime.findUnique({
      where: {
        id: parseInt(showtimeId),
      },
      include: {
        movie: {
          select: {
            id: true,
            title: true,
            duration: true,
            rating: true,
          },
        },
        theater: {
          select: {
            id: true,
            name: true,
            address: true,
            city: true,
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

    // Step 2: Check if showtime is in the past
    if (new Date(showtime.showTime) < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot book seats for past showtimes',
      });
    }

    // Step 3: Get all seats for this theater/screen
    // These are the physical seats (like chairs in the room)
    const allSeats = await prisma.seat.findMany({
      where: {
        theaterId: showtime.theaterId,
        screenNumber: showtime.screenNumber,
        isActive: true,
      },
      orderBy: [
        { rowName: 'asc' },    // Sort by row (A, B, C...)
        { seatColumn: 'asc' }, // Then by column (1, 2, 3...)
      ],
    });

    // Step 4: Get all bookings for this specific showtime
    // Find which seats are already taken by other users
    const bookedSeats = await prisma.booking.findMany({
      where: {
        showtimeId: parseInt(showtimeId),
        status: {
          in: ['confirmed', 'pending'], // Only count confirmed/pending bookings
        },
      },
      include: {
        bookingSeats: {
          include: {
            seat: true,
          },
        },
      },
    });

    // Step 5: Create a Set of booked seat IDs for fast lookup
    // Why Set? O(1) lookup time instead of O(n) with array.includes()
    const bookedSeatIds = new Set();
    bookedSeats.forEach((booking) => {
      booking.bookingSeats.forEach((bookingSeat) => {
        bookedSeatIds.add(bookingSeat.seatId);
      });
    });

    // Step 6: Mark each seat as booked or available
    const seatsWithStatus = allSeats.map((seat) => ({
      id: seat.id,
      seatNumber: seat.seatNumber,
      rowName: seat.rowName,
      seatColumn: seat.seatColumn,
      seatType: seat.seatType,
      price: seat.price || showtime.price, // Use seat price or default showtime price
      isBooked: bookedSeatIds.has(seat.id), // True if someone booked it
      isAisle: seat.isAisle, // For spacing in UI
    }));

    // Step 7: Calculate statistics
    const totalSeats = allSeats.length;
    const bookedCount = bookedSeatIds.size;
    const availableCount = totalSeats - bookedCount;

    // Step 8: Organize seats by row for easier UI rendering
    const seatsByRow = seatsWithStatus.reduce((acc, seat) => {
      if (!acc[seat.rowName]) {
        acc[seat.rowName] = [];
      }
      acc[seat.rowName].push(seat);
      return acc;
    }, {});

    // Step 9: Get unique rows and column count
    const rows = [...new Set(allSeats.map((s) => s.rowName))].sort();
    const maxColumns = Math.max(...allSeats.map((s) => s.seatColumn));

    // Step 10: Return organized response
    res.status(200).json({
      success: true,
      data: {
        showtime: {
          id: showtime.id,
          showTime: showtime.showTime,
          price: showtime.price,
          movie: showtime.movie,
          theater: showtime.theater,
          screenNumber: showtime.screenNumber,
        },
        seats: seatsWithStatus, // All seats with booking status
        seatsByRow, // Organized by row for easier rendering
        layout: {
          rows, // ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
          columns: maxColumns, // 12
          totalSeats,
          availableSeats: availableCount,
          bookedSeats: bookedCount,
        },
        pricing: {
          regular: allSeats.find((s) => s.seatType === 'regular')?.price || showtime.price,
          premium: allSeats.find((s) => s.seatType === 'premium')?.price || showtime.price,
        },
      },
    });
  } catch (error) {
    console.error('Get seats by showtime error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching seats',
    });
  }
};

/**
 * Check if specific seats are available
 * POST /api/showtimes/:showtimeId/seats/check
 *
 * WHY: Before creating a booking, verify seats are still available
 * - Prevents double-booking
 * - User might be slow to checkout, seat could be taken
 *
 * REQUEST BODY:
 * {
 *   "seatIds": [1, 2, 3]
 * }
 */
export const checkSeatAvailability = async (req, res) => {
  try {
    const { showtimeId } = req.params;
    const { seatIds } = req.body;

    // Validate input
    if (!Array.isArray(seatIds) || seatIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'seatIds must be a non-empty array',
      });
    }

    // Check if seats are already booked
    const bookedSeats = await prisma.bookingSeat.findMany({
      where: {
        seatId: {
          in: seatIds,
        },
        booking: {
          showtimeId: parseInt(showtimeId),
          status: {
            in: ['confirmed', 'pending'],
          },
        },
      },
      include: {
        seat: true,
      },
    });

    // If any seats are booked, return error
    if (bookedSeats.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Some seats are already booked',
        data: {
          unavailableSeats: bookedSeats.map((bs) => ({
            id: bs.seat.id,
            seatNumber: bs.seat.seatNumber,
          })),
        },
      });
    }

    // All seats available
    res.status(200).json({
      success: true,
      message: 'All seats are available',
    });
  } catch (error) {
    console.error('Check seat availability error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while checking seat availability',
    });
  }
};
