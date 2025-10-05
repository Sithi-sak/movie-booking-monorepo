import 'package:movie_booking_app/services/api_service.dart';
import 'package:movie_booking_app/data/models/movie_model.dart';

class MovieService {
  /// Get all movies with optional filters
  /// Parameters:
  /// - status: 'streaming_now' or 'coming_soon'
  /// - genre: Filter by genre
  /// - search: Search by title
  static Future<List<MovieModel>> getAllMovies({
    String? status,
    String? genre,
    String? search,
  }) async {
    try {
      // Build query string
      final queryParams = <String>[];
      if (status != null) queryParams.add('status=$status');
      if (genre != null) queryParams.add('genre=$genre');
      if (search != null) queryParams.add('search=$search');

      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final endpoint = '/movies$queryString';

      final response = await ApiService.get(endpoint);

      if (response['success'] == true && response['data'] != null) {
        final moviesData = response['data']['movies'] as List;
        return moviesData.map((json) => MovieModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch movies');
      }
    } catch (e) {
      throw Exception('Failed to fetch movies: $e');
    }
  }

  /// Get movies by status (streaming_now or coming_soon)
  static Future<List<MovieModel>> getMoviesByStatus(String status) async {
    try {
      final response = await ApiService.get('/movies/status/$status');

      if (response['success'] == true && response['data'] != null) {
        final moviesData = response['data']['movies'] as List;
        return moviesData.map((json) => MovieModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch movies');
      }
    } catch (e) {
      throw Exception('Failed to fetch movies by status: $e');
    }
  }

  /// Get a single movie by ID
  static Future<MovieModel> getMovieById(int id) async {
    try {
      final response = await ApiService.get('/movies/$id');

      if (response['success'] == true && response['data'] != null) {
        return MovieModel.fromJson(response['data']['movie']);
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch movie');
      }
    } catch (e) {
      throw Exception('Failed to fetch movie: $e');
    }
  }

  /// Get streaming now movies
  static Future<List<MovieModel>> getStreamingNowMovies() async {
    return getMoviesByStatus('streaming_now');
  }

  /// Get coming soon movies
  static Future<List<MovieModel>> getComingSoonMovies() async {
    return getMoviesByStatus('coming_soon');
  }
}
