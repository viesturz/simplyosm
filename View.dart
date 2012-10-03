class View {

  CanvasElement canvas;
  var context;
  IData data; //TODO: maybe remove data from view and go through layers completely.
  AreasLayer layer;

  List<Tool> tools;
  Tool activeTool;

  double canvasWidth;
  double canvasHeight;

  double prevX;
  double prevY;
  double zoom;
  double centerX;
  double centerY;

  List<Object> selection;

  View(CanvasElement canvas, IData data){
      this.canvas = canvas;
      this.data = data;
      this.layer = null;

      this.tools = [];
      this.selection = [];
      this.zoom = 1.0;
      this.centerX = 0.0;
      this.centerY = 0.0;

      this.context = canvas.getContext("2d");
      this.canvasWidth = canvas.width.toDouble();
      this.canvasHeight = canvas.height.toDouble();
      canvas.on.mouseDown.add((event) => this.handleMouseDown(event));
      canvas.on.mouseUp.add((event) => this.handleMouseUp(event));
      canvas.on.mouseMove.add(this.handleMouseMove);
      canvas.on.mouseWheel.add(this.handleMouseWheel);
      window.on.keyDown.add(this.handleKeyDown);

      this.addTool(new PanTool());
  }

  void addTool(Tool tool){
      this.tools.insertRange(0,1);
      this.tools[0] = tool;
      tool.attach(this);
  }

  void addLayer(var _layer){
    this.layer = _layer;
    this.layer.attach(this);
  }

  void paint(){
      this.context.clearRect(0,0,this.canvasWidth, this.canvasHeight);
      this.layer.paint();
  }

  double xToCanvas(double x){
      return (x - this.centerX) * this.zoom + this.canvasWidth/2;
  }

  double yToCanvas(double y){
      return this.canvasHeight/2 - (y - this.centerY) * this.zoom;
  }

  double xToData(double x){
      return (x - this.canvasWidth/2) / this.zoom + this.centerX;
  }

  double yToData(double y){
      return (this.canvasHeight/2 - y) / this.zoom + this.centerY;
  }

  void changeZoom(double canvasX, double canvasY, double scale){
      double x = this.xToData(canvasX);
      double y = this.yToData(canvasY);
      this.zoom *= scale;
      double x1 = this.xToData(canvasX);
      double y1 = this.yToData(canvasY);
      this.centerX += x - x1;
      this.centerY += y - y1;
  }

  void setSelected(List list){
      this.selection = list;
  }

  void pan(double canvasDx,double canvasDy){
      this.centerX -= canvasDx / this.zoom;
      this.centerY += canvasDy / this.zoom;
  }

  bool handleToolEvent(Function eventFunc){
    bool handled = false;

    if (this.activeTool != null)
    {
        var r = eventFunc(this.activeTool);
        if (r ==Tool.STATUS_FINISHED)
            this.activeTool = null;
        if (r !== Tool.STATUS_SKIP)
            handled = true;
    }

    if (!handled)
    for(Tool tool in this.tools)
    {
        var r = eventFunc(tool);
        if (r == Tool.STATUS_ACTIVE)
            this.activeTool = tool;
        if (r != Tool.STATUS_SKIP)
        {
            handled = true;
            break;
        }
    }

    if (handled)
    {
        this.paint();
    }

    return handled;
  }

  void handleMouseDown(evt){
      double x = evt.offsetX.toDouble();
      double y = evt.offsetY.toDouble();

      bool handled = handleToolEvent((tool) => tool.mouseDown(x, y));
      evt.preventDefault();
  }

  void handleMouseUp(evt){
      double x = evt.offsetX.toDouble();
      double y = evt.offsetY.toDouble();
      bool handled = this.handleToolEvent((tool) => tool.mouseUp(x, y));
      evt.preventDefault();
  }

  void handleMouseMove(evt){
      double x = evt.offsetX.toDouble();
      double y = evt.offsetY.toDouble();
      int buttons = evt.which;

      //drag delay - do not react on tiny drags.
      if (buttons != 0 && this.activeTool == null && this.prevX != null)
      {
          if (Geometry.distanceSquared(this.prevX, this.prevY, x,y) < 5*5)
          {
              evt.preventDefault();
              return;
          }
      }

      bool handled = this.handleToolEvent((tool) => tool.mouseMove(x,y, this.prevX, this.prevY, evt));

      this.prevX = x;
      this.prevY = y;
      evt.preventDefault();
  }


  void handleMouseWheel(evt){
      double x = evt.offsetX.toDouble();
      double y = evt.offsetY.toDouble();
      double d = evt.wheelDeltaY.toDouble();

      this.changeZoom(x,y, pow(1.001,d));
      this.paint();
      evt.preventDefault();
  }

  void handleKeyDown(evt){
      if (evt.keyCode == 27)  //escape
      {
          if (this.activeTool != null){
              this.activeTool.cancel();
              this.activeTool = new CancelTool();
              this.paint();
          }
      }
      else if (evt.keyCode == 68 || evt.keyCode == 46)  //delete
      {
          if (this.selection.length > 0)
          {
              if (this.activeTool != null)
                  this.activeTool.cancel();
              this.activeTool = null;
              this.data.deleteItems(this.selection);
              this.paint();
          }
      }
  }
}

class CancelTool extends Tool{
  CancelTool(){}
  int mouseDown(canvasX,canvasY){return Tool.STATUS_SKIP;}
  int mouseMove(canvasX, canvasY, canvasXPrev, canvasYPrev, dragging){return (dragging != 0) ? Tool.STATUS_ACTIVE : Tool.STATUS_SKIP;}
  int mouseUp(canvasX,canvasY){return Tool.STATUS_FINISHED;}
}

class PanTool extends Tool{
  PanTool(){}
  int mouseMove(double canvasX,double  canvasY, double canvasXPrev, double canvasYPrev, MouseEvent evt){
      if (evt.which != 0)
      {
          var dx = canvasX - canvasXPrev;
          var dy = canvasY - canvasYPrev;
          //drag canvas
          this.view.pan(dx, dy);
          return Tool.STATUS_ACTIVE;
      }
  }

  int mouseUp(canvasX,canvasY){
      return Tool.STATUS_FINISHED;
  }
}
