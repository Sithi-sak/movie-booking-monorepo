import { verifyToken } from '../utils/jwt.js';

/**
 * Admin authentication middleware
 * Protects admin routes by verifying JWT token and admin role
 */
export const authenticateAdmin = async (req, res, next) => {
  try {
    // 1. Get token from Authorization header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No token provided. Admin access denied.',
      });
    }

    const token = authHeader.substring(7);

    // 2. Verify token
    const decoded = verifyToken(token);

    // 3. Check if user has admin role
    if (decoded.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin privileges required.',
      });
    }

    // 4. Attach admin info to request object
    req.admin = decoded;

    // 5. Continue to next middleware/route handler
    next();
  } catch {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired admin token. Please login again.',
    });
  }
};
