class ShowtimeModel {
  final int id;
  final int movieId;
  final int theaterId;
  final int screenNumber;
  final DateTime showTime;
  final int availableSeats;
  final int totalSeats;
  final double price;
  final bool isActive;
  final TheaterModel? theater;
  final MovieBasicInfo? movie;

  ShowtimeModel({
    required this.id,
    required this.movieId,
    required this.theaterId,
    required this.screenNumber,
    required this.showTime,
    required this.availableSeats,
    required this.totalSeats,
    required this.price,
    required this.isActive,
    this.theater,
    this.movie,
  });

  factory ShowtimeModel.fromJson(Map<String, dynamic> json) {
    return ShowtimeModel(
      id: json['id'] as int? ?? 0,
      movieId: json['movieId'] as int? ?? 0,
      theaterId: json['theaterId'] as int? ?? 0,
      screenNumber: json['screenNumber'] as int? ?? 0,
      showTime: json['showTime'] != null
          ? DateTime.parse(json['showTime'] as String)
          : DateTime.now(),
      availableSeats: json['availableSeats'] as int? ?? 0,
      totalSeats: json['totalSeats'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      theater: json['theater'] != null
          ? TheaterModel.fromJson(json['theater'] as Map<String, dynamic>)
          : null,
      movie: json['movie'] != null
          ? MovieBasicInfo.fromJson(json['movie'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movieId': movieId,
      'theaterId': theaterId,
      'screenNumber': screenNumber,
      'showTime': showTime.toIso8601String(),
      'availableSeats': availableSeats,
      'totalSeats': totalSeats,
      'price': price,
      'isActive': isActive,
      'theater': theater?.toJson(),
      'movie': movie?.toJson(),
    };
  }

  // Helper to format showtime for display
  String get formattedTime {
    final hour = showTime.hour;
    final minute = showTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[showTime.month - 1]} ${showTime.day}';
  }
}

class TheaterModel {
  final int id;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? phone;
  final int screens;

  TheaterModel({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.phone,
    required this.screens,
  });

  factory TheaterModel.fromJson(Map<String, dynamic> json) {
    return TheaterModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Theater',
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      phone: json['phone'] as String?,
      screens: json['screens'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phone': phone,
      'screens': screens,
    };
  }

  String get fullAddress {
    final parts = [address, city, state, zipCode]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

class MovieBasicInfo {
  final int id;
  final String title;
  final int? duration;
  final String? rating;

  MovieBasicInfo({
    required this.id,
    required this.title,
    this.duration,
    this.rating,
  });

  factory MovieBasicInfo.fromJson(Map<String, dynamic> json) {
    return MovieBasicInfo(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Unknown Movie',
      duration: json['duration'] as int?,
      rating: json['rating'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'rating': rating,
    };
  }
}
