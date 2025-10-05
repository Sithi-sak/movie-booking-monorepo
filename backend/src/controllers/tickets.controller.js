import { PrismaClient } from '../../generated/prisma/index.js';

const prisma = new PrismaClient();

/**
 * Get all tickets (confirmed bookings) for logged-in user
 * GET /api/tickets
 */
export const getUserTickets = async (req, res) => {
  try {
    const userId = req.user.userId; // From auth middleware
    const { status } = req.query; // Optional: ?status=upcoming or ?status=past

    // STEP 1: Fetch all confirmed bookings for user
    // - userId: Only show MY tickets
    // - status: 'confirmed' = Paid and confirmed
    // - paymentStatus: 'completed' = Payment went through
    const tickets = await prisma.booking.findMany({
      where: {
        userId,
        status: 'confirmed',
        paymentStatus: 'completed',
      },
      include: {
        showtime: {
          include: {
            movie: {
              select: {
                id: true,
                title: true,
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
                phone: true,
              },
            },
          },
        },
        bookingSeats: {
          include: {
            seat: {
              select: {
                seatNumber: true,
                rowName: true,
                seatType: true,
              },
            },
          },
        },
      },
      orderBy: {
        bookingDate: 'desc',
      },
    });

    // STEP 2: Separate into upcoming and past tickets
    const now = new Date();

    const upcomingTickets = tickets.filter(
      (ticket) => new Date(ticket.showtime.showTime) > now
    );

    const pastTickets = tickets.filter(
      (ticket) => new Date(ticket.showtime.showTime) <= now
    );

    // STEP 3: Format tickets for frontend
    const formatTicket = (ticket) => ({
      // Booking Info
      id: ticket.id,
      bookingReference: ticket.bookingReference,
      bookingDate: ticket.bookingDate,
      totalAmount: ticket.totalAmount,
      paymentReference: ticket.paymentReference,

      // Movie Info (for display)
      movie: {
        id: ticket.showtime.movie.id,
        title: ticket.showtime.movie.title,
        posterUrl: ticket.showtime.movie.posterUrl,
        backdropUrl: ticket.showtime.movie.backdropUrl,
        duration: ticket.showtime.movie.duration,
        rating: ticket.showtime.movie.rating,
        genre: ticket.showtime.movie.genre,
      },

      // Theater Info (where to go)
      theater: {
        id: ticket.showtime.theater.id,
        name: ticket.showtime.theater.name,
        address: ticket.showtime.theater.address,
        city: ticket.showtime.theater.city,
        state: ticket.showtime.theater.state,
        phone: ticket.showtime.theater.phone,
      },

      // Showtime Info (when to go)
      showtime: {
        id: ticket.showtime.id,
        showTime: ticket.showtime.showTime,
        screenNumber: ticket.showtime.screenNumber,
      },

      // Seats Info (where to sit)
      seats: ticket.bookingSeats.map((bs) => ({
        seatNumber: bs.seat.seatNumber,
        rowName: bs.seat.rowName,
        seatType: bs.seat.seatType,
      })),
      seatCount: ticket.bookingSeats.length,

      qrCode: ticket.bookingReference,

      // Ticket status
      isUpcoming: new Date(ticket.showtime.showTime) > now,
      isPast: new Date(ticket.showtime.showTime) <= now,
    });

    // STEP 4: Apply status filter if provided
    let responseTickets;

    if (status === 'upcoming') {
      responseTickets = upcomingTickets.map(formatTicket);
    } else if (status === 'past') {
      responseTickets = pastTickets.map(formatTicket);
    } else {
      // No filter - return both, separated
      responseTickets = {
        upcoming: upcomingTickets.map(formatTicket),
        past: pastTickets.map(formatTicket),
      };
    }

    // STEP 5: Return response
    res.status(200).json({
      success: true,
      count: tickets.length,
      data: {
        tickets: responseTickets,
        summary: {
          total: tickets.length,
          upcoming: upcomingTickets.length,
          past: pastTickets.length,
        },
      },
    });
  } catch (error) {
    console.error('Get user tickets error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching tickets',
    });
  }
};

/**
 * Get a single ticket by booking ID
 * GET /api/tickets/:bookingId
 */
export const getTicketById = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.userId;

    // STEP 1: Find ticket and verify ownership
    const ticket = await prisma.booking.findFirst({
      where: {
        id: parseInt(bookingId),
        userId, // only your tickets
        status: 'confirmed', // Must be confirmed
        paymentStatus: 'completed', // Must be paid
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

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found or does not belong to you',
      });
    }

    // STEP 2: Check if ticket is for past showtime
    const now = new Date();
    const isUpcoming = new Date(ticket.showtime.showTime) > now;
    const isPast = new Date(ticket.showtime.showTime) <= now;

    // STEP 3: Calculate time until showtime (for countdown)
    const timeUntilShow = new Date(ticket.showtime.showTime) - now;
    const daysUntilShow = Math.floor(timeUntilShow / (1000 * 60 * 60 * 24));
    const hoursUntilShow = Math.floor(
      (timeUntilShow % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
    );

    // STEP 4: Format detailed ticket
    const formattedTicket = {
      // Ticket Metadata
      id: ticket.id,
      bookingReference: ticket.bookingReference,
      bookingDate: ticket.bookingDate,
      totalAmount: ticket.totalAmount,
      paymentReference: ticket.paymentReference,
      status: ticket.status,
      paymentStatus: ticket.paymentStatus,

      // Movie Details
      movie: {
        id: ticket.showtime.movie.id,
        title: ticket.showtime.movie.title,
        description: ticket.showtime.movie.description,
        posterUrl: ticket.showtime.movie.posterUrl,
        backdropUrl: ticket.showtime.movie.backdropUrl,
        duration: ticket.showtime.movie.duration,
        rating: ticket.showtime.movie.rating,
        genre: ticket.showtime.movie.genre,
      },

      // Theater Details (for navigation)
      theater: {
        id: ticket.showtime.theater.id,
        name: ticket.showtime.theater.name,
        address: ticket.showtime.theater.address,
        city: ticket.showtime.theater.city,
        state: ticket.showtime.theater.state,
        zipCode: ticket.showtime.theater.zipCode,
        phone: ticket.showtime.theater.phone,
      },

      // Showtime Details
      showtime: {
        id: ticket.showtime.id,
        showTime: ticket.showtime.showTime,
        screenNumber: ticket.showtime.screenNumber,
      },

      // Seat Details
      seats: ticket.bookingSeats.map((bs) => ({
        seatNumber: bs.seat.seatNumber,
        rowName: bs.seat.rowName,
        seatColumn: bs.seat.seatColumn,
        seatType: bs.seat.seatType,
      })),

      // Ticket Status
      isUpcoming,
      isPast,

      // Time Info (for countdown display)
      timeUntilShow: isUpcoming
        ? {
            days: daysUntilShow,
            hours: hoursUntilShow,
            totalMilliseconds: timeUntilShow,
          }
        : null,

      qrCode: ticket.bookingReference,
    };

    res.status(200).json({
      success: true,
      data: {
        ticket: formattedTicket,
      },
    });
  } catch (error) {
    console.error('Get ticket by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching ticket details',
    });
  }
};
