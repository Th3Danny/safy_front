import 'package:flutter/material.dart';
import 'package:safy/help/presentation/widgets/safety_info_widgets.dart';

class SpecificSituationsWidget extends StatelessWidget {
  const SpecificSituationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Título de sección
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.purple.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Situaciones Específicas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Acoso callejero
        const HarassmentSafetyWidget(),

        const SizedBox(height: 20),

        // Asaltos y robos
        const RobberySafetyWidget(),

        const SizedBox(height: 20),

        // Transporte público
        const PublicTransportSafetyWidget(),

        const SizedBox(height: 20),

        // Espacios públicos
        const PublicSpacesSafetyWidget(),
      ],
    );
  }
}

class HarassmentSafetyWidget extends StatelessWidget {
  const HarassmentSafetyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafetyCardWidget(
      title: '🚫 Acoso Callejero',
      color: Colors.pink,
      children: [
        const SafetyTipItem(
          icon: Icons.record_voice_over,
          title: 'Responde con firmeza',
          description:
              'Di "NO" de manera clara y firme. No tengas miedo de parecer "grosera"',
          isHighPriority: true,
        ),
        const SafetyTipItem(
          icon: Icons.visibility,
          title: 'Mantén contacto visual',
          description:
              'Míralos directamente para mostrar que no tienes miedo y que los puedes identificar',
        ),
        const SafetyTipItem(
          icon: Icons.people,
          title: 'Busca ayuda de otros',
          description:
              'Acércate a grupos de personas, especialmente mujeres o familias',
        ),
        const SafetyTipItem(
          icon: Icons.store,
          title: 'Entra a un negocio',
          description:
              'Busca refugio en tiendas, restaurantes o lugares con empleados',
        ),
        const SafetyTipItem(
          icon: Icons.phone_android,
          title: 'Documenta si es seguro',
          description:
              'Graba o toma fotos solo si no pone en riesgo tu seguridad',
        ),
      ],
    );
  }
}

class RobberySafetyWidget extends StatelessWidget {
  const RobberySafetyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafetyCardWidget(
      title: '💰 Asaltos y Robos',
      color: Colors.red,
      children: [
        const SafetyTipItem(
          icon: Icons.pan_tool,
          title: 'No resistas',
          description:
              'Entrega tus pertenencias sin oponerte. Tu vida vale más que cualquier objeto',
          isHighPriority: true,
        ),
        const SafetyTipItem(
          icon: Icons.psychology,
          title: 'Mantén la calma',
          description:
              'Habla despacio, evita movimientos bruscos y mantén las manos visibles',
        ),
        const SafetyTipItem(
          icon: Icons.visibility,
          title: 'Observa sin ser obvio',
          description:
              'Memoriza características: altura, complexión, voz, cicatrices, tatuajes',
        ),
        const SafetyTipItem(
          icon: Icons.directions_walk,
          title: 'Si puedes escapar',
          description:
              'Solo si tienes una ruta clara y estás seguro de poder huir',
        ),
        const SafetyTipItem(
          icon: Icons.credit_card,
          title: 'Cancela tarjetas inmediatamente',
          description: 'Llama a tu banco tan pronto como estés seguro',
        ),
      ],
    );
  }
}

class PublicTransportSafetyWidget extends StatelessWidget {
  const PublicTransportSafetyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafetyCardWidget(
      title: '🚌 Transporte Público',
      color: Colors.indigo,
      children: [
        const SafetyTipItem(
          icon: Icons.airline_seat_individual_suite,
          title: 'Siéntate cerca del conductor',
          description:
              'En los primeros asientos donde hay más visibilidad y control',
        ),
        const SafetyTipItem(
          icon: Icons.schedule,
          title: 'Evita horarios peligrosos',
          description:
              'Especialmente muy temprano en la mañana o muy tarde en la noche',
        ),
        const SafetyTipItem(
          icon: Icons.phone,
          title: 'Mantén el teléfono cargado',
          description: 'Y ten números de emergencia fácilmente accesibles',
        ),
        const SafetyTipItem(
          icon: Icons.backpack,
          title: 'Protege tus pertenencias',
          description:
              'Mochila adelante, cartera en bolsillo interno, celular no visible',
        ),
        const SafetyTipItem(
          icon: Icons.headphones,
          title: 'Mantente alerta',
          description:
              'Evita audífonos o música alta que te impida escuchar el entorno',
        ),
      ],
    );
  }
}

