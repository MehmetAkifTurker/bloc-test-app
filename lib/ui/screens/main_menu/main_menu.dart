import 'package:bloc_test_app/ui/router/app_bar.dart';
import 'package:bloc_test_app/ui/router/bottom_navigation.dart';
import 'package:bloc_test_app/ui/widgets/menu_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/cubit/navigaion_qubit_cubit.dart';
import '../../router/app_router.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    int index = 0;
    return Scaffold(
      appBar: commonAppBar(context, 'Main Menu'),
      //drawer: commonDrawer(context),
      bottomNavigationBar: bottomNavigationBar(context),
      body: Center(
          child: Column(
        children: [
          // const SizedBox(height: 40.0),
          // Image.asset(
          //   'assets/images/c4_TT_Logo_RGB.png',
          //   scale: 10.0,
          //   //width: 200.0,
          //   //height: 200.0,
          //   color: Colors.black,
          // ),
          // const Text('R&D - Tool & Test Systems',
          //     style: TextStyle(fontSize: 20)),
          // const SizedBox(height: 100.0),
          // const Text(
          //   'What do you want to do?',
          // ),
          BlocBuilder<NavigationCubit, int>(
            builder: (context, state) {
              return Expanded(
                child: ListView(
                  children: [
                    MenuCard(
                      title: 'Check a Box',
                      description:
                          'Check what is inside the box. Trigger Button can be used. When pressed, scans for 5 seconds.',
                      imageUrl: 'assets/images/rfid_box_check.jpg',
                      onTap: () {
                        index = 1;
                        context.read<NavigationCubit>().navigateToPage(index);
                        Navigator.pushNamedAndRemoveUntil(
                            context, pageNames[index], (route) => false);
                      },
                    ),
                    MenuCard(
                      title: 'Add or Update Tag',
                      description:
                          'Set the power level and scan for RFID tags to Add or Update. Trigger Button can be used. When pressed, scans for 5 seconds.',
                      imageUrl: 'assets/images/rfid_scan.jpg',
                      onTap: () {
                        index = 2;
                        context.read<NavigationCubit>().navigateToPage(index);
                        Navigator.pushNamedAndRemoveUntil(
                            context, pageNames[index], (route) => false);
                      },
                    ),
                    MenuCard(
                      title: 'Search Database',
                      description: 'Search in the database using filters',
                      imageUrl: 'assets/images/database.jpg',
                      onTap: () {
                        index = 3;
                        context.read<NavigationCubit>().navigateToPage(index);
                        Navigator.pushNamedAndRemoveUntil(
                            context, pageNames[index], (route) => false);
                      },
                    ),
                  ],
                ),
              );
            },
          )
        ],
      )),
    );
  }
}
