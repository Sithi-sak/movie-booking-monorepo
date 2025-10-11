import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { config } from 'dotenv';

// Load environment variables
config();

// Import routes
import authRouter from './src/routes/auth.routes.js';
import userRouter from './src/routes/user.routes.js';
import moviesRouter from './src/routes/movies.routes.js';
import showtimesRouter from './src/routes/showtimes.routes.js';
import bookingsRouter from './src/routes/bookings.routes.js';
import ticketsRouter from './src/routes/tickets.routes.js';
import adminRouter from './src/routes/admin.routes.js';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors()); // Enable CORS for Flutter app
app.use(express.json()); // Parse JSON request bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies
app.use(morgan('dev')); // Log HTTP requests in development

// API Routes
app.use('/api/auth', authRouter);
app.use('/api/users', userRouter);
app.use('/api/movies', moviesRouter);
app.use('/api/showtimes', showtimesRouter);
app.use('/api/bookings', bookingsRouter);
app.use('/api/tickets', ticketsRouter);
app.use('/api/admin', adminRouter);

// Health check endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to the Movie Booking API!',
    version: '1.0.0',
    status: 'running'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Movie Booking API is running on http://localhost:${PORT}`);
});

export default app;
