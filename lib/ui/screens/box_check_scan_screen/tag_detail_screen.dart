// // lib/ui/screens/tag_detail_screen.dart
// import 'dart:async';
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
// import 'package:water_boiler_rfid_labeler/models/tag_item.dart';
// import 'package:water_boiler_rfid_labeler/ui/screens/box_check_scan_screen/epc_user_codec.dart';

// class TagDetailScreen extends StatefulWidget {
//   final TagItem tagItem;
//   final String userMemoryHex;
//   const TagDetailScreen({
//     Key? key,
//     required this.tagItem,
//     required this.userMemoryHex,
//   }) : super(key: key);

//   @override
//   State<TagDetailScreen> createState() => _TagDetailScreenState();
// }

// class _TagDetailScreenState extends State<TagDetailScreen> {
//   bool _isLocating = false;
//   bool _locatingBusy = false;
//   bool _autoFetch = true;
//   bool _reading = false;
//   Timer? _umTimer;
//   String _userHex = "";
//   static const _interval = Duration(milliseconds: 600);

//   @override
//   void initState() {
//     super.initState();
//     _userHex = widget.userMemoryHex;
//     if (_userHex.isEmpty) _startAutoUserRead();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       log('DETAIL — PN:${widget.tagItem.partNumber} SN:${widget.tagItem.serialNumber} CAGE:${widget.tagItem.cage}');
//     });
//   }

//   @override
//   void dispose() {
//     _umTimer?.cancel();
//     super.dispose();
//   }

//   void _startAutoUserRead() {
//     _umTimer?.cancel();
//     if (!_autoFetch) return;
//     _umTimer = Timer.periodic(_interval, (_) => _tryReadUser());
//   }

//   Future<void> _tryReadUser() async {
//     if (_reading) return;
//     _reading = true;
//     try {
//       final hex =
//           await RfidC72Plugin.readUserMemoryForEpc(widget.tagItem.rawEpc);
//       if (hex != null && hex.length >= 16) {
//         if (!mounted) return;
//         setState(() {
//           _userHex = hex;
//           _autoFetch = false; // bulundu → döngü dursun
//         });
//         _umTimer?.cancel();
//       }
//     } catch (_) {
//       // yut — bir sonraki periyotta tekrar denenecek
//     } finally {
//       _reading = false;
//     }
//   }

//   Future<void> _toggleLocate() async {
//     if (_locatingBusy) return;
//     setState(() => _locatingBusy = true);
//     try {
//       if (!_isLocating) {
//         final ok = await RfidC72Plugin.startLocation(
//           label: widget.tagItem.rawEpc,
//           bank: 1,
//           ptr: 32,
//         );
//         if (!mounted) return;
//         if (ok == true) setState(() => _isLocating = true);
//       } else {
//         final ok = await RfidC72Plugin.stopLocation();
//         if (!mounted) return;
//         if (ok == true) setState(() => _isLocating = false);
//       }
//     } finally {
//       if (mounted) setState(() => _locatingBusy = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final decodedUser = decodeUserMemory(_userHex);

//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       appBar: AppBar(title: const Text('RFID Tag Details')),
//       body: Padding(
//         padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//         child: ListView(
//           children: [
//             // SADE BAŞLIK — sadece PN / SN / Üretici
//             Text("PN: ${widget.tagItem.partNumber}",
//                 style:
//                     const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             Text("SN: ${widget.tagItem.serialNumber}"),
//             Text("Üretici: ${widget.tagItem.cage}"),
//             const Divider(),

//             // USER Memory
//             Text(
//               "User Memory (Hex): ${_userHex.isEmpty ? '(reading...)' : _userHex}",
//               style: const TextStyle(fontSize: 13),
//             ),
//             if (decodedUser.isNotEmpty) ...[
//               const SizedBox(height: 6),
//               Text("Payload: ${decodedUser['payloadText'] ?? '-'}"),
//               const SizedBox(height: 6),
//               Text(
//                 "Header: w0=${decodedUser['w0']} w1=${decodedUser['w1']} w2=${decodedUser['w2']} w3=${decodedUser['w3']}",
//                 style: const TextStyle(fontSize: 12, color: Colors.black54),
//               ),
//             ] else if (_userHex.isEmpty) ...[
//               const SizedBox(height: 8),
//               const Text("Etikete doğrultun; otomatik okumayı deniyoruz..."),
//               const SizedBox(height: 8),
//               ElevatedButton.icon(
//                 onPressed: _tryReadUser,
//                 icon: const Icon(Icons.refresh),
//                 label: const Text("Read User Memory Now"),
//               ),
//             ],

