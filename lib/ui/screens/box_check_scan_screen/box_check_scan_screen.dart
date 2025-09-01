// import 'dart:async';
// import 'dart:developer';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:excel/excel.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';

// import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
// import 'package:water_boiler_rfid_labeler/models/tag_item.dart';
// import 'package:water_boiler_rfid_labeler/ui/router/app_bar.dart';
// import 'package:water_boiler_rfid_labeler/ui/screens/box_check_scan_screen/epc_user_codec.dart';
// import 'package:water_boiler_rfid_labeler/ui/screens/box_check_scan_screen/tag_detail_screen.dart';
// // import 'package:water_boiler_rfid_labeler/ui/router/bottom_navigation.dart'; // isterseniz açık bırakın

// class FilterOption {
//   final int id;
//   final String label;

//   const FilterOption(this.id, this.label);
// }

// const FilterOption kAtaAll = FilterOption(-999, 'All — show everything');

// const List<FilterOption> kAtaFilterOptions = [
//   FilterOption(0, 'All others'),
//   FilterOption(1, 'Item (general; not 8–63)'),
//   FilterOption(2, 'Carton'),
//   FilterOption(6, 'Pallet'),
//   FilterOption(8, 'Seat Cushions'),
//   FilterOption(9, 'Seat Covers'),
//   FilterOption(10, 'Seat Belts / Belt Ext.'),
//   FilterOption(11, 'Galley & Service Equip.'),
//   FilterOption(12, 'Galley Ovens'),
//   FilterOption(13, 'Aircraft Security Items'),
//   FilterOption(14, 'Life Vests'),
//   FilterOption(15, 'Oxygen Generators (not cylinders/bottles)'),
//   FilterOption(16, 'Engine & Engine Components'),
//   FilterOption(17, 'Avionics'),
//   FilterOption(18, 'Experimental (“flight test”) equip.'),
//   FilterOption(19, 'Other Emergency Equipment'),
//   FilterOption(20, 'Other Rotables'),
//   FilterOption(21, 'Other Repairables'),
//   FilterOption(22, 'Other Cabin Interior'),
//   FilterOption(23, 'Other Repair (e.g., structural)'),
//   FilterOption(24, 'Seat & Seat Components (excl. 8–10)'),
//   FilterOption(25, 'In-Flight Entertainment (IFE) & related'),
//   FilterOption(56, 'Location Identifier'),
//   FilterOption(57, 'Documentation'),
//   FilterOption(58, 'Tools'),
//   FilterOption(59, 'Ground Support Equipment'),
//   FilterOption(60, 'Other Non-Flyable Equipment'),
// ];

// class BoxCheckScanScreen extends StatelessWidget {
//   const BoxCheckScanScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: commonAppBar(context, 'TAG READER', showBack: true),
//       body: const _BoxCheckScanBody(),
//     );
//   }
// }

// class _BoxCheckScanBody extends StatefulWidget {
//   const _BoxCheckScanBody();

//   @override
//   State<_BoxCheckScanBody> createState() => _BoxCheckScanBodyState();
// }

// class _BoxCheckScanBodyState extends State<_BoxCheckScanBody> {
//   bool _isScanning = false;
//   bool _exportBusy = false;

//   int _umRoundRobinIndex = 0;
//   Timer? _scanTimer;

//   double _powerLevel = 5;
//   final double _minPower = 5;
//   final double _maxPower = 30;
//   final int _divisions = 25;

//   final List<TagItem> _tagItems = [];
//   final Set<String> _epcSet = <String>{};
//   final Map<String, DateTime> _lastSeen = {};
//   bool _scanTickBusy = false;

//   List<FilterOption> get _ataOptions => [kAtaAll, ...kAtaFilterOptions];

//   static const TextStyle _ddTextStyle = TextStyle(
//     fontSize: 16,
//     fontWeight: FontWeight.w600,
//     color: Colors.black87, // ✅ metin rengi sabit
//   );

//   static const double _controlHeight = 48.0; // buton & dropdown aynı yükseklik

// // Üst kontrollerin en fazla genişliği (butonlarla hizalı görünüm)
//   static const double _controlsMaxWidth = 360;

// // Liste görünümünde aynı anda en çok 5 satır görünsün (yaklaşık satır yüksekliği)
//   static const double _listRowApproxHeight = 60;
//   static const int _listMaxVisibleRows = 5;

//   // Sağ/sol padding 16 olduğu için ekranda kullanılabilir genişlik = width - 32
//   double _controlsWidth(BuildContext context) {
//     final screen = MediaQuery.of(context).size.width;
//     final usable = screen - 32;
//     return _controlsMaxWidth < usable ? _controlsMaxWidth : usable;
//   }

//   // --- ATA filter state ---
//   FilterOption? _selectedAta; // null => filtre yok

//   int? _ataClassOf(TagItem t) {
//     final hex = t.userHex;
//     if (hex == null || hex.length < 16) return null;
//     final d = decodeUserMemory(hex);
//     final v = d['ataClass'];
//     if (v is int) return v;
//     if (v is String) return int.tryParse(v);
//     return null;
//   }

//   /// Görüntülenecek liste (ATA class tam eşleşme)
//   List<TagItem> get _filteredItems {
//     final sel = _selectedAta;
//     if (sel == null || sel.id == kAtaAll.id)
//       return _tagItems; // ← tümünü göster
//     final code = sel.id;
//     return _tagItems.where((t) => _ataClassOf(t) == code).toList();
//   }

//   @override
//   void initState() {
//     super.initState();
//     _checkIfConnected();
//     _selectedAta = kAtaAll;
//   }

//   Future<void> _checkIfConnected() async {
//     log("Checking if RFID reader is already connected (BoxCheckScanScreen)...");
//     final bool? connected = await RfidC72Plugin.isConnected;
//     if (connected == true) {
//       log("Yes, RFID is connected in BoxCheckScanScreen");
//     } else {
//       log("RFID not connected.");
//     }
//   }

//   Future<void> _readTag() async {
//     try {
//       final String? raw = await RfidC72Plugin.readSingleTagEpc();
//       if (raw == null || raw.isEmpty) {
//         log("No tag found");
//         return;
//       }

