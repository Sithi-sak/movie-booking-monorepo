import { Router } from 'express';
import {
  getUserTickets,
  getTicketById,
} from '../controllers/tickets.controller.js';
import { authenticate } from '../middlewares/auth.middleware.js';

const ticketsRouter = Router();

/**
 * All ticket routes require authentication
 * WHY: Tickets are personal - must be logged in to view
 */

/**
 * Get all tickets for logged-in user
 * GET /api/tickets
 * Optional query: ?status=upcoming or ?status=past
 * Headers: Authorization: Bearer <token>
 *
 * USE CASE: "My Tickets" page in Flutter app
 */
ticketsRouter.get('/', authenticate, getUserTickets);

/**
 * Get a single ticket by booking ID
 * GET /api/tickets/:bookingId
 * Headers: Authorization: Bearer <token>
 *
 * USE CASE:
 * - View ticket details
 * - Show QR code at theater entrance
 * - Check ticket before showtime
 */
ticketsRouter.get('/:bookingId', authenticate, getTicketById);

export default ticketsRouter;
