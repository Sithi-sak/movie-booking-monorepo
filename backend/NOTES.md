enum MovieStatus {
  streamingNow,
  comingSoon,
}

class MovieModel {
  final int id;
  final String title;
  final String description;
  final String posterUrl;
  final String backdropUrl;
  final String genre;
  final int duration; // in minutes
  final double rating;
  final String language;
  final DateTime releaseDate;
  final List<String> showtimes;
  final double price;
  final String director;
  final List<String> cast;
  final String trailerUrl;
  final MovieStatus status;

  MovieModel({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.backdropUrl,
    required this.genre,
    required this.duration,
    required this.rating,
    required this.language,
    required this.releaseDate,
    required this.showtimes,
    required this.price,
    required this.director,
    required this.cast,
    required this.trailerUrl,
    required this.status,
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

  // Convert from JSON
  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      posterUrl: json['poster_url'],
      backdropUrl: json['backdrop_url'],
      genre: json['genre'],
      duration: json['duration'],
      rating: json['rating'].toDouble(),
      language: json['language'],
      releaseDate: DateTime.parse(json['release_date']),
      showtimes: List<String>.from(json['showtimes']),
      price: json['price'].toDouble(),
      director: json['director'],
      cast: List<String>.from(json['cast']),
      trailerUrl: json['trailer_url'],
      status: json['status'] == 'streaming_now'
          ? MovieStatus.streamingNow
          : MovieStatus.comingSoon,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'poster_url': posterUrl,
      'backdrop_url': backdropUrl,
      'genre': genre,
      'duration': duration,
      'rating': rating,
      'language': language,
      'release_date': releaseDate.toIso8601String(),
      'showtimes': showtimes,
      'price': price,
      'director': director,
      'cast': cast,
      'trailer_url': trailerUrl,
      'status': status == MovieStatus.streamingNow ? 'streaming_now' : 'coming_soon',
    };
  }
}