//       final epcHex = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();

//       // cooldown
//       final now = DateTime.now();
//       final last = _lastSeen[epcHex];
//       if (last != null && now.difference(last) < const Duration(seconds: 3)) {
//         log("Suppressed duplicate within cooldown: $epcHex");
//         return;
//       }
//       _lastSeen[epcHex] = now;

//       // unique
//       if (_epcSet.contains(epcHex)) {
//         log("Duplicate EPC ignored: $epcHex");
//         return;
//       }

//       // decode & add
//       final decoded = decodeEpc(epcHex);
//       setState(() {
//         _epcSet.add(epcHex);
//         _tagItems.insert(
//           0,
//           TagItem(
//             rawEpc: epcHex,
//             cage: decoded.cage,
//             partNumber: decoded.partNumber,
//             serialNumber: decoded.serialNumber,
//             userRead: false,
//           ),
//         );
//       });

//       // opportunistic user read
//       await _checkUserMemoryOnce(_tagItems.first);
//     } catch (e) {
//       log("Error reading tag: $e");
//     }
//   }

//   void _toggleScan() {
//     if (!_isScanning) {
//       _scanTimer =
//           Timer.periodic(const Duration(milliseconds: 400), (timer) async {
//         if (_scanTickBusy) return;
//         _scanTickBusy = true;
//         try {
//           await _readTag();
//           await _pollMissingUserMemoryDuringScan(maxPerTick: 2);
//         } finally {
//           _scanTickBusy = false;
//         }
//       });
//       setState(() => _isScanning = true);
//     } else {
//       _scanTimer?.cancel();
//       _scanTimer = null;
//       setState(() => _isScanning = false);
//     }
//   }

//   void _clearList() {
//     setState(() {
//       _tagItems.clear();
//       _epcSet.clear();
//       _lastSeen.clear();
//     });
//   }

//   /// EPC + USER verilerini Excel’e yazıp paylaş
//   Future<void> _shareExcelAnywhere() async {
//     if (_tagItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Liste boş: export için etiket yok.')),
//       );
//       return;
//     }

//     final wasScanning = _isScanning;
//     if (wasScanning) _toggleScan();
//     setState(() => _exportBusy = true);

//     try {
//       final excel = Excel.createExcel();
//       final String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
//       final sheet = excel.sheets[sheetName]!;

//       sheet.appendRow([
//         'No',
//         'PN',
//         'SN',
//         'Üretici (CAGE)',
//         'EPC (HEX)',
//         'USER HEX',
//         'w0',
//         'w1',
//         'w2',
//         'w3',
//         'ToC Major',
//         'ToC Minor',
//         'ATA Class',
//         'Tag Type',
//         'Payload Text',
//       ]);

//       int i = 1;
//       for (final t in _filteredItems) {
//         final userHex =
//             await RfidC72Plugin.readUserMemoryForEpc(t.rawEpc) ?? '';
//         final d = decodeUserMemory(userHex);
//         sheet.appendRow([
//           i++,
//           t.partNumber,
//           t.serialNumber,
//           t.cage,
//           t.rawEpc,
//           userHex,
//           d['w0'] ?? '',
//           d['w1'] ?? '',
//           d['w2'] ?? '',
//           d['w3'] ?? '',
//           d['tocMajor'] ?? '',
//           d['tocMinor'] ?? '',
//           d['ataClass'] ?? '',
//           d['tagType'] ?? '',
//           d['payloadText'] ?? '',
//         ]);
//       }

//       final bytes = excel.encode();
//       if (bytes == null) throw Exception('Excel encode null');

//       final dir = await getTemporaryDirectory();
//       final now = DateTime.now();
//       String two(int n) => n.toString().padLeft(2, '0');
//       final stamp =
//           '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';

//       final fileName = 'RFID-READ-TAGS-$stamp.xlsx';
//       final file = File('${dir.path}/$fileName')..createSync(recursive: true);
//       await file.writeAsBytes(bytes, flush: true);

//       await Share.shareXFiles(
//         [
//           XFile(file.path,
//               name: fileName,
//               mimeType:
//                   'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
//         ],
//         subject: 'RFID Export ($stamp)',
//         text: 'Ekte PN/SN/Üretici + EPC + USER içerikleri bulunmaktadır.',
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Paylaşım başarısız: $e')));
//     } finally {
//       if (wasScanning) _toggleScan();
//       if (mounted) setState(() => _exportBusy = false);
//     }
//   }

//   Future<void> _checkUserMemoryOnce(TagItem item) async {
//     if (item.userRead == true) return;
//     try {
//       final hex = await RfidC72Plugin.readUserMemoryForEpc(item.rawEpc);
//       if (!mounted) return;
//       if (hex != null && hex.length >= 16) {
//         setState(() {
//           item.userHex = hex;
//           item.userRead = true;
//         });
//       }
//     } catch (_) {}
//   }

//   Future<void> _pollMissingUserMemoryDuringScan({int maxPerTick = 2}) async {
//     if (!_isScanning || _tagItems.isEmpty) return;
//     int checked = 0;
//     final total = _tagItems.length;
//     while (checked < maxPerTick) {
//       _umRoundRobinIndex = (_umRoundRobinIndex + 1) % total;
//       final item = _tagItems[_umRoundRobinIndex];
//       if (!item.userRead) {
//         await _checkUserMemoryOnce(item);
//         checked++;
//       } else {
//         checked++;
//       }
//       if (!_isScanning) break;
//     }
//   }

//   static const _captionStyle = TextStyle(
//     fontSize: 13,
//     fontWeight: FontWeight.w600,
//     color: Colors.black54,
//   );

//   Widget _buildAtaFilterDropdown() {
//     final opts = _ataOptions;
//     final double vPad = (_controlHeight - 24) / 2; // 24 ≈ satır yüksekliği

