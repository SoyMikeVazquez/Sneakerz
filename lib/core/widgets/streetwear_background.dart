import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sneakerz_app/core/constants/colors.dart';

class StreetwearBackground extends StatelessWidget {
  final Widget child;

  const StreetwearBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo blanco
        Container(color: AppColors.background),
        
        // Texto gigante izquierdo (de abajo hacia arriba)
        Positioned(
          left: -40, // Ajuste para que se corte un poco
          top: 0,
          bottom: 0,
          child: RotatedBox(
            quarterTurns: 3,
            child: _buildOutlineText('SNEAKERZ', context),
          ),
        ),

        // Texto gigante derecho (de arriba hacia abajo)
        Positioned(
          right: -40,
          top: 0,
          bottom: 0,
          child: RotatedBox(
            quarterTurns: 1,
            child: _buildOutlineText('BODY SHOP', context),
          ),
        ),

        // Contenido principal de la pantalla
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }

  Widget _buildOutlineText(String text, BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 120, // Texto enorme
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: 10,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = AppColors.border.withOpacity(0.04), // Líneas muy suaves y transparentes
      ),
      maxLines: 1,
      overflow: TextOverflow.visible,
    );
  }
}
