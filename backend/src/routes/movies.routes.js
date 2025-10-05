import { Router } from 'express';
import {
  getAllMovies,
  getMovieById,
  getMoviesByStatus,
} from '../controllers/movies.controller.js';

const moviesRouter = Router();

// Get all movies (with optional filters)
// Example: GET /api/movies?status=streaming_now&genre=Action
moviesRouter.get('/', getAllMovies);

// Get movies by status
// Example: GET /api/movies/status/streaming_now
moviesRouter.get('/status/:status', getMoviesByStatus);

// Get single movie by ID
// Example: GET /api/movies/123
moviesRouter.get('/:id', getMovieById);

export default moviesRouter;