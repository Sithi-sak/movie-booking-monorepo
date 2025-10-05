import { Router } from 'express';
import {
  getShowtimes,
  getShowtimeById,
  getShowtimesByMovieGroupedByDate,
} from '../controllers/showtimes.controller.js';
import {
  getSeatsByShowtime,
  checkSeatAvailability,
} from '../controllers/seats.controller.js';

const showtimesRouter = Router();

/**
 * Get showtimes with optional filters
 * Examples:
 * - /api/showtimes?movieId=1 (all showtimes for movie 1)
 * - /api/showtimes?theaterId=2 (all showtimes at theater 2)
 * - /api/showtimes?movieId=1&date=2025-10-02 (specific movie on specific date)
 */
showtimesRouter.get('/', getShowtimes);

/**
 * Get showtimes for a movie grouped by date
 * Example: /api/showtimes/movie/1/dates
 * Returns: { "2025-10-01": [showtimes], "2025-10-02": [showtimes] }
 */
showtimesRouter.get('/movie/:movieId/dates', getShowtimesByMovieGroupedByDate);

/**
 * Get seats for a specific showtime
 * Example: GET /api/showtimes/1/seats
 * Returns: All seats with availability status
 */
showtimesRouter.get('/:showtimeId/seats', getSeatsByShowtime);

/**
 * Check if specific seats are available
 * Example: POST /api/showtimes/1/seats/check
 * Body: { "seatIds": [1, 2, 3] }
 */
showtimesRouter.post('/:showtimeId/seats/check', checkSeatAvailability);

/**
 * Get single showtime details
 * Example: /api/showtimes/123
 * Note: This route must come AFTER specific routes like /seats
 * (otherwise "seats" would be treated as an ID)
 */
showtimesRouter.get('/:id', getShowtimeById);

export default showtimesRouter;
