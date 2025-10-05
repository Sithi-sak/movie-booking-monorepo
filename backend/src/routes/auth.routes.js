import { Router } from 'express';
import { register, login, getProfile } from '../controllers/auth.controller.js';
import { authenticate } from '../middlewares/auth.middleware.js';

const authRouter = Router();

// Public routes (no authentication required)
authRouter.post('/register', register);
authRouter.post('/login', login);

// Protected routes (authentication required)
authRouter.get('/me', authenticate, getProfile);

export default authRouter;