class PublicSpacesSafetyWidget extends StatelessWidget {
  const PublicSpacesSafetyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafetyCardWidget(
      title: '🏛️ Espacios Públicos',
      color: Colors.teal,
      children: [
        const SafetyTipItem(
          icon: Icons.wb_sunny,
          title: 'Prefiere áreas iluminadas',
          description:
              'Mantente en lugares bien iluminados y con buena visibilidad',
        ),
        const SafetyTipItem(
          icon: Icons.group,
          title: 'Busca áreas concurridas',
          description: 'Los delincuentes evitan lugares con muchos testigos',
        ),
        const SafetyTipItem(
          icon: Icons.local_drink,
          title: 'Cuidado con bebidas',
          description:
              'Nunca dejes tu bebida sin vigilancia ni aceptes de desconocidos',
        ),
        const SafetyTipItem(
          icon: Icons.exit_to_app,
          title: 'Conoce las salidas',
          description:
              'Siempre identifica las rutas de escape en cualquier lugar',
        ),
        const SafetyTipItem(
          icon: Icons.person_pin_circle,
          title: 'Comparte tu ubicación',
          description:
              'Avisa a alguien de confianza dónde estarás y cuánto tiempo',
        ),
      ],
    );
  }
}

class VulnerableGroupsWidget extends StatelessWidget {
  const VulnerableGroupsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Título de sección
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.shield, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Consejos Específicos por Grupo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Mujeres
        const WomenSafetyWidget(),

        const SizedBox(height: 20),

        // Estudiantes
        const StudentsSafetyWidget(),

        const SizedBox(height: 20),

        // Adultos mayores
        const ElderlySafetyWidget(),

       
      ],
    );
  }
}

class WomenSafetyWidget extends StatelessWidget {
  const WomenSafetyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafetyCardWidget(
      title: '👩 Consejos para Mujeres',
      color: Colors.purple,
      children: [
        const SafetyTipItem(
          icon: Icons.vpn_key,
          title: 'Llaves como defensa',
          description:
              'Mantén las llaves entre los dedos como elemento disuasivo',
        ),
        const SafetyTipItem(
          icon: Icons.notifications_active,
          title: 'App de pánico',
          description:
              'Instala aplicaciones que envíen tu ubicación a contactos de emergencia',
        ),
        const SafetyTipItem(
          icon: Icons.sports_kabaddi,
          title: 'Aprende autodefensa básica',
          description:
              'Técnicas simples pueden darte segundos valiosos para escapar',
        ),
        const SafetyTipItem(
          icon: Icons.female,
          title: 'Red de apoyo femenina',
          description:
              'Crea grupos con amigas para compartir ubicaciones y horarios',
        ),
      ],
    );
  }
}

class StudentsSafetyWidget extends StatelessWidget {
  const StudentsSafetyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafetyCardWidget(
      title: '🎓 Consejos para Estudiantes',
      color: Colors.blue,
      children: [
        const SafetyTipItem(
          icon: Icons.schedule,
          title: 'Horarios inteligentes',
          description:
              'Coordina horarios de clases para evitar caminar solo en horas peligrosas',
        ),
        const SafetyTipItem(
          icon: Icons.group_add,
          title: 'Grupos de estudio seguros',
          description: 'Forma grupos para estudiar y movilizarse juntos',
        ),
        const SafetyTipItem(
          icon: Icons.local_library,
          title: 'Lugares de estudio seguros',
          description:
              'Prefiere bibliotecas y espacios universitarios con seguridad',
        ),
        const SafetyTipItem(
          icon: Icons.money,
          title: 'Lleva dinero limitado',
          description:
              'Solo el dinero necesario para el día, usa tarjetas cuando sea posible',
        ),
      ],
    );
  }
}

class ElderlySafetyWidget extends StatelessWidget {
  const ElderlySafetyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafetyCardWidget(
      title: '👴 Consejos para Adultos Mayores',
      color: Colors.green,
      children: [
        const SafetyTipItem(
          icon: Icons.phone_android,
          title: 'Teléfono simple y cargado',
          description:
              'Con números de emergencia programados y fáciles de marcar',
        ),
        const SafetyTipItem(
          icon: Icons.medical_services,
          title: 'Medicamentos identificables',
          description:
              'Lleva identificación médica y lista de medicamentos importantes',
        ),
        const SafetyTipItem(
          icon: Icons.access_time,
          title: 'Rutinas predecibles',
          description:
              'Informa a familiares sobre tus horarios y rutas habituales',
        ),
        const SafetyTipItem(
          icon: Icons.home,
          title: 'Seguridad en el hogar',
          description:
              'No abras la puerta a desconocidos, verifica identidad siempre',
        ),
      ],
    );
  }
}
