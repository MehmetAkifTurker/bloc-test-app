import 'package:water_boiler_rfid_labeler/data/models/variables.dart';
import 'package:flutter/material.dart';
import 'package:water_boiler_rfid_labeler/ui/router/app_router.dart'; // pageNames için

AppBar commonAppBar(BuildContext context, String title,
    {bool showBack = false}) {
  final textAndIconColor = titleTextAndIconColor;
  final backgroundColor = titleBackgroundColor;

  return AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  pageNames[0], // "Main"
                  (route) => false,
                );
              },
            )
          : null,

      // Başlığı tam ortaya sabitle
      centerTitle: true,

      // TAŞMAYI ÖNLE: Row genişlesin, metin Flexible ile ellipsize olsun
      title: Row(
        mainAxisSize: MainAxisSize.max, // tüm genişliği kullan
        mainAxisAlignment: MainAxisAlignment.center, // ortala
        children: [
          // Logoyu toolbar yüksekliğine göre sınırla
          Image.asset(
            'assets/images/c4_TT_Logo_RGB_only_logo.png',
            height: kToolbarHeight * 0.6, // ölçek yerine yükseklik
            color: titleTextAndIconColor,
          ),
          const SizedBox(width: 8),
          // Uzun başlık taşmasın
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),

      // Leading varken sağda simetri için görünmez boşluk bırak
      actions: showBack ? const [SizedBox(width: kToolbarHeight)] : null,
      foregroundColor: textAndIconColor,
      backgroundColor: backgroundColor);
}
