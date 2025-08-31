// import 'dart:ui' show ImageFilter;
// import 'package:flutter/material.dart';
// import 'package:water_boiler_rfid_labeler/ui/router/app_bar.dart';

// class MainMenu extends StatefulWidget {
//   const MainMenu({Key? key}) : super(key: key);

//   @override
//   State<MainMenu> createState() => _MainMenuState();
// }

// class _MainMenuState extends State<MainMenu> {
//   void _go(String route) {
//     Navigator.pushNamed(context, route);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       // Ana menüde sistem geri hareketini devre dışı bırak
//       canPop: false,
//       // Predictive back uyumlu: geri tetiklense bile hiçbir şey yapma
//       onPopInvokedWithResult: (didPop, result) {
//         if (didPop) return;
//         // İstersen bilgi mesajı gösterebilirsin:
//         // ScaffoldMessenger.of(context).showSnackBar(
//         //   const SnackBar(content: Text('Ana menüdesiniz')),
//         // );
//       },
//       child: Scaffold(
//         appBar: commonAppBar(context, 'Main Menu', showBack: false),
//         body: Column(
//           children: [
//             Expanded(
//               child: _HalfImageButton(
//                 imagePath: 'assets/images/rfid_box_check.jpg',
//                 label: 'TAG READER',
//                 onTap: () => _go('/read'),
//               ),
//             ),
//             Expanded(
//               child: _HalfImageButton(
//                 imagePath: 'assets/images/rfid_scan.jpg',
//                 label: 'TAG WRITER',
//                 onTap: () => _go('/write'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _HalfImageButton extends StatelessWidget {
//   final String imagePath;
//   final String label;
//   final VoidCallback onTap;

//   const _HalfImageButton({
//     Key? key,
//     required this.imagePath,
//     required this.label,
//     required this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         splashColor: Colors.white24,
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             Image.asset(imagePath, fit: BoxFit.cover),
//             ClipRect(
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
//                 child: Container(color: Colors.black.withOpacity(0.22)),
//               ),
//             ),
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: FittedBox(
//                   fit: BoxFit.scaleDown,
//                   child: Stack(
//                     children: [
//                       // kontur
//                       Text(
//                         label,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 52,
//                           fontWeight: FontWeight.w700,
//                           foreground: Paint()
//                             ..style = PaintingStyle.stroke
//                             ..strokeWidth = 3
//                             ..color = Colors.black,
//                         ),
//                       ),
//                       // dolgu
//                       Text(
//                         label,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           fontSize: 52,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:water_boiler_rfid_labeler/ui/router/app_bar.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  // THY renkleri (yakın tonlar)
  static const Color _thyRed = Color(0xFFE31837);
  static const Color _thyNavy = Color(0xFF003B5C);

  static const double _btnHeight = 80; // ↑ daha yüksek butonlar
  static const double _gap = 28; // ↑ butonlar arası mesafe
  static const double _radius = 18;

  void _go(String route) => Navigator.pushNamed(context, route);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ana menüde geri ile kapanmasın
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        appBar: commonAppBar(context, 'Main Menu', showBack: false),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık
                  Text(
                    'Tool ve Test Sistemleri RFID Yazılımı',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28, // ↑ daha büyük yazı
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: .2,
                      color: _thyNavy,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // TAG READER
                  _menuButton(
                    icon: Icons.qr_code_scanner,
                    label: 'TAG READER',
                    onTap: () => _go('/read'),
                    navy: _thyNavy,
                  ),
                  const SizedBox(height: _gap),

                  // TAG WRITER
                  _menuButton(
                    icon: Icons.edit,
                    label: 'TAG WRITER',
                    onTap: () => _go('/write'),
                    navy: _thyNavy,
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: const Color(0xFFF6F7F9), // hafif gri arka plan
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color navy,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          height: _btnHeight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F7FA), // laciverte yakın açık ton
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: navy.withOpacity(.12), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: navy, size: 28),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 20, // ↑ daha büyük yazı
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                  color: navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
