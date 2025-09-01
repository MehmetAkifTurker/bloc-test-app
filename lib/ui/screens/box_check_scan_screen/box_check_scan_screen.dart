import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:share_plus/share_plus.dart';

import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
import 'package:water_boiler_rfid_labeler/ui/router/app_bar.dart';
import 'package:water_boiler_rfid_labeler/ui/router/bottom_navigation.dart';

class BoxCheckScanScreen extends StatelessWidget {
  const BoxCheckScanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(context, 'TAG READER', showBack: true),
      // bottomNavigationBar: bottomNavigationBar(context),
      body: const _BoxCheckScanBody(),
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

  // Tek alıcı (deneme)

  int _umRoundRobinIndex = 0;

  Timer? _scanTimer;

  double _powerLevel = 5;
  final double _minPower = 5;
  final double _maxPower = 30;
  final int _divisions = 25;

  final List<TagItem> _tagItems = [];

  final Set<String> _epcSet = <String>{}; // ✅ Sert kopya engeli
  final Map<String, DateTime> _lastSeen =
      {}; // ✅ Hızlı tekrarları bastırma (cooldown)
  bool _scanTickBusy = false; // ✅ Aynı anda iki tick çalışmasın

  @override
  void initState() {
    super.initState();
    _checkIfConnected();
  }

  Future<void> _checkIfConnected() async {
    log("Checking if RFID reader is already connected (BoxCheckScanScreen)...");
    final bool? connected = await RfidC72Plugin.isConnected;
    if (connected == true) {
      log("Yes, RFID is connected in BoxCheckScanScreen");
    } else {
      log("RFID not connected.");
    }
  }

  Future<void> _readTag() async {
    try {
      final String? raw = await RfidC72Plugin.readSingleTagEpc();
      if (raw == null || raw.isEmpty) {
        log("No tag found");
        return;
      }

      // 1) EPC’yi normalize et (boşlukları at, büyük harfe çevir)
      final epcHex = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();

      // 2) Hızlı tekrarları (ör. 3 sn) bastır
      final now = DateTime.now();
      final last = _lastSeen[epcHex];
      if (last != null && now.difference(last) < const Duration(seconds: 3)) {
        log("Suppressed duplicate within cooldown: $epcHex");
        return;
      }
      _lastSeen[epcHex] = now;

      // 3) Sert kopya engeli – zaten gördüysek ekleme
      if (_epcSet.contains(epcHex)) {
        log("Duplicate EPC ignored: $epcHex");
        return;
      }

      // 4) Decode + listeye ekle
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

      // 5) Yeni eklenen için USER’ı fırsatçı okuma
      await _checkUserMemoryOnce(_tagItems.first);
    } catch (e) {
      log("Error reading tag: $e");
    }
  }

