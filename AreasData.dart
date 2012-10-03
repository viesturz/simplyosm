class AreasData implements IData {
  List<AreasPoint> points;
  List<AreasSegment> segments;
  List<AreasArea> areas;
  int nextId;
  
  List<AreasChange> undo_stack;
  List<AreasChange> redo_stack;
  AreasChange current_action;

  AreasData()
  {
    this.points = [];
    this.segments = [];
    this.areas = [];
    this.nextId = 0;

    this.undo_stack = [];
    this.redo_stack = [];
    this.current_action = new AreasChange();
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

  
  void commitChanges(){
    //Update areas
    //TODO:
    
    //update crossings
    //TODO:
    
    this.undo_stack.add(this.current_action);
    this.current_action = new AreasChange();
  }

  
  AreasPoint newPoint(double x, double y){
    var p = new AreasPoint(this.nextId ++, x, y);
    this.points.add(p);
    this.current_action.newPoints.add(p);
    return p;
  }

  AreasSegment newSegment(AreasPoint p0, AreasPoint p1){
    this.current_action.modifiedPoint(p0);
    this.current_action.modifiedPoint(p1);
    
    AreasSegment s = new AreasSegment(this.nextId++, p0, p1);
    p0.segments.add(s);
    p1.segments.add(s);
    
    this.current_action.newSegments.add(s);
    this.segments.add(s);    
    return s;
  }
  
  void removePoint(AreasPoint p){
    var i = this.points.indexOf(p);
    if (i == -1)
        return;

    this.current_action.deletedPoint(p);
    
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
    
    this.current_action.deletedSegment(segment);
    
    //reconnect areas
    while (segment.areas.length > 0)
    {
      AreasArea a = segment.areas[segment.areas.length -1];
      this.current_action.modifiedArea(a);
      a.removeSegment(segment);
    }

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
    this.current_action.modifiedPoint(p);
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

        //reconnect the segment, this sould be fine with areas after removing the connecting segment (if any).
        this.current_action.modifiedSegment(s);
        s._changeEnd(p1, p0);

        if (segI != -1)
        {
            //Segment exists from both p0 and p1 to the same point, merge them.
            this._mergeSegments(neighborSegments[segI], s);
        }
        else
        {   //keep the segment, add to neighbors
            neighborPoints.add(pp);
            neighborSegments.add(s);
        }
    }

    this.removePoint(p1);

    return p0;
  }

  AreasSegment joinSegments(AreasSegment s1, AreasPoint via, AreasSegment s2){
    this.current_action.modifiedSegment(s1);
    
    //update areas
    for (var area in s2.areas)
    {
      var ap0 = area.start;
      for(int i = 0; i < area.segments.length; i ++) 
      {
        var s = area.segments[i];
        
        if (s == s2)
        {
          this.current_action.modifiedArea(area);
          area.segments.removeRange(i,1);
          i --;
        }
        
        ap0 = s.otherEnd(ap0);
      }
    }
        
    //TODO: merge tags
    s1._changeEnd(via, s2.otherEnd(via));
    this.removeSegment(s2);
    return s1;
  }

  AreasSegment splitSegment(AreasSegment segment, AreasPoint point){
    var p1 = segment.p1;
    var seg1 = this.newSegment(point, p1);

    this.current_action.modifiedSegment(segment);
    
    //update areas
    for (var area in segment.areas)
    {
      this.current_action.modifiedArea(area);
      
      var ap0 = area.start;
      for(int i = 0; i < area.segments.length; i ++) 
      {
        var s = area.segments[i];
        
        if (s == segment)
        {
          if (ap0 == s.p0)
          {
            //insert after
            area.segments.insertRange(i+1, 1, seg1);
          }
          else if (ap0 == s.p1)
          {
            //insert before
            area.segments.insertRange(i, 1, seg1);
            i ++;
          }
          else
          {
            assert(false);
          }
        }
        
        ap0 = s.otherEnd(ap0);
      }
    }
    
    segment._changeEnd(p1, point);
    
    return seg1;
  }
  
  ///
  /// Getters
  ///

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
  /// Private stuff
  ///
  
  void _mergeSegments(AreasSegment s1, AreasSegment s2){
    assert(s1.otherEnd(s1.p0) == s2.otherEnd(s1.p0));
   
    //merge areas
    while (s2.areas.length > 0)
    {
      AreasArea a = s2.areas[s2.areas.length];
      this.current_action.modifiedArea(a);
      a.replaceSegment(s2,s1);
    }
    
    //TODO: merge tags
    this.removeSegment(s2);
  }
  
  AreasSegment _getRightmostSegment(AreasSegment seg, AreasPoint p)
  {
    AreasSegment result = null;
    
    for (AreasSegment s in p.segments)
    {
      if (s == seg) continue;
      if (result == null)
      {
        result = s;
      }
      else
      {
        var pr = result.otherEnd(p);
        var ps = s.otherEnd(p);
        if (!Geometry.isToTheLeft(p.x, p.y, pr.x, pr.y, ps.x, ps.y))
        {
          result = s;
        }
      }
    }
      
    if (result == null) result = seg;
    return result;
  }
  
  List<AreasSegment> _findAreaClockwise(AreasSegment start, AreasPoint fromp)
  {
    List<AreasSegment> result = [];
    List<AreasPoint> pts = [];
    var startp = start.otherEnd(fromp);
    var cur = start;
    var curp = startp;
    result.add(cur);
    pts.add(curp);
    
    var next = _getRightmostSegment(cur, curp);
    var nextp = next.otherEnd(curp);

    while (next != start || nextp != startp)
    {
      //test if there is a bad loop
      for (int i = 0; i < result.length; i++)
      {
        if (next == result[i] && nextp == pts[i])
        {
          return null;
        }
      }
      
      cur = next;
      curp = nextp;

      result.add(cur);
      pts.add(curp);
      
            
      next = _getRightmostSegment(cur, curp);
      nextp = next.otherEnd(curp);
    }
        
    return result;
  }
  
  void _tryNewArea(var startingPoint, List<AreasSegment> segments)
  {
    //check if this is outer shape
    double angle = 0.0;
    
    var p0 = null;
    var p1 = segments[segments.length - 1].otherEnd(startingPoint);
    var p2 = startingPoint;
    for (var seg in segments)
    {
      p0 = p1;
      p1 = p2;
      p2 = seg.otherEnd(p1);
      
      angle += Geometry.angleBetweenVectors(p1.x-p0.x,p1.y-p1.y, p2.x-p1.x, p2.y - p1.y);     
    }
    
    //the shape should go clockwise, counterclockwise means outer shape
    if (angle <= 0)
      return;
    

    //check if such shape already exists
    var commonShapes = [];
    commonShapes.addAll(segments[0].areas);

    for (var seg in segments)
    {
      commonShapes.filter((x) => seg.areas.indexOf(x) != -1);  
    }
    
    if (commonShapes.length > 0)
      return;
    
    //add new area
    var area = new AreasArea(this.nextId++, startingPoint, segments);
    
    for(var seg in segments)
    {
      this.current_action.modifiedSegment(seg);
      seg.areas.add(area);
    }

    this.current_action.newAreas.add(area);
    this.areas.add(area);
  }
}


