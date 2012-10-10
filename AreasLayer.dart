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

  
  void paintArea(AreasArea a, bool selected)
  {
    var context = view.context;
    context.beginPath();
    AreasPoint p = a.startPoint();
    var x = view.xToCanvas(p.x);
    var y = view.yToCanvas(p.y);
    context.moveTo(x, y);

    for (AreasSegment seg in a.segments)
    {
      p = seg.otherEnd(p);
      x = view.xToCanvas(p.x);
      y = view.yToCanvas(p.y);
      context.lineTo(x, y);
    }
    
    if (selected)
      context.fillStyle='#FFC';
    else
      context.fillStyle='#CFC';
    context.fill();
  }
  
  void paint(){
    var context = view.context;
    List selection = view.selection;

    context.font="20px Arial";

    
    for (AreasArea a in this.data.areas)
    {
      if (selection.indexOf(a) == -1)
        this.paintArea(a, false);
    }
    
    for (AreasArea a in this.data.areas)
    {
      if (selection.indexOf(a) != -1)
        this.paintArea(a, true);
    }
    
    if (view.debug)
    {
        
      for (AreasArea a in this.data.areas)
      {
        AreasPoint p = a.startPoint();
        var centerX = 0.0;
        var centerY = 0.0;
        var count = a.segments.length;
        
        if  (!a.isClosed())
        {
          centerX += view.xToCanvas(p.x);
          centerY += view.yToCanvas(p.y);
          count ++;
       }
        
        for (AreasSegment seg in a.segments)
        {
           p = seg.otherEnd(p);
           centerX += view.xToCanvas(p.x);
           centerY += view.yToCanvas(p.y);
        }
        
        centerX /= count;
        centerY /= count;        
        context.fillStyle="#D0D";
        context.fillText("${a.id}", centerX, centerY);        
      }
    }
    
    for (AreasSegment s in this.data.segments){
        context.beginPath();
        var x0 = view.xToCanvas(s.p0.x);
        var y0 = view.yToCanvas(s.p0.y);
        var x1 = view.xToCanvas(s.p1.x);
        var y1 = view.yToCanvas(s.p1.y);
        context.moveTo(x0,y0);
        context.lineTo(x1, y1);

        context.lineWidth = 2;
        if (selection.indexOf(s) != -1)
            context.strokeStyle='#F33';
        else
            context.strokeStyle='#666666';
        context.stroke();

        if (view.debug)
        {
          context.fillStyle="#000";
          context.fillText("${s.id}", (x0+x1)/2, (y0+y1)/2-20);
          
          /*
          if (s0 != null && s0.p1 == s.p0){
            var angle = Geometry.angleBetweenVectors(s.p0.x - s0.p0.x, s.p0.y - s0.p0.y, s.p1.x - s.p0.x, s.p1.y-s.p0.y);
            
            context.fillText("${angle}", x0 + 20, y0);
          }*/
        }
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
        
        if (view.debug)
        {
          context.fillStyle="#000";
          context.fillText("${p.id}", x-5, y-20);
        }
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


  AreasArea findArea(double canvasX, double canvasY){
      double treshold = 7/this.view.zoom;
      double x = this.view.xToData(canvasX);
      double y = this.view.yToData(canvasY);
      AreasArea best = null;

      for (AreasArea area in this.data.areas){

        //find top
        var p = area.startPoint();
        double y0 = p.y;
        for(AreasSegment s in area.segments)
        {
          p = s.otherEnd(p);
          y0 = min(y0, p.y);
        }

        y0 -= treshold;
        if (y < y0) continue;

        //count intersections betwen x,y->x,y0
        
        int intersections = 0;
        for (AreasSegment seg in area.segments)
        {
          var intersection = Geometry.intersection(x, y, x, y0, seg.p0.x, seg.p0.y, seg.p1.x,seg.p1.y);
          if (intersection != null) intersections += 1;
        }
        
        if (intersections %2 == 1)
        {
          return area;
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
