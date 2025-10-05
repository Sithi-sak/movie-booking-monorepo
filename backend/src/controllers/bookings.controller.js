import { PrismaClient } from '../../generated/prisma/index.js';
import crypto from 'crypto';

const prisma = new PrismaClient();

/**
 * Generate a unique booking reference
 * Format: BK-XXXXXX (e.g., BK-A3F9D2)
 *
 * WHY: User-friendly ID for tracking bookings
 * - Don't expose database IDs to users
 * - Easy to read over phone/email
 * - Professional appearance
 */
function generateBookingReference() {
  return 'BK-' + crypto.randomBytes(3).toString('hex').toUpperCase();
}

/**
 * Create a new booking
 * POST /api/bookings
 *
 * REQUEST BODY:
 * {
 *   "showtimeId": 1,
 *   "seatIds": [45, 46, 47]
 * }
 *
 * WHY THIS IS COMPLEX:
 * 1. Must prevent double-booking (two users clicking at same time)
 * 2. Must calculate total price correctly
 * 3. Must handle multiple seats atomically (all or nothing)
 * 4. Must validate everything before committing
 */
export const createBooking = async (req, res) => {
  try {
    const { showtimeId, seatIds } = req.body;
    const userId = req.user.userId; // From auth middleware

    // STEP 1: Validate input
    if (!showtimeId || !Array.isArray(seatIds) || seatIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'showtimeId and seatIds (non-empty array) are required',
      });
    }

    // STEP 2: Verify showtime exists and is bookable
    const showtime = await prisma.showtime.findUnique({
      where: { id: parseInt(showtimeId) },
      include: {
        movie: {
          select: {
            title: true,
            duration: true,
          },
        },
        theater: {
          select: {
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

    // Check if showtime is in the past
    if (new Date(showtime.showTime) < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot book seats for past showtimes',
      });
    }

    // STEP 3: Get seat details and verify they exist
    const seats = await prisma.seat.findMany({
      where: {
        id: {
          in: seatIds.map((id) => parseInt(id)),
        },
        theaterId: showtime.theaterId,
        screenNumber: showtime.screenNumber,
        isActive: true,
      },
    });

    // Check if all requested seats exist
    if (seats.length !== seatIds.length) {
      return res.status(400).json({
        success: false,
        message: 'Some seats are invalid or do not exist',
      });
    }

    // STEP 4: Check if seats are already booked
    // This is CRITICAL to prevent double-booking!
    const existingBookings = await prisma.bookingSeat.findMany({
      where: {
        seatId: {
          in: seatIds.map((id) => parseInt(id)),
        },
        booking: {
          showtimeId: parseInt(showtimeId),
          status: {
            in: ['confirmed', 'pending'], // Don't allow booking if someone has pending/confirmed
          },
        },
      },
      include: {
        seat: true,
        booking: true,
      },
    });

    if (existingBookings.length > 0) {
      const bookedSeatNumbers = existingBookings.map((eb) => eb.seat.seatNumber);
      return res.status(409).json({
        success: false,
        message: 'Some seats are already booked',
        data: {
          bookedSeats: bookedSeatNumbers,
        },
      });
    }

    // STEP 5: Calculate total amount
    // Each seat has a price (premium vs regular)
    const subtotal = seats.reduce((sum, seat) => {
      return sum + (seat.price || showtime.price);
    }, 0);

    // Add service fee (10%) and tax (8%) to match frontend calculation
    const serviceFee = subtotal * 0.10;
    const tax = subtotal * 0.08;
    const totalAmount = subtotal + serviceFee + tax;

    // STEP 6: Generate unique booking reference
    let bookingReference;
    let isUnique = false;

    // Keep trying until we get a unique reference
    // (very unlikely to collide, but we check anyway)
    while (!isUnique) {
      bookingReference = generateBookingReference();
      const existing = await prisma.booking.findUnique({
        where: { bookingReference },
      });
      if (!existing) isUnique = true;
    }

    // STEP 7: Create booking and link seats in a TRANSACTION
    // WHY TRANSACTION? All or nothing - prevents partial bookings
    // If anything fails, everything rolls back
    const booking = await prisma.$transaction(async (tx) => {
      // Create the booking record
      const newBooking = await tx.booking.create({
        data: {
          userId,
          showtimeId: parseInt(showtimeId),
          bookingReference,
          seats: JSON.stringify(seats.map((s) => s.seatNumber)), // Store seat numbers as JSON
          totalAmount,
          status: 'pending', // Not confirmed until payment
          paymentStatus: 'pending',
        },
      });

      // Link all seats to this booking
      const bookingSeatData = seatIds.map((seatId) => ({
        bookingId: newBooking.id,
        seatId: parseInt(seatId),
        status: 'confirmed', // Seat is held for this booking
      }));

      await tx.bookingSeat.createMany({
        data: bookingSeatData,
      });

      // Return the booking with all details
      return tx.booking.findUnique({
        where: { id: newBooking.id },
        include: {
          showtime: {
            include: {
              movie: true,
              theater: true,
            },
          },
          bookingSeats: {
            include: {
              seat: true,
            },
          },
        },
      });
    });

    // STEP 8: Format response
    res.status(201).json({
      success: true,
      message: 'Booking created successfully',
      data: {
        booking: {
          id: booking.id,
          bookingReference: booking.bookingReference,
          status: booking.status,
          paymentStatus: booking.paymentStatus,
          totalAmount: booking.totalAmount,
          bookingDate: booking.bookingDate,
          showtime: {
            id: booking.showtime.id,
            showTime: booking.showtime.showTime,
            movie: booking.showtime.movie.title,
            theater: booking.showtime.theater.name,
            screenNumber: booking.showtime.screenNumber,
          },
          seats: booking.bookingSeats.map((bs) => ({
            seatNumber: bs.seat.seatNumber,
            seatType: bs.seat.seatType,
            price: bs.seat.price || booking.showtime.price,
          })),
        },
      },
    });
  } catch (error) {
    console.error('Create booking error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while creating booking',
    });
  }
};

