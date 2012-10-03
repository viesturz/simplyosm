#import('dart:html');
#import('dart:math');

#source('Geometry.dart');
#source('Tool.dart');
#source('IAction.dart');
#source('IData.dart');
#source('View.dart');

#source('AreasData.dart');
#source('AreasLayer.dart');
#source('AreasTools.dart');
#source('AreasActions.dart');

#source('Editor.dart');


class simplyjosm {

  simplyjosm() {
  }

  void run() {  
    
    var e = new Editor(document.query('#mapCanvas'));
    document.query('#undo').on.click.add((event) => e.undo());
    document.query('#redo').on.click.add((event) => e.redo());
    
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
