import { verifyToken } from '../utils/jwt.js';

/**
 * Authentication middleware
 * Protects routes by verifying JWT token
 * Usage: Add this middleware to any route that requires authentication
 */
export const authenticate = async (req, res, next) => {
  try {
    // 1. Get token from Authorization header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No token provided. Please login first.',
      });
    }

    const token = authHeader.substring(7);

    // 2. Verify token
    const decoded = verifyToken(token);

    // 3. Attach user info to request object
    req.user = decoded;

    // 4. Continue to next middleware/route handler
    next();
  } catch {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token. Please login again.',
    });
  }
};