//     return SizedBox(
//       height: _controlHeight, // butonlarla aynı
//       child: DropdownButtonFormField<FilterOption>(
//         value: _selectedAta ?? kAtaAll,
//         isDense: true,
//         isExpanded: true,
//         itemHeight: _controlHeight, // menü satır yüksekliği ≥ 48
//         menuMaxHeight: _controlHeight * 5 + 16, // ≈ 5 satır
//         decoration: InputDecoration(
//           labelText: 'ATA Class', // sadece labelText
//           floatingLabelBehavior: FloatingLabelBehavior.never,
//           contentPadding: EdgeInsets.symmetric(
//             horizontal: 12,
//             vertical: vPad, // kapalı görünüm yüksekliği
//           ),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         items: opts.map((o) {
//           final label = o.id == kAtaAll.id ? o.label : '${o.id} — ${o.label}';
//           return DropdownMenuItem(
//             value: o,
//             child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
//           );
//         }).toList(),
//         onChanged: (v) => setState(() => _selectedAta = v),
//       ),
//     );
//   }

//   Widget _buildPowerSlider() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Başlığı küçült (yalnız dikey etki)
//         Text(
//           "Adjust Power Level => ${_powerLevel.toInt()}",
//           style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 6),
//         SliderTheme(
//           data: SliderTheme.of(context).copyWith(
//             trackHeight: 2, // daha ince hat → dikey yer kazanır
//             thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
//             overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
//           ),
//           child: Row(
//             children: [
//               SizedBox(
//                 width: 24,
//                 child: Text(_minPower.toInt().toString(),
//                     textAlign: TextAlign.center,
//                     style:
//                         const TextStyle(fontSize: 12, color: Colors.black54)),
//               ),
//               Expanded(
//                 child: Slider(
//                   value: _powerLevel,
//                   min: _minPower,
//                   max: _maxPower,
//                   divisions: _divisions,
//                   onChanged: (v) => setState(() => _powerLevel = v),
//                   onChangeEnd: (v) {
//                     RfidC72Plugin.setPowerLevel(v.toInt().toString());
//                     log("Power level set to ${v.toInt()}");
//                   },
//                 ),
//               ),
//               SizedBox(
//                 width: 24,
//                 child: Text(_maxPower.toInt().toString(),
//                     textAlign: TextAlign.center,
//                     style:
//                         const TextStyle(fontSize: 12, color: Colors.black54)),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildButtonRow() {
//     final dense = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
//     final denseText =
//         const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

//     final elevStyle = ElevatedButton.styleFrom(
//       padding: dense,
//       textStyle: denseText,
//       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//       visualDensity: const VisualDensity(vertical: -2),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       // Renk: Start=yeşil, Stop=kırmızı
//       backgroundColor:
//           _isScanning ? Colors.red.shade600 : Colors.green.shade600,
//       foregroundColor: Colors.white,
//     );

//     final outStyle = OutlinedButton.styleFrom(
//       padding: dense,
//       textStyle: denseText,
//       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//       visualDensity: const VisualDensity(vertical: -2),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//     );

//     return Row(
//       children: [
//         Expanded(
//           child: SizedBox(
//             height: _controlHeight, // 🔸 sabit yükseklik
//             child: ElevatedButton(
//               onPressed: _toggleScan,
//               style: elevStyle,
//               child: Text(_isScanning ? "Stop Scan" : "Start Scan"),
//             ),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: SizedBox(
//             height: _controlHeight, // 🔸 sabit yükseklik
//             child: OutlinedButton(
//               onPressed: _clearList,
//               style: outStyle,
//               child: const Text("Clear List"),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTagList() {
//     final items = _filteredItems;

//     // En fazla 5 satır kadar yükseklik
//     final maxListHeight = _listRowApproxHeight * _listMaxVisibleRows;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
//           child: Text(
//             "Total Tags: ${items.length} / ${_tagItems.length}",
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//           ),
//         ),
//         const SizedBox(height: 4),

