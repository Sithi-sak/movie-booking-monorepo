enum MovieStatus {
  streamingNow,
  comingSoon,
}

class MovieModel {
  final int id;
  final String title;
  final String? description;
  final String? posterUrl;
  final String? backdropUrl;
  final String? genre;
  final int? duration; // in minutes
  final String? rating; // PG, PG-13, R, etc. (certification rating)
  final double? score; // 0-10 numeric rating score
  final String? language;
  final DateTime? releaseDate;
  final String? director;
  final List<String>? cast;
  final String? trailerUrl;
  final MovieStatus status;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Showtime data
  final List<String>? showtimes; // Simple showtime strings from API
  final List<ShowtimeDetail>? showtimesDetails; // Full showtime details

  MovieModel({
    required this.id,
    required this.title,
    this.description,
    this.posterUrl,
    this.backdropUrl,
    this.genre,
    this.duration,
    this.rating,
    this.score,
    this.language,
    this.releaseDate,
    this.director,
    this.cast,
    this.trailerUrl,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.showtimes,
    this.showtimesDetails,
  });

  // Convenience getters
  bool get isNowShowing => status == MovieStatus.streamingNow;
  bool get isComingSoon => status == MovieStatus.comingSoon;

  String get statusDisplayName {
    switch (status) {
      case MovieStatus.streamingNow:
        return 'Streaming Now';
      case MovieStatus.comingSoon:
        return 'Coming Soon';
    }
  }

  // For backward compatibility with old UI that expects price
  double get price => showtimesDetails?.isNotEmpty == true
      ? (showtimesDetails!.first.price ?? 0.0)
      : 0.0;

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    List<String>? parseCast(dynamic castData) {
      if (castData == null) return null;
      if (castData is List) {
        return castData.map((e) => e.toString()).toList();
      }
      return null;
    }

    return MovieModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      posterUrl: json['posterUrl'] as String?,
      backdropUrl: json['backdropUrl'] as String?,
      genre: json['genre'] as String?,
      duration: json['duration'] as int?,
      rating: json['rating'] as String?,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      language: json['language'] as String?,
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'] as String)
          : null,
      director: json['director'] as String?,
      cast: parseCast(json['cast']),
      trailerUrl: json['trailerUrl'] as String?,
      status: json['status'] == 'streaming_now'
          ? MovieStatus.streamingNow
          : MovieStatus.comingSoon,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      showtimes: json['showtimes'] != null
          ? List<String>.from(json['showtimes'] as List)
          : null,
      showtimesDetails: json['showtimesDetails'] != null
          ? (json['showtimesDetails'] as List)
              .map((s) => ShowtimeDetail.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'genre': genre,
      'duration': duration,
      'rating': rating,
      'score': score,
      'language': language,
      'releaseDate': releaseDate?.toIso8601String(),
      'director': director,
      'cast': cast,
      'trailerUrl': trailerUrl,
      'status': status == MovieStatus.streamingNow ? 'streaming_now' : 'coming_soon',
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'showtimes': showtimes,
      'showtimesDetails': showtimesDetails?.map((s) => s.toJson()).toList(),
    };
  }
}

// Showtime detail model
class ShowtimeDetail {
  final int id;
  final DateTime showTime;
  final double? price;
  final int? availableSeats;
  final TheaterInfo? theater;

  ShowtimeDetail({
    required this.id,
    required this.showTime,
    this.price,
    this.availableSeats,
    this.theater,
  });

  factory ShowtimeDetail.fromJson(Map<String, dynamic> json) {
    return ShowtimeDetail(
      id: json['id'] as int,
      showTime: DateTime.parse(json['showTime'] as String),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      availableSeats: json['availableSeats'] as int?,
      theater: json['theater'] != null
          ? TheaterInfo.fromJson(json['theater'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'showTime': showTime.toIso8601String(),
      'price': price,
      'availableSeats': availableSeats,
      'theater': theater?.toJson(),
    };
  }
}

// Theater info model
class TheaterInfo {
  final int id;
  final String name;
  final String? city;

  TheaterInfo({
    required this.id,
    required this.name,
    this.city,
  });

  factory TheaterInfo.fromJson(Map<String, dynamic> json) {
    return TheaterInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      city: json['city'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
    };
  }
}
