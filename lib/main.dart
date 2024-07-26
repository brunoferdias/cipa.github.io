import 'package:cipa_web/screens/menu/menu_initial.dart';
import 'package:cipa_web/server/server.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  await Parse().initialize(
    keyApplicationId,
    keyParseServerUrl,
    clientKey: keyClientKey,
    autoSendSessionId: true,
  );
  runApp(MaterialApp(
    home: MenuInitial(),
    debugShowCheckedModeBanner: false,
  ));
}
