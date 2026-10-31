import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/cuenta_screen.dart';

class AppBarCuenta extends AppBar {
  AppBarCuenta({
    super.key,
    super.title,
    super.backgroundColor,
    super.leading,
    super.leadingWidth,
    super.automaticallyImplyLeading,
    super.bottom,
    super.toolbarHeight,
    List<Widget>? actions,
  }) : super(
         actions: [
           ...?actions,
           Builder(
             builder: (context) => IconButton(
               tooltip: 'Mi cuenta',
               icon: const Icon(Icons.account_circle_outlined),
               onPressed: () => Navigator.of(
                 context,
                 rootNavigator: true,
               ).push(MaterialPageRoute(builder: (_) => const CuentaScreen())),
             ),
           ),
         ],
       );
}
