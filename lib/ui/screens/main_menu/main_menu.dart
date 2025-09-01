// import 'package:water_boiler_rfid_labeler/ui/router/app_bar.dart';
// import 'package:water_boiler_rfid_labeler/ui/router/bottom_navigation.dart';
// import 'package:water_boiler_rfid_labeler/ui/widgets/menu_card.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../business_logic/cubit/navigaion_qubit_cubit.dart';
// import '../../router/app_router.dart';

// class MainMenu extends StatelessWidget {
//   const MainMenu({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     int index = 0;
//     return Scaffold(
//       appBar: commonAppBar(context, 'Main Menu'),
//       // bottomNavigationBar: bottomNavigationBar(context),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // const Text(
//             //   'OVEN RFID',
//             //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             // ),
//             const SizedBox(height: 7),
//             // İki büyük buton, alt alta olacak şekilde Expanded ile doldurulacak
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // 1. Buton: Tag Okuma (Box Check)
//                   Expanded(
//                     child: GestureDetector(
//                       onTap: () {
//                         index = 1; // BoxCheck sayfa indexi
//                         context.read<NavigationCubit>().navigateToPage(index);
//                         Navigator.pushNamedAndRemoveUntil(
//                           context,
//                           pageNames[index],
//                           (route) => false,
//                         );
//                       },
//                       child: Card(
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20)),
//                         elevation: 4,
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(6),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Expanded(
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(20),
//                                   child: Image.asset(
//                                     'assets/images/rfid_box_check.jpg',
//                                     fit: BoxFit.contain,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 12),
//                               const Text(
//                                 'RFID TAG Reading',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                               // const SizedBox(height: 6),
//                               // const Text(
//                               //   'Etiketleri oku',
//                               //   textAlign: TextAlign.center,
//                               // ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   // 2. Buton: Tag Yazma
//                   Expanded(
//                     child: GestureDetector(
//                       onTap: () {
//                         index = 2; // Tag Write sayfa indexi
//                         context.read<NavigationCubit>().navigateToPage(index);
//                         Navigator.pushNamedAndRemoveUntil(
//                           context,
//                           pageNames[index],
//                           (route) => false,
//                         );
//                       },
//                       child: Card(
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20)),
//                         elevation: 4,
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(6),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Expanded(
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(20),
//                                   child: Image.asset(
//                                     'assets/images/rfid_scan.jpg',
//                                     fit: BoxFit.contain,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 12),
//                               const Text(
//                                 'RFID TAG Writing',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                               // const SizedBox(height: 6),
//                               // const Text(
//                               //   'Yeni tag oluştur ya da mevcut tag\'i güncelle',
//                               //   textAlign: TextAlign.center,
//                               // ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_boiler_rfid_labeler/ui/router/app_bar.dart';
import 'package:water_boiler_rfid_labeler/ui/router/app_router.dart';
import '../../../business_logic/cubit/navigaion_qubit_cubit.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(context, 'Main Menu', showBack: false),
      body: Column(
        children: [
          // ÜST YARI — READING
          Expanded(
            child: _HalfImageButton(
              imagePath: 'assets/images/rfid_box_check.jpg',
              label: 'TAG READER',
              onTap: () {
                const index = 1; // Read Tag / BoxCheck
                context.read<NavigationCubit>().navigateToPage(index);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  pageNames[index],
                  (route) => false,
                );
              },
            ),
          ),

          // ORTA ÇİZGİ
          // Divider(height: 1, thickness: 1, color: Colors.grey.shade300),

          // ALT YARI — WRITING
          Expanded(
            child: _HalfImageButton(
              imagePath: 'assets/images/rfid_scan.jpg',
              label: 'TAG /*WRITER',
              onTap: () {
                const index = 2; // Write Tag
                context.read<NavigationCubit>().navigateToPage(index);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  pageNames[index],
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HalfImageButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _HalfImageButton({
    Key? key,
    required this.imagePath,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Arkaplan görsel
            Image.asset(imagePath, fit: BoxFit.cover),

            // Blur + karartma katmanı (sigmaX == sigmaY => çizgi/şerit algısı olmaz)
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: Colors.black.withOpacity(0.22)),
              ),
            ),

            // Merkezde metin
            Center(
              child: Stack(
                children: [
                  // --- Siyah kontur ---
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.w700,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3
                        ..color = Colors.black, // kontur rengi
                    ),
                  ),
                  // --- Beyaz doldurma ---
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.w700,
                      color: Colors.white, // doldurma rengi
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
