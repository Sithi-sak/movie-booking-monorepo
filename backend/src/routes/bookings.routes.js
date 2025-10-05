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


bookingsRouter.post('/', authenticate, createBooking);

bookingsRouter.get('/', authenticate, getUserBookings);


bookingsRouter.post('/:bookingId/payment', authenticate, processPayment);


bookingsRouter.get('/:bookingId/payment', authenticate, getPaymentDetails);


bookingsRouter.get('/:id', authenticate, getBookingById);


bookingsRouter.delete('/:id', authenticate, cancelBooking);

export default bookingsRouter;
