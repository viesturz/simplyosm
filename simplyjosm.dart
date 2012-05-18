#import('dart:html');

#source('Geometry.dart');
#source('Tool.dart');
#source('IData.dart');
#source('View.dart');

#source('AreasData.dart');
#source('AreasLayer.dart');
#source('AreasTools.dart');

#source('Editor.dart');


class simplyjosm {

  simplyjosm() {
  }

  void run() {
    var e = new Editor(document.query('#mapCanvas'));
    write("Editor started!");
  }

  void write(String message) {
    // the HTML library defines a global "document" variable
    document.query('#status').innerHTML = message;
  }
}

void main() {
  new simplyjosm().run();
}