//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: _locatingBusy ? null : _toggleLocate,
//                 icon: _locatingBusy
//                     ? const SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(
//                             strokeWidth: 2, color: Colors.white),
//                       )
//                     : Icon(_isLocating ? Icons.stop : Icons.podcasts),
//                 label: Text(_isLocating ? 'Stop Searching' : 'Find Tag'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _isLocating ? Colors.red : null,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             const LocationStatusWidget(isLocating: false) // Başlangıç: false
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Basit sinyal göstergesi — EventChannel('LocationStatus') ile dBm benzeri bir değer bekler
// class LocationStatusWidget extends StatefulWidget {
//   final bool isLocating;
//   const LocationStatusWidget({super.key, required this.isLocating});

//   @override
//   State<LocationStatusWidget> createState() => _LocationStatusWidgetState();
// }

// class _LocationStatusWidgetState extends State<LocationStatusWidget> {
//   static const EventChannel _locationStatusChannel =
//       EventChannel('LocationStatus');
//   StreamSubscription? _locationSub;
//   int? _signalStrength;

//   void _subscribe() {
//     _locationSub ??= _locationStatusChannel.receiveBroadcastStream().listen(
//       (event) {
//         setState(() {
//           _signalStrength =
//               event is int ? event : int.tryParse(event.toString());
//         });
//       },
//       onError: (_) => setState(() => _signalStrength = null),
//     );
//   }

//   void _unsubscribe() {
//     _locationSub?.cancel();
//     _locationSub = null;
//   }

//   @override
//   void initState() {
//     super.initState();
//     if (widget.isLocating) _subscribe();
//   }

//   @override
//   void didUpdateWidget(covariant LocationStatusWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.isLocating && !oldWidget.isLocating) {
//       _signalStrength = null;
//       _subscribe();
//     } else if (!widget.isLocating && oldWidget.isLocating) {
//       _unsubscribe();
//       _signalStrength = null;
//     }
//   }

//   @override
//   void dispose() {
//     _unsubscribe();
//     super.dispose();
//   }

//   int getBarLevel(int? v) {
//     if (v == null) return 0;
//     if (v >= 70) return 3;
//     if (v >= 40) return 2;
//     if (v > 0) return 1;
//     return 0;
//   }

//   Color getBarColor(int level, int activeLevel) {
//     if (level > activeLevel) return Colors.grey.shade300;
//     switch (level) {
//       case 1:
//         return Colors.green.shade900;
//       case 2:
//         return Colors.green.shade600;
//       case 3:
//         return Colors.green.shade300;
//       default:
//         return Colors.grey.shade300;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final int activeLevel = getBarLevel(_signalStrength);

//     if (!widget.isLocating) {
//       return const Card(
//         margin: EdgeInsets.all(8),
//         child: ListTile(
//           title: Text('Tag search not started yet'),
//           subtitle: Text('Press "Start Locate" to begin'),
//         ),
//       );
//     }

//     final String subtitleText = _signalStrength == null
//         ? 'Searching...'
//         : 'Signal Strength: $_signalStrength dBm';

//     final TextStyle subtitleStyle = _signalStrength == null
//         ? const TextStyle(color: Colors.orange)
//         : TextStyle(
//             fontWeight: FontWeight.w600, color: getBarColor(activeLevel, 3));

//     return Card(
//       margin: const EdgeInsets.all(8),
//       child: ListTile(
//         leading: SizedBox(
//           width: 32,
//           height: 32,
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(3, (i) {
//               final int level = i + 1;
//               return Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 1.5),
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 300),
//                   width: 7,
//                   height: 10.0 + 7.0 * level,
//                   decoration: BoxDecoration(
//                     color: getBarColor(level, activeLevel),
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               );
//             }),
//           ),
//         ),
//         title: const Text('Location Signal Strength'),
//         subtitle: Text(subtitleText, style: subtitleStyle),
//       ),
//     );
//   }
// }
// lib/ui/screens/tag_detail_screen.dart
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemSound için
import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
import 'package:water_boiler_rfid_labeler/models/tag_item.dart';
import 'package:water_boiler_rfid_labeler/ui/screens/box_check_scan_screen/epc_user_codec.dart';

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

// Ses modu
enum AudioFeedback { off, beep }

class _TagDetailScreenState extends State<TagDetailScreen> {
  bool _isLocating = false;
  bool _locatingBusy = false;

  bool _autoFetch = true;
  bool _reading = false;
  Timer? _umTimer;
  String _userHex = "";
  static const _interval = Duration(milliseconds: 600);

  // --- Ses/Beep kontrolü ---
  AudioFeedback _audio = AudioFeedback.off;
  static const EventChannel _locationStatusChannel =
      EventChannel('LocationStatus'); // aynı kanaldan sinyal okuyoruz
  StreamSubscription? _soundSub;
  Timer? _beepTimer;
  Duration? _beepEvery;

