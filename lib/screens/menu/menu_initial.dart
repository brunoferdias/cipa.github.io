import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../../components/button.dart';
import '../PDFscreen/see_pdf.dart';
import '../admin/change_links.dart';

class MenuInitial extends StatefulWidget {
  MenuInitial({Key? key}) : super(key: key);

  @override
  State<MenuInitial> createState() => _MenuInitialState();
}

class _MenuInitialState extends State<MenuInitial> {
  Map<String, String> links = {};
  bool isLoadingAdm = false;

  Future<Map<String, String>> fetchLinksFromParse() async {
    final query = QueryBuilder<ParseObject>(ParseObject('Link'))
      ..orderByAscending('nome');

    final response = await query.query();
    if (response.success && response.results != null) {
      final links = response.results as List<ParseObject>;

      final linkMap = <String, String>{};
      for (var link in links) {
        final nome = link.get<String>('nome');
        final url = link.get<String>('link');
        if (nome != null && url != null) {
          linkMap[nome] = url;
        }
      }
      return linkMap;
    } else {
      throw 'Erro ao recuperar links: ${response.error?.message}';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final fetchedLinks = await fetchLinksFromParse();
      setState(() {
        links = fetchedLinks;
      });
    } catch (e) {
      print('Erro ao carregar links: $e');
    }
  }

  Future<void> openPDF(String url, String title) async {
    try {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 0.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Carregando $title...',
                    style: TextStyle(color: Colors.white,fontSize: 18),textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Baixar o arquivo PDF
      var response = await http.get(Uri.parse(url));
      var bytes = response.bodyBytes;

      // Salvar o arquivo no diretório temporário
      var dir = await getTemporaryDirectory();
      File file = File('${dir.path}/temp.pdf');
      await file.writeAsBytes(bytes, flush: true);

      // Fechar o diálogo de carregamento
      Navigator.of(context).pop();

      // Navegar para a tela do PDF
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PDFScreen(
            url: file.path,
            title: title,
          ),
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
      // Fechar o diálogo de carregamento em caso de erro
      Navigator.of(context).pop();
      throw 'Algo deu errado: $e';
    }
  }

  Future<bool> verifyAdminCode(String code) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Adm'))
      ..whereEqualTo('code', code);

    final response = await query.query();
    if (response.success && response.results != null) {
      return true;
    } else {
      return false;
    }
  }

  void showAuthorizationDialog() {
    TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text('Autorização Necessária',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: codeController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Digite o código de autorização',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

                 TextButton(
                    child:
                    isLoadingAdm
                        ? Container(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 0.4,
                      ),
                    ): Text('Enviar', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      setState(() {
                        isLoadingAdm = true;
                      });
                      HapticFeedback.heavyImpact();
                      String code = codeController.text.trim();
                      if (await verifyAdminCode(code)) {
                        Navigator.of(context).pop();
                        setState(() {
                          isLoadingAdm = false;
                        });
                        navigateToEditLinksScreen(code);
                      } else {
                        setState(() {
                          isLoadingAdm = false;
                        });
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.black,
                              title: Text('Erro',
                                  style: TextStyle(color: Colors.white)),
                              content: Text('Código de autorização inválido',
                                  style: TextStyle(color: Colors.white)),
                              actions: [
                                TextButton(
                                  child: Text('OK',
                                      style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
          ],
        );
      },
    );
  }

  Future<void> navigateToEditLinksScreen(String code) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Adm'))
      ..whereEqualTo('code', code);

    final response = await query.query();
    if (response.success && response.results != null) {
      final adm = response.results!.first as ParseObject;
      final nome = adm.get<String>('nome');

      if (nome != null) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                EditLinksScreen(
              initialMembrosLink: links['membros'] ?? '',
              initialCalendarioLink: links['calendario'] ?? '',
              initialEquipesLink: links['equipes'] ?? '',
              initialSegurancaLink: links['seguranca'] ?? '',
              initialRosLink: links['ros'] ?? '',
              adminName: nome,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end);
              var curvedAnimation =
                  CurvedAnimation(parent: animation, curve: curve);
              var offsetAnimation = tween.animate(curvedAnimation);

              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void goToMembros() async {
    var link = links['membros'] ?? '';
    HapticFeedback.heavyImpact();
    //await openPDF(link, "MEMBROS Cipa 23");
    if (!await launchUrl(Uri.parse(link))) {
      throw 'Algo deu errado';
    }
  }

  void goToCalendario() async {
    var link = links['calendario'] ?? '';
    HapticFeedback.heavyImpact();
    //await openPDF(link, "Calendário Reuniões");
    if (!await launchUrl(Uri.parse(link))) {
      throw 'Algo deu errado';
    }
  }

  void goToEquipes() async {
    var link = links['equipes'] ?? '';
    HapticFeedback.heavyImpact();
    //await openPDF(link, "Equipes x Setores (PARA IAS)");
    if (!await launchUrl(Uri.parse(link))) {
      throw 'Algo deu errado';
    }
  }

  void goToSeguranca() async {
    var link = links['seguranca'] ?? '';
    HapticFeedback.heavyImpact();
    if (!await launchUrl(Uri.parse(link))) {
      throw 'Algo deu errado';
    }
  }

  void goToROS() async {
    var link = links['ros'] ?? '';
    HapticFeedback.heavyImpact();
    if (!await launchUrl(Uri.parse(link))) {
      throw 'Algo deu errado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = [
      SizedBox(height: 50),
      CustomizedButton(
        text: "MEMBROS Cipa 23",
        icon: Icons.add,
        onTap: goToMembros,
      ),
      SizedBox(height: 10),
      CustomizedButton(
        text: "Calendário Reuniões",
        icon: Icons.calendar_month,
        onTap: goToCalendario,
      ),
      SizedBox(height: 10),
      CustomizedButton(
        text: "Equipes x Setores (PARA IAS)",
        icon: Icons.person,
        onTap: goToEquipes,
      ),
      SizedBox(height: 10),
      CustomizedButton(
        text: "Inspeção de Segurança",
        icon: Icons.file_copy_outlined,
        onTap: goToSeguranca,
      ),
      SizedBox(height: 10),
      CustomizedButton(
        text: "ROQSE",
        icon: Icons.circle,
        onTap: goToROS,
      ),
      SizedBox(height: 50),
    ];

    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        title: Text(
          "Cipa Jundiaí",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.add_moderator, color: Colors.white70),
          onPressed: () {
            HapticFeedback.heavyImpact();
            showAuthorizationDialog();
          },
        ),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Colors.green, Colors.green.shade900],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 25,
            ),
            Image.asset(
              "assets/cipa.png",
              height: 125,
              width: 125,
            ),
            SizedBox(
              height: 10,
            ),
            Expanded(
              child: Stack(
                children: [
                  AnimationLimiter(
                    child: ListView.builder(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.all(8.0),
                      itemCount: buttons.length,
                      itemBuilder: (BuildContext context, int index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 1000),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: buttons[index],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 50, // Altura do efeito de fade
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.green.withOpacity(1),
                            Colors.green.withOpacity(0.8),
                            Colors.green.withOpacity(0.6),
                            Colors.green.withOpacity(0.4),
                            Colors.green.withOpacity(0.2),
                            Colors.green.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
