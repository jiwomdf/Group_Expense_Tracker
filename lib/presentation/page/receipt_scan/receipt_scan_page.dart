import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/data/ocr/receipt_scanner.dart';
import 'package:group_expense_tracker/presentation/bloc/receipt_scan/receipt_scan_bloc.dart';
import 'package:group_expense_tracker/util/ext/date_format_util.dart';
import 'package:group_expense_tracker/util/ext/int_util.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';
import 'package:image_picker/image_picker.dart';
import 'package:group_expense_tracker/util/platform_util.dart';

/// Photographs a receipt, reads it with on-device OCR, and pops the parsed
/// result back to the caller.
///
/// Mobile only — reach it through `openReceiptScanner` rather than importing it
/// directly, so the web build never links ML Kit.
///
/// Nothing is saved here. The scan is handed to the expense form, where the
/// user picks a category and confirms, because OCR on a creased thermal
/// receipt is never reliable enough to trust unattended.
class ReceiptScanPage extends StatefulWidget {
  static const routeName = '/receipt-scan-page';

  const ReceiptScanPage({super.key});

  @override
  State<ReceiptScanPage> createState() => _ReceiptScanPageState();
}

class _ReceiptScanPageState extends State<ReceiptScanPage> {
  /// Built here rather than through GetIt so the ML Kit recogniser is released
  /// as soon as the user leaves this page.
  final _scanner = ReceiptScanner();
  final _picker = ImagePicker();
  late final ReceiptScanBloc _bloc = ReceiptScanBloc(_scanner);

  @override
  void dispose() {
    _bloc.close();
    _scanner.close();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        // Downscaling keeps OCR fast without losing the printed text.
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (image == null) return;

      _bloc.add(ScanReceiptEvent(image.path));
    } catch (e) {
      if (!mounted) return;
      final target = source == ImageSource.camera ? "camera" : "file picker";
      context.show("Could not open the $target: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Scan receipt"),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: SafeArea(
          child: BlocConsumer<ReceiptScanBloc, ReceiptScanState>(
            listener: (context, state) {
              if (state is ReceiptScanError) context.show(state.message);
            },
            builder: (context, state) {
              return switch (state) {
                ReceiptScanLoading() => const _ScanningIndicator(),
                ReceiptScanHasData(:final result, :final imagePath) =>
                  _resultView(context, result, imagePath),
                _ => _sourcePicker(context),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _sourcePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 96),
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text(
              PlatformUtil.isWeb()
                  ? "Upload your receipt"
                  : "Photograph your receipt",
              style: TextUtil(context)
                  .plusJakarta(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            PlatformUtil.isWeb()
                ? "Pick a photo or scan of your receipt. The text is read in your browser, the image is never uploaded."
                : "Lay it flat, fill the frame, and keep the total visible. The text is read on your device, nothing is uploaded.",
            textAlign: TextAlign.center,
            style: TextUtil(context)
                .plusJakarta(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          // The browser has no camera flow worth offering here, so web uploads
          // a file instead.
          if (!PlatformUtil.isWeb())
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text("Take a photo"),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: PlatformUtil.isWeb() ? 32 : 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: Icon(PlatformUtil.isWeb()
                    ? Icons.upload_file
                    : Icons.photo_library),
                label: Text(PlatformUtil.isWeb()
                    ? "Upload a receipt"
                    : "Choose from gallery"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultView(
      BuildContext context, ReceiptScanModel result, String imagePath) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // image_picker hands back a blob: URL on web and a file path on
              // mobile, and Image.network reads both.
              child: Image.network(
                PlatformUtil.isWeb()
                    ? imagePath
                    : Uri.file(imagePath).toString(),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 180),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 4),
              child: Text(
                "What the scanner read",
                style: TextUtil(context)
                    .plusJakarta(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              "Check these before saving — you can still edit everything on the next screen.",
              style: TextUtil(context)
                  .plusJakarta(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            _resultRow(
                context, "Merchant", result.note.isEmpty ? null : result.note),
            _resultRow(context, "Total",
                result.price == null ? null : "Rp ${result.price?.toRupiah()}"),
            _resultRow(
                context,
                "Items",
                result.items.isEmpty
                    ? "none readable, will be one expense"
                    : "${result.items.length} found"
                        "${result.itemsMatchTotal ? ", matching the total" : ""}"),
            _resultRow(
                context,
                "Date",
                result.date?.toDateString(DateFormatUtil.ddMMMyyyy) ??
                    "not found, today will be used"),
            _monospaceExpander(context, "Show full text", result.rawText),
            _monospaceExpander(
                context, "Show process log", result.log.join('\n')),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, result),
                  child: const Text("Use this"),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _bloc.add(const ResetReceiptScanEvent()),
                  child: const Text("Scan again"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Both the raw OCR dump and the stage trace read like console output, so
  /// they share one collapsed monospace panel.
  Widget _monospaceExpander(BuildContext context, String title, String body) {
    if (body.trim().isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            title,
            style: TextUtil(context)
                .plusJakarta(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                body,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(BuildContext context, String label, String? value) {
    final missing = value == null;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextUtil(context)
                  .plusJakarta(fontSize: 14, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value ?? "not found",
              textAlign: TextAlign.end,
              style: TextUtil(context).plusJakarta(
                fontSize: 14,
                fontWeight: missing ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningIndicator extends StatelessWidget {
  const _ScanningIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text("Reading the receipt...",
                style: TextUtil(context)
                    .plusJakarta(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