//         // 🔸 5 satırı aşmayacak yükseklikte bir konteyner; fazlası scroll ile görülür
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: ConstrainedBox(
//             constraints: BoxConstraints(maxHeight: maxListHeight),
//             child: items.isEmpty
//                 ? const Center(child: Text("No tags read yet."))
//                 : ListView.separated(
//                     shrinkWrap: true,
//                     padding: EdgeInsets.zero,
//                     itemCount: items
//                         .length, // hepsini verir, ama yükseklik 5 satır kadar
//                     separatorBuilder: (_, __) =>
//                         const Divider(height: 1, thickness: 1),
//                     itemBuilder: (context, index) {
//                       final item = items[index];
//                       final bool ok = (item.userRead == true);

//                       return Container(
//                         padding: const EdgeInsets.symmetric(vertical: 4.0),
//                         color:
//                             ok ? Colors.green.shade50 : Colors.yellow.shade100,
//                         child: Row(
//                           crossAxisAlignment:
//                               CrossAxisAlignment.start, // 🔸 sarma için start
//                           children: [
//                             const SizedBox(width: 8),
//                             CircleAvatar(
//                               radius: 16,
//                               backgroundColor: ok ? Colors.green : Colors.amber,
//                               child: Text(
//                                 (index + 1).toString(),
//                                 style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                             const SizedBox(width: 12),

//                             // 🔸 Uzun metinler satır atlayabilir
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text("PN: ${item.partNumber}",
//                                       softWrap: true),
//                                   Text("SN: ${item.serialNumber}",
//                                       softWrap: true),
//                                   Text("Üretici: ${item.cage}", softWrap: true),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _scanTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             // Üstte Power + küçük boşluk
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//               child: _buildPowerSlider(),
//             ),
//             const SizedBox(height: 8),

//             // START/CLEAR (dropdown ile aynı genişlik)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: SizedBox(
//                   width: _controlsWidth(context),
//                   child: _buildButtonRow(),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),

//             // ATA Class dropdown (butonlar ile birebir hizalı)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: SizedBox(
//                   width: _controlsWidth(context),
//                   child: _buildAtaFilterDropdown(),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),

//             // Liste
//             _buildTagList(),
//           ],
//         ),

//         // Paylaş FAB
//         Positioned(
//           right: 8,
//           bottom: 8,
//           child: IgnorePointer(
//             ignoring: _exportBusy || _tagItems.isEmpty,
//             child: Opacity(
//               opacity: (_exportBusy || _tagItems.isEmpty) ? 0.5 : 1.0,
//               child: FloatingActionButton(
//                 heroTag: 'fabShareEmail',
//                 tooltip: 'E-posta ile paylaş (.xlsx)',
//                 shape: const CircleBorder(),
//                 backgroundColor: Colors.grey.shade700,
//                 foregroundColor: Colors.white,
//                 onPressed: (_exportBusy || _tagItems.isEmpty)
//                     ? null
//                     : _shareExcelAnywhere,
//                 child: AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 200),
//                   child: _exportBusy
//                       ? const SizedBox(
//                           key: ValueKey('loader'),
//                           width: 22,
//                           height: 22,
//                           child: CircularProgressIndicator(
//                               strokeWidth: 2, color: Colors.white),
//                         )
//                       : const Icon(Icons.mail_outline, key: ValueKey('icon')),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// // }
// import 'dart:async';
// import 'dart:developer';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:excel/excel.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';

// import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
// import 'package:water_boiler_rfid_labeler/models/tag_item.dart';
// import 'package:water_boiler_rfid_labeler/ui/router/app_bar.dart';
// import 'package:water_boiler_rfid_labeler/ui/screens/box_check_scan_screen/epc_user_codec.dart';
// import 'package:water_boiler_rfid_labeler/ui/screens/box_check_scan_screen/tag_detail_screen.dart';

// class FilterOption {
//   final int id;
//   final String label;
//   const FilterOption(this.id, this.label);
// }

// const FilterOption kAtaAll = FilterOption(-999, 'All — show everything');

// const List<FilterOption> kAtaFilterOptions = [
//   FilterOption(0, 'All others'),
//   FilterOption(1, 'Item (general; not 8–63)'),
//   FilterOption(2, 'Carton'),
//   FilterOption(6, 'Pallet'),
//   FilterOption(8, 'Seat Cushions'),
//   FilterOption(9, 'Seat Covers'),
//   FilterOption(10, 'Seat Belts / Belt Ext.'),
//   FilterOption(11, 'Galley & Service Equip.'),
//   FilterOption(12, 'Galley Ovens'),
//   FilterOption(13, 'Aircraft Security Items'),
//   FilterOption(14, 'Life Vests'),
//   FilterOption(15, 'Oxygen Generators (not cylinders/bottles)'),
//   FilterOption(16, 'Engine & Engine Components'),
//   FilterOption(17, 'Avionics'),
//   FilterOption(18, 'Experimental (“flight test”) equip.'),
//   FilterOption(19, 'Other Emergency Equipment'),
//   FilterOption(20, 'Other Rotables'),
//   FilterOption(21, 'Other Repairables'),
//   FilterOption(22, 'Other Cabin Interior'),
//   FilterOption(23, 'Other Repair (e.g., structural)'),
//   FilterOption(24, 'Seat & Seat Components (excl. 8–10)'),
//   FilterOption(25, 'In-Flight Entertainment (IFE) & related'),
//   FilterOption(56, 'Location Identifier'),
//   FilterOption(57, 'Documentation'),
//   FilterOption(58, 'Tools'),
//   FilterOption(59, 'Ground Support Equipment'),
//   FilterOption(60, 'Other Non-Flyable Equipment'),
// ];

// class BoxCheckScanScreen extends StatelessWidget {
//   const BoxCheckScanScreen({Key? key}) : super(key: key);

//   // @override
//   // Widget build(BuildContext context) {
//   //   return Scaffold(
//   //     appBar: commonAppBar(context, 'TAG READER', showBack: true),
//   //     body: const _BoxCheckScanBody(),
//   //   );
//   // }
//   Future<bool> _goHome(BuildContext context) async {
//     Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
//     return false; // bu sayfayı pop etme
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false, // geri eylemini biz yöneteceğiz
//       onPopInvokedWithResult: (didPop, result) {
//         if (didPop) return; // Navigator zaten pop ettiyse dokunma
//         Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
//       },
//       child: Scaffold(
//         appBar: commonAppBar(context, 'TAG READER', showBack: true),
//         body: const _BoxCheckScanBody(),
//       ),
//     );
//   }
// }

// class _BoxCheckScanBody extends StatefulWidget {
//   const _BoxCheckScanBody();
//   @override
//   State<_BoxCheckScanBody> createState() => _BoxCheckScanBodyState();
// }

// class _BoxCheckScanBodyState extends State<_BoxCheckScanBody> {
//   bool _isScanning = false;
//   bool _exportBusy = false;

//   int _umRoundRobinIndex = 0;
//   Timer? _scanTimer;

//   double _powerLevel = 5;
//   final double _minPower = 5;
//   final double _maxPower = 30;
//   final int _divisions = 25;

//   final List<TagItem> _tagItems = [];
//   final Set<String> _epcSet = <String>{};
//   final Map<String, DateTime> _lastSeen = {};
//   bool _scanTickBusy = false;

//   List<FilterOption> get _ataOptions => [kAtaAll, ...kAtaFilterOptions];

//   // UI ölçüler
//   static const double _controlHeight = 48.0; // buton ve kapalı dropdown
//   static const double _controlsMaxWidth = 360;
//   static const double _listRowApproxHeight = 60;
//   static const int _listMaxVisibleRows = 5;

//   double _controlsWidth(BuildContext context) {
//     final usable = MediaQuery.of(context).size.width - 32;
//     return _controlsMaxWidth < usable ? _controlsMaxWidth : usable;
//   }

//   // --- ATA filter state ---
//   FilterOption? _selectedAta;

//   int? _ataClassOf(TagItem t) {
//     final hex = t.userHex;
//     if (hex == null || hex.length < 16) return null;
//     final d = decodeUserMemory(hex);
//     final v = d['ataClass'];
//     if (v is int) return v;
//     if (v is String) return int.tryParse(v);
//     return null;
//   }

//   List<TagItem> get _filteredItems {
//     final sel = _selectedAta;
//     if (sel == null || sel.id == kAtaAll.id) return _tagItems;
//     final code = sel.id;
//     return _tagItems.where((t) => _ataClassOf(t) == code).toList();
//   }

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkIfConnected(); // ağır iş: plugin init/bağlantı
//     });
//     _selectedAta = kAtaAll;
//   }

//   Future<void> _checkIfConnected() async {
//     log("Checking if RFID reader is already connected (BoxCheckScanScreen)...");
//     final bool? connected = await RfidC72Plugin.isConnected;
//     log(connected == true ? "Yes, RFID connected" : "RFID not connected.");
//   }

//   Future<void> _readTag() async {
//     try {
//       final String? raw = await RfidC72Plugin.readSingleTagEpc();
//       if (raw == null || raw.isEmpty) return;

//       final epcHex = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();

//       final now = DateTime.now();
//       final last = _lastSeen[epcHex];
//       if (last != null && now.difference(last) < const Duration(seconds: 3)) {
//         return;
//       }
//       _lastSeen[epcHex] = now;

//       if (_epcSet.contains(epcHex)) return;

//       final decoded = decodeEpc(epcHex);
//       setState(() {
//         _epcSet.add(epcHex);
//         _tagItems.insert(
//           0,
//           TagItem(
//             rawEpc: epcHex,
//             cage: decoded.cage,
//             partNumber: decoded.partNumber,
//             serialNumber: decoded.serialNumber,
//             userRead: false,
//           ),
//         );
//       });

//       await _checkUserMemoryOnce(_tagItems.first);
//     } catch (e) {
//       log("Error reading tag: $e");
//     }
//   }

//   void _toggleScan() {
//     if (!_isScanning) {
//       _scanTimer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
//         if (_scanTickBusy) return;
//         _scanTickBusy = true;
//         try {
//           await _readTag();
//           await _pollMissingUserMemoryDuringScan(maxPerTick: 2);
//         } finally {
//           _scanTickBusy = false;
//         }
//       });
//       setState(() => _isScanning = true);
//     } else {
//       _scanTimer?.cancel();
//       _scanTimer = null;
//       setState(() => _isScanning = false);
//     }
//   }

//   void _clearList() {
//     setState(() {
//       _tagItems.clear();
//       _epcSet.clear();
//       _lastSeen.clear();
//     });
//   }

//   Future<void> _shareExcelAnywhere() async {
//     if (_tagItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Liste boş: export için etiket yok.')),
//       );
//       return;
//     }

//     final wasScanning = _isScanning;
//     if (wasScanning) _toggleScan();
//     setState(() => _exportBusy = true);

//     try {
//       final excel = Excel.createExcel();
//       final String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
//       final sheet = excel.sheets[sheetName]!;

//       sheet.appendRow([
//         'No',
//         'PN',
//         'SN',
//         'Üretici (CAGE)',
//         'EPC (HEX)',
//         'USER HEX',
//         'w0',
//         'w1',
//         'w2',
//         'w3',
//         'ToC Major',
//         'ToC Minor',
//         'ATA Class',
//         'Tag Type',
//         'Payload Text',
//       ]);

//       int i = 1;
//       for (final t in _filteredItems) {
//         final userHex =
//             await RfidC72Plugin.readUserMemoryForEpc(t.rawEpc) ?? '';
//         final d = decodeUserMemory(userHex);
//         sheet.appendRow([
//           i++,
//           t.partNumber,
//           t.serialNumber,
//           t.cage,
//           t.rawEpc,
//           userHex,
//           d['w0'] ?? '',
//           d['w1'] ?? '',
//           d['w2'] ?? '',
//           d['w3'] ?? '',
//           d['tocMajor'] ?? '',
//           d['tocMinor'] ?? '',
//           d['ataClass'] ?? '',
//           d['tagType'] ?? '',
//           d['payloadText'] ?? '',
//         ]);
//       }

//       final bytes = excel.encode();
//       if (bytes == null) throw Exception('Excel encode null');

//       final dir = await getTemporaryDirectory();
//       final now = DateTime.now();
//       String two(int n) => n.toString().padLeft(2, '0');
//       final stamp =
//           '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';

//       final fileName = 'RFID-READ-TAGS-$stamp.xlsx';
//       final file = File('${dir.path}/$fileName')..createSync(recursive: true);
//       await file.writeAsBytes(bytes, flush: true);

//       await Share.shareXFiles(
//         [
//           XFile(file.path,
//               name: fileName,
//               mimeType:
//                   'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
//         ],
//         subject: 'RFID Export ($stamp)',
//         text: 'Ekte PN/SN/Üretici + EPC + USER içerikleri bulunmaktadır.',
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Paylaşım başarısız: $e')),
//       );
//     } finally {
//       if (wasScanning) _toggleScan();
//       if (mounted) setState(() => _exportBusy = false);
//     }
//   }

//   Future<void> _checkUserMemoryOnce(TagItem item) async {
//     if (item.userRead == true) return;
//     try {
//       final hex = await RfidC72Plugin.readUserMemoryForEpc(item.rawEpc);
//       if (!mounted) return;
//       if (hex != null && hex.length >= 16) {
//         setState(() {
//           item.userHex = hex;
//           item.userRead = true;
//         });
//       }
//     } catch (_) {}
//   }

//   Future<void> _pollMissingUserMemoryDuringScan({int maxPerTick = 2}) async {
//     if (!_isScanning || _tagItems.isEmpty) return;
//     int checked = 0;
//     final total = _tagItems.length;
//     while (checked < maxPerTick) {
//       _umRoundRobinIndex = (_umRoundRobinIndex + 1) % total;
//       final item = _tagItems[_umRoundRobinIndex];
//       if (!item.userRead) await _checkUserMemoryOnce(item);
//       checked++;
//       if (!_isScanning) break;
//     }
//   }

//   Widget _buildAtaFilterDropdown() {
//     final opts = _ataOptions;
//     return DropdownButtonFormField<FilterOption>(
//       value: _selectedAta ?? kAtaAll,
//       isDense: true,
//       isExpanded: true,
//       itemHeight: _controlHeight, // >= 48 şartını sağlıyor
//       menuMaxHeight: _controlHeight * 5 + 16,
//       decoration: InputDecoration(
//         labelText: 'ATA Class',
//         floatingLabelBehavior: FloatingLabelBehavior.auto,
//         isDense: true,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey.shade400),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey.shade600, width: 1.5),
//         ),
//       ),
//       items: opts.map((o) {
//         final label = o.id == kAtaAll.id ? o.label : '${o.id} — ${o.label}';
//         return DropdownMenuItem(
//           value: o,
//           child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
//         );
//       }).toList(),
//       onChanged: (v) => setState(() => _selectedAta = v),
//     );
//   }

//   Widget _buildPowerSlider() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Adjust Power Level => ${_powerLevel.toInt()}",
//             style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
//         const SizedBox(height: 6),
//         SliderTheme(
//           data: SliderTheme.of(context).copyWith(
//             trackHeight: 2,
//             thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
//             overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
//           ),
//           child: Row(
//             children: [
//               SizedBox(
//                 width: 24,
//                 child: Text(_minPower.toInt().toString(),
//                     textAlign: TextAlign.center,
//                     style:
//                         const TextStyle(fontSize: 12, color: Colors.black54)),
//               ),
//               Expanded(
//                 child: Slider(
//                   value: _powerLevel,
//                   min: _minPower,
//                   max: _maxPower,
//                   divisions: _divisions,
//                   onChanged: (v) => setState(() => _powerLevel = v),
//                   onChangeEnd: (v) {
//                     RfidC72Plugin.setPowerLevel(v.toInt().toString());
//                     log("Power level set to ${v.toInt()}");
//                   },
//                 ),
//               ),
//               SizedBox(
//                 width: 24,
//                 child: Text(_maxPower.toInt().toString(),
//                     textAlign: TextAlign.center,
//                     style:
//                         const TextStyle(fontSize: 12, color: Colors.black54)),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildButtonRow() {
//     final dense = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
//     final denseText =
//         const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

//     final elevStyle = ElevatedButton.styleFrom(
//       padding: dense,
//       textStyle: denseText,
//       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//       visualDensity: const VisualDensity(vertical: -2),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       backgroundColor:
//           _isScanning ? Colors.red.shade600 : Colors.green.shade600,
//       foregroundColor: Colors.white,
//       minimumSize: const Size.fromHeight(_controlHeight),
//     );

//     final outStyle = OutlinedButton.styleFrom(
//       padding: dense,
//       textStyle: denseText,
//       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//       visualDensity: const VisualDensity(vertical: -2),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       minimumSize: const Size.fromHeight(_controlHeight),
//     );

//     return Row(
//       children: [
//         Expanded(
//             child: ElevatedButton(
//                 onPressed: _toggleScan,
//                 style: elevStyle,
//                 child: Text(_isScanning ? "Stop Scan" : "Start Scan"))),
//         const SizedBox(width: 8),
//         Expanded(
//             child: OutlinedButton(
//                 onPressed: _clearList,
//                 style: outStyle,
//                 child: const Text("Clear List"))),
//       ],
//     );
//   }

//   Widget _buildTagList() {
//     final items = _filteredItems;

//     return Expanded(
//       // <- boş alan kalmasın, liste alanı tüm alt kısmı doldursun
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
//             child: Text(
//               "Total Tags: ${items.length} / ${_tagItems.length}",
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Expanded(
//             child: items.isEmpty
//                 ? const Center(child: Text("No tags read yet."))
//                 : ListView.separated(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     itemCount: items.length,
//                     separatorBuilder: (_, __) =>
//                         const Divider(height: 1, thickness: 1),
//                     itemBuilder: (context, index) {
//                       final item = items[index];
//                       final ok = item.userRead == true;

//                       return Material(
//                         color:
//                             ok ? Colors.green.shade50 : Colors.yellow.shade100,
//                         child: ListTile(
//                           contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 8, vertical: 6),
//                           // ① Numara: dikeyde otomatik ortalı
//                           leading: CircleAvatar(
//                             radius: 16,
//                             backgroundColor: ok ? Colors.green : Colors.amber,
//                             child: FittedBox(
//                               child: Text(
//                                 '${index + 1}',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           // ② Metinler
//                           title: Text('PN: ${item.partNumber}', softWrap: true),
//                           subtitle: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('SN: ${item.serialNumber}', softWrap: true),
//                               Text('Üretici: ${item.cage}', softWrap: true),
//                             ],
//                           ),
//                           // ③ Tıklayınca detay sayfası
//                           onTap: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (_) => TagDetailScreen(
//                                   tagItem: item,
//                                   // Eğer daha önce okunmadıysa boş ver,
//                                   // TagDetailScreen kendi otomatik okuyor.
//                                   userMemoryHex: item.userHex ?? '',
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _scanTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//                 child: _buildPowerSlider()),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: SizedBox(
//                     width: _controlsWidth(context), child: _buildButtonRow()),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: SizedBox(
//                     width: _controlsWidth(context),
//                     child: _buildAtaFilterDropdown()),
//               ),
//             ),
//             const SizedBox(height: 8),
//             _buildTagList(),
//           ],
//         ),
//         Positioned(
//           right: 8,
//           bottom: 8,
//           child: IgnorePointer(
//             ignoring: _exportBusy || _tagItems.isEmpty,
//             child: Opacity(
//               opacity: (_exportBusy || _tagItems.isEmpty) ? 0.5 : 1.0,
//               child: FloatingActionButton(
//                 heroTag: 'fabShareEmail',
//                 tooltip: 'E-posta ile paylaş (.xlsx)',
//                 shape: const CircleBorder(),
//                 backgroundColor: Colors.grey.shade700,
//                 foregroundColor: Colors.white,
//                 onPressed: (_exportBusy || _tagItems.isEmpty)
//                     ? null
//                     : _shareExcelAnywhere,
//                 child: AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 200),
//                   child: _exportBusy
//                       ? const SizedBox(
//                           key: ValueKey('loader'),
//                           width: 22,
//                           height: 22,
//                           child: CircularProgressIndicator(
//                               strokeWidth: 2, color: Colors.white),
//                         )
//                       : const Icon(Icons.mail_outline, key: ValueKey('icon')),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
// lib/ui/screens/box_check_scan_screen/box_check_scan_screen.dart
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
import 'package:water_boiler_rfid_labeler/models/tag_item.dart';
import 'package:water_boiler_rfid_labeler/ui/router/app_bar.dart';
import 'package:water_boiler_rfid_labeler/ui/screens/box_check_scan_screen/epc_user_codec.dart';
import 'package:water_boiler_rfid_labeler/ui/screens/box_check_scan_screen/tag_detail_screen.dart';

class FilterOption {
  final int id;
  final String label;
  const FilterOption(this.id, this.label);
}

const FilterOption kAtaAll = FilterOption(-999, 'All — show everything');

const List<FilterOption> kAtaFilterOptions = [
  FilterOption(0, 'All others'),
  FilterOption(1, 'Item (general; not 8–63)'),
  FilterOption(2, 'Carton'),
  FilterOption(6, 'Pallet'),
  FilterOption(8, 'Seat Cushions'),
  FilterOption(9, 'Seat Covers'),
  FilterOption(10, 'Seat Belts / Belt Ext.'),
  FilterOption(11, 'Galley & Service Equip.'),
  FilterOption(12, 'Galley Ovens'),
  FilterOption(13, 'Aircraft Security Items'),
  FilterOption(14, 'Life Vests'),
  FilterOption(15, 'Oxygen Generators (not cylinders/bottles)'),
  FilterOption(16, 'Engine & Engine Components'),
  FilterOption(17, 'Avionics'),
  FilterOption(18, 'Experimental (“flight test”) equip.'),
  FilterOption(19, 'Other Emergency Equipment'),
  FilterOption(20, 'Other Rotables'),
  FilterOption(21, 'Other Repairables'),
  FilterOption(22, 'Other Cabin Interior'),
  FilterOption(23, 'Other Repair (e.g., structural)'),
  FilterOption(24, 'Seat & Seat Components (excl. 8–10)'),
  FilterOption(25, 'In-Flight Entertainment (IFE) & related'),
  FilterOption(56, 'Location Identifier'),
  FilterOption(57, 'Documentation'),
  FilterOption(58, 'Tools'),
  FilterOption(59, 'Ground Support Equipment'),
  FilterOption(60, 'Other Non-Flyable Equipment'),
];

class BoxCheckScanScreen extends StatelessWidget {
  const BoxCheckScanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      },
      child: Scaffold(
        appBar: commonAppBar(context, 'TAG READER', showBack: true),
        body: const _BoxCheckScanBody(),
      ),
    );
  }
}

