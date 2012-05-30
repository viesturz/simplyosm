class RemoveCrossingAction implements IAction{
  static final int RADIUS = 10;

  double x;
  double y;
  double cx;
  double cy;
  AreasData data;
  AreasSegment segment1;
  AreasSegment segment2;

  RemoveCrossingAction(double x, double y, AreasData data, AreasSegment segment1, AreasSegment segment2){
    this.x = x;
    this.y = y;
    this.data = data;
    this.segment1 = segment1;
    this.segment2 = segment2;
  }

  void paint(View view){
    var g = view.context;
    this.cx = view.xToCanvas(this.x);
    this.cy = view.xToCanvas(this.y);

    g.setFillColor(255, 120, 120, 100);
    g.arc(this.cx,this.cy, RADIUS, 0,Math.PI * 2, false);
  }

  bool hit(View view, double canvasX, double canvasY)
  {
    return Geometry.distanceSquared(this.cx, this.cy, canvasX, canvasY) < RADIUS*RADIUS;
  }

  int mouseMove(View view, double canvasX, double canvasY){
    if (this.hit(view, canvasX, canvasY))
      return IAction.STATUS_ACTIVE;
    return IAction.STATUS_SKIP;
  }

  int click(View view, double canvasX, double canvasY){
    if (!this.hit(view, canvasX, canvasY))
      return IAction.STATUS_SKIP;

    //perform the merging
    AreasPoint p = this.data.newPoint(this.x, this.y);
    this.data.splitSegment(this.segment1, p);
    this.data.splitSegment(this.segment2, p);
    return IAction.STATUS_FINISHED;
  }
}
