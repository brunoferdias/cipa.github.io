import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomizedButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final bool hasImage;
  final VoidCallback? onTap;

  const CustomizedButton({
    Key? key,
    required this.text,
    required this.icon,
    this.hasImage = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<CustomizedButton> createState() => _CustomizedButtonState();
}

class _CustomizedButtonState extends State<CustomizedButton> {
  double _scaleTicket = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        setState(() {
          _scaleTicket = 0.85;
        });
        await Future.delayed(Duration(milliseconds: 200));
        setState(() {
          _scaleTicket = 1.0;
        });
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      child: AnimatedScale(
        curve: Curves.ease,
        scale: _scaleTicket,
        duration: Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(50, 194, 208, 196),
                  Color.fromARGB(50, 35, 53, 114),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(230, 3, 54, 7).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 5,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: widget.hasImage
                              ? Image.asset(
                            "assets/coca.png",
                            height: 40, // Ajuste a altura aqui
                            width: 40,  // Ajuste a largura aqui
                          )
                              : Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 25, // Ajuste o tamanho do ícone aqui
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          widget.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
