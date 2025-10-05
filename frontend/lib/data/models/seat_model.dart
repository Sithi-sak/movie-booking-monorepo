import 'package:movie_booking_app/data/models/showtime_model.dart';

class SeatModel {
  final int id;
  final String seatNumber; // e.g., "A1", "B5"
  final String rowName; // e.g., "A", "B", "C"
  final int seatColumn; // e.g., 1, 2, 3
  final String seatType; // "regular" or "premium"
  final double price;
  final bool isBooked;
  final bool isAisle; // For spacing in UI

  SeatModel({
    required this.id,
    required this.seatNumber,
    required this.rowName,
    required this.seatColumn,
    required this.seatType,
    required this.price,
    required this.isBooked,
    required this.isAisle,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      id: json['id'] as int? ?? 0,
      seatNumber: json['seatNumber'] as String? ?? '',
      rowName: json['rowName'] as String? ?? '',
      seatColumn: json['seatColumn'] as int? ?? 0,
      seatType: json['seatType'] as String? ?? 'regular',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isBooked: json['isBooked'] as bool? ?? false,
      isAisle: json['isAisle'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seatNumber': seatNumber,
      'rowName': rowName,
      'seatColumn': seatColumn,
      'seatType': seatType,
      'price': price,
      'isBooked': isBooked,
      'isAisle': isAisle,
    };
  }

  bool get isPremium => seatType == 'premium';
  bool get isRegular => seatType == 'regular';
  bool get isAvailable => !isBooked;
}

class SeatLayoutResponse {
  final ShowtimeModel showtime;
  final List<SeatModel> seats;
  final Map<String, List<SeatModel>> seatsByRow;
  final SeatLayoutInfo layout;
  final SeatPricing pricing;

  SeatLayoutResponse({
    required this.showtime,
    required this.seats,
    required this.seatsByRow,
    required this.layout,
    required this.pricing,
  });

  factory SeatLayoutResponse.fromJson(Map<String, dynamic> json) {
    try {
      final data = json['data'] as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('No data field in response');
      }

      // Parse seats
      final seatsJson = data['seats'] as List?;
      if (seatsJson == null) {
        throw Exception('No seats field in data');
      }

      final seatsList = seatsJson
          .map((s) => SeatModel.fromJson(s as Map<String, dynamic>))
          .toList();

      // Parse seatsByRow
      final seatsByRowMap = <String, List<SeatModel>>{};
      final seatsByRowJson = data['seatsByRow'] as Map<String, dynamic>?;

      if (seatsByRowJson != null) {
        seatsByRowJson.forEach((row, seatsJson) {
          if (seatsJson is List) {
            seatsByRowMap[row] = seatsJson
                .map((s) => SeatModel.fromJson(s as Map<String, dynamic>))
                .toList();
          }
        });
      }

      final showtimeJson = data['showtime'] as Map<String, dynamic>?;
      final layoutJson = data['layout'] as Map<String, dynamic>?;
      final pricingJson = data['pricing'] as Map<String, dynamic>?;

      if (showtimeJson == null) throw Exception('No showtime field');
      if (layoutJson == null) throw Exception('No layout field');
      if (pricingJson == null) throw Exception('No pricing field');

      return SeatLayoutResponse(
        showtime: ShowtimeModel.fromJson(showtimeJson),
        seats: seatsList,
        seatsByRow: seatsByRowMap,
        layout: SeatLayoutInfo.fromJson(layoutJson),
        pricing: SeatPricing.fromJson(pricingJson),
      );
    } catch (e) {
      print('ERROR parsing SeatLayoutResponse: $e');
      print('JSON received: $json');
      rethrow;
    }
  }

  List<String> get sortedRows => layout.rows;

  int get maxColumns => layout.columns;
}

class SeatLayoutInfo {
  final List<String> rows; // e.g., ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
  final int columns; // e.g., 12
  final int totalSeats;
  final int availableSeats;
  final int bookedSeats;

  SeatLayoutInfo({
    required this.rows,
    required this.columns,
    required this.totalSeats,
    required this.availableSeats,
    required this.bookedSeats,
  });

  factory SeatLayoutInfo.fromJson(Map<String, dynamic> json) {
    return SeatLayoutInfo(
      rows: json['rows'] != null ? List<String>.from(json['rows'] as List) : [],
      columns: json['columns'] as int? ?? 0,
      totalSeats: json['totalSeats'] as int? ?? 0,
      availableSeats: json['availableSeats'] as int? ?? 0,
      bookedSeats: json['bookedSeats'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'columns': columns,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'bookedSeats': bookedSeats,
    };
  }
}

class SeatPricing {
  final double regular;
  final double premium;

  SeatPricing({
    required this.regular,
    required this.premium,
  });

  factory SeatPricing.fromJson(Map<String, dynamic> json) {
    return SeatPricing(
      regular: (json['regular'] as num?)?.toDouble() ?? 0.0,
      premium: (json['premium'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'regular': regular,
      'premium': premium,
    };
  }
}
