import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../config/theme_config.dart';
import '../../domain/entities/lounge_booking.dart';
import '../../presentation/providers/lounge_booking_provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _isProcessingScan = false;
  bool _isFetching = false;
  bool _isToggling = false;
  String? _scannedQrCodeData;
  LoungeBooking? _booking;
  String? _errorMessage;
  int _scannerSession = 0;

  static final RegExp _qrCodeDataRegex = RegExp(
    r'(LQ-[A-Za-z0-9-]+)',
    caseSensitive: false,
  );

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessingScan) return;

    final qrCodeData = _extractQrCodeDataFromCapture(capture);
    if (qrCodeData == null) {
      setState(() {
        _errorMessage =
            'Invalid QR content. Expected QR code data like LQ-20260219094711-A1B2C3D4.';
      });
      return;
    }

    _isProcessingScan = true;
    await _cameraController.stop();
    await _lookupBookingByQrCodeData(qrCodeData);
  }

  String? _extractQrCodeDataFromCapture(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        final qrCodeData = _extractQrCodeData(rawValue);
        if (qrCodeData != null) return qrCodeData;
      }

      final displayValue = barcode.displayValue;
      if (displayValue != null && displayValue.trim().isNotEmpty) {
        final qrCodeData = _extractQrCodeData(displayValue);
        if (qrCodeData != null) return qrCodeData;
      }

      final rawBytes = barcode.rawBytes;
      if (rawBytes != null && rawBytes.isNotEmpty) {
        final decoded = utf8.decode(rawBytes, allowMalformed: true).trim();
        if (decoded.isNotEmpty) {
          final qrCodeData = _extractQrCodeData(decoded);
          if (qrCodeData != null) return qrCodeData;
        }
      }
    }

    return null;
  }

  String? _extractQrCodeData(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final normalized = trimmed
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u2212', '-')
        .replaceAll('_', '-');

    final directMatch = _qrCodeDataRegex.firstMatch(normalized);
    if (directMatch != null) {
      return directMatch.group(1)?.toUpperCase().trim();
    }

    final uri = Uri.tryParse(normalized);
    if (uri != null) {
      final queryCandidates = [
        uri.queryParameters['qr_code_data'],
        uri.queryParameters['qrCodeData'],
        uri.queryParameters['qr'],
        uri.queryParameters['code'],
      ];

      for (final candidate in queryCandidates) {
        if (candidate != null && candidate.trim().isNotEmpty) {
          final match = _qrCodeDataRegex.firstMatch(candidate.trim());
          if (match != null) {
            return match.group(1)?.toUpperCase().trim();
          }
        }
      }
    }

    if (uri != null && uri.pathSegments.isNotEmpty) {
      for (final segment in uri.pathSegments.reversed) {
        final match = _qrCodeDataRegex.firstMatch(segment);
        if (match != null) {
          return match.group(1)?.toUpperCase().trim();
        }
      }
    }

    final decoded = Uri.decodeFull(normalized);
    if (decoded != normalized) {
      final decodedMatch = _qrCodeDataRegex.firstMatch(decoded);
      if (decodedMatch != null) {
        return decodedMatch.group(1)?.toUpperCase().trim();
      }
    }

    return null;
  }

  Future<void> _lookupBookingByQrCodeData(String qrCodeData) async {
    if (!mounted) return;

    setState(() {
      _isFetching = true;
      _errorMessage = null;
      _scannedQrCodeData = qrCodeData;
      _booking = null;
    });

    final bookingProvider = context.read<LoungeBookingProvider>();
    final success = await bookingProvider.getBookingByQrCodeData(qrCodeData);

    if (!mounted) return;

    setState(() {
      _isFetching = false;
      _booking = success ? bookingProvider.selectedBooking : null;
      _errorMessage =
          success ? null : (bookingProvider.error ?? 'Booking not found');
    });
  }

  Future<void> _scanAgain() async {
    setState(() {
      _isProcessingScan = false;
      _isFetching = false;
      _errorMessage = null;
      _booking = null;
      _scannedQrCodeData = null;
      _scannerSession++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _cameraController.stop();
      } catch (_) {}
      if (!mounted) return;
      try {
        await _cameraController.start();
      } catch (_) {}
    });
  }

  Future<void> _showManualReferenceDialog() async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Reference ID'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Booking reference',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );

    final qrCodeData = _extractQrCodeData(controller.text);
    if (!mounted) return;

    if (qrCodeData == null) {
      setState(() {
        _errorMessage =
            'Please enter valid QR code data like LQ-20260219094711-A1B2C3D4.';
      });
      return;
    }

    _isProcessingScan = true;
    await _cameraController.stop();
    await _lookupBookingByQrCodeData(qrCodeData);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
      case 'checked_in':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'completed':
      case 'checked_out':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  bool _canToggleBooking(LoungeBooking booking) {
    final status = booking.status.toLowerCase();
    return status == 'confirmed' || status == 'checked_in';
  }

  String _toggleButtonLabel(LoungeBooking booking) {
    final status = booking.status.toLowerCase();
    return status == 'checked_in' ? 'Check Out' : 'Check In';
  }

  Future<void> _toggleCheckInOut() async {
    if (!mounted || _booking == null || _isToggling) return;
    final booking = _booking!;
    if (!_canToggleBooking(booking)) return;

    setState(() {
      _isToggling = true;
      _errorMessage = null;
    });

    final bookingProvider = context.read<LoungeBookingProvider>();
    final message = await bookingProvider.toggleBookingCheckInOut(
      bookingId: booking.id,
    );

    if (!mounted) return;

    setState(() {
      _isToggling = false;
      _booking = bookingProvider.selectedBooking ?? _booking;
      if (message == null) {
        _errorMessage = bookingProvider.error ?? 'Action failed';
      }
    });

    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
        title: const Text(
          'QR Scanner',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scan booking QR to fetch details',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isFetching
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _booking != null
                        ? _buildBookingResult()
                        : _buildScannerArea(),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showManualReferenceDialog,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Enter Reference Manually'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerArea() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: MobileScanner(
          key: ValueKey(_scannerSession),
          controller: _cameraController,
          fit: BoxFit.cover,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Camera unavailable: ${error.errorDetails?.message ?? 'Please allow camera access.'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingResult() {
    final booking = _booking!;
    final statusColor = _statusColor(booking.status);
    final canToggle = _canToggleBooking(booking);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Booking Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _rowItem('Reference', booking.bookingReference),
                _rowItem('QR Data', _scannedQrCodeData ?? 'N/A'),
                _rowItem('Guest', booking.passengerName ?? 'N/A'),
                _rowItem('Phone', booking.passengerPhone ?? 'N/A'),
                _rowItem('Guests', booking.guestCount.toString()),
                _rowItem('Lounge', booking.loungeName ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (canToggle) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isToggling ? null : _toggleCheckInOut,
                icon: const Icon(Icons.login),
                label: Text(_toggleButtonLabel(booking)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scanAgain,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Another QR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
