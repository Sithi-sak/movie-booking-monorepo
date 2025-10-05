import { Router } from 'express';
import {
  getAllMovies,
  getMovieById,
  getMoviesByStatus,
} from '../controllers/movies.controller.js';

const moviesRouter = Router();

// Get all movies (with optional filters)
moviesRouter.get('/', getAllMovies);

// Get movies by status
moviesRouter.get('/status/:status', getMoviesByStatus);

// Get single movie by ID
moviesRouter.get('/:id', getMovieById);

export default moviesRouter;