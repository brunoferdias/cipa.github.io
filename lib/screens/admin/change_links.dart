import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../menu/menu_initial.dart';

class EditLinksScreen extends StatefulWidget {
  final String initialMembrosLink;
  final String initialCalendarioLink;
  final String initialEquipesLink;
  final String initialSegurancaLink;
  final String initialRosLink;
  final String adminName;

  EditLinksScreen({
    Key? key,
    required this.initialMembrosLink,
    required this.initialCalendarioLink,
    required this.initialEquipesLink,
    required this.initialSegurancaLink,
    required this.initialRosLink,
    required this.adminName,
  }) : super(key: key);

  @override
  _EditLinksScreenState createState() => _EditLinksScreenState();
}

class _EditLinksScreenState extends State<EditLinksScreen> {
  final _membrosController = TextEditingController();
  final _calendarioController = TextEditingController();
  final _equipesController = TextEditingController();
  final _segurancaController = TextEditingController();
  final _rosController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _membrosController.text = widget.initialMembrosLink;
    _calendarioController.text = widget.initialCalendarioLink;
    _equipesController.text = widget.initialEquipesLink;
    _segurancaController.text = widget.initialSegurancaLink;
    _rosController.text = widget.initialRosLink;
  }

  Future<void> _updateLinksInParse() async {
    final query = QueryBuilder<ParseObject>(ParseObject('Link'));

    final response = await query.query();
    if (response.success && response.results != null) {
      final links = response.results as List<ParseObject>;

      for (var link in links) {
        switch (link.get<String>('nome')) {
          case 'membros':
            link.set('link', _membrosController.text);
            break;
          case 'calendario':
            link.set('link', _calendarioController.text);
            break;
          case 'equipes':
            link.set('link', _equipesController.text);
            break;
          case 'seguranca':
            link.set('link', _segurancaController.text);
            break;
          case 'ros':
            link.set('link', _rosController.text);
            break;
        }
        await link.save();
      }
    } else {
      throw 'Erro ao atualizar links: ${response.error?.message}';
    }
  }

  void _saveLinks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _updateLinksInParse();
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MenuInitial(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: Text('Erro', style: TextStyle(color: Colors.white)),
            content: Text('Erro ao salvar links: $e', style: TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                child: Text('OK', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearTextField(TextEditingController controller) {
    setState(() {
      controller.clear();
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => _clearTextField(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade300,
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: Text("Olá ${widget.adminName}, edite os links 😉"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(
                  controller: _membrosController,
                  labelText: "Link MEMBROS Cipa 23",
                ),
                SizedBox(height: 30),
                _buildTextField(
                  controller: _calendarioController,
                  labelText: "Link Calendário Reuniões",
                ),
                SizedBox(height: 30),
                _buildTextField(
                  controller: _equipesController,
                  labelText: "Link Equipes x Setores (PARA IAS)",
                ),
                SizedBox(height: 30),
                _buildTextField(
                  controller: _segurancaController,
                  labelText: "Link Segurança",
                ),
                SizedBox(height: 30),
                _buildTextField(
                  controller: _rosController,
                  labelText: "Link Ros",
                ),
                SizedBox(height: 50),
                _isLoading
                    ? CircularProgressIndicator(color: Colors.green,strokeWidth: 1,)
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: _saveLinks,
                  child: Text(
                    "Salvar Links",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
