class AreasLayer {
  AreasData data;
  View view;
  List<IAction> actions;
  ActionsTool actionsTool;

  AreasLayer(AreasData data)
  {
    this.data = data;
    this.view = null;
    this.actions = [];
    this.actionsTool = new ActionsTool(this);
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
        context.arc(x,y,5, 0, 2*PI, false);

        if (selection.indexOf(p) != -1)
            context.fillStyle='#F33';
        else
            context.fillStyle='#666666';
        context.fill();
    }
    
    for (AreasArea a in this.data.areas)
    {
      context.beginPath();
      AreasPoint p = a.start;
      context.moveTo(view.xToCanvas(p.x), view.yToCanvas(p.y));
      
      for (AreasSegment seg in a.segments)
      {
         p = seg.otherEnd(p);
         context.lineTo(view.xToCanvas(p.x), view.yToCanvas(p.y));
      }
      
      context.fillStyle='#CFC';
      context.fill();
    }
    
    for (IAction action in this.actions){
      action.paint(this.view);
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

  void update()
  {
    this.actions = [];

    //Crossings
    for (int pos1 = 0; pos1 < this.data.segments.length; pos1 ++){
      for (int pos2 = pos1+1; pos2 < this.data.segments.length; pos2 ++){
        AreasSegment s1 = this.data.segments[pos1];
        AreasSegment s2 = this.data.segments[pos2];

        if (s1.sharesPointWith(s2)) continue;
        Intersection i = Geometry.intersection(s1.p0.x,s1.p0.y, s1.p1.x,s1.p1.y, s2.p0.x,s2.p0.y, s2.p1.x,s2.p1.y);
        if (i != null){
          this.actions.add(new RemoveCrossingAction(i.x, i.y, this, s1, s2));
        }
      }
    }
  }
}
