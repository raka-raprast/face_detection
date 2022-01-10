import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DataBaseService {
  static final DataBaseService _cameraServiceService =
      DataBaseService._internal();

  factory DataBaseService() {
    return _cameraServiceService;
  }

  DataBaseService._internal();

  File? jsonFile;

  Map<String, dynamic> _db = <String, dynamic>{};
  Map<String, dynamic> get db => _db;

  Future loadDB() async {
    var tempDir = await getApplicationDocumentsDirectory();
    String _embPath = tempDir.path + '/emb.json';

    jsonFile = File(_embPath);

    if (jsonFile!.existsSync()) {
      _db = json.decode(jsonFile!.readAsStringSync());
    }
  }

  Future saveData(String user, String password, List modelData) async {
    String userAndPass = user + ':' + password;
    _db[userAndPass] = modelData;
    jsonFile!.writeAsStringSync(json.encode(_db));
  }

  cleanDB() {
    this._db = Map<String, dynamic>();
    jsonFile!.writeAsStringSync(json.encode({}));
  }
}