class AreasPoint implements Hashable{
  int id;
  double x;
  double y;
  List<AreasSegment> segments;

  AreasPoint(int id, double x, double y){
    this.id = id;
    this.x = x;
    this.y = y;
    this.segments = [];
  }
  
  int hashCode() => this.id;
}

class AreasSegment implements Hashable{
  int id;
  AreasPoint p0;
  AreasPoint p1;
  List<AreasArea> areas;

  AreasSegment(int id, AreasPoint p0, AreasPoint p1){
    assert(p0 != p1);
    this.id = id;
    this.p0 = p0;
    this.p1 = p1;
  }
  
  int hashCode()
  {
    return this.id;
  }
 

  AreasPoint otherEnd(AreasPoint p){
      if (p == this.p0)
        return this.p1;
      if (p == this.p1)
          return this.p0;
      assert(false);
  }
  
  AreasPoint commonPoint(AreasSegment s){
    if (this.p0 == s.p0 || this.p0 == s.p1)
      return this.p0;
    if (this.p1 == s.p0 || this.p1 == s.p1)
      return this.p1;
    assert(false);
  }
  
  void _changeEnd(AreasPoint from, AreasPoint to){
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


class AreasArea implements Hashable{
  int id;
  AreasPoint start;
  List<AreasSegment> segments;

  AreasArea(int id, AreasPoint start, List<AreasSegment> segments)
  {
    this.id = id;
    this.start = start;
    this.segments = segments;
  }
  
  int hashCode() => this.id;
  
  void disconnect()
  {
    for(var seg in this.segments)
    {
      var pos = seg.areas.indexOf(this);
      seg.areas.removeRange(pos, 1);
    }
  }
  
  void removeSegment(AreasSegment segment)
  {
    //TODO: this possiby makes the area invalid - there is a breaking.
    
    for(int i = 0; i < this.segments.length; i ++)
    {
      var seg = this.segments[i];
      if (seg == segment)
      {
         this.segments.removeRange(i,1);
         i --;
      }
    }
    
    int i = 0;
    while ((i = segment.areas.indexOf(this, 0)) != -1){
      segment.areas.removeRange(i, 1);
    }
  }
  
  void replaceSegment(AreasSegment from, AreasSegment to)
  {
    assert(to.otherEnd(to.p0) == from.otherEnd(to.p0));
    
    for(int i = 0; i < this.segments.length; i ++)
    {
      var seg = this.segments[i];
      if (seg == from)
      {
         this.segments[i] = to;
         to.areas.add(this);
      }
    }
    
    int i = 0;
    while ((i = from.areas.indexOf(this, 0)) != -1){
      from.areas.removeRange(i, 1);
    }
  }
}

class AreasChange{
  Map<AreasPoint, AreasPoint> changedPoints = new Map<AreasPoint, AreasPoint>();
  List<AreasPoint> newPoints = [];
  List<AreasPoint> deletedPoints = [];
  
  Map<AreasSegment, AreasSegment> changedSegments = new Map<AreasSegment, AreasSegment>();
  List<AreasSegment> newSegments = [];
  List<AreasSegment> deletedSegments = [];
  
  Map<AreasArea, AreasArea> changedAreas = new Map<AreasArea, AreasArea>();
  List<AreasArea> newAreas = [];
  List<AreasArea> deletedAreas = [];
 
  void modifiedPoint(AreasPoint p)
  {
    if (this.changedPoints.containsKey(p))
      return;
   
    AreasPoint copy = new AreasPoint(p.id, p.x, p.y);
    copy.segments = new List.from(p.segments);
   
    this.changedPoints[p] = copy;
  }
  
  void modifiedSegment(AreasSegment s)
  {
    if (this.changedSegments.containsKey(s))
      return;
   
    AreasSegment copy = new AreasSegment(s.id, s.p0, s.p1);
    copy.areas = new List.from(s.areas);
   
    this.changedSegments[s] = copy;
  }
  
  void modifiedArea(AreasArea a)
  {
    if (this.changedAreas.containsKey(a))
      return;
   
    AreasArea copy = new AreasArea(a.id, a.start,new List.from(a.segments));  
    this.changedAreas[a] = copy;
  }
 
  void deletedPoint(AreasPoint p)
  {
    if (this.deletedPoints.indexOf(p) != -1)
    {
      this.deletedPoints.add(p);
    }

    this.modifiedPoint(p);
  }
  
  
  void deletedSegment(AreasSegment s)
  {
    if (this.deletedSegments.indexOf(s) != -1)
    {
      this.deletedSegments.add(s);
    }

    this.modifiedSegment(s);
    this.modifiedPoint(s.p0);
    this.modifiedPoint(s.p1);
  }

}