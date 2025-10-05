import 'package:movie_booking_app/data/models/booking_model.dart';
import 'package:movie_booking_app/data/models/showtime_model.dart';
import 'package:movie_booking_app/data/models/seat_model.dart';
import 'package:movie_booking_app/services/api_service.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  /// Get showtimes for a specific movie, grouped by date
  /// GET /api/showtimes/movie/:movieId/dates
  static Future<Map<String, List<ShowtimeModel>>> getShowtimesByMovie(
      int movieId) async {
    try {
      final response =
          await ApiService.get('/showtimes/movie/$movieId/dates');

      if (response['success'] == true && response['data'] != null) {
        final Map<String, List<ShowtimeModel>> showtimesByDate = {};
        final data = response['data'] as Map<String, dynamic>;
        final dates = data['dates'] as List;

        for (var dateGroup in dates) {
          final date = dateGroup['date'] as String;
          final showtimesJson = dateGroup['showtimes'] as List;

          final showtimes = showtimesJson
              .map((json) => ShowtimeModel.fromJson(json as Map<String, dynamic>))
              .toList();

          showtimesByDate[date] = showtimes;
        }

        return showtimesByDate;
      }

      throw Exception(response['message'] ?? 'Failed to fetch showtimes');
    } catch (e) {
      throw Exception('Failed to fetch showtimes: $e');
    }
  }

  /// Get all seats for a specific showtime with availability status
  /// GET /api/showtimes/:showtimeId/seats
  static Future<SeatLayoutResponse> getSeatsByShowtime(int showtimeId) async {
    try {
      final response = await ApiService.get('/showtimes/$showtimeId/seats');

      if (response['success'] == true) {
        return SeatLayoutResponse.fromJson(response);
      }

      throw Exception(response['message'] ?? 'Failed to fetch seats');
    } catch (e) {
      throw Exception('Failed to fetch seats: $e');
    }
  }

  /// Check if specific seats are still available
  /// POST /api/showtimes/:showtimeId/seats/check
  static Future<bool> checkSeatAvailability({
    required int showtimeId,
    required List<int> seatIds,
  }) async {
    try {
      final response = await ApiService.post(
        '/showtimes/$showtimeId/seats/check',
        {'seatIds': seatIds},
      );

      return response['success'] == true;
    } catch (e) {
      // If error occurs, assume seats are not available
      return false;
    }
  }

  /// Create a new booking
  /// POST /api/bookings
  /// Requires authentication
  static Future<CreateBookingResponse> createBooking({
    required int showtimeId,
    required List<int> seatIds,
  }) async {
    try {
      final response = await ApiService.post(
        '/bookings',
        {
          'showtimeId': showtimeId,
          'seatIds': seatIds,
        },
        requiresAuth: true,
      );

      return CreateBookingResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get all bookings for the logged-in user
  /// GET /api/bookings
  /// Requires authentication
  static Future<List<BookingModel>> getUserBookings() async {
    try {
      final response = await ApiService.get('/bookings', requiresAuth: true);

      if (response['success'] == true && response['data'] != null) {
        final bookingsData = response['data']['bookings'] as List;
        return bookingsData
            .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(response['message'] ?? 'Failed to fetch bookings');
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  /// Get a single booking by ID
  /// GET /api/bookings/:id
  /// Requires authentication
  static Future<BookingModel> getBookingById(int bookingId) async {
    try {
      final response = await ApiService.get('/bookings/$bookingId', requiresAuth: true);

      if (response['success'] == true && response['data'] != null) {
        return BookingModel.fromJson(
            response['data']['booking'] as Map<String, dynamic>);
      }

      throw Exception(response['message'] ?? 'Booking not found');
    } catch (e) {
      throw Exception('Failed to fetch booking: $e');
    }
  }

  /// Process payment for a booking (MOCK)
  /// POST /api/bookings/:bookingId/payment
  /// Requires authentication
  static Future<Map<String, dynamic>> processPayment({
    required int bookingId,
    required double amount,
    String paymentMethod = 'credit_card',
    String? cardNumber,
    String? expiryDate,
    String? cvv,
  }) async {
    try {
      final response = await ApiService.post(
        '/bookings/$bookingId/payment',
        {
          'amount': amount,
          'paymentMethod': paymentMethod,
          'cardNumber': cardNumber,
          'expiryDate': expiryDate,
          'cvv': cvv,
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }

      throw Exception(response['message'] ?? 'Payment failed');
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  /// Cancel a booking
  /// DELETE /api/bookings/:id
  /// Requires authentication
  static Future<bool> cancelBooking(int bookingId) async {
    try {
      final response = await ApiService.delete('/bookings/$bookingId', requiresAuth: true);

      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }
}
