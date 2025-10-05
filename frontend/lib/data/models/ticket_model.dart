class TicketModel {
  final String id;
  final String movieTitle;
  final String moviePoster;
  final String date;
  final String showtime;
  final List<String> seats;
  final double totalPrice;
  final String cinema;
  final DateTime bookingDate;
  final String status; // 'confirmed', 'used', 'cancelled'

  TicketModel({
    required this.id,
    required this.movieTitle,
    required this.moviePoster,
    required this.date,
    required this.showtime,
    required this.seats,
    required this.totalPrice,
    required this.cinema,
    required this.bookingDate,
    required this.status,
  });
}