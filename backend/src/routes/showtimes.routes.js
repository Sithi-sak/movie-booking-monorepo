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

showtimesRouter.get('/', getShowtimes);

showtimesRouter.get('/movie/:movieId/dates', getShowtimesByMovieGroupedByDate);

showtimesRouter.get('/:showtimeId/seats', getSeatsByShowtime);

showtimesRouter.post('/:showtimeId/seats/check', checkSeatAvailability);

showtimesRouter.get('/:id', getShowtimeById);

export default showtimesRouter;
