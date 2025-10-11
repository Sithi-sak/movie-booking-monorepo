import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AdminService {
  static const String _adminTokenKey = 'admin_token';

  /// Admin Login - Authenticate with passcode
  static Future<void> login({required String password}) async {
    try {
      final response = await ApiService.post(
        '/admin/login',
        {'password': password},
        requiresAuth: false,
      );

      if (response['success'] == true) {
        final token = response['data']['token'] as String;

        // Save admin token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_adminTokenKey, token);
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Admin login failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Check if admin is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_adminTokenKey);
  }

  /// Get admin token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminTokenKey);
  }

  /// Logout admin
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminTokenKey);
  }

  /// Get Dashboard Statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await ApiService.get(
        '/admin/stats',
        requiresAuth: true,
        tokenKey: _adminTokenKey,
      );

      if (response['success'] == true) {
        return response['data']['stats'];
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch stats');
      }
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Get All Movies (including inactive)
  static Future<List<Map<String, dynamic>>> getAllMovies({
    String? status,
    String? search,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      String endpoint = '/admin/movies?page=$page&limit=$limit';

      if (status != null && status.isNotEmpty) {
        endpoint += '&status=$status';
      }

      if (search != null && search.isNotEmpty) {
        endpoint += '&search=$search';
      }

      final response = await ApiService.get(
        endpoint,
        requiresAuth: true,
        tokenKey: _adminTokenKey,
      );

      if (response['success'] == true) {
        final movies = response['data']['movies'] as List;
        return movies.cast<Map<String, dynamic>>();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch movies');
      }
    } catch (e) {
      throw Exception('Failed to fetch movies: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Get Single Movie by ID
  static Future<Map<String, dynamic>> getMovieById(int id) async {
    try {
      final response = await ApiService.get(
        '/admin/movies/$id',
        requiresAuth: true,
        tokenKey: _adminTokenKey,
      );

      if (response['success'] == true) {
        return response['data']['movie'];
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch movie');
      }
    } catch (e) {
      throw Exception('Failed to fetch movie details: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Create New Movie
  static Future<Map<String, dynamic>> createMovie({
    required String title,
    String? description,
    String? genre,
    int? duration,
    String? rating,
    double? score,
    String? posterUrl,
    String? backdropUrl,
    String? trailerUrl,
    String? language,
    String? director,
    List<String>? cast,
    DateTime? releaseDate,
    String status = 'coming_soon',
  }) async {
    try {
      final Map<String, dynamic> movieData = {
        'title': title,
        'status': status,
      };

      if (description != null) movieData['description'] = description;
      if (genre != null) movieData['genre'] = genre;
      if (duration != null) movieData['duration'] = duration;
      if (rating != null) movieData['rating'] = rating;
      if (score != null) movieData['score'] = score;
      if (posterUrl != null) movieData['posterUrl'] = posterUrl;
      if (backdropUrl != null) movieData['backdropUrl'] = backdropUrl;
      if (trailerUrl != null) movieData['trailerUrl'] = trailerUrl;
      if (language != null) movieData['language'] = language;
      if (director != null) movieData['director'] = director;
      if (cast != null) movieData['cast'] = cast;
      if (releaseDate != null) {
        movieData['releaseDate'] = releaseDate.toIso8601String();
      }

      final response = await ApiService.post(
        '/admin/movies',
        movieData,
        requiresAuth: true,
        tokenKey: _adminTokenKey,
      );

      if (response['success'] == true) {
        return response['data']['movie'];
      } else {
        throw Exception(response['message'] ?? 'Failed to create movie');
      }
    } catch (e) {
      throw Exception('Failed to create movie: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Update Movie
  static Future<Map<String, dynamic>> updateMovie({
    required int id,
    String? title,
    String? description,
    String? genre,
    int? duration,
    String? rating,
    double? score,
    String? posterUrl,
    String? backdropUrl,
    String? trailerUrl,
    String? language,
    String? director,
    List<String>? cast,
    DateTime? releaseDate,
    String? status,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> movieData = {};

      if (title != null) movieData['title'] = title;
      if (description != null) movieData['description'] = description;
      if (genre != null) movieData['genre'] = genre;
      if (duration != null) movieData['duration'] = duration;
      if (rating != null) movieData['rating'] = rating;
      if (score != null) movieData['score'] = score;
      if (posterUrl != null) movieData['posterUrl'] = posterUrl;
      if (backdropUrl != null) movieData['backdropUrl'] = backdropUrl;
      if (trailerUrl != null) movieData['trailerUrl'] = trailerUrl;
      if (language != null) movieData['language'] = language;
      if (director != null) movieData['director'] = director;
      if (cast != null) movieData['cast'] = cast;
      if (releaseDate != null) {
        movieData['releaseDate'] = releaseDate.toIso8601String();
      }
      if (status != null) movieData['status'] = status;
      if (isActive != null) movieData['isActive'] = isActive;

      final response = await ApiService.put(
        '/admin/movies/$id',
        movieData,
        requiresAuth: true,
        tokenKey: _adminTokenKey,
      );

      if (response['success'] == true) {
        return response['data']['movie'];
      } else {
        throw Exception(response['message'] ?? 'Failed to update movie');
      }
    } catch (e) {
      throw Exception('Failed to update movie: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  static Future<void> deleteMovie(int id) async {
    try {
      final response = await ApiService.delete(
        '/admin/movies/$id',
        requiresAuth: true,
        tokenKey: _adminTokenKey,
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete movie');
      }
    } catch (e) {
      throw Exception('Failed to delete movie: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Toggle Movie Status (streaming_now <-> coming_soon)
  static Future<Map<String, dynamic>> toggleMovieStatus(int id) async {
    try {
      final response = await ApiService.patch(
        '/admin/movies/$id/status',
        requiresAuth: true,
        tokenKey: _adminTokenKey,
      );

      if (response['success'] == true) {
        return response['data']['movie'];
      } else {
        throw Exception(response['message'] ?? 'Failed to toggle status');
      }
    } catch (e) {
      throw Exception('Failed to toggle movie status: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  static Future<void> restoreMovie(int id) async {
    try {
      final response = await ApiService.patch(
        '/admin/movies/$id/restore',
        requiresAuth: true,
        tokenKey: _adminTokenKey,
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to restore movie');
      }
    } catch (e) {
      throw Exception('Failed to restore movie: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}
