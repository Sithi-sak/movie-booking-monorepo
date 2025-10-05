import { PrismaClient } from '../../generated/prisma/index.js';
import crypto from 'crypto';

const prisma = new PrismaClient();

/**
 * Generate a mock payment reference
 * Format: MOCK-PAY-XXXXXX (e.g., MOCK-PAY-A3F9D2)
 *
 * WHY: Simulates a payment gateway transaction ID
 * - In real systems: Stripe returns "ch_1A2B3C4D5E6F"
 * - Our mock: "MOCK-PAY-A3F9D2"
 */
function generatePaymentReference() {
  return 'MOCK-PAY-' + crypto.randomBytes(3).toString('hex').toUpperCase();
}

/**
 * Process payment for a booking (MOCK IMPLEMENTATION)
 * POST /api/bookings/:bookingId/payment
 *
 * WHY THIS IS MOCK:
 * - No real credit card processing
 * - No connection to Stripe/PayPal
 * - Just updates database status
 * - Perfect for university projects!
 *
 * WHAT IT DOES:
 * 1. Validates booking exists and belongs to user
 * 2. Checks if already paid (prevent double payment)
 * 3. Validates amount matches booking total
 * 4. Simulates 1 second payment processing
 * 5. Updates booking status to "confirmed"
 * 6. Generates fake payment reference
 * 7. Returns success
 *
 * REQUEST BODY:
 * {
 *   "amount": 30.00,
 *   "paymentMethod": "credit_card",
 *   "cardNumber": "4111111111111111",    // Optional - not validated
 *   "expiryDate": "12/25",                 // Optional - not validated
 *   "cvv": "123"                           // Optional - not validated
 * }
 */
export const processPayment = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.userId; // From auth middleware
    const {
      amount,
      paymentMethod = 'credit_card',
      cardNumber,
      expiryDate,
      // cvv is accepted but not used in mock payment
    } = req.body;

    // STEP 1: Validate input
    if (!amount || typeof amount !== 'number') {
      return res.status(400).json({
        success: false,
        message: 'Amount is required and must be a number',
      });
    }

    // STEP 2: Find booking and verify ownership
    const booking = await prisma.booking.findFirst({
      where: {
        id: parseInt(bookingId),
        userId, // Ensure user can only pay for their own bookings
      },
      include: {
        showtime: {
          include: {
            movie: {
              select: {
                title: true,
              },
            },
            theater: {
              select: {
                name: true,
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
    });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found or does not belong to you',
      });
    }

    // STEP 3: Check if already paid
    if (booking.status === 'confirmed') {
      return res.status(400).json({
        success: false,
        message: 'This booking has already been paid for',
        data: {
          booking: {
            id: booking.id,
            bookingReference: booking.bookingReference,
            paymentStatus: booking.paymentStatus,
            paymentReference: booking.paymentReference,
          },
        },
      });
    }

    // STEP 4: Check if booking is cancelled
    if (booking.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Cannot pay for a cancelled booking',
      });
    }

    // STEP 5: Validate amount matches booking total
    // This prevents users from paying wrong amount
    if (amount !== booking.totalAmount) {
      return res.status(400).json({
        success: false,
        message: `Amount mismatch. Expected ${booking.totalAmount}, received ${amount}`,
        data: {
          expectedAmount: booking.totalAmount,
          receivedAmount: amount,
        },
      });
    }

    // STEP 6: Log payment details (for demonstration/debugging)
    // In real system, this would go to payment gateway
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('💳 MOCK PAYMENT PROCESSING');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('Booking ID:', booking.id);
    console.log('Booking Reference:', booking.bookingReference);
    console.log('User ID:', userId);
    console.log('Amount:', amount);
    console.log('Payment Method:', paymentMethod);
    if (cardNumber) console.log('Card Number:', cardNumber.slice(-4).padStart(16, '*')); // Only show last 4 digits
    if (expiryDate) console.log('Expiry Date:', expiryDate);
    console.log('Movie:', booking.showtime.movie.title);
    console.log('Theater:', booking.showtime.theater.name);
    console.log('Seats:', booking.bookingSeats.map((bs) => bs.seat.seatNumber).join(', '));
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // STEP 7: Simulate payment processing delay
    // Real payment gateways take 1-3 seconds
    // This makes the UX feel realistic
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // STEP 8: Generate payment reference
    // In real system: Stripe returns "ch_3Abc123Def456"
    // Our mock: "MOCK-PAY-A3F9D2"
    const paymentReference = generatePaymentReference();

    // STEP 9: Update booking in database
    // This is the critical step - changes status from "pending" to "confirmed"
    const updatedBooking = await prisma.booking.update({
      where: {
        id: parseInt(bookingId),
      },
      data: {
        status: 'confirmed', // Now the booking is confirmed!
        paymentStatus: 'completed', // Payment is done
        paymentReference, // Store our mock payment ID
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

    // STEP 10: Log success
    console.log('✅ Payment processed successfully!');
    console.log('Payment Reference:', paymentReference);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // STEP 11: Return success response
    res.status(200).json({
      success: true,
      message: 'Payment processed successfully',
      data: {
        payment: {
          paymentReference,
          paymentMethod,
          amount,
          processedAt: new Date(),
        },
        booking: {
          id: updatedBooking.id,
          bookingReference: updatedBooking.bookingReference,
          status: updatedBooking.status,
          paymentStatus: updatedBooking.paymentStatus,
          totalAmount: updatedBooking.totalAmount,
          showtime: {
            showTime: updatedBooking.showtime.showTime,
            movie: updatedBooking.showtime.movie.title,
            theater: updatedBooking.showtime.theater.name,
          },
          seats: updatedBooking.bookingSeats.map((bs) => ({
            seatNumber: bs.seat.seatNumber,
            seatType: bs.seat.seatType,
          })),
        },
      },
    });
  } catch (error) {
    console.error('Process payment error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while processing payment',
    });
  }
};

/**
 * Get payment details for a booking
 * GET /api/bookings/:bookingId/payment
 *
 * WHY: User wants to see payment confirmation/receipt
 * - After payment, show receipt
 * - Check payment status
 */
export const getPaymentDetails = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.userId;

    const booking = await prisma.booking.findFirst({
      where: {
        id: parseInt(bookingId),
        userId,
      },
      select: {
        id: true,
        bookingReference: true,
        totalAmount: true,
        status: true,
        paymentStatus: true,
        paymentReference: true,
        bookingDate: true,
        updatedAt: true,
      },
    });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    // Check if payment exists
    if (booking.paymentStatus === 'pending') {
      return res.status(200).json({
        success: true,
        message: 'Payment is pending',
        data: {
          payment: null,
          booking: {
            id: booking.id,
            bookingReference: booking.bookingReference,
            totalAmount: booking.totalAmount,
            paymentStatus: booking.paymentStatus,
          },
        },
      });
    }

    // Return payment details
    res.status(200).json({
      success: true,
      data: {
        payment: {
          paymentReference: booking.paymentReference,
          amount: booking.totalAmount,
          status: booking.paymentStatus,
          paidAt: booking.updatedAt,
        },
        booking: {
          id: booking.id,
          bookingReference: booking.bookingReference,
          status: booking.status,
        },
      },
    });
  } catch (error) {
    console.error('Get payment details error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching payment details',
    });
  }
};
