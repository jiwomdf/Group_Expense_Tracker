import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_expense_tracker/util/ext/date_format_util.dart';
import 'package:group_expense_tracker/util/ext/int_util.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/platform_util.dart';

/// Shows what the scanner read and lets the user correct it before it reaches
/// the expense form.
///
/// Every parsed line is editable here rather than only on the next screen: a
/// name or an amount the OCR got wrong is quickest to fix while the photo is
/// still on screen beside it.
class ReceiptReviewView extends StatefulWidget {
  final ReceiptScanModel result;
  final String imagePath;

  /// Called with the scan the user accepted, already carrying their edits.
  final ValueChanged<ReceiptScanModel> onUse;

  final VoidCallback onRescan;

  const ReceiptReviewView({
    super.key,
    required this.result,
    required this.imagePath,
    required this.onUse,
    required this.onRescan,
  });

  @override
  State<ReceiptReviewView> createState() => _ReceiptReviewViewState();
}

class _ReceiptReviewViewState extends State<ReceiptReviewView> {
  late final List<_EditableItem> _items = [
    for (final item in widget.result.items) _EditableItem.from(item),
  ];

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  List<ReceiptLineItem> get _edited => _items
      .map((item) => item.toModel())
      .whereType<ReceiptLineItem>()
      .toList();

  int get _editedTotal => _edited.fold(0, (sum, item) => sum + item.price);

  /// The item list is only the safer choice when it adds up to the printed
  /// total. Otherwise the single total is what the user should reach for first.
  bool get _itemsReconcile =>
      _edited.isNotEmpty && widget.result.price == _editedTotal;

  void _removeAt(int index) {
    setState(() => _items.removeAt(index).dispose());
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

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
                    ? widget.imagePath
                    : Uri.file(widget.imagePath).toString(),
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
              "Fix anything it got wrong — you can still edit everything on the next screen.",
              style: TextUtil(context)
                  .plusJakarta(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            _row(context, "Merchant", result.note.isEmpty ? null : result.note),
            _row(context, "Total",
                result.price == null ? null : "Rp ${result.price?.toRupiah()}"),
            _row(
                context,
                "Date",
                result.date?.toDateString(DateFormatUtil.ddMMMyyyy) ??
                    "not found, today will be used"),
            _itemList(context),
            _expander(context, "Show full text", result.rawText),
            _expander(context, "Show process log", result.log.join('\n')),
            ..._actions(context),
          ],
        ),
      ),
    );
  }

  Widget _itemList(BuildContext context) {
    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          "No item lines were readable, so this will be one expense.",
          style: TextUtil(context)
              .plusJakarta(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: Text(
            "Items (${_items.length})",
            style: TextUtil(context)
                .plusJakarta(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        for (var i = 0; i < _items.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _items[i].note,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: "Name",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _items[i].price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: "Price",
                      prefixText: "Rp ",
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeAt(i),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: "Remove",
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _itemsReconcile
                ? "Items add up to the total."
                : "Items add up to Rp ${_editedTotal.toRupiah()}"
                    "${widget.result.price == null ? "" : ", the total reads Rp ${widget.result.price?.toRupiah()}"}.",
            style: TextUtil(context)
                .plusJakarta(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  /// The reconciling option is the filled button, so the safer choice is the
  /// obvious one without hiding the other.
  List<Widget> _actions(BuildContext context) {
    final useItems = _edited.isEmpty
        ? null
        : () => widget.onUse(widget.result.copyWith(items: _edited));
    void useTotal() => widget.onUse(widget.result.totalOnly);

    return [
      if (useItems != null)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: SizedBox(
            width: double.infinity,
            child: _itemsReconcile
                ? FilledButton(
                    onPressed: useItems,
                    child: Text("Use ${_edited.length} items"))
                : OutlinedButton(
                    onPressed: useItems,
                    child: Text("Use ${_edited.length} items")),
          ),
        ),
      Padding(
        padding: EdgeInsets.only(top: useItems == null ? 24 : 12),
        child: SizedBox(
          width: double.infinity,
          child: _itemsReconcile
              ? OutlinedButton(
                  onPressed: useTotal, child: const Text("Use total only"))
              : FilledButton(
                  onPressed: useTotal, child: const Text("Use total only")),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: widget.onRescan,
            child: const Text("Scan again"),
          ),
        ),
      ),
    ];
  }

  /// Both the raw OCR dump and the stage trace read like console output, so
  /// they share one collapsed monospace panel.
  Widget _expander(BuildContext context, String title, String body) {
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

  Widget _row(BuildContext context, String label, String? value) {
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
                fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One parsed line while the user is editing it.
class _EditableItem {
  final TextEditingController note;
  final TextEditingController price;

  _EditableItem._(this.note, this.price);

  factory _EditableItem.from(ReceiptLineItem item) => _EditableItem._(
        TextEditingController(text: item.note),
        TextEditingController(text: item.price.toString()),
      );

  /// Null while the row is incomplete, so a half-typed line never leaves here.
  ReceiptLineItem? toModel() {
    final amount = int.tryParse(price.text.trim());
    if (amount == null || amount <= 0) return null;

    return ReceiptLineItem(note: note.text.trim(), price: amount);
  }

  void dispose() {
    note.dispose();
    price.dispose();
  }
}
