import { Router } from 'express';
import {
  getUserTickets,
  getTicketById,
} from '../controllers/tickets.controller.js';
import { authenticate } from '../middlewares/auth.middleware.js';

const ticketsRouter = Router();


ticketsRouter.get('/', authenticate, getUserTickets);

ticketsRouter.get('/:bookingId', authenticate, getTicketById);

export default ticketsRouter;