class _BoxCheckScanBody extends StatefulWidget {
  const _BoxCheckScanBody();
  @override
  State<_BoxCheckScanBody> createState() => _BoxCheckScanBodyState();
}

class _BoxCheckScanBodyState extends State<_BoxCheckScanBody> {
  bool _isScanning = false;
  bool _exportBusy = false;

  Timer? _scanTimer;
  bool _scanTickBusy = false;

  // RF power
  double _powerLevel = 5;
  final double _minPower = 5;
  final double _maxPower = 30;
  final int _divisions = 25;

  // Data
  final List<TagItem> _tagItems = [];
  final Set<String> _epcSet = <String>{};
  final Map<String, DateTime> _lastSeen = {};

  // Filter
  FilterOption? _selectedAta = kAtaAll;
  List<FilterOption> get _ataOptions => [kAtaAll, ...kAtaFilterOptions];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfConnected());
  }

  Future<void> _checkIfConnected() async {
    log("Checking if RFID reader is already connected (BoxCheckScanScreen)...");
    final bool? connected = await RfidC72Plugin.isConnected;
    log(connected == true ? "Yes, RFID connected" : "RFID not connected.");
  }

  int? _ataClassOf(TagItem t) {
    final hex = t.userHex;
    if (hex == null || hex.length < 16) return null;
    final d = decodeUserMemory(hex);
    final v = d['ataClass'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  int? _epcFilterFromHex(String epcHex) {
    if (epcHex.isEmpty) return null;
    try {
      final d = decodeEpc(epcHex); // epc_user_codec.dart
      return d.filterValue;
    } catch (_) {
      return null;
    }
  }

  List<TagItem> get _filteredItems {
    final sel = _selectedAta;
    if (sel == null || sel.id == kAtaAll.id) return _tagItems;

    final wanted = sel.id; // 0..63
    return _tagItems.where((t) {
      final f = _epcFilterFromHex(t.rawEpc);
      return f == wanted;
    }).toList();
  }

  Future<void> _readTag() async {
    try {
      final String? raw = await RfidC72Plugin.readSingleTagEpc();
      if (raw == null || raw.isEmpty) return;

      final epcHex = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();

      final now = DateTime.now();
      final last = _lastSeen[epcHex];
      if (last != null && now.difference(last) < const Duration(seconds: 3)) {
        return;
      }
      _lastSeen[epcHex] = now;

      if (_epcSet.contains(epcHex)) return;

      final decoded = decodeEpc(epcHex);
      setState(() {
        _epcSet.add(epcHex);
        _tagItems.insert(
          0,
          TagItem(
            rawEpc: epcHex,
            cage: decoded.cage,
            partNumber: decoded.partNumber,
            serialNumber: decoded.serialNumber,
            userRead: false,
          ),
        );
      });

      // İlk USER denemesi
      await _checkUserMemoryOnce(_tagItems.first);
    } catch (e) {
      log("Error reading tag: $e");
    }
  }

  void _toggleScan() {
    if (!_isScanning) {
      _scanTimer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
        if (_scanTickBusy) return;
        _scanTickBusy = true;
        try {
          await _readTag();
          // user memory'leri yuvarlanarak doldur
          for (final t in _tagItems) {
            if (!t.userRead) {
              await _checkUserMemoryOnce(t);
              break;
            }
          }
        } finally {
          _scanTickBusy = false;
        }
      });
      setState(() => _isScanning = true);
    } else {
      _scanTimer?.cancel();
      _scanTimer = null;
      setState(() => _isScanning = false);
    }
  }

  void _clearList() {
    setState(() {
      _tagItems.clear();
      _epcSet.clear();
      _lastSeen.clear();
    });
  }

  Future<void> _checkUserMemoryOnce(TagItem item) async {
    if (item.userRead == true) return;
    try {
      final hex = await RfidC72Plugin.readUserMemoryForEpc(item.rawEpc);
      if (!mounted) return;
      if (hex != null && hex.length >= 16) {
        setState(() {
          item.userHex = hex;
          item.userRead = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _shareExcelAnywhere() async {
    if (_tagItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liste boş: export için etiket yok.')),
      );
      return;
    }

    final wasScanning = _isScanning;
    if (wasScanning) _toggleScan();
    setState(() => _exportBusy = true);

    try {
      final excel = Excel.createExcel();
      final String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel.sheets[sheetName]!;

      sheet.appendRow([
        'No',
        'PN',
        'SN',
        'Üretici (CAGE)',
        'EPC (HEX)',
        'USER HEX',
        'w0',
        'w1',
        'w2',
        'w3',
        'ToC Major',
        'ToC Minor',
        'ATA Class',
        'Tag Type',
        'Payload Text',
      ]);

      int i = 1;
      for (final t in _filteredItems) {
        final userHex =
            await RfidC72Plugin.readUserMemoryForEpc(t.rawEpc) ?? '';
        final d = decodeUserMemory(userHex);
        sheet.appendRow([
          i++,
          t.partNumber,
          t.serialNumber,
          t.cage,
          t.rawEpc,
          userHex,
          d['w0'] ?? '',
          d['w1'] ?? '',
          d['w2'] ?? '',
          d['w3'] ?? '',
          d['tocMajor'] ?? '',
          d['tocMinor'] ?? '',
          d['ataClass'] ?? '',
          d['tagType'] ?? '',
          d['payloadText'] ?? '',
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Excel encode null');

      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final stamp =
          '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';

      final fileName = 'RFID-READ-TAGS-$stamp.xlsx';
      final file = File('${dir.path}/$fileName')..createSync(recursive: true);
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [
          XFile(file.path,
              name: fileName,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        ],
        subject: 'RFID Export ($stamp)',
        text: 'Ekte PN/SN/Üretici + EPC + USER içerikleri bulunmaktadır.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paylaşım başarısız: $e')),
      );
    } finally {
      if (wasScanning) _toggleScan();
      if (mounted) setState(() => _exportBusy = false);
    }
  }

  void _openDetail(TagItem item) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TagDetailScreen(
        tagItem: item,
        userMemoryHex: item.userHex ?? '',
      ),
    ));
  }

  Widget _buildPowerSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Adjust Power Level => ${_powerLevel.toInt()}",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(_minPower.toInt().toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
            Expanded(
              child: Slider(
                value: _powerLevel,
                min: _minPower,
                max: _maxPower,
                divisions: _divisions,
                onChanged: (v) => setState(() => _powerLevel = v),
                onChangeEnd: (v) {
                  RfidC72Plugin.setPowerLevel(v.toInt().toString());
                  log("Power level set to ${v.toInt()}");
                },
              ),
            ),
            SizedBox(
              width: 24,
              child: Text(_maxPower.toInt().toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
          ],
        ),
      ],
    );
  }

  // --- Sadece bu fonksiyonu güncelleyin ---
  Widget _buildAtaFilterDropdown() {
    final opts = _ataOptions;
    return DropdownButtonFormField<FilterOption>(
      value: _selectedAta ?? kAtaAll,
      isDense: true,
      isExpanded: true,
      // <= Menü yüksekliğini 5 satırla sınırla
      menuMaxHeight: 5 * kMinInteractiveDimension,
      decoration: InputDecoration(
        labelText: 'ATA Class',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: opts.map((o) {
        final label = o.id == kAtaAll.id ? o.label : '${o.id} — ${o.label}';
        return DropdownMenuItem(
          value: o,
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedAta = v),
    );
  }

  Widget _buildButtonRow() {
    final dense = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final denseText =
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    final elevStyle = ElevatedButton.styleFrom(
      padding: dense,
      textStyle: denseText,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(vertical: -2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor:
          _isScanning ? Colors.red.shade600 : Colors.green.shade600,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
    );

    final outStyle = OutlinedButton.styleFrom(
      padding: dense,
      textStyle: denseText,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(vertical: -2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      minimumSize: const Size.fromHeight(48),
    );

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _toggleScan,
            style: elevStyle,
            child: Text(_isScanning ? "Stop Scan" : "Start Scan"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _clearList,
            style: outStyle,
            child: const Text("Clear List"),
          ),
        ),
      ],
    );
  }

  // --- Sadece bu fonksiyonu güncelleyin ---
  Widget _listItem(TagItem item, int index) {
    final ok = item.userRead == true;
    return InkWell(
      onTap: () => _openDetail(item),
      child: Container(
        color: ok ? Colors.green.shade50 : Colors.yellow.shade100,
        padding: const EdgeInsets.symmetric(vertical: 10), // biraz daha nefes
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // <== dikeyde ortala
          children: [
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: ok ? Colors.green : Colors.amber,
              child: Text(
                (index + 1).toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PN: ${item.partNumber}", softWrap: true),
                    Text("SN: ${item.serialNumber}", softWrap: true),
                    Text("Üretici: ${item.cage}", softWrap: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagList() {
    final items = _filteredItems;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Text(
              "Total Tags: ${items.length} / ${_tagItems.length}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text("No tags read yet."))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 1),
                    itemBuilder: (context, index) =>
                        _listItem(items[index], index),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildPowerSlider(),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildButtonRow(),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAtaFilterDropdown(),
            ),
            const SizedBox(height: 8),
            _buildTagList(),
          ],
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: IgnorePointer(
            ignoring: _exportBusy || _tagItems.isEmpty,
            child: Opacity(
              opacity: (_exportBusy || _tagItems.isEmpty) ? 0.5 : 1.0,
              child: FloatingActionButton(
                heroTag: 'fabShareEmail',
                tooltip: 'E-posta ile paylaş (.xlsx)',
                shape: const CircleBorder(),
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
                onPressed: (_exportBusy || _tagItems.isEmpty)
                    ? null
                    : _shareExcelAnywhere,
                child: _exportBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.mail_outline),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
