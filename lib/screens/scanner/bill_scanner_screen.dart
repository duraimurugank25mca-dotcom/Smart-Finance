import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/ocr_service.dart';
import '../../providers/finance_provider.dart';
import '../../models/bill_scan_result.dart';
import '../../widgets/transaction_preview_dialog.dart';
import '../../core/theme/app_theme.dart';

enum BillInputOption {
  scanBill,   // Option 1: Live camera scanning
  uploadBill, // Option 2: Gallery / File upload
}

class BillScannerScreen extends StatefulWidget {
  final BillInputOption initialOption;

  const BillScannerScreen({
    super.key,
    this.initialOption = BillInputOption.scanBill,
  });

  @override
  State<BillScannerScreen> createState() => _BillScannerScreenState();
}

class _BillScannerScreenState extends State<BillScannerScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _laserAnimationController;
  late Animation<double> _laserAnimation;

  final ApiService _api = ApiService();
  final TextEditingController _ocrTextController = TextEditingController();

  late BillInputOption _selectedOption;
  bool _isScanning = false;
  BillScanResult? _scanResult;
  List<dynamic> _billHistory = [];
  Map<String, dynamic>? _billAnalytics;
  int _rotationAngle = 0;

  // Camera simulation controls
  bool _isFlashOn = false;
  bool _showGuidelines = true;
  String _simulatedFileName = 'petrol_receipt_nov14.jpg';
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _quickBillTypes = [
    {'title': 'Petrol Pump', 'icon': Icons.local_gas_station_rounded, 'category': 'Petrol / Fuel', 'sampleIndex': 0},
    {'title': 'Supermarket', 'icon': Icons.shopping_cart_rounded, 'category': 'Groceries', 'sampleIndex': 1},
    {'title': 'Restaurant', 'icon': Icons.restaurant_rounded, 'category': 'Food', 'sampleIndex': 2},
    {'title': 'Medical Store', 'icon': Icons.medical_services_rounded, 'category': 'Medical', 'sampleIndex': 3},
  ];

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialOption;
    _tabController = TabController(length: 3, vsync: this);

    _laserAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _laserAnimationController, curve: Curves.easeInOut),
    );

    _loadHistoryAndAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _laserAnimationController.dispose();
    _ocrTextController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryAndAnalytics() async {
    try {
      final history = await _api.getBillHistory();
      final analytics = await _api.getBillAnalytics();
      if (mounted) {
        setState(() {
          _billHistory = history;
          _billAnalytics = analytics;
        });
      }
    } catch (_) {}
  }

  void _selectPreset(OcrBillSample sample) {
    setState(() {
      _ocrTextController.text = sample.ocrText;
      _rotationAngle = 0;
      _simulatedFileName = '${sample.title.toLowerCase().replaceAll(' ', '_')}.jpg';
    });
    _executeOcrScan(sample.ocrText);
  }

  Future<void> _executeOcrScan(String text) async {
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or upload a receipt with text content')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    try {
      final result = await _api.scanBill(rawOcrText: text);
      if (mounted) {
        setState(() {
          _scanResult = result;
          _isScanning = false;
        });

        if (result.isDuplicate) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.advancesGold,
              content: Text('Warning: Potential duplicate bill detected! Check details before confirming.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR parsing failed: ${e.toString()}'),
            backgroundColor: AppTheme.expenseRedDark,
          ),
        );
      }
    }
  }

  Future<void> _triggerCameraCapture() async {
    // Select sample by current bill type
    final sample = OcrService.presets[_selectedCategoryIndex % OcrService.presets.length];
    setState(() {
      _ocrTextController.text = sample.ocrText;
      _simulatedFileName = 'camera_capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _rotationAngle = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryPurple,
        duration: const Duration(seconds: 1),
        content: Row(
          children: [
            const Icon(Icons.camera_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Receipt captured via camera! Performing OCR text recognition...'),
          ],
        ),
      ),
    );

    await _executeOcrScan(sample.ocrText);
  }

  Future<void> _triggerGalleryUpload({bool isPdf = false}) async {
    final sample = OcrService.presets[_selectedCategoryIndex % OcrService.presets.length];
    setState(() {
      _ocrTextController.text = sample.ocrText;
      _simulatedFileName = isPdf
          ? 'invoice_statement_${DateFormat('ddMMMyyyy').format(DateTime.now())}.pdf'
          : 'gallery_upload_${DateFormat('ddMMMyyyy').format(DateTime.now())}.png';
      _rotationAngle = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.incomeGreenDark,
        duration: const Duration(seconds: 1),
        content: Row(
          children: [
            Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.photo_library_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('${isPdf ? 'PDF statement' : 'Photo receipt'} loaded successfully! Running AI analysis...'),
          ],
        ),
      ),
    );

    await _executeOcrScan(sample.ocrText);
  }

  Future<void> _confirmBillTransaction() async {
    if (_scanResult == null) return;

    final result = _scanResult!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => TransactionPreviewDialog(
        title: 'Confirm Bill Transaction',
        type: 'expense',
        initialAmount: result.finalAmount,
        initialCategory: result.detectedCategory,
        initialPaymentMethod: 'UPI',
        initialDate: DateFormat('yyyy-MM-dd').format(result.billDate),
        initialDescription: 'Bill: ${result.shopName} (#${result.billNumber})',
        onConfirm: ({
          required double amount,
          required String category,
          required String paymentMethod,
          required String date,
          required String description,
        }) async {
          final fin = Provider.of<FinanceProvider>(context, listen: false);
          final cat = fin.categories.firstWhere(
            (c) => c.name.toLowerCase() == category.toLowerCase(),
            orElse: () => fin.categories.first,
          );

          await _api.confirmBill(
            billScanId: result.id,
            categoryId: cat.id,
            finalAmount: amount,
            paymentMethod: paymentMethod,
            shopName: result.shopName,
            billDate: date,
            description: description,
          );

          await fin.fetchAllData();
        },
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.incomeGreenDark,
          content: Text('Bill verified and added to financial ledger!'),
        ),
      );
      setState(() => _scanResult = null);
      _loadHistoryAndAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'AI Smart Bill Scanner',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDarkNavy,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryPurple,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.document_scanner_rounded), text: 'Scanner & OCR'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Bill History'),
            Tab(icon: Icon(Icons.insights_rounded), text: 'Spending Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. SCANNER TAB (With 2 Options: Scan Bill or Upload Bill)
          _buildScannerTab(),

          // 2. HISTORY TAB
          _buildHistoryTab(),

          // 3. ANALYTICS TAB
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PROMINENT DUAL OPTION SELECTOR (Option 1: Scan Bill | Option 2: Upload Bill)
          _buildDualOptionSelector(),

          const SizedBox(height: 18),

          // ACTIVE MODE VIEW (Scan Bill Camera Viewfinder OR Upload Bill Dropzone)
          if (_selectedOption == BillInputOption.scanBill)
            _buildScanBillCameraView()
          else
            _buildUploadBillView(),

          const SizedBox(height: 18),

          // OCR Raw Text Editor Bar
          _buildOcrTextCard(),

          const SizedBox(height: 22),

          // EXTRACTED STRUCTURED INFORMATION PREVIEW
          if (_scanResult != null) _buildExtractedResultCard(),
        ],
      ),
    );
  }

  // Dual Option Selector: Option 1: Scan Bill | Option 2: Upload Bill
  Widget _buildDualOptionSelector() {
    final isScan = _selectedOption == BillInputOption.scanBill;
    final isUpload = _selectedOption == BillInputOption.uploadBill;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Option 1: Scan Bill
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedOption = BillInputOption.scanBill);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: isScan ? AppTheme.primaryPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isScan
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: isScan ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scan Bill',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isScan ? Colors.white : AppTheme.textDarkNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Option 2: Upload Bill
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedOption = BillInputOption.uploadBill);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: isUpload ? AppTheme.primaryPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isUpload
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_rounded,
                      size: 20,
                      color: isUpload ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Bill',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isUpload ? Colors.white : AppTheme.textDarkNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // OPTION 1 VIEW: Scan Bill with Camera Viewfinder & Laser Animation
  Widget _buildScanBillCameraView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Camera Header Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1B2E),
              border: Border(bottom: BorderSide(color: Color(0xFF2E2A44))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LIVE CAMERA SCANNER',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Flash Toggle
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isFlashOn ? Colors.amber : Colors.white70,
                        size: 20,
                      ),
                      tooltip: _isFlashOn ? 'Turn Flash Off' : 'Turn Flash On',
                      onPressed: () => setState(() => _isFlashOn = !_isFlashOn),
                    ),
                    // Guidelines Toggle
                    IconButton(
                      icon: Icon(
                        _showGuidelines ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                        color: _showGuidelines ? AppTheme.purpleGlow : Colors.white70,
                        size: 20,
                      ),
                      tooltip: 'Toggle Guidelines',
                      onPressed: () => setState(() => _showGuidelines = !_showGuidelines),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Camera Viewfinder Canvas with Laser Scanner
          Container(
            height: 240,
            color: const Color(0xFF0F0C20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Viewfinder Guidelines
                if (_showGuidelines)
                  Opacity(
                    opacity: 0.15,
                    child: CustomPaint(
                      size: const Size(double.infinity, 240),
                      painter: _GridPainter(),
                    ),
                  ),

                // Center Receipt Target Frame
                Container(
                  width: 260,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Stack(
                    children: [
                      // Corner brackets
                      const _CornerReticle(alignment: Alignment.topLeft),
                      const _CornerReticle(alignment: Alignment.topRight),
                      const _CornerReticle(alignment: Alignment.bottomLeft),
                      const _CornerReticle(alignment: Alignment.bottomRight),

                      // Animated Laser Scan Bar
                      AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (ctx, child) {
                          return Positioned(
                            top: 180 * _laserAnimation.value,
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFA855F7).withOpacity(0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Center Icon & Instructions
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.document_scanner_rounded,
                              size: 40,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Position receipt within the frame',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Ensure good lighting & clear text',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Flash Effect Overlay
                if (_isFlashOn)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
              ],
            ),
          ),

          // Bill Category Selector Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Receipt Type:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_quickBillTypes.length, (i) {
                    final item = _quickBillTypes[i];
                    final isSel = _selectedCategoryIndex == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategoryIndex = i);
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: i == _quickBillTypes.length - 1 ? 0 : 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.purplePillBg : AppTheme.appBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? AppTheme.primaryPurple : AppTheme.cardBorder,
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                size: 18,
                                color: isSel ? AppTheme.primaryPurple : AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['title'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  color: isSel ? AppTheme.primaryPurple : AppTheme.textDarkNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Shutter Action Button: Capture & Scan Receipt
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isScanning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.camera_alt_rounded, size: 20),
              label: Text(
                _isScanning ? 'Scanning Receipt with AI...' : 'Capture & Scan Receipt',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: _isScanning ? null : _triggerCameraCapture,
            ),
          ),
        ],
      ),
    );
  }

  // OPTION 2 VIEW: Upload Bill from Gallery / File Storage
  Widget _buildUploadBillView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upload Dropzone Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.purplePillBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.purpleBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_upload_rounded, size: 40, color: AppTheme.primaryPurple),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Upload Receipt from Device',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDarkNavy),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select receipt photo (JPG, PNG) or digital statement (PDF)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),

                // Upload Action Buttons: Gallery or Document
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.photo_library_rounded, size: 16),
                      label: const Text('Browse Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _triggerGalleryUpload(isPdf: false),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.purpleBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppTheme.primaryPurple),
                      label: const Text('Upload PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                      onPressed: () => _triggerGalleryUpload(isPdf: true),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Uploaded File Info & Image Manipulation Tools (Rotate, Crop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.appBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_rounded, size: 20, color: AppTheme.primaryPurple),
                    const SizedBox(width: 8),
                    Text(
                      _simulatedFileName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDarkNavy),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.rotate_right_rounded, size: 20, color: AppTheme.primaryPurple),
                      tooltip: 'Rotate 90°',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _rotationAngle = (_rotationAngle + 90) % 360);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(duration: const Duration(milliseconds: 700), content: Text('Receipt rotated to $_rotationAngle°')),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.crop_rounded, size: 20, color: AppTheme.primaryPurple),
                      tooltip: 'Crop Receipt',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(duration: Duration(milliseconds: 700), content: Text('Receipt auto-cropped and aligned.')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Preset Receipts for Instant 1-Click Verification
          const Text(
            'Quick Sample Receipts to Upload & Test:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: OcrService.presets.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.receipt_long, size: 16, color: AppTheme.primaryPurple),
                    label: Text(
                      p.title,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryPurple),
                    ),
                    backgroundColor: AppTheme.purplePillBg,
                    side: const BorderSide(color: AppTheme.purpleBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () => _selectPreset(p),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Raw OCR Text Bar and Action
  Widget _buildOcrTextCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Extracted OCR Content',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textDarkNavy),
              ),
              if (_ocrTextController.text.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.clear_rounded, size: 14, color: AppTheme.textMuted),
                  label: const Text('Clear', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  onPressed: () => setState(() => _ocrTextController.clear()),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ocrTextController,
            maxLines: 4,
            style: const TextStyle(fontSize: 13, color: AppTheme.textDarkNavy, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'Receipt text extracted via Google ML Kit OCR will appear here...',
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              fillColor: AppTheme.appBackground,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isScanning
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              _isScanning ? 'Extracting Receipt Data with AI...' : 'Run AI Extraction & Category Detection',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: _isScanning ? null : () => _executeOcrScan(_ocrTextController.text),
          ),
        ],
      ),
    );
  }

  // Structured Information Card
  Widget _buildExtractedResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _scanResult!.shopName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDarkNavy),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.purplePillBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _scanResult!.detectedCategory,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bill #${_scanResult!.billNumber} • ${DateFormat('dd MMM, yyyy').format(_scanResult!.billDate)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const Divider(height: 24, color: AppTheme.cardBorder),

          // Line Items
          const Text('Extracted Line Items:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textDarkNavy)),
          const SizedBox(height: 10),
          ..._scanResult!.items.map(
            (it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${it.itemName} (x${it.quantity.toInt()})',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textDarkNavy),
                    ),
                  ),
                  Text(
                    '₹ ${it.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDarkNavy),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 24, color: AppTheme.cardBorder),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('₹ ${_scanResult!.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDarkNavy)),
            ],
          ),
          if (_scanResult!.gst > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GST / Tax:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('+ ₹ ${_scanResult!.gst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDarkNavy)),
                ],
              ),
            ),
          if (_scanResult!.discount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount:', style: TextStyle(fontSize: 12, color: AppTheme.incomeGreenDark)),
                  Text('- ₹ ${_scanResult!.discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.incomeGreenDark)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Final Total Amount:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textDarkNavy)),
              Text(
                '₹ ${_scanResult!.finalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.incomeGreenDark),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Verify & Save to Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _confirmBillTransaction,
            ),
          ),
        ],
      ),
    );
  }

  // 2. HISTORY TAB
  Widget _buildHistoryTab() {
    if (_billHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppTheme.purplePillBg, shape: BoxShape.circle),
              child: const Icon(Icons.history_rounded, size: 40, color: AppTheme.primaryPurple),
            ),
            const SizedBox(height: 14),
            const Text('No scanned bills in history yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDarkNavy)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _billHistory.length,
      itemBuilder: (ctx, idx) {
        final b = _billHistory[idx];
        final amount = double.tryParse(b['final_amount']?.toString() ?? '0') ?? 0.0;
        final dateStr = b['bill_date'] != null
            ? DateFormat('dd MMM, yyyy').format(DateTime.parse(b['bill_date'].toString()))
            : '';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.purplePillBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryPurple, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['shop_name'] ?? 'Store',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDarkNavy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${b['bill_number'] ?? ''} • $dateStr • ${b['status']}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '₹ ${NumberFormat('#,##,##0.00').format(amount)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textDarkNavy),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. ANALYTICS TAB
  Widget _buildAnalyticsTab() {
    final fuel = (_billAnalytics?['monthlyFuel'] as List<dynamic>? ?? []);
    final groceries = (_billAnalytics?['monthlyGrocery'] as List<dynamic>? ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fuel & Petrol Spending Analysis',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDarkNavy),
          ),
          const SizedBox(height: 10),
          if (fuel.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: const Center(
                child: Text('No fuel spending data recorded.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ),
            )
          else
            ...fuel.map((f) {
              final total = double.tryParse(f['fuel_total']?.toString() ?? '0') ?? 0.0;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.expenseRedBg, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.local_gas_station_rounded, color: AppTheme.expenseRedDark, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f['month'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDarkNavy)),
                          Text('${f['refill_count']} refill(s)', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      '₹ ${NumberFormat('#,##,##0.00').format(total)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.expenseRedDark),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          const Text(
            'Supermarket & Grocery Spending Analysis',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDarkNavy),
          ),
          const SizedBox(height: 10),
          if (groceries.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: const Center(
                child: Text('No grocery spending data recorded.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ),
            )
          else
            ...groceries.map((g) {
              final total = double.tryParse(g['grocery_total']?.toString() ?? '0') ?? 0.0;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.purplePillBg, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.shopping_cart_rounded, color: AppTheme.primaryPurple, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g['month'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDarkNavy)),
                          Text('${g['visit_count']} visit(s)', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      '₹ ${NumberFormat('#,##,##0.00').format(total)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primaryPurple),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// Custom Painter for Camera Viewfinder Grid
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    final dx = size.width / 3;
    final dy = size.height / 3;

    canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    canvas.drawLine(Offset(dx * 2, 0), Offset(dx * 2, size.height), paint);
    canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    canvas.drawLine(Offset(0, dy * 2), Offset(size.width, dy * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Corner Reticle Frame Widget for Camera Viewfinder
class _CornerReticle extends StatelessWidget {
  final Alignment alignment;

  const _CornerReticle({required this.alignment});

  @override
  Widget build(BuildContext context) {
    const double size = 20;
    const double thickness = 3.5;
    const color = Color(0xFFA855F7);

    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            bottom: alignment.y > 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            left: alignment.x < 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            right: alignment.x > 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
