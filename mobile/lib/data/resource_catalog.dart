import 'resource.dart';

/// Catálogo local de respaldo.
///
/// La app está pensada para alimentarse de un catálogo remoto (backend propio o
/// una API gratuita de psicoeducación). Mientras ese servicio no esté
/// disponible, se muestra este contenido curado para que la pantalla de
/// Recursos funcione sin conexión.
class ResourceCatalog {
  const ResourceCatalog._();

  static const resources = <Resource>[
    Resource(
      id: 'regulacion-sistema-nervioso',
      title: 'Regulación del Sistema Nervioso Autónomo en 4 Pasos',
      description:
          'Una guía práctica para desactivar la hiperactivación fisiológica cuando '
          'sientes sobrecarga vespertina.',
      category: 'Neurobiología Aplicada',
      readMinutes: 4,
      kind: ResourceKind.guide,
      featured: true,
      clinical: true,
      imageUrl:
          'https://images.pexels.com/photos/6633496/pexels-photo-6633496.jpeg?auto=compress&cs=tinysrgb&w=1200',
      imageCaption: 'Neurobiología Aplicada',
      tags: ['enfoque somatico', 'audio', 'estrés', 'respiración'],
      content:
          'Cuando el día acumula tensión, el sistema nervioso simpático mantiene el '
          'cuerpo en alerta incluso cuando ya estás en casa. Esta guía te ayuda a '
          'volver a un estado de calma de forma gradual, sin forzar la respiración.\n\n'
          '1. Reconoce la señal. Antes de intentar cambiar lo que sientes, nota dónde '
          'está la tensión: mandíbula, hombros, pecho o abdomen. Nombrarla reduce la '
          'respuesta de alarma.\n\n'
          '2. Alarga la exhalación. Inhala por la nariz en 4 tiempos y exhala en 6 u 8. '
          'La exhalación larga activa el nervio vago y favorece el descenso del pulso.\n\n'
          '3. Ancla la atención en el cuerpo. Apoya los pies en el suelo y siente el '
          'contacto durante treinta segundos. Después lleva la mano al pecho y observa '
          'el calor de la palma.\n\n'
          '4. Cierra con una micro-pausa. Bebe agua, baja la luz y elige una acción '
          'sencilla para los próximos diez minutos. La regulación ocurre en la '
          'transición, no en la prisa.\n\n'
          'Puedes repetir esta secuencia tantas veces como necesites. Si la '
          'sobrecarga se mantiene varios días, considera hablarlo con un profesional.',
    ),
    Resource(
      id: 'respiracion-cuadrada',
      title: 'Respiración Cuadrada',
      description:
          'Ejercicio breve para estabilizar el pulso y calmar la mente antes de '
          'una conversación difícil.',
      category: 'Respiración',
      readMinutes: 3,
      kind: ResourceKind.exercise,
      clinical: true,
      tags: ['pulso visual', 'ansiedad', 'respiración'],
      content:
          'La respiración cuadrada equilibra la entrada y la salida de aire. Siéntate '
          'con la espalda apoyada y los hombros sueltos.\n\n'
          'Inhala en 4 tiempos, sostén 4, exhala 4 y permanece sin aire 4. Repite el '
          'ciclo durante tres minutos.\n\n'
          'No busques una respiración perfecta: si te cuesta sostener el aire, acorta '
          'el tiempo y mantén el ritmo cómodo.',
    ),
    Resource(
      id: 'escaneo-corporal',
      title: 'Escaneo Corporal',
      description:
          'Recorrido guiado por el cuerpo para soltar la tensión acumulada y '
          'preparar el descanso.',
      category: 'Sueño & Descanso',
      readMinutes: 8,
      kind: ResourceKind.audio,
      clinical: true,
      tags: ['sonido relajante', 'descanso', 'audio'],
      content:
          'Acuéstate boca arriba con las palmas hacia arriba y cierra los ojos.\n\n'
          'Lleva la atención a los pies. Observa el contacto con la superficie y '
          'permite que los músculos se aflojen. Sube lentamente por pantorrillas, '
          'muslos, cadera, abdomen, pecho, brazos, cuello y rostro.\n\n'
          'Si aparece un pensamiento, nómbralo y vuelve al punto del cuerpo donde '
          'estabas. Al terminar, quédate unos segundos en silencio antes de moverte.',
    ),
    Resource(
      id: 'desencadenantes-emocionales',
      title: 'Comprendiendo los desencadenantes emocionales: el mapa de tu estrés',
      description:
          'Identificar qué situaciones activan tu alarma emocional es el primer paso '
          'para responder con más margen y menos automático.',
      category: 'Ansiedad & Pánico',
      readMinutes: 6,
      kind: ResourceKind.article,
      clinical: true,
      author: 'Dra. Elena Ramos',
      imageUrl:
          'https://images.pexels.com/photos/5357086/pexels-photo-5357086.jpeg?auto=compress&cs=tinysrgb&w=900',
      tags: ['ansiedad', 'estrés', 'autoconocimiento'],
      content:
          'Un desencadenante no es la causa de tu emoción, sino la señal que activa '
          'una respuesta aprendida. Puede ser una conversación, un olor, una hora del '
          'día o incluso el cansancio acumulado.\n\n'
          'El primer paso es observarlos sin juicio. Durante una semana, anota qué '
          'estaba pasando justo antes de notar tensión o ansiedad. Con el tiempo '
          'aparecen patrones: reuniones a última hora, notificaciones, discusiones '
          'familiares o noches sin dormir.\n\n'
          'Cuando reconoces el patrón, puedes introducir una pausa entre el estímulo y '
          'la reacción. Esa pausa, aunque dure diez segundos, devuelve la sensación '
          'de elección.\n\n'
          'La psicoeducación no elimina el malestar, pero cambia la relación que '
          'tienes con él. Si los desencadenantes te desbordan con frecuencia, '
          'acompañarte de un profesional puede ayudarte a trabajarlos con seguridad.',
    ),
    Resource(
      id: 'ciencia-del-sueno',
      title: 'La ciencia del sueño y su impacto directo en la resiliencia',
      description:
          'Dormir no es solo descansar: es el momento en el que el cerebro procesa '
          'las emociones del día y recupera capacidad de respuesta.',
      category: 'Sueño & Descanso',
      readMinutes: 5,
      kind: ResourceKind.article,
      clinical: true,
      author: 'Psic. Mariana Valdés',
      imageUrl:
          'https://images.unsplash.com/photo-1616627561950-9f746e330187?auto=format&fit=crop&w=900&q=80',
      tags: ['sueño', 'descanso', 'resiliencia'],
      content:
          'Durante el sueño profundo el cuerpo repara tejidos y regula hormonas del '
          'estrés. En la fase REM, el cerebro reorganiza recuerdos y da sentido a las '
          'emociones vividas.\n\n'
          'Cuando el descanso es insuficiente, la amígdala responde con más intensidad '
          'y la corteza prefrontal pierde capacidad para modular esa respuesta. Por eso '
          'todo se siente más grande después de una mala noche.\n\n'
          'La higiene del sueño no consiste en dormir más, sino en proteger el ritmo. '
          'Horarios estables, luz natural por la mañana y menos pantallas antes de '
          'acostarte son intervenciones sencillas con efecto acumulativo.\n\n'
          'Si el insomnio se prolonga más de tres semanas o interfiere con tu día, '
          'conviene consultarlo con un profesional de la salud.',
    ),
    Resource(
      id: 'respiracion-fisiologica',
      title: 'Respiración fisiológica: el ancla del sistema nervioso',
      description:
          'Una técnica simple que puedes usar en el transporte, antes de dormir o en '
          'medio de una emoción intensa.',
      category: 'Respiración',
      readMinutes: 7,
      kind: ResourceKind.article,
      clinical: true,
      author: 'Dr. Andrés Molina',
      imageUrl:
          'https://images.pexels.com/photos/13865894/pexels-photo-13865894.jpeg?auto=compress&cs=tinysrgb&w=900',
      tags: ['respiración', 'ansiedad', 'pulso'],
      content:
          'La respiración fisiológica es la que ocurre cuando duermes: el abdomen se '
          'expande y la exhalación es larga y pasiva. Recuperarla en momentos de estrés '
          'es una de las formas más rápidas de enviar seguridad al cuerpo.\n\n'
          'Coloca una mano en el abdomen y otra en el pecho. Intenta que solo la mano '
          'del abdomen se mueva. Inhala por la nariz sin elevar los hombros y deja que '
          'la exhalación salga sola.\n\n'
          'Practícalo durante dos minutos en un momento neutro del día. Así será más '
          'fácil recordarlo cuando aparezca la ansiedad.\n\n'
          'Esta técnica complementa el acompañamiento psicológico; no sustituye la '
          'atención profesional.',
    ),
    Resource(
      id: 'limites-afectivos',
      title: 'Límites afectivos: aprender a decir no sin culpa',
      description:
          'Poner límites no es alejar a los demás. Es cuidar la energía que necesitas '
          'para estar presente.',
      category: 'Vínculos',
      readMinutes: 5,
      kind: ResourceKind.article,
      clinical: true,
      author: 'Psic. Lucía Ferrer',
      imageUrl:
          'https://images.pexels.com/photos/8590237/pexels-photo-8590237.jpeg?auto=compress&cs=tinysrgb&w=900',
      tags: ['vínculos', 'límites', 'autoestima'],
      content:
          'Decir que no suele activar el miedo a decepcionar. Sin embargo, un límite '
          'claro protege la relación de resentimientos que se acumulan en silencio.\n\n'
          'Un límite saludable describe qué necesitas, no qué está mal en la otra '
          'persona. Por ejemplo: “Hoy necesito descansar; mañana te llamo con calma”.\n\n'
          'La culpa puede aparecer al principio. No es una señal de que estés haciendo '
          'algo malo, sino de que estás aprendiendo una forma nueva de vincularte.\n\n'
          'Empieza con límites pequeños y observa cómo responde tu cuerpo. La práctica '
          'constante hace que el cuidado propio deje de sentirse como una amenaza.',
    ),
    Resource(
      id: 'micro-pausas-estres',
      title: 'Higiene del estrés: micro-pausas que sí funcionan',
      description:
          'Tres intervenciones de menos de dos minutos que reducen la carga acumulada '
          'sin interrumpir tu jornada.',
      category: 'Estrés',
      readMinutes: 4,
      kind: ResourceKind.article,
      clinical: true,
      author: 'Dra. Elena Ramos',
      imageUrl:
          'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=900&q=80',
      tags: ['estrés', 'trabajo', 'pausas'],
      content:
          'El estrés sostenido se acumula en el cuerpo aunque la mente siga trabajando. '
          'Las micro-pausas buscan descargar esa activación antes de que se convierta en '
          'agotamiento.\n\n'
          'Primera pausa: mira un punto lejano durante veinte segundos. El cambio de '
          'distancia relaja la musculatura de los ojos y reduce la señal de alerta.\n\n'
          'Segunda pausa: suelta la mandíbula y baja los hombros. Son dos zonas donde '
          'la tensión pasa desapercibida.\n\n'
          'Tercera pausa: camina dos minutos sin el teléfono. El movimiento cambia el '
          'patrón respiratorio y ayuda a procesar la carga mental.\n\n'
          'No necesitas hacerlas perfectas. La constancia importa más que la duración.',
    ),
  ];
}
