Snappy 1.1.9, misma versión utilizada por Firebase C++ SDK 12.7.0 (Firestore CocoaPods-11.10.0).
Fuente: https://github.com/google/snappy/tree/1.1.9
Archivo original SHA256: 75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7
Cambios: target OBJECT para resolver sus símbolos antes del archivo estático de Firebase; parche inline utilizado por Firebase; BMI2 y SSSE3 desactivados desde CMake para procesadores antiguos.
No se modifican archivos binarios del proveedor. Mantener COPYING en las distribuciones.

Se usa el espacio de nombres f_b_snappy del SDK de Firebase para sustituir sus símbolos de forma efectiva.
