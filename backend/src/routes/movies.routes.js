import { Router } from 'express';
import {
  getAllMovies,
  getMovieById,
  getMoviesByStatus,
} from '../controllers/movies.controller.js';

const moviesRouter = Router();

moviesRouter.get('/', getAllMovies);

moviesRouter.get('/status/:status', getMoviesByStatus);

moviesRouter.get('/:id', getMovieById);

export default moviesRouter;