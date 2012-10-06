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
  /// Undo, redo
  ///

  void toOsm(){
  }

  void fromOsm(){
  }

  void undo(){
    this.cancelChanges();
    
    if (this.undo_stack.length > 0)
    {
      var undo = this.undo_stack.removeLast();
      var redo = this._revertChanges(undo);
      this.redo_stack.add(redo);
    }
    
    //TODO: update crossings.
    
    this.check();
  }

  void redo(){
    this.cancelChanges();
    
    if (this.redo_stack.length > 0)
    {
      var redo = this.redo_stack.removeLast();
      var undo = this._revertChanges(redo);
      this.undo_stack.add(undo);
    }
    
    //TODO: update crossings.
    
    this.check();
  }
  
  void commitChanges(){
    //Update areas
    this._updateAreasAfterEdit(this.current_action);
    
    //commit
    this.redo_stack.clear();
    this.undo_stack.add(this.current_action);
    this.current_action = new AreasChange();

    //update crossings
    //TODO:
    
    this.check();
  }
  
  void cancelChanges()
  {
    this._revertChanges(this.current_action);
    this.current_action = new AreasChange();

    //update crossings
    //TODO:
    
    this.check();
  }

  AreasChange _revertChanges(AreasChange change)
  {
    AreasChange redo = new AreasChange();
       
    //points first
    for(AreasPoint p in change.changedPoints.getKeys())
    {
      redo.modifiedPoint(p);
      change.restorePoint(p);
    }
    
    for(AreasPoint p in change.deletedPoints)
    {
      this.points.add(p);
      redo.newPoints.add(p);
    }
    
    for(AreasPoint p in change.newPoints)
    {
      redo.deletedPoint(p);
      this.points.removeRange(this.points.indexOf(p), 1);
    }
    
    //then lines
    for(AreasSegment l in change.changedSegments.getKeys())
    {
      redo.modifiedSegment(l);
      change.restoreSegment(l);
    }
    
    for(AreasSegment l in change.deletedSegments)
    {
      this.segments.add(l);
      redo.newSegments.add(l);
    }
    
    for(AreasSegment l in change.newSegments)
    {
      redo.deletedSegment(l);
      this.segments.removeRange(this.segments.indexOf(l), 1);
    }
    
    //areas last
    for(AreasArea l in change.changedAreas.getKeys())
    {
      redo.modifiedArea(l);
      change.restoreArea(l);
    }
    
    for(AreasArea l in change.deletedAreas)
    {
      this.areas.add(l);
      redo.newAreas.add(l);
    }
    
    for(AreasArea l in change.newAreas)
    {
      redo.deletedArea(l);
      this.areas.removeRange(this.areas.indexOf(l), 1);
    }
    
    return redo;
  }

  void check()
  {
    for(AreasPoint p in this.points)
    {
      var i0 = this.points.indexOf(p);
      assert(this.points.indexOf(p, i0 + 1) == -1);
      
      for( var seg in p.segments)
      {
        assert(this.segments.indexOf(seg) != -1);
        
        assert(seg.p0 == p || seg.p1 == p);
      }
    }
    
    for(AreasSegment s in this.segments)
    {
      var i0 = this.segments.indexOf(s);
      assert(this.segments.indexOf(s, i0 + 1) == -1);
      
      assert(this.points.indexOf(s.p0) != -1);
      assert(this.points.indexOf(s.p1) != -1);
      
      for(var area in s.areas)
      {
        assert(this.areas.indexOf(area) != -1);  
        assert(area.segments.indexOf(s) != -1);
      }
    }
    
    for(AreasArea a in this.areas)
    {
      var i0 = this.areas.indexOf(a);
      assert(this.areas.indexOf(a, i0 + 1) == -1);
      
      assert(this.points.indexOf(a.start) != -1);
      assert(a.segments.length > 0);
      assert(a.segments[0].p0 == a.start || a.segments[0].p1 == a.start);
      
      for(var seg in a.segments)
      {
        assert(this.segments.indexOf(seg) != -1);
      }
    }
    
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


  AreasArea newArea(AreasPoint startingPoint, List<AreasSegment> segments)
  {
    var area = new AreasArea(this.nextId++, startingPoint, segments);

    for(var seg in segments)
    {
      this.current_action.modifiedSegment(seg);
      seg.areas.add(area);
    }

    this.current_action.newAreas.add(area);
    this.areas.add(area);
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
    
    this.current_action.modifiedPoint(p0);
    this.current_action.modifiedPoint(p1);

    this.segments.removeRange(i,1);
    segment.disconnect();

    if (p0.segments.length == 0)
        this.removePoint(p0);
    if (p1.segments.length == 0)
        this.removePoint(p1);
  }
  
  void removeArea(AreasArea area)
  {
    this.current_action.deletedArea(area); //makrs segments as modified
    area.disconnect(); //removes area from segments
    this.areas.removeRange(this.areas.indexOf(area), 1);
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
    
    this.current_action.modifiedPoint(p0);
    this.current_action.modifiedPoint(p1);

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
            this._mergeParralelSegments(neighborSegments[segI], s);
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
            seg1.areas.add(area);
            i++;
          }
          else if (ap0 == s.p1)
          {
            //insert before
            area.segments.insertRange(i, 1, seg1);
            seg1.areas.add(area);
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
  
  void _updateAreasAfterEdit(AreasChange changes)
  {
     var segsToCheck = new List.from(changes.newSegments);
     segsToCheck.addAll(changes.changedSegments.getKeys());

     for(AreasSegment seg in segsToCheck)
     {
       //TODO: dumb code here
       
       var areaSegs = AreasProcessing.findAreaClockwise(seg.p0, seg);
       if (areaSegs != null)
         AreasProcessing.tryNewArea(this, seg.p0, areaSegs);

       areaSegs = AreasProcessing.findAreaClockwise(seg.p1, seg);
       if (areaSegs != null)
         AreasProcessing.tryNewArea(this, seg.p1, areaSegs);
     }
     
     
     //delete trivial areas
     for(int i = 0; i < this.areas.length; i ++)
     {
       var a = this.areas[i];
       if (a.segments.length < 3)
       {
         this.removeArea(a);
         i --;
       }       
     }
    
  }
  

  void _mergeParralelSegments(AreasSegment s1, AreasSegment s2)
  {
    assert(s1.otherEnd(s1.p0) == s2.otherEnd(s1.p0));
   
    this.current_action.modifiedSegment(s1);
    this.current_action.modifiedSegment(s2);
    
    //merge areas
    while (s2.areas.length > 0)
    {
      AreasArea a = s2.areas[s2.areas.length - 1];
      this.current_action.modifiedArea(a);
      a.replaceSegment(s2,s1);
    }
    
    //TODO: merge tags
    this.removeSegment(s2);
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
    this.areas = [];
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
    //this possiby makes the area invalid - need to run updateAreas afterwards.
    
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

  void restorePoint(AreasPoint p)
  {
    assert(this.changedPoints.containsKey(p));
    AreasPoint copy = this.changedPoints[p];
    p.x = copy.x;
    p.y = copy.y;
    p.segments = new List.from(copy.segments);
  }

  
  void modifiedSegment(AreasSegment s)
  {
    if (this.changedSegments.containsKey(s))
      return;
   
    AreasSegment copy = new AreasSegment(s.id, s.p0, s.p1);
    copy.areas = new List.from(s.areas);
   
    this.changedSegments[s] = copy;
  }

  void restoreSegment(AreasSegment s)
  {
    assert(this.changedSegments.containsKey(s));
    
    AreasSegment copy = this.changedSegments[s];
    s.p0 = copy.p0;
    s.p1 = copy.p1;
    s.areas = new List.from(copy.areas);
  }

  void modifiedArea(AreasArea a)
  {
    if (this.changedAreas.containsKey(a))
      return;
   
    AreasArea copy = new AreasArea(a.id, a.start,new List.from(a.segments));  
    this.changedAreas[a] = copy;
  }

  void restoreArea(AreasArea a)
  {
    assert(this.changedAreas.containsKey(a));
    AreasArea copy = this.changedAreas[a];
    a.start = copy.start;
    a.segments = new List.from(copy.segments);  
  }

  void deletedPoint(AreasPoint p)
  {
    if (this.deletedPoints.indexOf(p) == -1)
    {
      if (this.newPoints.indexOf(p) != -1)
      {
        this.newPoints.removeRange(this.newPoints.indexOf(p), 1);
      }
      else
      {
        this.deletedPoints.add(p);
      }
    }

    this.modifiedPoint(p);
  }
  
  
  void deletedSegment(AreasSegment s)
  {
    if (this.deletedSegments.indexOf(s) == -1)
    {
      if (this.newSegments.indexOf(s) != -1)
      {
        this.newSegments.removeRange(this.newSegments.indexOf(s), 1);
      }
      else
      {
        this.deletedSegments.add(s);
      }
    }

    this.modifiedSegment(s);
    this.modifiedPoint(s.p0);
    this.modifiedPoint(s.p1);
  }

  void deletedArea(AreasArea a)
  {
    if (this.deletedAreas.indexOf(a) == -1)
    {
      if (this.newAreas.indexOf(a) != -1)
      {
        this.newAreas.removeRange(this.newAreas.indexOf(a), 1);
      }
      else
      {
        this.deletedAreas.add(a);
      }
    }
    
    this.modifiedArea(a);
    
    for (var seg in a.segments)
    {
      this.modifiedSegment(seg);
    }
  }

}