/**
 * Get all bookings for the logged-in user
 * GET /api/bookings
 *
 * WHY: User wants to see "My Bookings" page
 * - Shows all past and upcoming bookings
 * - Includes movie, theater, seats info
 */
export const getUserBookings = async (req, res) => {
  try {
    const userId = req.user.userId;

    const bookings = await prisma.booking.findMany({
      where: {
        userId,
      },
      include: {
        showtime: {
          include: {
            movie: {
              select: {
                id: true,
                title: true,
                posterUrl: true,
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
        },
        bookingSeats: {
          include: {
            seat: true,
          },
        },
      },
      orderBy: {
        bookingDate: 'desc', // Most recent first
      },
    });

    // Format response
    const formattedBookings = bookings.map((booking) => ({
      id: booking.id,
      bookingReference: booking.bookingReference,
      status: booking.status,
      paymentStatus: booking.paymentStatus,
      totalAmount: booking.totalAmount,
      bookingDate: booking.bookingDate,
      showtime: {
        id: booking.showtime.id,
        showTime: booking.showtime.showTime,
        screenNumber: booking.showtime.screenNumber,
      },
      movie: booking.showtime.movie,
      theater: booking.showtime.theater,
      seats: booking.bookingSeats.map((bs) => ({
        seatNumber: bs.seat.seatNumber,
        seatType: bs.seat.seatType,
      })),
      seatCount: booking.bookingSeats.length,
    }));

    res.status(200).json({
      success: true,
      count: formattedBookings.length,
      data: {
        bookings: formattedBookings,
      },
    });
  } catch (error) {
    console.error('Get user bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching bookings',
    });
  }
};

/**
 * Get a single booking by ID
 * GET /api/bookings/:id
 *
 * WHY: User clicks on a booking to see full details
 * - Confirmation page after booking
 * - View ticket details
 */
export const getBookingById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    const booking = await prisma.booking.findFirst({
      where: {
        id: parseInt(id),
        userId, // Ensure user can only see their own bookings
      },
      include: {
        showtime: {
          include: {
            movie: true,
            theater: true,
          },
        },
        bookingSeats: {
          include: {
            seat: true,
          },
        },
      },
    });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        booking: {
          id: booking.id,
          bookingReference: booking.bookingReference,
          status: booking.status,
          paymentStatus: booking.paymentStatus,
          totalAmount: booking.totalAmount,
          bookingDate: booking.bookingDate,
          showtime: {
            id: booking.showtime.id,
            showTime: booking.showtime.showTime,
            price: booking.showtime.price,
            screenNumber: booking.showtime.screenNumber,
          },
          movie: booking.showtime.movie,
          theater: booking.showtime.theater,
          seats: booking.bookingSeats.map((bs) => ({
            seatNumber: bs.seat.seatNumber,
            rowName: bs.seat.rowName,
            seatColumn: bs.seat.seatColumn,
            seatType: bs.seat.seatType,
            price: bs.seat.price || booking.showtime.price,
          })),
        },
      },
    });
  } catch (error) {
    console.error('Get booking by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching booking details',
    });
  }
};

/**
 * Cancel a booking
 * DELETE /api/bookings/:id
 *
 * WHY: User wants to cancel their booking
 * - Frees up seats for others
 * - Updates booking status to "cancelled"
 */
export const cancelBooking = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    // Find booking and verify ownership
    const booking = await prisma.booking.findFirst({
      where: {
        id: parseInt(id),
        userId,
      },
      include: {
        showtime: true,
      },
    });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    // Check if already cancelled
    if (booking.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Booking is already cancelled',
      });
    }

    // Check if showtime has already passed
    if (new Date(booking.showtime.showTime) < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel bookings for past showtimes',
      });
    }

    // Update booking status to cancelled
    const updatedBooking = await prisma.booking.update({
      where: { id: parseInt(id) },
      data: {
        status: 'cancelled',
      },
    });

    res.status(200).json({
      success: true,
      message: 'Booking cancelled successfully',
      data: {
        booking: {
          id: updatedBooking.id,
          bookingReference: updatedBooking.bookingReference,
          status: updatedBooking.status,
        },
      },
    });
  } catch (error) {
    console.error('Cancel booking error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while cancelling booking',
    });
  }
};
