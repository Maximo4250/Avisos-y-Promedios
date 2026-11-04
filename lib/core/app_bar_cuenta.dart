import 'package:flutter/material.dart';
import '../services/delegados_service.dart';
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
           ValueListenableBuilder(
             valueListenable: DelegadosService.instance.permiso,
             builder: (context, d, _) => d == null
                 ? const SizedBox.shrink()
                 : Tooltip(
                     message: 'Delegado de ${d.etiqueta}',
                     child: const Padding(
                       padding: EdgeInsets.symmetric(horizontal: 4),
                       child: Icon(Icons.verified_outlined, size: 18),
                     ),
                   ),
           ),
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
