import 'package:flutter/material.dart';
import 'package:flutter_application_2/core/constants.dart';

/// `true` si la nota (o promedio) alcanza para aprobar.
bool estaAprobada(double nota) => nota >= kNotaAprobacion;

/// Verde si aprueba, rojo si desaprueba.
Color colorSegunNota(double nota) =>
    estaAprobada(nota) ? Colors.green : Colors.red;
