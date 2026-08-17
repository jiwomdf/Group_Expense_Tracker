/// The vocabulary the receipt parser matches against, in Indonesian and
/// English.
///
/// Kept apart from the parsing logic because this is the part that gets edited
/// when a real receipt comes out wrong: add the offending word to the right
/// list, add a test, done.
class ReceiptKeywords {
  const ReceiptKeywords._();

  /// Labels that mark the real total, most specific first. The first group that
  /// matches anywhere on the receipt wins, so `grand total` beats a bare
  /// `total`, and cash-tendered lines are only used as a last resort because
  /// the customer often pays more than the total.
  static const totalTiers = <List<String>>[
    [
      'grand total',
      'total akhir',
      'total belanja',
      'total bayar',
      'receipt total',
      'total due',
      'balance due',
    ],
    ['total'],
    // Deliberately no bare 'amount': on printed invoices that matches the
    // AMOUNT column header and picks up the first line item instead.
    ['jumlah', 'amount due'],
    ['tunai', 'cash', 'bayar', 'debit', 'kredit', 'card'],
  ];

  /// Lines that contain a total-ish word but never the amount we want.
  /// `subtotal` sits above the total, and `total item`/`total qty` count goods
  /// rather than money.
  static const totalExclusions = <String>[
    'sub total',
    'subtotal',
    'sub-total',
    'total item',
    'total qty',
    'total barang',
    'total diskon',
    'total discount',
    'ppn',
    'pajak',
    'tax',
    'kembali',
    'kembalian',
    'change',
    'save',
    'hemat',
    // Column headers on printed invoices, where the figures below them are line
    // items rather than the total.
    'unit price',
    'description',
    'qty',
  ];

  /// Words that mean a top-of-receipt line is address or registration detail
  /// rather than the merchant name.
  static const merchantExclusions = <String>[
    'jl.',
    'jl ',
    'jalan',
    'telp',
    'tel.',
    'phone',
    'npwp',
    'no.',
    'kasir',
    'cashier',
    'struk',
    'receipt',
    'invoice',
    'nota',
    'faktur',
    'tanggal',
    'date',
    'www.',
    'http',
    '.com',
  ];

  /// Lines that carry an amount but are not a purchased item: the summary
  /// block, column headers, and receipt metadata.
  static const itemExclusions = <String>[
    'total',
    'jumlah',
    'tunai',
    'cash',
    'bayar',
    'debit',
    'kredit',
    'card',
    'amount due',
    'balance due',
    'ppn',
    'pajak',
    'tax',
    'kembali',
    'change',
    'save',
    'hemat',
    'diskon',
    'discount',
    'unit price',
    'description',
    'qty',
    'harga',
    'npwp',
    'telp',
    'kasir',
    'cashier',
    'struk',
    'invoice',
    'faktur',
    'tanggal',
    'date',
    'jl.',
    'jalan',
  ];

  /// Month abbreviations in both languages, keyed by their first three letters.
  static const monthNames = <String, int>{
    'jan': 1,
    'feb': 2,
    'peb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'mei': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'agu': 8,
    'ags': 8,
    'sep': 9,
    'oct': 10,
    'okt': 10,
    'nov': 11,
    'dec': 12,
    'des': 12,
  };
}
