import { Router } from 'express';
import {
  createBooking,
  getUserBookings,
  getBookingById,
  cancelBooking,
} from '../controllers/bookings.controller.js';
import {
  processPayment,
  getPaymentDetails,
} from '../controllers/payment.controller.js';
import { authenticate } from '../middlewares/auth.middleware.js';

const bookingsRouter = Router();

/**
 * All booking routes require authentication
 * User must be logged in to:
 * - Create bookings
 * - View bookings
 * - Cancel bookings
 */

/**
 * Create a new booking
 * POST /api/bookings
 * Body: { showtimeId, seatIds }
 * Headers: Authorization: Bearer <token>
 */
bookingsRouter.post('/', authenticate, createBooking);

/**
 * Get all bookings for logged-in user
 * GET /api/bookings
 * Headers: Authorization: Bearer <token>
 */
bookingsRouter.get('/', authenticate, getUserBookings);

/**
 * Process payment for a booking (MOCK)
 * POST /api/bookings/:bookingId/payment
 * Body: { amount, paymentMethod, cardNumber, expiryDate, cvv }
 * Headers: Authorization: Bearer <token>
 */
bookingsRouter.post('/:bookingId/payment', authenticate, processPayment);

/**
 * Get payment details for a booking
 * GET /api/bookings/:bookingId/payment
 * Headers: Authorization: Bearer <token>
 */
bookingsRouter.get('/:bookingId/payment', authenticate, getPaymentDetails);

/**
 * Get a single booking by ID
 * GET /api/bookings/:id
 * Headers: Authorization: Bearer <token>
 */
bookingsRouter.get('/:id', authenticate, getBookingById);

/**
 * Cancel a booking
 * DELETE /api/bookings/:id
 * Headers: Authorization: Bearer <token>
 */
bookingsRouter.delete('/:id', authenticate, cancelBooking);

export default bookingsRouter;
