import 'dart:convert';
import 'package:flutter/services.dart';
import 'emberMap.dart';

export 'emberMap.dart';

class EmberReader{
  EmberReader(this.pathFile,[this.level]){
    String fileName = pathFile.split('/').last;
    if (!fileName.contains('.json') && !fileName.contains('.ember')) {
      throw Exception('only supports json and ember files');
    }
    if (fileName.contains('.ember') && level == null) {
      throw Exception('ember files must have a level');
    }
    basePathFile = pathFile.replaceAll(fileName, '');
  }

  final String pathFile;
  late String basePathFile;
  late EmberMap _map;
  late int? level;

  Future<EmberMap> read(int level) async {
    String data = await rootBundle.loadString(pathFile);
    String fileName = pathFile.split('/').last;

    dynamic _result = jsonDecode(data);
    if(fileName.contains('.json')){
      _map = EmberMap.fromJSON(_result);
    }
    else{
      _map = EmberMap.fromEmber(_result,level);
    }

    return Future.value(_map);
  }
}