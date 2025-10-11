import 'package:flutter/material.dart';
import 'package:movie_booking_app/services/admin_service.dart';

class MovieFormScreen extends StatefulWidget {
  final Map<String, dynamic>? movie; // null for create, non-null for edit

  const MovieFormScreen({super.key, this.movie});

  @override
  State<MovieFormScreen> createState() => _MovieFormScreenState();
}

class _MovieFormScreenState extends State<MovieFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _genreController;
  late final TextEditingController _durationController;
  late final TextEditingController _ratingController;
  late final TextEditingController _scoreController;
  late final TextEditingController _posterUrlController;
  late final TextEditingController _backdropUrlController;
  late final TextEditingController _trailerUrlController;
  late final TextEditingController _languageController;
  late final TextEditingController _directorController;
  late final TextEditingController _castController;

  DateTime? _releaseDate;
  String _selectedStatus = 'coming_soon';

  bool get isEditMode => widget.movie != null;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController = TextEditingController(text: widget.movie?['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.movie?['description'] ?? '');
    _genreController = TextEditingController(text: widget.movie?['genre'] ?? '');
    _durationController = TextEditingController(
      text: widget.movie?['duration']?.toString() ?? '',
    );
    _ratingController = TextEditingController(text: widget.movie?['rating'] ?? '');
    _scoreController = TextEditingController(
      text: widget.movie?['score']?.toString() ?? '',
    );
    _posterUrlController = TextEditingController(text: widget.movie?['posterUrl'] ?? '');
    _backdropUrlController = TextEditingController(text: widget.movie?['backdropUrl'] ?? '');
    _trailerUrlController = TextEditingController(text: widget.movie?['trailerUrl'] ?? '');
    _languageController = TextEditingController(text: widget.movie?['language'] ?? '');
    _directorController = TextEditingController(text: widget.movie?['director'] ?? '');

    // Cast - convert from JSON array to comma-separated string
    if (widget.movie?['cast'] != null) {
      final castList = widget.movie!['cast'] as List;
      _castController = TextEditingController(text: castList.join(', '));
    } else {
      _castController = TextEditingController();
    }

    // Release date
    if (widget.movie?['releaseDate'] != null) {
      _releaseDate = DateTime.parse(widget.movie!['releaseDate']);
    }

    // Status
    _selectedStatus = widget.movie?['status'] ?? 'coming_soon';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _genreController.dispose();
    _durationController.dispose();
    _ratingController.dispose();
    _scoreController.dispose();
    _posterUrlController.dispose();
    _backdropUrlController.dispose();
    _trailerUrlController.dispose();
    _languageController.dispose();
    _directorController.dispose();
    _castController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse cast from comma-separated string to list
      List<String>? cast;
      if (_castController.text.isNotEmpty) {
        cast = _castController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      if (isEditMode) {
        // Update existing movie
        await AdminService.updateMovie(
          id: widget.movie!['id'],
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          genre: _genreController.text.isEmpty ? null : _genreController.text,
          duration: _durationController.text.isEmpty ? null : int.parse(_durationController.text),
          rating: _ratingController.text.isEmpty ? null : _ratingController.text,
          score: _scoreController.text.isEmpty ? null : double.parse(_scoreController.text),
          posterUrl: _posterUrlController.text.isEmpty ? null : _posterUrlController.text,
          backdropUrl: _backdropUrlController.text.isEmpty ? null : _backdropUrlController.text,
          trailerUrl: _trailerUrlController.text.isEmpty ? null : _trailerUrlController.text,
          language: _languageController.text.isEmpty ? null : _languageController.text,
          director: _directorController.text.isEmpty ? null : _directorController.text,
          cast: cast,
          releaseDate: _releaseDate,
          status: _selectedStatus,
        );
      } else {
        // Create new movie
        await AdminService.createMovie(
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          genre: _genreController.text.isEmpty ? null : _genreController.text,
          duration: _durationController.text.isEmpty ? null : int.parse(_durationController.text),
          rating: _ratingController.text.isEmpty ? null : _ratingController.text,
          score: _scoreController.text.isEmpty ? null : double.parse(_scoreController.text),
          posterUrl: _posterUrlController.text.isEmpty ? null : _posterUrlController.text,
          backdropUrl: _backdropUrlController.text.isEmpty ? null : _backdropUrlController.text,
          trailerUrl: _trailerUrlController.text.isEmpty ? null : _trailerUrlController.text,
          language: _languageController.text.isEmpty ? null : _languageController.text,
          director: _directorController.text.isEmpty ? null : _directorController.text,
          cast: cast,
          releaseDate: _releaseDate,
          status: _selectedStatus,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode ? 'Movie updated successfully' : 'Movie created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2D5F4D),
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _releaseDate) {
      setState(() {
        _releaseDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? 'Edit Movie' : 'Add New Movie',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title (Required)
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'Enter movie title',
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Enter movie description',
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Genre
            _buildTextField(
              controller: _genreController,
              label: 'Genre',
              hint: 'e.g., Action, Drama, Comedy',
            ),
            const SizedBox(height: 16),

            // Duration and Rating (Row)
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _durationController,
                    label: 'Duration (minutes)',
                    hint: '120',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _ratingController,
                    label: 'Rating',
                    hint: 'PG-13',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Score
            _buildTextField(
              controller: _scoreController,
              label: 'Score (0-10)',
              hint: '7.5',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Poster URL
            _buildTextField(
              controller: _posterUrlController,
              label: 'Poster URL',
              hint: 'https://image.tmdb.org/...',
            ),
            const SizedBox(height: 16),

            // Backdrop URL
            _buildTextField(
              controller: _backdropUrlController,
              label: 'Backdrop URL',
              hint: 'https://image.tmdb.org/...',
            ),
            const SizedBox(height: 16),

            // Trailer URL
            _buildTextField(
              controller: _trailerUrlController,
              label: 'Trailer URL',
              hint: 'https://www.youtube.com/...',
            ),
            const SizedBox(height: 16),

            // Language and Director (Row)
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _languageController,
                    label: 'Language',
                    hint: 'English',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _directorController,
                    label: 'Director',
                    hint: 'Director name',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cast
            _buildTextField(
              controller: _castController,
              label: 'Cast',
              hint: 'Actor 1, Actor 2, Actor 3',
              helperText: 'Separate actors with commas',
            ),
            const SizedBox(height: 16),

            // Release Date
            const Text(
              'Release Date',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _releaseDate != null
                          ? '${_releaseDate!.year}-${_releaseDate!.month.toString().padLeft(2, '0')}-${_releaseDate!.day.toString().padLeft(2, '0')}'
                          : 'Select release date',
                      style: TextStyle(
                        color: _releaseDate != null ? Colors.white : const Color(0xFF666666),
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: Color(0xFF666666)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status
            const Text(
              'Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text(
                      'Streaming Now',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 'streaming_now',
                    groupValue: _selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                    activeColor: const Color(0xFF2D5F4D),
                    tileColor: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text(
                      'Coming Soon',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 'coming_soon',
                    groupValue: _selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                    activeColor: const Color(0xFF2D5F4D),
                    tileColor: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5F4D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditMode ? 'Update Movie' : 'Create Movie',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF666666)),
            helperText: helperText,
            helperStyle: const TextStyle(color: Color(0xFF666666), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2D5F4D), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label is required';
            }
            if (keyboardType == TextInputType.number && value != null && value.isNotEmpty) {
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
            }
            if (keyboardType == const TextInputType.numberWithOptions(decimal: true) &&
                value != null &&
                value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
