import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movie_booking_app/core/theme/app_theme.dart';
import 'package:movie_booking_app/data/models/movie_model.dart';
import 'package:movie_booking_app/data/models/showtime_model.dart';
import 'package:movie_booking_app/data/models/seat_model.dart';
import 'package:movie_booking_app/presentation/screens/booking/booking_confirmation_screen.dart';
import 'package:movie_booking_app/services/booking_service.dart';

class TicketBookingScreen extends StatefulWidget {
  final MovieModel movie;

  const TicketBookingScreen({
    super.key,
    required this.movie,
  });

  @override
  State<TicketBookingScreen> createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _seatAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Booking flow state
  int currentStep = 0;

  // Showtime state
  Map<String, List<ShowtimeModel>> showtimesByDate = {};
  String selectedDate = '';
  ShowtimeModel? selectedShowtime;
  bool _isLoadingShowtimes = false;
  String? _showtimesError;

  // Seat state
  SeatLayoutResponse? seatLayout;
  List<SeatModel> selectedSeats = [];
  bool _isLoadingSeats = false;
  String? _seatsError;

  final PageController _pageController = PageController();

  final List<String> stepTitles = [
    'Date & Time',
    'Pick Seats',
    'Review & Pay'
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _seatAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _seatAnimationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // Fetch showtimes for the movie
    _fetchShowtimesByMovie();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _seatAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Fetch showtimes from backend API
  Future<void> _fetchShowtimesByMovie() async {
    setState(() {
      _isLoadingShowtimes = true;
      _showtimesError = null;
    });

    try {
      final showtimes = await BookingService.getShowtimesByMovie(widget.movie.id);

      setState(() {
        showtimesByDate = showtimes;
        _isLoadingShowtimes = false;

        // Auto-select first date if available
        if (showtimesByDate.isNotEmpty) {
          selectedDate = showtimesByDate.keys.first;
        }
      });
    } catch (e) {
      setState(() {
        _showtimesError = e.toString();
        _isLoadingShowtimes = false;
      });
    }
  }

  /// Fetch seats for selected showtime
  Future<void> _fetchSeatsByShowtime(int showtimeId) async {
    setState(() {
      _isLoadingSeats = true;
      _seatsError = null;
    });

    try {
      final layout = await BookingService.getSeatsByShowtime(showtimeId);

      setState(() {
        seatLayout = layout;
        _isLoadingSeats = false;
      });
    } catch (e) {
      setState(() {
        _seatsError = e.toString();
        _isLoadingSeats = false;
      });
    }
  }

  void _nextStep() {
    if (currentStep < 2) {
      setState(() {
        currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectSeat(SeatModel seat) {
    if (seat.isBooked) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat ${seat.seatNumber} is already booked'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      final index = selectedSeats.indexWhere((s) => s.id == seat.id);
      if (index >= 0) {
        selectedSeats.removeAt(index);
      } else {
        selectedSeats.add(seat);
      }
    });

    _seatAnimationController.forward().then((_) {
      _seatAnimationController.reverse();
    });

    HapticFeedback.selectionClick();
  }

  double _calculateTotalPrice() {
    return selectedSeats.fold(0.0, (sum, seat) => sum + seat.price);
  }

  Color _getSeatColor(SeatModel seat) {
    if (seat.isBooked) return Colors.red.shade300;
    if (selectedSeats.any((s) => s.id == seat.id)) return AppTheme.primaryRed;
    if (seat.isPremium) return AppTheme.surfaceDark.withValues(alpha: 0.9);
    return AppTheme.surfaceDark;
  }

  bool _canProceed() {
    switch (currentStep) {
      case 0:
        return selectedDate.isNotEmpty && selectedShowtime != null;
      case 1:
        return selectedSeats.isNotEmpty;
      case 2:
        return selectedSeats.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark.withValues(alpha: 0.8),
              AppTheme.backgroundDark.withValues(alpha: 0.9),
              AppTheme.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      currentStep = index;
                    });
                  },
                  children: [
                    _buildDateTimeSelection(),
                    _buildSeatSelection(),
                    _buildReviewPage(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Tickets',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stepTitles[currentStep],
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(stepTitles.length, (index) {
          bool isActive = index <= currentStep;
          bool isCurrent = index == currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < stepTitles.length - 1 ? 8 : 0),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primaryRed : AppTheme.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: isCurrent ? AppTheme.primaryRed :
                             isActive ? AppTheme.textPrimary : AppTheme.textTertiary,
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    child: Text(stepTitles[index]),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMovieHeader(),
              const SizedBox(height: 32),
              Text(
                'When would you like to watch?',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your preferred date and time',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              if (_isLoadingShowtimes)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_showtimesError != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load showtimes',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showtimesError!,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchShowtimesByMovie,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (showtimesByDate.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No showtimes available',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This movie is not currently showing',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Date Selection
                Text(
                  'Choose Date',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: showtimesByDate.keys.length,
                    itemBuilder: (context, index) {
                      final date = showtimesByDate.keys.elementAt(index);
                      final showtimes = showtimesByDate[date]!;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildDateButton(date, showtimes.length),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Time Selection
                if (selectedDate.isNotEmpty) ...[
                  Text(
                    'Choose Showtime',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available showtimes for ${_formatDateDisplay(selectedDate)}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: showtimesByDate[selectedDate]!.length,
                      itemBuilder: (context, index) {
                        final showtime = showtimesByDate[selectedDate]![index];
                        return _buildShowtimeButton(showtime);
                      },
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatSelection() {
    if (_isLoadingSeats) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_seatsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load seats',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _seatsError!,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (selectedShowtime != null) {
                  _fetchSeatsByShowtime(selectedShowtime!.id);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (seatLayout == null) {
      return Center(
        child: Text(
          'Please select a showtime first',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your seats',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${seatLayout!.layout.availableSeats} seats available',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Screen indicator
          _buildScreenIndicator(),

          const SizedBox(height: 32),

          // Seat layout
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDynamicSeatLayout(),
                  const SizedBox(height: 24),
                  _buildSeatLegend(),
                  const SizedBox(height: 24),
                  if (selectedSeats.isNotEmpty) _buildSeatSummary(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review your booking',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Double-check everything looks good',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildBookingSummaryCard(),
                  const SizedBox(height: 20),
                  _buildPricingBreakdown(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 35, 35, 35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderDark.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.movie.posterUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.surfaceDark,
                    child: Icon(
                      Icons.movie_creation_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.movie.title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.movie.genre?.split(',').first ?? 'Unknown',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.movie.score?.toStringAsFixed(1) ?? widget.movie.rating ?? 'N/A',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String date, int showtimeCount) {
    bool isSelected = selectedDate == date;
    final dateTime = DateTime.parse(date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String displayLabel;
    if (dateTime == today) {
      displayLabel = 'Today';
    } else if (dateTime == tomorrow) {
      displayLabel = 'Tomorrow';
    } else {
      displayLabel = _formatDateDisplay(date);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDate = date;
          selectedShowtime = null;
          selectedSeats.clear();
          seatLayout = null;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [AppTheme.primaryRed, AppTheme.primaryRed.withValues(alpha: 0.8)],
          ) : null,
          color: !isSelected ? AppTheme.surfaceDark.withValues(alpha: 0.6) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : AppTheme.borderDark,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryRed.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayLabel,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$showtimeCount showtime${showtimeCount != 1 ? 's' : ''}',
              style: TextStyle(
                color: const Color.fromARGB(255, 208, 208, 208),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowtimeButton(ShowtimeModel showtime) {
    bool isSelected = selectedShowtime?.id == showtime.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedShowtime = showtime;
          selectedSeats.clear();
        });
        _fetchSeatsByShowtime(showtime.id);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        height: 400,
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [AppTheme.primaryRed, const Color.fromARGB(255, 71, 56, 56).withValues(alpha: 0.8)],
          ) : null,
          color: !isSelected ? AppTheme.surfaceDark.withValues(alpha: 0.6) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : AppTheme.borderDark,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              showtime.formattedTime,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              showtime.theater?.name ?? 'Theater',
              style: TextStyle(
                color: const Color.fromARGB(255, 209, 209, 209),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${showtime.availableSeats} seats left',
              style: TextStyle(
                color: showtime.availableSeats < 10 ? Colors.orange : const Color.fromARGB(255, 209, 209, 209),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenIndicator() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.primaryRed.withValues(alpha: 0.6),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'SCREEN',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicSeatLayout() {
    if (seatLayout == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: seatLayout!.sortedRows.map((row) {
            final seatsInRow = seatLayout!.seatsByRow[row] ?? [];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row label
                  SizedBox(
                    width: 20,
                    child: Text(
                      row,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Seats
                  ...seatsInRow.map((seat) {
                    if (seat.isAisle) {
                      return const SizedBox(width: 24, height: 24);
                    }
                    return _buildSeatWidget(seat);
                  }),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSeatWidget(SeatModel seat) {
    bool isSelected = selectedSeats.any((s) => s.id == seat.id);

    return GestureDetector(
      onTap: () => _selectSeat(seat),
      child: ScaleTransition(
        scale: isSelected ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: _getSeatColor(seat),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isSelected ? AppTheme.primaryRed :
                     seat.isBooked ? Colors.red.shade400 :
                     seat.isPremium ? Colors.amber.shade700 : AppTheme.borderDark,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.primaryRed.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ] : seat.isBooked ? [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
          child: Stack(
            children: [
              Center(
                child: seat.isBooked
                    ? Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      )
                    : Text(
                        seat.seatNumber.replaceAll(RegExp(r'[A-Z]'), ''),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (seat.isPremium && !seat.isBooked)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 8,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatLegend() {
    if (seatLayout == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Available', AppTheme.surfaceDark, null),
              _buildLegendItem('Selected', AppTheme.primaryRed, null),
              _buildLegendItem('Booked', Colors.red.shade300, null),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                'Premium (\$${seatLayout!.pricing.premium.toStringAsFixed(0)})',
                AppTheme.surfaceDark,
                Icons.star,
              ),
              _buildLegendItem(
                'Regular (\$${seatLayout!.pricing.regular.toStringAsFixed(0)})',
                AppTheme.surfaceDark,
                null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData? icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: icon != null ? Colors.amber.shade700 : AppTheme.borderDark,
            ),
          ),
          child: icon != null
              ? Icon(icon, color: Colors.amber, size: 10)
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatSummary() {
    final totalPrice = _calculateTotalPrice();
    final premiumSeats = selectedSeats.where((s) => s.isPremium).toList();
    final regularSeats = selectedSeats.where((s) => !s.isPremium).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryRed.withValues(alpha: 0.1),
            AppTheme.primaryRed.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryRed.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Seats (${selectedSeats.length})',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (premiumSeats.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Premium: ${premiumSeats.map((s) => s.seatNumber).join(', ')}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (regularSeats.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.event_seat, color: AppTheme.textSecondary, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Regular: ${regularSeats.map((s) => s.seatNumber).join(', ')}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceDark.withValues(alpha: 0.8),
            AppTheme.surfaceDark.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderDark.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Movie', widget.movie.title),
          _buildSummaryRow('Date', _formatDateDisplay(selectedDate)),
          _buildSummaryRow('Time', selectedShowtime?.formattedTime ?? ''),
          _buildSummaryRow('Theater', selectedShowtime?.theater?.name ?? 'N/A'),
          _buildSummaryRow('Screen', 'Screen ${selectedShowtime?.screenNumber ?? ''}'),
          _buildSummaryRow('Seats', selectedSeats.map((s) => s.seatNumber).join(', ')),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    double subtotal = _calculateTotalPrice();
    double fees = subtotal * 0.1;
    double tax = (subtotal + fees) * 0.08;
    double finalTotal = subtotal + fees + tax;

    final premiumCount = selectedSeats.where((s) => s.isPremium).length;
    final regularCount = selectedSeats.where((s) => !s.isPremium).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryRed.withValues(alpha: 0.1),
            AppTheme.primaryRed.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryRed.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Breakdown',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (premiumCount > 0)
            _buildPriceRow(
              'Premium Seats ($premiumCount)',
              '\$${(selectedSeats.where((s) => s.isPremium).fold<double>(0, (sum, s) => sum + s.price)).toStringAsFixed(2)}',
            ),
          if (regularCount > 0)
            _buildPriceRow(
              'Regular Seats ($regularCount)',
              '\$${(selectedSeats.where((s) => !s.isPremium).fold<double>(0, (sum, s) => sum + s.price)).toStringAsFixed(2)}',
            ),
          _buildPriceRow('Service Fee', '\$${fees.toStringAsFixed(2)}'),
          _buildPriceRow('Tax', '\$${tax.toStringAsFixed(2)}'),
          const Divider(color: Colors.white24, height: 20),
          _buildPriceRow('Total Amount', '\$${finalTotal.toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isTotal ? AppTheme.primaryRed : AppTheme.textPrimary,
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    double finalTotal = _calculateTotalPrice() * 1.18; // Including fees and tax

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderDark.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed() ? () {
                if (currentStep == 2) {
                  // Navigate to confirmation with all required data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingConfirmationScreen(
                        movie: widget.movie,
                        showtime: selectedShowtime!,
                        selectedSeatIds: selectedSeats.map((s) => s.id).toList(),
                        selectedSeatData: selectedSeats,
                        totalPrice: finalTotal,
                      ),
                    ),
                  );
                } else {
                  _nextStep();
                }
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canProceed() ? AppTheme.primaryRed : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _canProceed() ? 8 : 0,
              ),
              child: Text(
                currentStep == 2 ? 'Confirm Booking' : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateDisplay(String dateStr) {
    try {
      // Backend returns dates in YYYY-MM-DD format
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      // If parsing fails, return the original string
      print('Error parsing date: $dateStr, error: $e');
      return dateStr;
    }
  }
}
