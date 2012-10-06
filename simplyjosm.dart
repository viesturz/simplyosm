#import('dart:html');
#import('dart:math');

#source('Geometry.dart');
#source('Tool.dart');
#source('IAction.dart');
#source('IData.dart');
#source('View.dart');

#source('AreasData.dart');
#source('AreasProcessing.dart');
#source('AreasLayer.dart');
#source('AreasTools.dart');
#source('AreasActions.dart');

#source('Editor.dart');


class simplyjosm {

  simplyjosm() {
  }

  void run() {  
    
    //update canvas size to fit parent
    var canvas = document.query('#mapCanvas');    
    var e = new Editor(canvas);
    document.query('#undo').on.click.add((event) => e.undo());
    document.query('#redo').on.click.add((event) => e.redo());
    document.query('#debug').on.click.add((event) => e.toggleDebug());
    
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
