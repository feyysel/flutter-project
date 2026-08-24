import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'driver_profile_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_home_screen.dart';
import '../../services/ride_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_side_menu.dart';
import '../../widgets/premium_ui.dart';

class DriverRidePostScreen extends StatefulWidget {
  const DriverRidePostScreen({super.key});

  @override
  State<DriverRidePostScreen> createState() => _DriverRidePostScreenState();
}

class _DriverRidePostScreenState extends State<DriverRidePostScreen> {
  final _supabase = Supabase.instance.client;

  static const List<SideMenuItem> _menuItems = [
    SideMenuItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: "Map"),
    SideMenuItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: "Ride Post"),
    SideMenuItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: "Earnings"),
    SideMenuItem(icon: Icons.person_outline, activeIcon: Icons.person, label: "Profile"),
  ];

  Widget _menuDestination(int index) {
    switch (index) {
      case 0:
        return DriverHomeScreen();
      case 2:
        return DriverEarningsScreen();
      case 3:
        return DriverProfileScreen();
      default:
        return DriverRidePostScreen();
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  final fromController = TextEditingController();
  final toController = TextEditingController();
  final pickupController = TextEditingController();
  final dropController = TextEditingController();
  final priceController = TextEditingController();
  final seatsController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isLoading = false;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  String? get _formattedRideTime {
    if (selectedDate == null || selectedTime == null) return null;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour =
        selectedTime!.hourOfPeriod == 0 ? 12 : selectedTime!.hourOfPeriod;
    final minute = selectedTime!.minute.toString().padLeft(2, '0');
    final period = selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return "${days[selectedDate!.weekday - 1]}, "
        "${months[selectedDate!.month - 1]} ${selectedDate!.day} • "
        "$hour:$minute $period";
  }

  Future<void> postRide() async {
    final rideTime = _formattedRideTime;
    if (fromController.text.isEmpty ||
        toController.text.isEmpty ||
        priceController.text.isEmpty ||
        seatsController.text.isEmpty ||
        rideTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(rideTime == null
                ? "Select date and time"
                : "Fill all required fields")),
      );
      return;
    }

    final driverDoc = await _supabase
        .from('profiles')
        .select()
        .eq('id', _currentUserId)
        .maybeSingle();

    if (driverDoc?['is_verified'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: AppColors.warning,
            content: Text("Verify your account first")),
      );
      return;
    }

    setState(() => isLoading = true);

    final departureAt = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    await RideService.addRide(
      from: fromController.text,
      to: toController.text,
      time: rideTime,
      price: priceController.text,
      driverId: _currentUserId,
      driverName: driverDoc?['name'] ?? '',
      vehicleModel: driverDoc?['vehicle_model'] ?? 'Economy',
      seats: int.parse(seatsController.text),
      departureAt: departureAt,
      pickupLocation: pickupController.text.trim().isEmpty
          ? null
          : pickupController.text.trim(),
      dropLocation: dropController.text.trim().isEmpty
          ? null
          : dropController.text.trim(),
    );

    setState(() => isLoading = false);

    fromController.clear();
    toController.clear();
    pickupController.clear();
    dropController.clear();
    priceController.clear();
    seatsController.clear();
    setState(() {
      selectedDate = null;
      selectedTime = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          backgroundColor: AppColors.success,
          content: Text("Ride Posted Successfully")),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "accepted":
        return AppColors.success;
      case "completed":
        return AppColors.primaryVivid;
      default:
        return AppColors.warning;
    }
  }

  Widget buildRideCard(dynamic ride) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase
          .from('ride_requests')
          .select()
          .eq('ride_id', ride['id']),
      builder: (context, requestSnapshot) {
        bool isBooked = false;
        dynamic request;

        if (requestSnapshot.hasData && requestSnapshot.data!.isNotEmpty) {
          isBooked = true;
          request = requestSnapshot.data!.first;
        }

        final status = !isBooked ? null : request['status'].toString();
        final chipLabel = !isBooked ? "Open" : (status ?? "Booked");
        final chipColor = !isBooked
            ? AppColors.accent
            : _statusColor(status);

        return GestureDetector(
          onTap: () => showRideDetails(ride, request),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(chipLabel, color: chipColor),
                    const Spacer(),
                    Text("${ride['price']} ETB",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold)),
                  ],
                ),
                const SizedBox(height: 10),
                Text("${ride['from']} → ${ride['to']}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event_seat_rounded,
                        size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text("${ride['seats']} seats • ${ride['time'] ?? ''}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary)),
                    ),
                    if (!isBooked)
                      GestureDetector(
                        onTap: () async {
                          await RideService.deletePost(ride['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                backgroundColor: AppColors.danger,
                                content: Text("Ride cancelled")),
                          );
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.danger.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.danger),
                        ),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded,
                          size: 20, color: AppColors.textMuted),
                  ],
                ),
                if ((ride['pickup_location'] ?? '').toString().isNotEmpty ||
                    (ride['drop_location'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.alt_route_rounded,
                            size: 15, color: AppColors.accent),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            [
                              if ((ride['pickup_location'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                "Pick up: ${ride['pickup_location']}",
                              if ((ride['drop_location'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                "Drop: ${ride['drop_location']}",
                            ].join(" → "),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showRideDetails(dynamic ride, dynamic request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF161C33), Color(0xFF0B0E1E)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text("${ride['from']} → ${ride['to']}",
                  style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Price",
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary)),
                        Text("${ride['price']} ETB",
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Seats",
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary)),
                        Text("${ride['seats']}",
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
              if (request != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MicroLabel("Passenger details",
                          color: AppColors.accent),
                      const SizedBox(height: 12),
                      Text("${request['passenger_name']}",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      StatusChip(request['status'].toString(),
                          color: _statusColor(request['status'].toString())),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Post Ride",
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4)),
        leading: Builder(
          builder: (menuContext) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(menuContext).openDrawer(),
          ),
        ),
      ),
      drawer: PremiumSideMenu(
        items: _menuItems,
        currentIndex: 1,
        roleLabel: 'Driver',
        onLogout: _signOut,
        onItemTap: (index) => PremiumSideMenu.navigateAfterClose(
          context,
          _menuDestination(index),
          isCurrent: index == 1,
        ),
      ),
      body: PremiumBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MicroLabel("New ride", color: AppColors.accent),
                    const SizedBox(height: 16),
                    textField(controller: fromController, hint: "From", icon: Icons.location_on_rounded),
                    const SizedBox(height: 14),
                    textField(controller: toController, hint: "To", icon: Icons.location_on_outlined),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: _pickerTile(
                          icon: Icons.calendar_month_rounded,
                          label: selectedDate == null
                              ? "Select date"
                              : _dateLabel(),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _pickerTile(
                          icon: Icons.access_time_rounded,
                          label: selectedTime == null
                              ? "Select time"
                              : selectedTime!.format(context),
                        )),
                      ],
                    ),
                    const SizedBox(height: 14),
                    textField(controller: priceController, hint: "Price (ETB)", icon: Icons.payments_rounded),
                    const SizedBox(height: 14),
                    textField(controller: seatsController, hint: "Available Seats", icon: Icons.event_seat_rounded),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 1,
                          color: AppColors.border,
                        ),
                        const SizedBox(width: 10),
                        const MicroLabel("Optional stops"),
                        const SizedBox(width: 10),
                        Expanded(child: Container(height: 1, color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    textField(
                        controller: pickupController,
                        hint: "Pick up location (optional)",
                        icon: Icons.trip_origin_rounded),
                    const SizedBox(height: 14),
                    textField(
                        controller: dropController,
                        hint: "Drop location (optional)",
                        icon: Icons.adjust_rounded),
                    const SizedBox(height: 22),
                    PremiumButton(
                      label: "Post Ride",
                      loading: isLoading,
                      height: 54,
                      onPressed: isLoading ? null : postRide,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.only(left: 4, bottom: 14),
                child: const MicroLabel("My posted rides"),
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: RideService.getDriverPosts(_currentUserId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(snapshot.error.toString(),
                          style: const TextStyle(color: AppColors.danger)),
                    );
                  }
                  if (snapshot.data!.isEmpty) {
                    return const EmptyState(
                      icon: Icons.post_add_rounded,
                      title: "No posted rides yet",
                      message: "Publish a new ride above and it will appear here.",
                    );
                  }
                  final rides = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rides.length,
                    itemBuilder: (context, index) {
                      return buildRideCard(rides[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      keyboardType:
          hint.contains("Seats") || hint.contains("Price")
              ? TextInputType.numberWithOptions(decimal: hint.contains("Price"))
              : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  String _dateLabel() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return "${months[selectedDate!.month - 1]} ${selectedDate!.day}, ${selectedDate!.year}";
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
  }) {
    final hasValue = label != "Select date" && label != "Select time";
    return GestureDetector(
      onTap: icon == Icons.calendar_month_rounded ? _pickDate : _pickTime,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color:
                    hasValue ? AppColors.accent : AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