  @override
  void initState() {
    super.initState();
    _userHex = widget.userMemoryHex;
    if (_userHex.isEmpty) _startAutoUserRead();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      log('DETAIL — PN:${widget.tagItem.partNumber} SN:${widget.tagItem.serialNumber} CAGE:${widget.tagItem.cage}');
    });
  }

  @override
  void dispose() {
    _umTimer?.cancel();
    _stopBeep();
    _soundSub?.cancel();
    super.dispose();
  }

  // ----------------- USER MEMORY AUTO READ -----------------
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
        if (!mounted) return;
        setState(() {
          _userHex = hex;
          _autoFetch = false; // bulundu → döngü dursun
        });
        _umTimer?.cancel();
      }
    } catch (_) {
      // yut — bir sonraki periyotta tekrar denenecek
    } finally {
      _reading = false;
    }
  }

  // ----------------- LOCATE -----------------
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
        if (ok == true) {
          setState(() => _isLocating = true);
          _wireAudio(); // locate açıldı → ses kablola
        }
      } else {
        final ok = await RfidC72Plugin.stopLocation();
        if (!mounted) return;
        if (ok == true) {
          setState(() => _isLocating = false);
          _wireAudio(); // locate kapandı → ses kapat
        }
      }
    } finally {
      if (mounted) setState(() => _locatingBusy = false);
    }
  }

  // ----------------- AUDIO (BEEP) -----------------
  void _wireAudio() {
    // Locate kapalıysa ya da ses off ise her şeyi kapat.
    if (!_isLocating || _audio == AudioFeedback.off) {
      _soundSub?.cancel();
      _soundSub = null;
      _stopBeep();
      return;
    }

    // Zaten bağlıysa tekrar bağlama
    _soundSub ??=
        _locationStatusChannel.receiveBroadcastStream().listen((event) {
      final int? s = event is int ? event : int.tryParse(event.toString());
      final d = _intervalForStrength(s);
      // Aralık değiştiyse timer'ı yeniden başlat
      if (_beepEvery?.inMilliseconds != d.inMilliseconds) {
        _startBeepTimer(d);
      }
    }, onError: (_) {
      _startBeepTimer(const Duration(milliseconds: 900));
    });
  }

  Duration _intervalForStrength(int? s) {
    // Yaklaştıkça daha sık bip
    if (s == null) return const Duration(milliseconds: 900);
    if (s < 30) return const Duration(milliseconds: 800);
    if (s < 50) return const Duration(milliseconds: 600);
    if (s < 70) return const Duration(milliseconds: 400);
    return const Duration(milliseconds: 220);
  }

  void _startBeepTimer(Duration every) {
    _beepEvery = every;
    _beepTimer?.cancel();
    _beepTimer = Timer.periodic(every, (_) async {
      try {
        await SystemSound.play(SystemSoundType.alert); // basit bip
      } catch (_) {}
    });
  }

  void _stopBeep() {
    _beepTimer?.cancel();
    _beepTimer = null;
    _beepEvery = null;
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    final decodedUser = decodeUserMemory(_userHex);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('RFID Tag Details')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: ListView(
          children: [
            // Başlık
            Text("PN: ${widget.tagItem.partNumber}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("SN: ${widget.tagItem.serialNumber}"),
            Text("Üretici: ${widget.tagItem.cage}"),
            const Divider(),

            // USER Memory
            Text(
              "User Memory (Hex): ${_userHex.isEmpty ? '(reading...)' : _userHex}",
              style: const TextStyle(fontSize: 13),
            ),
            if (decodedUser.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text("Payload: ${decodedUser['payloadText'] ?? '-'}"),
              const SizedBox(height: 6),
              Text(
                "Header: w0=${decodedUser['w0']} w1=${decodedUser['w1']} w2=${decodedUser['w2']} w3=${decodedUser['w3']}",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
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

            // Ses combobox'ı
            DropdownButtonFormField<AudioFeedback>(
              value: _audio,
              decoration: const InputDecoration(
                labelText: 'Sound (while locating)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: AudioFeedback.off,
                  child: Text('Off'),
                ),
                DropdownMenuItem(
                  value: AudioFeedback.beep,
                  child: Text('Beep'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _audio = v);
                _wireAudio(); // seçim değişti
              },
            ),
            const SizedBox(height: 12),

            // Locate butonu
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

            // Görsel seviye göstergesi
            LocationStatusWidget(isLocating: _isLocating),
          ],
        ),
      ),
    );
  }
}

/// Basit sinyal göstergesi — EventChannel('LocationStatus') ile dBm benzeri bir değer bekler
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
      _signalStrength = null;
      _subscribe();
    } else if (!widget.isLocating && oldWidget.isLocating) {
      _unsubscribe();
      _signalStrength = null;
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

    final TextStyle subtitleStyle = _signalStrength == null
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
