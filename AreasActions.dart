class RemoveCrossingAction implements IAction{
  static final double RADIUS = 10.0;

  double x;
  double y;
  double cx;
  double cy;
  AreasLayer layer;
  AreasSegment segment1;
  AreasSegment segment2;

  RemoveCrossingAction(double x, double y, AreasLayer layer, AreasSegment segment1, AreasSegment segment2){
    this.x = x;
    this.y = y;
    this.layer = layer;
    this.segment1 = segment1;
    this.segment2 = segment2;
  }

  void paint(View view){
    var g = view.context;
    this.cx = view.xToCanvas(this.x);
    this.cy = view.yToCanvas(this.y);

    g.beginPath();
    g.fillStyle = "#FFF";
    g.strokeStyle = "#BBB";
    g.arc(this.cx,this.cy, RADIUS, 0,PI * 2, false);
    g.fill();
    g.stroke();
    
    var o = RADIUS / 2 - 1;
    g.beginPath();
    g.strokeStyle = "#F33";
    g.moveTo(this.cx - o, this.cy - o);
    g.lineTo(this.cx + o, this.cy + o);
    g.moveTo(this.cx - o, this.cy + o);
    g.lineTo(this.cx + o, this.cy - o);
    g.stroke();
  }

  bool hit(View view, double canvasX, double canvasY)
  {
    return Geometry.distanceSquared(this.cx, this.cy, canvasX, canvasY) < RADIUS*RADIUS;
  }

  void mouseMove(View view, double canvasX, double canvasY){
    this.layer.view.setSelected([]);
  }

  void click(View view, double canvasX, double canvasY){
    //perform the merging
    AreasPoint p = this.layer.data.newPoint(this.x, this.y);
    this.layer.data.splitSegment(this.segment1, p);
    this.layer.data.splitSegment(this.segment2, p);
    this.layer.update();
  }
}
