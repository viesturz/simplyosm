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
  static List<List<AreasSegment>> extractProperAreas(List<AreasSegment> segments)
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

  static void processNewSegment(AreasData data, AreasSegment segment)
  {
    var segs = findAreaClockwise(segment.p0, segment);
    if (segs != null)
    {
      var areas = extractProperAreas(segs);
      for(var area in areas)
      {
        tryNewArea(data, area);
      }
    }

    segs = findAreaClockwise(segment.p1, segment);
    if (segs != null)
    {
      var areas = extractProperAreas(segs);
      for(var area in areas)
      {
        tryNewArea(data, area);
      }
    }
  }

  static void processChangedArea(AreasData data, AreasArea area)
  {

    if (area.segments.length < 3)
    {
      data.removeArea(a);
    }
    else
    {
      //TODO:
    }
  }

  static void tryNewArea(AreasData data, List<AreasSegment> segments)
  {
    assert(segments != null);
    assert(segments.length >= 2);

    //check if this is outer shape
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
    if (angle <= 0)
      return;

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
    data.newArea(segments);

  }

}