  void _toggleScan() {
    if (!_isScanning) {
      _scanTimer =
          Timer.periodic(const Duration(milliseconds: 400), (timer) async {
        if (_scanTickBusy) return; // ⛔️ Overlap yok
        _scanTickBusy = true;
        try {
          await _readTag();
          await _pollMissingUserMemoryDuringScan(maxPerTick: 2);
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

  /// EPC + USER verilerini Excel’e yazıp sabit alıcıya e‑posta ile paylaş
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
      // 1) Excel oluştur

      final excel = Excel.createExcel();
      final String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel.sheets[sheetName]!; // rename yok → patlama yok

      sheet.appendRow([
        'No',
        'EPC (HEX)',
        'CAGE',
        'Part Number',
        'Serial Number',
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
      for (final t in _tagItems) {
        final userHex =
            await RfidC72Plugin.readUserMemoryForEpc(t.rawEpc) ?? '';
        final d = decodeUserMemory(userHex);
        sheet.appendRow([
          i++,
          t.rawEpc,
          t.cage,
          t.partNumber,
          t.serialNumber,
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

// YYYYMMDD_HHMMSS time-stamp
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final stamp =
          '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';

// Dosya adı: RFID-READ-TAGS-YYYYMMDD_HHMMSS.xlsx
      final fileName = 'RFID-READ-TAGS-$stamp.xlsx';
      final file = File('${dir.path}/$fileName')..createSync(recursive: true);
      await file.writeAsBytes(bytes, flush: true);

      // 2) Paylaşım menüsünü aç (Outlook/Teams/WhatsApp/Drive vs.)
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            name: fileName,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          )
        ],
        subject: 'RFID Export ($stamp)',
        text: 'Ekte RFID etiketlerinin EPC + USER içeriği bulunmaktadır.',
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

  Future<void> _checkUserMemoryOnce(TagItem item) async {
    if (item.userRead == true) return;
    try {
      final hex = await RfidC72Plugin.readUserMemoryForEpc(item.rawEpc);
      if (!mounted) return;
      if (hex != null && hex.length >= 16) {
        setState(() {
          item.userHex = hex; // <-- CACHE
          item.userRead = true; // <-- renk yeşil
        });
      }
    } catch (_) {}
  }

  Future<void> _pollMissingUserMemoryDuringScan({int maxPerTick = 2}) async {
    if (!_isScanning || _tagItems.isEmpty) return;

    int checked = 0;
    final total = _tagItems.length;
    // her tıkta en fazla 'maxPerTick' okumaya çalış; cihazı yormayalım
    while (checked < maxPerTick) {
      // sıradaki indeksi seç
      _umRoundRobinIndex = (_umRoundRobinIndex + 1) % total;
      final item = _tagItems[_umRoundRobinIndex];

      if (!item.userRead) {
        await _checkUserMemoryOnce(item);
        checked++;
      } else {
        // zaten okunmuş; başka adayı dene
        // tümü okunduysa bu döngü hızlıca bitecek
        checked++;
      }

      // tarama kapandıysa çık
      if (!_isScanning) break;
    }
  }

  Widget _buildPowerSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
          child: Text(
            "Adjust Power Level (Current: ${_powerLevel.toInt()})",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(_minPower.toInt().toString(),
                  style: const TextStyle(fontSize: 16)),
            ),
            Expanded(
              child: Slider(
                value: _powerLevel,
                min: _minPower,
                max: _maxPower,
                divisions: _divisions,
                label: _powerLevel.toInt().toString(),
                onChanged: (value) {
                  setState(() {
                    _powerLevel = value;
                  });
                },
                onChangeEnd: (value) {
                  RfidC72Plugin.setPowerLevel(value.toInt().toString());
                  log("Power level set to ${value.toInt()}");
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(_maxPower.toInt().toString(),
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _toggleScan,
          child: Text(_isScanning ? "Stop Scan" : "Start Scan"),
        ),
        ElevatedButton(
          onPressed: _clearList,
          child: const Text("Clear List"),
        ),
      ],
    );
  }

  // Widget _buildTagList() {
  //   return Expanded(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  //           child: Text(
  //             "Total Tags: ${_tagItems.length}",
  //             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Expanded(
  //           child: _tagItems.isEmpty
  //               ? const Center(child: Text("No tags read yet."))
  //               : ListView.separated(
  //                   itemCount: _tagItems.length,
  //                   separatorBuilder: (context, index) =>
  //                       const Divider(height: 1, color: Colors.grey),
  //                   itemBuilder: (context, index) {
  //                     final item = _tagItems[index];
  //                     final bool ok = (item.userRead == true); // null-safe bool

  //                     return InkWell(
  //                       onTap: () async {
  //                         if (_isScanning) _toggleScan();

  //                         // önce cache varsa onu kullan
  //                         String hex = item.userHex ?? '';

  //                         // cache boşsa bir kez daha dene
  //                         if (hex.isEmpty) {
  //                           final fresh =
  //                               await RfidC72Plugin.readUserMemoryForEpc(
  //                                   item.rawEpc);
  //                           if (fresh != null && fresh.length >= 16) {
  //                             if (!mounted) return;
  //                             setState(() {
  //                               item.userHex = fresh; // <-- CACHE’i güncelle
  //                               item.userRead = true; // güvence
  //                             });
  //                             hex = fresh;
  //                           }
  //                         }

  //                         // Detay ekranına CACHE’i taşı
  //                         if (!mounted) return;
  //                         Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                             builder: (context) => TagDetailScreen(
  //                               tagItem: item,
  //                               userMemoryHex:
  //                                   hex, // <-- cache varsa direkt görünür
  //                             ),
  //                           ),
  //                         );
  //                       },
  //                       child: Container(
  //                         color: ok
  //                             ? Colors.green.shade50
  //                             : Colors.yellow.shade100, // <--- RENK
  //                         padding: const EdgeInsets.symmetric(
  //                             vertical: 4.0, horizontal: 8.0),
  //                         child: Row(
  //                           crossAxisAlignment: CrossAxisAlignment.center,
  //                           children: [
  //                             CircleAvatar(
  //                               radius: 16,
  //                               backgroundColor:
  //                                   ok ? Colors.green : Colors.amber,
  //                               // <--- BALON
  //                               child: Text(
  //                                 (index + 1).toString(),
  //                                 style: const TextStyle(
  //                                   color: Colors.white,
  //                                   fontSize: 14,
  //                                   fontWeight: FontWeight.bold,
  //                                 ),
  //                               ),
  //                             ),
  //                             const SizedBox(width: 12),
  //                             Expanded(
  //                               child: Column(
  //                                 crossAxisAlignment: CrossAxisAlignment.start,
  //                                 children: [
  //                                   Text("Raw EPC: ${item.rawEpc}"),
  //                                   Text("CAGE: ${item.cage}"),
  //                                   Text("Part Number: ${item.partNumber}"),
  //                                   Text("Serial Number: ${item.serialNumber}"),
  //                                   // İstersen durum etiketi:
  //                                   // Text(item.userRead ? 'USER: OK' : 'USER: NOT READ',
  //                                   //   style: TextStyle(
  //                                   //     fontSize: 12,
  //                                   //     fontWeight: FontWeight.w600,
  //                                   //     color: item.userRead ? Colors.green.shade800 : Colors.orange.shade800,
  //                                   //   )),
  //                                 ],
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildTagList() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlıkta yan padding olmasın
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4), // ⬅ yan 16
            child: Text(
              "Total Tags: ${_tagItems.length}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _tagItems.isEmpty
                ? const Center(child: Text("No tags read yet."))
                : ListView.separated(
                    // Liste padding’i tamamen sıfır
                    padding: EdgeInsets.zero,
                    itemCount: _tagItems.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, thickness: 1),
                    itemBuilder: (context, index) {
                      final item = _tagItems[index];
                      final bool ok = (item.userRead == true);

                      return InkWell(
                        onTap: () async {
                          if (_isScanning) _toggleScan();
                          String hex = item.userHex ?? '';
                          if (hex.isEmpty) {
                            final fresh =
                                await RfidC72Plugin.readUserMemoryForEpc(
                                    item.rawEpc);
                            if (fresh != null && fresh.length >= 16) {
                              if (!mounted) return;
                              setState(() {
                                item.userHex = fresh;
                                item.userRead = true;
                              });
                              hex = fresh;
                            }
                          }
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TagDetailScreen(
                                tagItem: item,
                                userMemoryHex: hex,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          // YAN padding’i kaldır, yalnızca dikey kalsın
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 0.0),
                          color: ok
                              ? Colors.green.shade50
                              : Colors.yellow.shade100,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(
                                  width: 8), // avatar soluna çok küçük boşluk
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    ok ? Colors.green : Colors.amber,
                                child: Text(
                                  (index + 1).toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Raw EPC: ${item.rawEpc}"),
                                    Text("CAGE: ${item.cage}"),
                                    Text("Part Number: ${item.partNumber}"),
                                    Text("Serial Number: ${item.serialNumber}"),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                  width:
                                      8), // sağ kenarda simetrik küçük boşluk
                            ],
                          ),
                        ),
                      );
                    },
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

  // @override
  // Widget build(BuildContext context) {
  //   return Padding(
  //     // Alttaki butona yer bırakmak için dış boşluk
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       children: [
  //         _buildPowerSlider(),
  //         const SizedBox(height: 16),
  //         _buildButtonRow(),
  //         const SizedBox(height: 16),
  //         _buildTagList(),
  //         const SizedBox(height: 12),

  //         // Altta tam genişlikte e‑posta butonu — liste boşken kapalı
  //         SafeArea(
  //           top: false,
  //           child: SizedBox(
  //             width: double.infinity,
  //             child: ElevatedButton.icon(
  //               onPressed: (_exportBusy || _tagItems.isEmpty)
  //                   ? null
  //                   : _shareExcelAnywhere,
  //               icon: _exportBusy
  //                   ? const SizedBox(
  //                       width: 18,
  //                       height: 18,
  //                       child: CircularProgressIndicator(
  //                           strokeWidth: 2, color: Colors.white),
  //                     )
  //                   : const Icon(Icons.email_outlined),
  //               label: Text(_exportBusy
  //                   ? 'Hazırlanıyor…'
  //                   : 'E‑posta ile paylaş (.xlsx)'),
  //               style: ElevatedButton.styleFrom(
  //                 minimumSize: const Size.fromHeight(48),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // içerik
        Column(
          children: [
            // ÜST BAŞLIK + SLIDER (yanlardan 16, üstten 16)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildPowerSlider(),
            ),
            const SizedBox(height: 16),

            // START/CLEAR butonları (yanlardan 16)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildButtonRow(),
            ),
            const SizedBox(height: 16),

            // LİSTE: full-bleed (yan padding yok)
            Expanded(child: _buildTagList()),
          ],
        ),

        // Sağ-alt köşe FAB (daire + gri)
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _exportBusy
                      ? const SizedBox(
                          key: ValueKey('loader'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.mail_outline, key: ValueKey('icon')),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LocationStatusWidget extends StatefulWidget {
  final bool isLocating;
  const LocationStatusWidget({super.key, required this.isLocating});

  @override
  State<LocationStatusWidget> createState() => _LocationStatusWidgetState();
}

class _LocationStatusWidgetState extends State<LocationStatusWidget> {
  static const EventChannel _locationStatusChannel =
      EventChannel('LocationStatus');
  StreamSubscription? _locationSub;
  int? _signalStrength;

  void _subscribe() {
    _locationSub ??= _locationStatusChannel.receiveBroadcastStream().listen(
      (event) {
        setState(() {
          _signalStrength =
              event is int ? event : int.tryParse(event.toString());
        });
      },
      onError: (_) => setState(() => _signalStrength = null),
    );
  }

  void _unsubscribe() {
    _locationSub?.cancel();
    _locationSub = null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.isLocating) _subscribe();
  }

  @override
  void didUpdateWidget(covariant LocationStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLocating && !oldWidget.isLocating) {
      _signalStrength = null; // yeni arama: sıfırla
      _subscribe();
    } else if (!widget.isLocating && oldWidget.isLocating) {
      _unsubscribe();
      _signalStrength = null; // arama durdu: temizle
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  int getBarLevel(int? v) {
    if (v == null) return 0;
    if (v >= 70) return 3;
    if (v >= 40) return 2;
    if (v > 0) return 1;
    return 0;
  }

  Color getBarColor(int level, int activeLevel) {
    if (level > activeLevel) return Colors.grey.shade300;
    switch (level) {
      case 1:
        return Colors.green.shade900;
      case 2:
        return Colors.green.shade600;
      case 3:
        return Colors.green.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int activeLevel = getBarLevel(_signalStrength);

    if (!widget.isLocating) {
      return const Card(
        margin: EdgeInsets.all(8),
        child: ListTile(
          title: Text('Tag search not started yet'),
          subtitle: Text('Press "Start Locate" to begin'),
        ),
      );
    }

    final String subtitleText = _signalStrength == null
        ? 'Searching...'
        : 'Signal Strength: $_signalStrength dBm';

    final TextStyle? subtitleStyle = _signalStrength == null
        ? const TextStyle(color: Colors.orange)
        : TextStyle(
            fontWeight: FontWeight.w600, color: getBarColor(activeLevel, 3));

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: SizedBox(
          width: 32,
          height: 32,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final int level = i + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 7,
                  height: 10.0 + 7.0 * level,
                  decoration: BoxDecoration(
                    color: getBarColor(level, activeLevel),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        title: const Text('Location Signal Strength'),
        subtitle: Text(subtitleText, style: subtitleStyle),
      ),
    );
  }
}

class TagDetailScreen extends StatefulWidget {
  final TagItem tagItem;
  final String userMemoryHex;
  const TagDetailScreen({
    Key? key,
    required this.tagItem,
    required this.userMemoryHex,
  }) : super(key: key);

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends State<TagDetailScreen> {
  bool _isLocating = false;
  bool _locatingBusy = false;
  bool _autoFetch = true; // otomatik dene
  bool _reading = false; // re-entrancy koruması
  Timer? _umTimer;
  String _userHex = ""; // ekranda gösterilecek güncel USER
  static const _interval = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _userHex = widget.userMemoryHex; // ilk gelen (boş olabilir)
    if (_userHex.isEmpty) _startAutoUserRead();
  }

  @override
  void dispose() {
    _umTimer?.cancel();
    super.dispose();
  }

  void _startAutoUserRead() {
    _umTimer?.cancel();
    if (!_autoFetch) return;
    _umTimer = Timer.periodic(_interval, (_) => _tryReadUser());
  }

  Future<void> _tryReadUser() async {
    if (_reading) return;
    _reading = true;
    try {
      final hex =
          await RfidC72Plugin.readUserMemoryForEpc(widget.tagItem.rawEpc);
      if (hex != null && hex.length >= 16) {
        setState(() {
          _userHex = hex;
          _autoFetch = false; // bulundu → döngüyü durdur
        });
        _umTimer?.cancel();
      }
    } catch (_) {
      // yut — bir sonraki periyotta tekrar denenecek
    } finally {
      _reading = false;
    }
  }

  Future<void> _toggleLocate() async {
    if (_locatingBusy) return;
    setState(() => _locatingBusy = true);

    try {
      if (!_isLocating) {
        final ok = await RfidC72Plugin.startLocation(
          label: widget.tagItem.rawEpc,
          bank: 1,
          ptr: 32,
        );
        if (!mounted) return;
        if (ok == true) setState(() => _isLocating = true);
      } else {
        final ok = await RfidC72Plugin.stopLocation();
        if (!mounted) return;
        if (ok == true) setState(() => _isLocating = false);
      }
    } finally {
      if (mounted) setState(() => _locatingBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decodedUser = decodeUserMemory(_userHex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      log('--- RFID Tag Details ---');
      log('EPC   : ${widget.tagItem.rawEpc}');
      log('CAGE  : ${widget.tagItem.cage}');
      log('PN    : ${widget.tagItem.partNumber}');
      log('SN    : ${widget.tagItem.serialNumber}');
      log('USERH : $_userHex');
      if (decodedUser.isNotEmpty) {
        log('w0=${decodedUser['w0']} w1=${decodedUser['w1']} '
            'w2=${decodedUser['w2']} w3=${decodedUser['w3']}');
        log('ToC: major=${decodedUser['tocMajor']} minor=${decodedUser['tocMinor']} '
            'ataClass=${decodedUser['ataClass']} tagType=${decodedUser['tagType']}');
        log('Payload: ${decodedUser['payloadText']}');
      } else {
        log('USER decode: EMPTY or INVALID');
      }
      log('-------------------------');
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('RFID Tag Details')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: ListView(
          children: [
            Text("Raw EPC: ${widget.tagItem.rawEpc}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("CAGE: ${widget.tagItem.cage}"),
            Text("Part Number: ${widget.tagItem.partNumber}"),
            Text("Serial Number: ${widget.tagItem.serialNumber}"),
            const Divider(),
            Text(
                "User Memory (Hex): ${_userHex.isEmpty ? '(reading...)' : _userHex}"),
            if (decodedUser.isNotEmpty) ...[
              const Divider(),
              const Text("User Memory Header:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text("w0 (DSFID): ${decodedUser['w0']}"),
              Text("w1: ${decodedUser['w1']}"),
              Text("w2: ${decodedUser['w2']}"),
              Text("w3 (Word Count): ${decodedUser['w3']}"),
              const Divider(),
              const Text("Payload:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(decodedUser['payloadText'] ?? "-"),
            ] else if (_userHex.isEmpty) ...[
              const SizedBox(height: 8),
              const Text("Etikete doğrultun; otomatik okumayı deniyoruz..."),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _tryReadUser,
                icon: const Icon(Icons.refresh),
                label: const Text("Read User Memory Now"),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _locatingBusy ? null : _toggleLocate,
                icon: _locatingBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_isLocating ? Icons.stop : Icons.podcasts),
                label: Text(_isLocating ? 'Stop Searching' : 'Find Tag'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLocating ? Colors.red : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            LocationStatusWidget(isLocating: _isLocating),
          ],
        ),
      ),
    );
  }
}

/// TagItem model
class TagItem {
  final String rawEpc;
  final String cage;
  final String partNumber;
  final String serialNumber;

  bool userRead;
  String? userHex;

  TagItem({
    required this.rawEpc,
    required this.cage,
    required this.partNumber,
    required this.serialNumber,
    this.userRead = false,
    this.userHex,
  });
}

/// EPC decode logic
class DecodedEpcData {
  final String headerBits;
  final int filterValue;
  final String cage;
  final String partNumber;
  final String serialNumber;

  DecodedEpcData({
    required this.headerBits,
    required this.filterValue,
    required this.cage,
    required this.partNumber,
    required this.serialNumber,
  });
}

DecodedEpcData decodeEpc(String epcHex) {
  final binary = _hexToBinary(epcHex);
  final headerBits = binary.substring(0, 8);
  final filterBits = binary.substring(8, 14);
  final filterVal = int.parse(filterBits, radix: 2);
  int pointer = 14;
  final cageBits = binary.substring(pointer, pointer + 36);
  pointer += 36;

  String pnBits = "";
  bool delimiterDetected = false;
  String snBits = "";

  while (pointer + 6 <= binary.length) {
    final chunk = binary.substring(pointer, pointer + 6);
    pointer += 6;
    if (chunk == "000000") {
      if (!delimiterDetected) {
        delimiterDetected = true;
        continue;
      } else {
        break;
      }
    }
    if (!delimiterDetected) {
      pnBits += chunk;
    } else {
      snBits += chunk;
    }
  }

  final cageAscii = _decodeSixBitString(cageBits);
  final pnAscii = _decodeSixBitString(pnBits);
  final snAscii = _decodeSixBitString(snBits);

  return DecodedEpcData(
    headerBits: headerBits,
    filterValue: filterVal,
    cage: cageAscii,
    partNumber: pnAscii,
    serialNumber: snAscii,
  );
}

String _hexToBinary(String hexValue) {
  final buffer = StringBuffer();
  for (int i = 0; i < hexValue.length; i++) {
    final nibble = int.parse(hexValue[i], radix: 16);
    buffer.write(nibble.toRadixString(2).padLeft(4, '0'));
  }
  return buffer.toString();
}

const Map<String, String> ASCII6_MAP = {
  "000000": "NUL",
  "000001": "A",
  "000010": "B",
  "000011": "C",
  "000100": "D",
  "000101": "E",
  "000110": "F",
  "000111": "G",
  "001000": "H",
  "001001": "I",
  "001010": "J",
  "001011": "K",
  "001100": "L",
  "001101": "M",
  "001110": "N",
  "001111": "O",
  "010000": "P",
  "010001": "Q",
  "010010": "R",
  "010011": "S",
  "010100": "T",
  "010101": "U",
  "010110": "V",
  "010111": "W",
  "011000": "X",
  "011001": "Y",
  "011010": "Z",
  "011011": "[",
  "011100": "\\",
  "011101": "]",
  "011110": "^",
  "011111": "_",
  "110000": "0",
  "110001": "1",
  "110010": "2",
  "110011": "3",
  "110100": "4",
  "110101": "5",
  "110110": "6",
  "110111": "7",
  "111000": "8",
  "111001": "9",
  "111111": "?",
  "100001": "!",
  "100011": "#",
  "100100": "\$",
  "100101": "%",
  "100110": "&",
  "100111": "'",
  "101000": "(",
  "101001": ")",
  "101010": "*",
  "101011": "+",
  "101100": ",",
  "101101": "-",
  "101110": ".",
  "101111": "/",
  "111010": ":",
  "111011": ";",
  "111100": "<",
  "111101": "=",
  "111110": ">",
  "100000": " "
};

String _decodeSixBitString(String bits) {
  final sb = StringBuffer();
  for (int i = 0; i < bits.length; i += 6) {
    if (i + 6 > bits.length) break;
    final chunk = bits.substring(i, i + 6);
    final char = ASCII6_MAP[chunk] ?? "?";
    if (char == "NUL") continue;
    sb.write(char);
  }
  return sb.toString();
}

/// USER MEMORY decode logic (header + 6bit-encoded payload)
Map<String, dynamic> decodeUserMemory(String userMemoryHex) {
  if (userMemoryHex.isEmpty || userMemoryHex.length < 16) return {};

  final w0 = userMemoryHex.substring(0, 4);
  final w1hex = userMemoryHex.substring(4, 8);
  final w2 = userMemoryHex.substring(8, 12);
  final w3 = userMemoryHex.substring(12, 16);
  final payloadHex = userMemoryHex.substring(16);

  final w1 = int.parse(w1hex, radix: 16);

  final tocMajor = (w1 >> 12) & 0xF;
  final tocMinor = (w1 >> 9) & 0x7;
  final ataClass = (w1 >> 4) & 0x1F;
  final tagType = w1 & 0xF;

  final payloadBin = _hexToBinary(payloadHex);
  String text = '';
  for (int i = 0; i + 6 <= payloadBin.length; i += 6) {
    final chunk = payloadBin.substring(i, i + 6);
    if (chunk == '000000') break;
    final char = ASCII6_MAP[chunk] ?? '?';
    text += char;
  }

  return {
    'w0': w0,
    'w1': w1hex,
    'w2': w2,
    'w3': w3,
    'tocMajor': tocMajor,
    'tocMinor': tocMinor,
    'ataClass': ataClass,
    'tagType': tagType,
    'payloadText': text,
  };
}
