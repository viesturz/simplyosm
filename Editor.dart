
class Editor {
  View view;

  Editor(canvas){
    var data = new AreasData();
    var layer = new AreasLayer(data);

    this.view = new View(canvas, data);
    this.view.addLayer(layer);

    this.view.addTool(new CreateLinesTool(layer));
    this.view.addTool(new AddNodeOnLineTool(layer));
    this.view.addTool(new DragPointsTool(layer));
    this.view.addTool(new SelectOnClickTool(layer));
    this.view.addTool(layer.actionsTool);
  }
}
