

class AreasProcessing {
    AreasProcessing() {
    }

  static AreasSegment getRightmostSegment(AreasSegment from, AreasPoint p)
  {
    AreasSegment result = null;
    var p0 = from.otherEnd(p);

    for (AreasSegment s in p.segments)
    {
      if (s == from) continue;
      if (result == null)
      {
        result = s;
      }
      else
      {
        var ps = s.otherEnd(p);
        var pr = result.otherEnd(p);

        bool toRight;
        if (Geometry.isLeftToRight(p0.x,p0.y, p.x, p.y, ps.x, ps.y))
        {//ps to the right of from direction
          toRight = !Geometry.isLeftToRight(p0.x, p0.y, p.x, p.y, pr.x, pr.y) ||
          Geometry.isLeftToRight(p.x,p.y, pr.x, pr.y, ps.x, ps.y);
        }
        else
        {//ps straight or to the left of from direction
          toRight = Geometry.isLeftToRight(p0.x, p0.y, pr.x, pr.y, p.x, p.y) &&
          Geometry.isLeftToRight(p.x, p.y, pr.x, pr.y, ps.x, ps.y);
        }

        if (toRight)
        {
          result = s;
        }
      }
    }

    if (result == null) result = from;
    return result;
  }

  static List<AreasSegment> findAreaClockwise(AreasPoint fromp, AreasSegment start)
  {
    List<AreasSegment> result = [];
    List<AreasPoint> pts = [];
    var startp = start.otherEnd(fromp);
    var cur = start;
    var curp = startp;
    result.add(cur);
    pts.add(curp);

    var next = getRightmostSegment(cur, curp);
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


      next = getRightmostSegment(cur, curp);
      nextp = next.otherEnd(curp);
    }

