import express from 'express';
import {
  adminLogin,
  getAllMovies,
  getMovieById,
  createMovie,
  updateMovie,
  deleteMovie,
  toggleMovieStatus,
  restoreMovie,
  getDashboardStats,
} from '../controllers/admin.controller.js';
import { authenticateAdmin } from '../middlewares/admin.middleware.js';

const router = express.Router();

router.post('/login', adminLogin);

router.get('/stats', authenticateAdmin, getDashboardStats);
router.get('/movies', authenticateAdmin, getAllMovies);
router.get('/movies/:id', authenticateAdmin, getMovieById);
router.post('/movies', authenticateAdmin, createMovie);
router.put('/movies/:id', authenticateAdmin, updateMovie);
router.delete('/movies/:id', authenticateAdmin, deleteMovie);
router.patch('/movies/:id/status', authenticateAdmin, toggleMovieStatus);
router.patch('/movies/:id/restore', authenticateAdmin, restoreMovie);

export default router;
