import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';

class BookingHistoryPage extends StatefulWidget {
  final List<Booking> bookings;
  final VoidCallback? onBack;
  final VoidCallback? onCreateBooking;

  const BookingHistoryPage({
    super.key,
    required this.bookings,
    this.onBack,
    this.onCreateBooking,
  });

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _filterStatus = 'all'; // all, upcoming, past

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Booking> get _filteredBookings {
    final now = DateTime.now();
    if (_filterStatus == 'upcoming') {
      return widget.bookings.where((b) => b.dateTime.isAfter(now)).toList();
    } else if (_filterStatus == 'past') {
      return widget.bookings.where((b) => b.dateTime.isBefore(now)).toList();
    }
    return widget.bookings;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sortedBookings = List<Booking>.from(_filteredBookings)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, scheme),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStats(sortedBookings, scheme),
                const SizedBox(height: 12),
                _buildFilterChips(scheme),
                const SizedBox(height: 8),
              ],
            ),
          ),
          sortedBookings.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(scheme),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildBookingCard(
                        sortedBookings[index],
                        index,
                        scheme,
                      );
                    }, childCount: sortedBookings.length),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ================== APPBAR ==================
  Widget _buildAppBar(BuildContext context, ColorScheme scheme) {
    return SliverAppBar(
      expandedHeight: 150,
      collapsedHeight: 80,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: scheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Booking',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Semua reservasi Anda',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.secondary],
            ),
          ),
        ),
      ),
    );
  }

  // ================== STATS ==================
  Widget _buildStats(List<Booking> bookings, ColorScheme scheme) {
    final now = DateTime.now();
    final upcoming = bookings.where((b) => b.dateTime.isAfter(now)).length;
    final past = bookings.where((b) => b.dateTime.isBefore(now)).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.event_available_rounded,
              label: 'Mendatang',
              count: upcoming,
              color: Colors.blue.shade600,
              scheme: scheme,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              icon: Icons.history_rounded,
              label: 'Selesai',
              count: past,
              color: Colors.green.shade600,
              scheme: scheme,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              icon: Icons.calendar_month_rounded,
              label: 'Total',
              count: widget.bookings.length,
              color: Colors.deepPurple.shade600,
              scheme: scheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required ColorScheme scheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================== FILTER ==================
  Widget _buildFilterChips(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Semua',
            value: 'all',
            icon: Icons.list_rounded,
            scheme: scheme,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Mendatang',
            value: 'upcoming',
            icon: Icons.upcoming_rounded,
            scheme: scheme,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Selesai',
            value: 'past',
            icon: Icons.done_all_rounded,
            scheme: scheme,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
    required ColorScheme scheme,
  }) {
    final isSelected = _filterStatus == value;
    return Expanded(
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : scheme.primary,
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _filterStatus = value);
          }
        },
        backgroundColor: Colors.white,
        selectedColor: scheme.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? scheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      ),
    );
  }

  // ================== CARD BOOKING ==================
  Widget _buildBookingCard(Booking booking, int index, ColorScheme scheme) {
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.08,
          (index * 0.08) + 0.35,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    final now = DateTime.now();
    final isUpcoming = booking.dateTime.isAfter(now);
    final isPast = booking.dateTime.isBefore(now);
    final isToday =
        booking.dateTime.year == now.year &&
        booking.dateTime.month == now.month &&
        booking.dateTime.day == now.day;

    final statusColor = isUpcoming
        ? Colors.blue.shade600
        : isPast
        ? Colors.green.shade600
        : Colors.orange.shade600;

    final statusLabel = isToday
        ? 'Hari Ini'
        : isUpcoming
        ? 'Mendatang'
        : 'Selesai';

    final statusIcon = isToday
        ? Icons.today_rounded
        : isUpcoming
        ? Icons.upcoming_rounded
        : Icons.check_circle_rounded;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showBookingDetails(booking, scheme),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.placeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withOpacity(0.08),
                          scheme.secondary.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.calendar_today_rounded,
                            label: 'Tanggal',
                            value: DateFormat(
                              'dd MMM yyyy',
                              'id_ID',
                            ).format(booking.dateTime),
                            color: scheme.primary,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.access_time_rounded,
                            label: 'Waktu',
                            value: DateFormat('HH:mm').format(booking.dateTime),
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailChip(
                          icon: Icons.people_rounded,
                          label: '${booking.people} Orang',
                          color: Colors.purple.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetailChip(
                          icon: Icons.table_restaurant_rounded,
                          label: 'Meja ${booking.tableName}',
                          color: Colors.teal.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTimeAgo(booking.dateTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================== EMPTY STATE ==================
  Widget _buildEmptyState(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 64,
                color: scheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _filterStatus == 'upcoming'
                  ? 'Tidak Ada Booking Mendatang'
                  : _filterStatus == 'past'
                  ? 'Belum Ada Riwayat'
                  : 'Belum Ada Booking',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _filterStatus == 'upcoming'
                  ? 'Anda belum memiliki reservasi untuk masa depan.'
                  : _filterStatus == 'past'
                  ? 'Anda belum pernah melakukan booking sebelumnya.'
                  : 'Mulai booking tempat favoritmu sekarang!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onCreateBooking != null) {
                  widget.onCreateBooking!();
                } else {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Buat Booking Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== UTIL ==================
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      final futureDiff = dateTime.difference(now);
      if (futureDiff.inDays > 0) {
        return '${futureDiff.inDays} hari lagi';
      } else if (futureDiff.inHours > 0) {
        return '${futureDiff.inHours} jam lagi';
      } else if (futureDiff.inMinutes > 0) {
        return '${futureDiff.inMinutes} menit lagi';
      } else {
        return 'Sebentar lagi';
      }
    } else {
      if (difference.inDays > 7) {
        return '${(difference.inDays / 7).floor()} minggu yang lalu';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} menit yang lalu';
      } else {
        return 'Baru saja';
      }
    }
  }

  void _showBookingDetails(Booking booking, ColorScheme scheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [scheme.primary, scheme.secondary],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detail Booking',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.placeName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      icon: Icons.calendar_month_rounded,
                      label: 'Tanggal Booking',
                      value: DateFormat(
                        'EEEE, dd MMMM yyyy',
                        'id_ID',
                      ).format(booking.dateTime),
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Waktu',
                      value: DateFormat('HH:mm').format(booking.dateTime),
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.people_rounded,
                      label: 'Jumlah Tamu',
                      value: '${booking.people} Orang',
                      color: Colors.purple.shade600,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.table_restaurant_rounded,
                      label: 'Nomor Meja',
                      value: booking.tableName,
                      color: Colors.teal.shade600,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.amber.shade700,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Harap datang 10 menit sebelum waktu booking untuk konfirmasi.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Mengerti'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
