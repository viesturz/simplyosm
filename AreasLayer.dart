class AreasLayer {
  AreasData data;
  View view;

  AreasLayer(AreasData data)
  {
    this.data = data;
    this.view = null;
  }

  void attach(View _view){
    this.view = _view;
  }

  void paint(){
    var context = view.context;
    List selection = view.selection;

    for (AreasSegment s in this.data.segments){
        context.beginPath();
        context.moveTo(view.xToCanvas(s.p0.x),view.yToCanvas(s.p0.y));
        context.lineTo(view.xToCanvas(s.p1.x),view.yToCanvas(s.p1.y));

        context.lineWidth = 2;
        if (selection.indexOf(s) != -1)
            context.strokeStyle='#F33';
        else
            context.strokeStyle='#666666';
        context.stroke();
    }

    for (AreasPoint p in this.data.points){
        double x = view.xToCanvas(p.x);
        double y = view.yToCanvas(p.y);
        context.beginPath();
        context.arc(x,y,5, 0, 2*Math.PI, false);

        if (selection.indexOf(p) != -1)
            context.fillStyle='#F33';
        else
            context.fillStyle='#666666';
        context.fill();
    }
  }

  AreasPoint findPoint(double canvasX, double  canvasY, [AreasPoint ignoreThis]){
    double treshold = 7/this.view.zoom;
    double x = this.view.xToData(canvasX);
    double y = this.view.yToData(canvasY);

    treshold *= treshold;
    if (ignoreThis != null)
      treshold *= 4;

    AreasPoint best = null;
    double bestd = treshold;

    for (AreasPoint p in this.data.points){
        if (p == ignoreThis)
            continue;

        double ds = Geometry.distanceSquared(p.x, p.y, x, y);
        if (ds < bestd)
        {
            bestd = ds;
            best = p;
        }
    }

    return best;
  }

  Intersection findSegment(double canvasX, double canvasY, [AreasPoint ignoreThis]){
      double treshold = 7/this.view.zoom;
      double x = this.view.xToData(canvasX);
      double y = this.view.yToData(canvasY);

      Intersection best = null;

      for (AreasSegment seg in this.data.segments){
        if (ignoreThis != null && ignoreThis.segments.indexOf(seg) != -1)
              continue;

        Intersection dst = Geometry.distanceToSegment(seg.p0.x, seg.p0.y, seg.p1.x, seg.p1.y, x, y);

        if (dst.distance < treshold)
        {
          if (best == null || best.distance > dst.distance){
             best = dst;
             best.item = seg;
          }
        }
      }

      return best;
  }
}
