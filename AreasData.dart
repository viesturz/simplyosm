class AreasData implements IData {
  List<AreasPoint> points;
  List<AreasSegment> segments;
  List<AreasArea> areas;

  List<Object> undo_stack;
  List<Object> redo_stack;
  Object current_action;

  AreasData()
  {
    this.points = [];
    this.segments = [];
    this.areas = [];

    this.undo_stack = [];
    this.redo_stack = [];
    this.current_action = null;
  }

  AreasPoint newPoint(double x, double y){
    var p = new AreasPoint(x, y);
    this.points.add(p);
    return p;
  }

  AreasSegment newSegment(AreasPoint p0, AreasPoint p1){
    AreasSegment l = new AreasSegment(p0, p1);
    this.segments.add(l);
    return l;
  }

  void removePoint(AreasPoint p){
    var i = this.points.indexOf(p);
    if (i == -1)
        return;

    if (p.segments.length == 2){
        //merge neighbor segments
        var s1 = p.segments[0];
        var s2 = p.segments[1];
        this.joinSegments(s1, p, s2);
    }
    else
    {
        while (p.segments.length > 0){
            this.removeSegment(p.segments[p.segments.length - 1]);
        }
    }

    i = this.points.indexOf(p);
    if (i != -1)
        this.points.removeRange(i,1);
  }

  void removeSegment(AreasSegment segment){
    var i = this.segments.indexOf(segment);
    if (i == -1)
        return;

    var p0 = segment.p0;
    var p1 = segment.p1;

    this.segments.removeRange(i,1);
    segment.disconnect();

    if (p0.segments.length == 0)
        this.removePoint(p0);
    if (p1.segments.length == 0)
        this.removePoint(p1);
  }

  void deleteItems(List<Object> itemList){

    //first remove segments
    for(var i = 0; i < itemList.length; i ++){
        if (itemList[i] is AreasSegment){
            this.removeSegment(itemList[i]);
        }
    }

    //now remove points, otherwise segments will be affected by removed points
    for(var i = 0; i < itemList.length; i ++){
        if (itemList[i] is AreasPoint){
            this.removePoint(itemList[i]);
        }
    }
  }

  void movePoint(AreasPoint p, double x, double y){
    p.x = x;
    p.y = y;
  }

  AreasPoint mergePoints(AreasPoint p0, AreasPoint p1){
    assert(p0 != p1);

    //remove direct segments
    for (var i = 0; i < p1.segments.length; i ++){

        var s = p1.segments[i];
        var pp = s.otherEnd(p1);
        if (pp == p0){
            this.removeSegment(s);
            i --;
        }
    }

    var neighborPoints = [];
    var neighborSegments = [];

    //collect neighbor points of p0;
    for (var i = 0; i < p0.segments.length; i ++){
        neighborPoints.add(p0.segments[i].otherEnd(p0));
        neighborSegments.add(p0.segments[i]);
    }


    //merge remaining segments
    while (p1.segments.length > 0){
        var s = p1.segments[p1.segments.length - 1];
        var pp = s.otherEnd(p1);
        var segI = neighborPoints.indexOf(pp);

        s.changeEnd(p1, p0);

        if (segI != -1)
        {
            this._mergeSegments(neighborSegments[segI], s);
        }
        else
        {
            neighborPoints.add(pp);
            neighborSegments.add(s);
        }
    }

    this.removePoint(p1);

    return p0;
  }

  AreasSegment joinSegments(AreasSegment s1, AreasPoint via, AreasSegment s2){
    //TODO: merge tags
    s1.changeEnd(via, s2.otherEnd(via));
    this.removeSegment(s2);
    return s1;
  }

   void _mergeSegments(AreasSegment s1, AreasSegment s2){
     assert(s1.otherEnd(s1.p0) == s2.otherEnd(s1.p0));
    //TODO: merge tags
    this.removeSegment(s2);
  }

  AreasSegment splitSegment(AreasSegment segment, AreasPoint point){
    var seg1 = this.newSegment(segment.p1, point);
    segment.changeEnd(segment.p1, point);
    return seg1;
  }

  List<AreasSegment> getLineSegments(AreasSegment seg){
    var result = [seg];

    var s = seg;
    var p = seg.p0;

    while(p.segments.length == 2){
        if (p.segments[0] == s)
        {
            s = p.segments[1];
        }
        else
        {
            s = p.segments[0];
        }

        p = s.otherEnd(p);

        //prevent infinite loops
        if (result.indexOf(s) != -1)
            break;
        result.add(s);
    }

    s = seg;
    p = seg.p1;


    while(p.segments.length == 2){
        if (p.segments[0] == s)
        {
            s = p.segments[1];
        }
        else
        {
            s = p.segments[0];
        }

        p = s.otherEnd(p);

        //prevent infinite loops
        if (result.indexOf(s) != -1)
            break;

        result.add(s);
    }

    return result;
  }


  ///
  /// Undo, redo - TODO:
  ///

  void undo(){
  }

  void redo(){
  }

  void toOsm(){
  }

  void fromOsm(){

  }




}


class AreasPoint{
  double x;
  double y;
  List<AreasSegment> segments;

  AreasPoint(double x, double y){
    this.x = x;
    this.y = y;
    this.segments = [];
  }
}

class AreasSegment{
  AreasPoint p0;
  AreasPoint p1;

  AreasSegment(AreasPoint p0, AreasPoint p1){
    assert(p0 != p1);
    this.p0 = p0;
    this.p1 = p1;
    this.p0.segments.add(this);
    this.p1.segments.add(this);
  }

  AreasPoint otherEnd(AreasPoint p){
      if (p == this.p0)
        return this.p1;
      if (p == this.p1)
          return this.p0;
      assert(false);
  }

  void changeEnd(AreasPoint from, AreasPoint to){
      if (from == this.p0)
      {
          var pos = this.p0.segments.indexOf(this);
          this.p0.segments.removeRange(pos, 1);
          this.p0 = to;
          this.p0.segments.add(this);
      }
      else if (from == this.p1)
      {
          var pos = this.p1.segments.indexOf(this);
          this.p1.segments.removeRange(pos, 1);
          this.p1 = to;
          this.p1.segments.add(this);
      }
      else
      {
          assert(false);
      }
  }

  void disconnect(){
      var pos = this.p0.segments.indexOf(this);
      this.p0.segments.removeRange(pos, 1);
      pos = this.p1.segments.indexOf(this);
      this.p1.segments.removeRange(pos, 1);
  }

  bool sharesPointWith(AreasSegment s1){
    return this.p0 == s1.p0 || this.p0 == s1.p1 || this.p1 == s1.p0 || this.p1 == s1.p1;
  }
}


class AreasArea{
  List<AreasSegment> segments;

  //TODO:
}