    return result;
  }

  // Splits the segments chain into one or several areas, by removeing segements that are used twice.
  static List<List<AreasSegment>> removeRepeatedSegments(List<AreasSegment> segments)
  {
    Map<AreasSegment, int> segmentPos = new Map<AreasSegment, int>();
    List<List<AreasSegment>> result = [];

    for(int i = 0; i < segments.length; i++)
    {
      AreasSegment seg = segments[i];
      if (segmentPos.containsKey(seg))
      {
        var starti = segmentPos[seg];
        var endi = i;

        if (starti +1 < endi)
        {
          result.add(segments.getRange(starti+1, endi-starti-1));
        }

        //backtrack until first split
        while (starti >=0 && endi < segments.length && segments[starti] == segments[endi])
        {
          starti --;
          endi ++;
        }
        
        //remove the range
        segments.removeRange(starti+1, endi-starti-1);
        i = starti;
        //continue on.
      }
      else
      {
        segmentPos[seg] = i;
      }
    }

    //if there is something left in segments it's a good shape
    if (segments.length > 0)
    {
      result.add(segments); 
    }

    return result;
  }
  

  static List<AreasSegment> findAreaStartingHere(AreasPoint fromp, AreasSegment start)
  {
    var x = findAreaClockwise(fromp, start);
    var y = removeRepeatedSegments(x);
    
    for(List<AreasSegment> z in y)
    {
      if (z.indexOf(start) != -1)
        return z;
    }
    
    return null;
  }
  
  //splits in two things - next segment not connected, next segment not the rightmost one.
  static List<List<AreasSegment>> extractContigousSegments(List<AreasSegment> segments)
  {
    //TODO: remove list copying, removeRepeatedSegments modifies the input list.
    List<List<AreasSegment>> part1 = removeRepeatedSegments(new List<AreasSegment>.from(segments));
    List<List<AreasSegment>> result = [];
        
    //split on gaps
    for(List<AreasSegment> list in part1)
    {
      //find splits
      AreasSegment s0 = list.last();
      List<int> splits = [];
      
      for (int i = 0; i < list.length; i ++)
      {
        AreasSegment s = list[i];
        var p = s0.hasCommonPoint(s);
        
        if (p == null)
        {
          splits.add(i);
        }
        else if (getRightmostSegment(s0, p) != s)
        {
          splits.add(i);
        }
        
        s0 = s;
      }
      
      if (splits.length == 0)
      {
        result.add(list);
      }
      else
      {
        //split in gaps
        for (int i = 0; i < splits.length - 1; i ++)
        {
          result.add(list.getRange(splits[i], splits[i+1] - splits[i]));
        }
        
        //add the last part:
        var last = list.getRange(splits.last(), list.length - splits.last());
        last.addAll(list.getRange(0, splits[0]));
        result.add(last);
      }
    }

    return result;
  }

  static void processNewSegment(AreasData data, AreasSegment segment)
  {
    //just try to add new area on both sides
    
    var segs = findAreaClockwise(segment.p0, segment);
    if (segs != null)
    {
      var areas = removeRepeatedSegments(segs);
      for(var area in areas)
      {
        tryNewArea(data, area);
      }
    }

    segs = findAreaClockwise(segment.p1, segment);
    if (segs != null)
    {
      var areas = removeRepeatedSegments(segs);
      for(var area in areas)
      {
        tryNewArea(data, area);
      }
    }
  }

  
  static bool isClosed(List<AreasSegment> segments)
  {
    return ((segments.length > 2) && segments[0].hasCommonPoint(segments.last()) != null) ||
        (segments.length == 2 && segments[0] == segments[1]);
  }
  
  static void processChanges(AreasData data, List<AreasArea> areas, List<AreasSegment> segments, List<AreasPoint> points)
  {
    //Split the areas into contigous parts
    List<AreaPart> parts = [];
    List<AreasArea> areasToUpdate = [];

    //Collect all areas
    for (var s in segments)
    {
      for (var a in s.areas)
      {
        if (areas.indexOf(a) == -1)
        {
          areas.add(a);
        }
      }
    }
    
    for (var p in points)
    {
      for (var s in p.segments)
      {
        for (var a in s.areas)
        {
          if (areas.indexOf(a) == -1)
          {
            areas.add(a);
          }
        }
      }
    }
    
    for(var a in areas)
    {
      List<List<AreasSegment>> segs = extractContigousSegments(a.segments);
      
      if (segs.length == 0)
      {
        data.removeArea(a);
      }
      else if (segs.length == 1 && segs[0].length == a.segments.length && isClosed(segs[0]))
      {
        if (a.segments.length < 3)
        {
          //Proper area needs at least 3 segments
          data.removeArea(a);
        }
        //no change, all as before, skip this
      }
      else
      {
        areasToUpdate.add(a);
        
        for (var x in segs)
        {
          if (x.length == 1)
          {
            //TODO; not sure if there is anything we can do here.
            continue;
          }
          
          parts.add(new AreaPart(a, x));
        }
      }
    }
    
    //Take one part at a time and make a full area or out of it
    while (parts.length > 0)
    {
      AreaPart p = parts.last();
      
      var secondPoint = p.segments[0].commonPoint(p.segments[1]);
      var firstPoint = p.segments[0].otherEnd(secondPoint);
      List<AreasSegment> fullArea = findAreaStartingHere(firstPoint, p.segments[0]);
      if (fullArea == null)
      {
        //Just leave as is.
        data.newArea(p.segments);
        //TODO: transfer tags.     
        parts.removeLast();
        continue;
      }
   
      List<AreaPart> match = matchParts(fullArea, parts);
      
      if (isOuterShate(fullArea))
      {
        //Outer, keep each part separate
        for(var m in match)
        {
          data.newArea(m.segments);
          //TODO: transfer tags.
        }
      }
      else
      {
        //Inner, try to join parts
        int startIndex = 0;
        AreasArea aa = null;
        
        AreaPart last = null;
        
        for (AreaPart p in match)
        {
            if (aa == null)
            {
              aa = p.area;
            }
            else if (aa != p.area) 
            {
              //TODO: Automatic merge parts areas have same tags.
              //split part
              data.newArea(fullArea.getRange(startIndex, last.position + last.segments.length - startIndex));
              startIndex = last.position + last.segments.length;
            }
            
            last = p;
        }
        
        //add last area
        {
          data.newArea(fullArea.getRange(startIndex, fullArea.length - startIndex));
        }
                
      } 
      
      //remove parts from list
      for(var x in match) parts.removeRange(parts.indexOf(x), 1);
    }
    
    //Delete the old stuff
    for(AreasArea x in areasToUpdate)
    {
      data.removeArea(x);
    }
    
    //add areas if new segments
    for(AreasSegment seg in segments)
    {
      AreasProcessing.processNewSegment(data, seg);
    }

  }
  
  static List<AreaPart> matchParts(List<AreasSegment> segments, List<AreaPart> parts)
  {
    List<AreaPart> result = [];

    for(var i = 0; i < segments.length; i++)
    {
      var seg = segments[i];
      var nextSeg = segments[(i+1)%segments.length];
      
      for (AreaPart p in parts)
      {
        int j = 0;
        while(i+j < segments.length && j < p.segments.length && p.segments[j] == segments[i+j]) j++;
        
        if (j == p.segments.length)
        {
          p.position = i;
          result.add(p);
          i += j-1;
        }
      }
    }
    
    return result;
  }

  static bool isOuterShate(List<AreasSegment> segments)
  {
    double angle = 0.0;

    var p0 = null;
    var p2 = segments[0].commonPoint(segments.last());
    var p1 = segments.last().otherEnd(p2);
    for (var seg in segments)
    {
      p0 = p1;
      p1 = p2;
      p2 = seg.otherEnd(p1);
      angle += Geometry.angleBetweenVectors(p1.x-p0.x,p1.y-p0.y, p2.x-p1.x, p2.y - p1.y);
    }

    //the shape should go clockwise, counterclockwise means outer shape
    return (angle <= 0);
  }
  
  static AreasArea tryNewArea(AreasData data, List<AreasSegment> segments)
  {
    assert(segments != null);
    assert(segments.length >= 2);

    //check if this is outer shape
    if (isOuterShate(segments))
    {
      return null;
    }

    //check if the shape has zero volume
    Map<AreasSegment, int> segmentTimes = new Map<AreasSegment, int>();
    for (var seg in segments)
    {
      if (segmentTimes.containsKey(seg))
      {
        segmentTimes[seg] += 1;
      }
      else
      {
        segmentTimes[seg] = 1;
      }
    }

    bool hasVolume = false;
    for (var seg in segmentTimes.getKeys())
    {
      int times = segmentTimes[seg];
      assert(times <= 2);
      hasVolume = hasVolume || (times == 1);
    }

    if (!hasVolume)
      return null;

    //check if such shape already exists
    List<AreasArea> commonShapes = [];
    commonShapes.addAll(segments[0].areas);

    for (var seg in segments)
    {
      commonShapes = commonShapes.filter((x) => seg.areas.indexOf(x) != -1);
    }

    if (commonShapes.length > 0)
      return commonShapes[0];

    //add new area
    return data.newArea(segments);
  }

}

class AreaPart
{
  AreasArea area;
  List<AreasSegment> segments;
  int position;
  
  AreaPart(var a, var s){area = a; segments = s; position = -1;}
}
