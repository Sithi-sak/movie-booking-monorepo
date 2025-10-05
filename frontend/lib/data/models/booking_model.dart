import 'package:movie_booking_app/data/models/showtime_model.dart';

class BookingModel {
  final int id;
  final String bookingReference; // e.g., "BK-A3F9D2"
  final String status; // "confirmed", "pending", "cancelled"
  final String paymentStatus; // "pending", "completed", "failed"
  final double totalAmount;
  final DateTime bookingDate;
  final ShowtimeInfoInBooking? showtime;
  final MovieInfoInBooking? movie;
  final TheaterModel? theater;
  final List<BookedSeat> seats;
  final int seatCount;

  BookingModel({
    required this.id,
    required this.bookingReference,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.bookingDate,
    this.showtime,
    this.movie,
    this.theater,
    required this.seats,
    required this.seatCount,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int,
      bookingReference: json['bookingReference'] as String,
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      showtime: json['showtime'] != null
          ? ShowtimeInfoInBooking.fromJson(json['showtime'] as Map<String, dynamic>)
          : null,
      movie: json['movie'] != null
          ? MovieInfoInBooking.fromJson(json['movie'] as Map<String, dynamic>)
          : null,
      theater: json['theater'] != null
          ? TheaterModel.fromJson(json['theater'] as Map<String, dynamic>)
          : null,
      seats: json['seats'] != null
          ? (json['seats'] as List)
              .map((s) => BookedSeat.fromJson(s as Map<String, dynamic>))
              .toList()
          : [],
      seatCount: json['seatCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingReference': bookingReference,
      'status': status,
      'paymentStatus': paymentStatus,
      'totalAmount': totalAmount,
      'bookingDate': bookingDate.toIso8601String(),
      'showtime': showtime?.toJson(),
      'movie': movie?.toJson(),
      'theater': theater?.toJson(),
      'seats': seats.map((s) => s.toJson()).toList(),
      'seatCount': seatCount,
    };
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';

  bool get isPaid => paymentStatus == 'completed';
  bool get isPaymentPending => paymentStatus == 'pending';
}

class ShowtimeInfoInBooking {
  final int id;
  final DateTime showTime;
  final int screenNumber;
  final double? price;

  ShowtimeInfoInBooking({
    required this.id,
    required this.showTime,
    required this.screenNumber,
    this.price,
  });

  factory ShowtimeInfoInBooking.fromJson(Map<String, dynamic> json) {
    return ShowtimeInfoInBooking(
      id: json['id'] as int,
      showTime: DateTime.parse(json['showTime'] as String),
      screenNumber: json['screenNumber'] as int,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'showTime': showTime.toIso8601String(),
      'screenNumber': screenNumber,
      'price': price,
    };
  }

  String get formattedTime {
    final hour = showTime.hour;
    final minute = showTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[showTime.month - 1]} ${showTime.day}, ${showTime.year}';
  }
}

class MovieInfoInBooking {
  final int id;
  final String title;
  final String? posterUrl;
  final int? duration;
  final String? rating;

  MovieInfoInBooking({
    required this.id,
    required this.title,
    this.posterUrl,
    this.duration,
    this.rating,
  });

  factory MovieInfoInBooking.fromJson(Map<String, dynamic> json) {
    return MovieInfoInBooking(
      id: json['id'] as int,
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String?,
      duration: json['duration'] as int?,
      rating: json['rating'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterUrl': posterUrl,
      'duration': duration,
      'rating': rating,
    };
  }
}

class BookedSeat {
  final String seatNumber;
  final String? seatType;
  final double? price;
  final String? rowName;
  final int? seatColumn;

  BookedSeat({
    required this.seatNumber,
    this.seatType,
    this.price,
    this.rowName,
    this.seatColumn,
  });

  factory BookedSeat.fromJson(Map<String, dynamic> json) {
    return BookedSeat(
      seatNumber: json['seatNumber'] as String,
      seatType: json['seatType'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      rowName: json['rowName'] as String?,
      seatColumn: json['seatColumn'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seatNumber': seatNumber,
      'seatType': seatType,
      'price': price,
      'rowName': rowName,
      'seatColumn': seatColumn,
    };
  }
}

// Response model for creating a booking
class CreateBookingResponse {
  final bool success;
  final String message;
  final BookingData? booking;

  CreateBookingResponse({
    required this.success,
    required this.message,
    this.booking,
  });

  factory CreateBookingResponse.fromJson(Map<String, dynamic> json) {
    return CreateBookingResponse(
      success: json['success'] as bool,
      message: json['message'] as String? ?? '',
      booking: json['data']?['booking'] != null
          ? BookingData.fromJson(json['data']['booking'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BookingData {
  final int id;
  final String bookingReference;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final DateTime bookingDate;
  final BookingShowtimeInfo showtime;
  final List<BookedSeat> seats;

  BookingData({
    required this.id,
    required this.bookingReference,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.bookingDate,
    required this.showtime,
    required this.seats,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      id: json['id'] as int,
      bookingReference: json['bookingReference'] as String,
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      showtime: BookingShowtimeInfo.fromJson(json['showtime'] as Map<String, dynamic>),
      seats: (json['seats'] as List)
          .map((s) => BookedSeat.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BookingShowtimeInfo {
  final int id;
  final DateTime showTime;
  final String movie;
  final String theater;
  final int screenNumber;

  BookingShowtimeInfo({
    required this.id,
    required this.showTime,
    required this.movie,
    required this.theater,
    required this.screenNumber,
  });

  factory BookingShowtimeInfo.fromJson(Map<String, dynamic> json) {
    return BookingShowtimeInfo(
      id: json['id'] as int,
      showTime: DateTime.parse(json['showTime'] as String),
      movie: json['movie'] as String,
      theater: json['theater'] as String,
      screenNumber: json['screenNumber'] as int,
    );
  }
}
