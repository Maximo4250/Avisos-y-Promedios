/// Repara exclusivamente las variantes dañadas que publicó el catálogo antiguo.
/// No agrupa materias diferentes por aproximación ni altera IDs de notas.
String normalizarNombreMateria(String nombre) {
  const reparaciones = {
    'MatemÃ¡ticas': 'Matemáticas',
    'BiologÃ­a': 'Biología',
    'InglÃ©s': 'Inglés',
    'ED FÃ­sica': 'ED Física',
    'EI TecnologÃ­a': 'EI Tecnología',
  };
  return reparaciones[nombre] ?? nombre;
}
