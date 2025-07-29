import 'package:flutter/material.dart';

class SafetyInfoSection extends StatelessWidget {
  const SafetyInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        
        // Título principal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de Seguridad',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Conoce qué hacer en situaciones de riesgo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Situaciones de emergencia
        const EmergencyActionsWidget(),
        
        const SizedBox(height: 20),
        
        // Prevención
        const PreventionTipsWidget(),
        
        const SizedBox(height: 20),
        
        // Qué hacer durante
        const DuringIncidentWidget(),
        
        const SizedBox(height: 20),
        
        // Después del incidente
        const AfterIncidentWidget(),
      ],
    );
  }
}

class EmergencyActionsWidget extends StatelessWidget {
  const EmergencyActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafetyCardWidget(
      title: '🚨 En Caso de Emergencia',
      color: Colors.red,
      children: [
        const SafetyTipItem(
          icon: Icons.phone_in_talk,
          title: 'Llama inmediatamente',
          description: '911 para emergencias graves\n089 para denuncias anónimas',
          isHighPriority: true,
        ),
        const SafetyTipItem(
          icon: Icons.location_on,
          title: 'Comparte tu ubicación',
          description: 'Envía tu ubicación exacta a contactos de confianza',
        ),
        const SafetyTipItem(
          icon: Icons.directions_run,
          title: 'Busca un lugar seguro',
          description: 'Dirígete al lugar público más cercano con gente',
        ),
        const SafetyTipItem(
          icon: Icons.volume_up,
          title: 'Pide ayuda en voz alta',
          description: 'Grita para llamar la atención de otras personas',
        ),
      ],
    );
  }
}

class PreventionTipsWidget extends StatelessWidget {
  const PreventionTipsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafetyCardWidget(
      title: '🛡️ Prevención y Seguridad',
      color: Colors.green,
      children: [
        const SafetyTipItem(
          icon: Icons.lightbulb_outline,
          title: 'Mantente alerta',
          description: 'Evita distracciones como auriculares o teléfono en zonas desconocidas',
        ),
        const SafetyTipItem(
          icon: Icons.group,
          title: 'Viaja acompañado',
          description: 'Especialmente durante la noche o en zonas poco transitadas',
        ),
        const SafetyTipItem(
          icon: Icons.wb_sunny,
          title: 'Prefiere horarios seguros',
          description: 'Evita caminar solo durante la madrugada o en lugares oscuros',
        ),
        const SafetyTipItem(
          icon: Icons.phone,
          title: 'Contactos de emergencia',
          description: 'Tenlos programados y accesibles rápidamente',
        ),
        const SafetyTipItem(
          icon: Icons.money_off,
          title: 'No exhibas objetos de valor',
          description: 'Mantén discreta la tecnología, joyas o dinero en efectivo',
        ),
      ],
    );
  }
}

class DuringIncidentWidget extends StatelessWidget {
  const DuringIncidentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafetyCardWidget(
      title: '⚠️ Durante un Incidente',
      color: Colors.orange,
      children: [
        const SafetyTipItem(
          icon: Icons.psychology,
          title: 'Mantén la calma',
          description: 'Respira profundo y piensa antes de actuar',
          isHighPriority: true,
        ),
        const SafetyTipItem(
          icon: Icons.hearing,
          title: 'Coopera si es un robo',
          description: 'Tu seguridad vale más que cualquier objeto material',
        ),
        const SafetyTipItem(
          icon: Icons.visibility,
          title: 'Observa detalles',
          description: 'Memoriza características físicas, ropa, dirección de escape',
        ),
        const SafetyTipItem(
          icon: Icons.no_photography,
          title: 'No tomes fotos',
          description: 'Puede provocar agresión. Enfócate en tu seguridad',
        ),
        const SafetyTipItem(
          icon: Icons.record_voice_over,
          title: 'Si hay testigos',
          description: 'Pide ayuda clara: "Llamen a la policía" dirigiéndote a alguien específico',
        ),
      ],
    );
  }
}

class AfterIncidentWidget extends StatelessWidget {
  const AfterIncidentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafetyCardWidget(
      title: '📋 Después del Incidente',
      color: Colors.blue,
      children: [
        const SafetyTipItem(
          icon: Icons.local_police,
          title: 'Denuncia inmediatamente',
          description: 'Ve a la estación de policía más cercana o llama al 911',
          isHighPriority: true,
        ),
        const SafetyTipItem(
          icon: Icons.healing,
          title: 'Busca atención médica',
          description: 'Incluso si no hay heridas visibles, el trauma puede afectar tu salud',
        ),
        const SafetyTipItem(
          icon: Icons.description,
          title: 'Documenta todo',
          description: 'Escribe todos los detalles mientras los recuerdes claramente',
        ),
        const SafetyTipItem(
          icon: Icons.support_agent,
          title: 'Busca apoyo psicológico',
          description: 'Contacta servicios de apoyo emocional especializados',
        ),
        const SafetyTipItem(
          icon: Icons.share,
          title: 'Reporta en la app',
          description: 'Ayuda a otros usuarios conociendo las zonas de riesgo',
        ),
      ],
    );
  }
}

class SafetyCardWidget extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> children;

  const SafetyCardWidget({
    super.key,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.security,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class SafetyTipItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isHighPriority;

  const SafetyTipItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isHighPriority = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighPriority 
            ? Colors.red.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: isHighPriority 
            ? Border.all(color: Colors.red.withOpacity(0.2))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighPriority 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isHighPriority ? Colors.red : Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isHighPriority ? Colors.red.shade700 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
