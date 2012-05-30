class SelectOnClickTool extends Tool{
  AreasLayer layer;

  SelectOnClickTool(AreasLayer layer){
    this.layer = layer;
  }

  int mouseDown(double canvasX, double canvasY){
    var point = this.layer.findPoint(canvasX, canvasY, null);

    if (point != null){
        this.view.setSelected([point]);
        return Tool.STATUS_FINISHED;
    }

    return Tool.STATUS_SKIP;
  }

  int mouseMove(canvasX, canvasY, canvasXPrev, canvasYPrev, evt){
    if (evt.which == 0)
    {
        var p = this.layer.findPoint(canvasX, canvasY, null);
        if (p != null)
        {
            this.view.setSelected([p]);
            return Tool.STATUS_FINISHED;
        }
    }

    return Tool.STATUS_SKIP;
  }
}

class AddNodeOnLineTool extends Tool{
  AreasLayer layer;
  AreasData data;

  AddNodeOnLineTool(AreasLayer layer){
    this.layer = layer;
    this.data = layer.data;
  }

  int mouseDown(canvasX,canvasY){
    Intersection segment = this.layer.findSegment(canvasX, canvasY, null);

    if (segment != null){
        var x = this.view.xToData(canvasX);
        var y = this.view.yToData(canvasY);
        var point = this.data.newPoint(x,y);
        this.data.splitSegment(segment.item, point);
        this.view.setSelected([point]);
        return Tool.STATUS_FINISHED;
    }

    return Tool.STATUS_SKIP;
  }

  int mouseMove(canvasX, canvasY, canvasXPrev, canvasYPrev, evt){
    if (evt.which == 0)
    {
        Intersection segment = this.layer.findSegment(canvasX, canvasY, null);
        if (segment != null)
        {
            this.view.setSelected([segment.item]);
            return Tool.STATUS_FINISHED;
        }
    }

    return Tool.STATUS_SKIP;
  }
}

class DragPointsTool extends Tool{
  bool isDragging = false;
  AreasLayer layer;
  AreasData data;
  AreasPoint point = null;
  double oldX = 0.0;
  double oldY = 0.0;

  DragPointsTool(AreasLayer layer){
    this.layer = layer;
    this.data = layer.data;
  }

  int mouseMove(canvasX, canvasY, canvasXPrev, canvasYPrev, MouseEvent evt){
    bool dragging = evt.which != 0;

    if (!dragging)
        return Tool.STATUS_SKIP;

    if (!this.isDragging)
    {
        var p = this.layer.findPoint(canvasXPrev, canvasYPrev);
        if (dragging != 0 && p != null){
            this.oldX = p.x;
            this.oldY = p.y;
            this.isDragging = true;
            this.point = p;
        }
    }

    if (this.isDragging)
    {
        var x = this.view.xToData(canvasX);
        var y = this.view.yToData(canvasY);
        this.data.movePoint(this.point, x, y);
        AreasPoint p = this.layer.findPoint(canvasX, canvasY, this.point);
        Intersection l = this.layer.findSegment(canvasX, canvasY, this.point);
        if (p != null)
            this.view.setSelected([this.point, p]);
        else if (l != null)
            this.view.setSelected([this.point, l.item]);
        else
            this.view.setSelected([this.point]);
        return Tool.STATUS_ACTIVE;
    }

    return Tool.STATUS_SKIP;
  }

  int mouseUp(canvasX,canvasY){
      if (this.isDragging)
      {
          this.isDragging = false;

          AreasPoint p = this.layer.findPoint(canvasX, canvasY, this.point);

          if (p != null)
          {
              this.data.mergePoints(p, this.point);
          }
          else
          {
              Intersection l = this.layer.findSegment(canvasX, canvasY, this.point);
              if (l != null)
                  this.data.splitSegment(l.item, this.point);
          }

          this.view.setSelected([this.point]);
          this.isDragging = false;
          return Tool.STATUS_FINISHED;
      }

      return Tool.STATUS_SKIP;
  }

  void cancel(){
      if (this.isDragging)
      {
          this.data.movePoint(this.point, this.oldX, this.oldY);
          this.isDragging = false;
          this.point = null;
      }
  }
}


class CreateLinesTool extends Tool{
  AreasLayer layer;
  AreasData data;
  AreasPoint newPoint = null;
  AreasSegment line = null;
  AreasPoint startingPoint = null;

  CreateLinesTool(AreasLayer layer){
    this.layer = layer;
    this.data = layer.data;
  }

  int mousedown(canvasX,canvasY){
    if (this.line == null)
        return Tool.STATUS_SKIP;

    //handle this event but do nothing
    return Tool.STATUS_ACTIVE;
  }

  int mouseMove(canvasX, canvasY, canvasXPrev, canvasYPrev, MouseEvent evt){
    if (this.line == null)
        return Tool.STATUS_SKIP;

    AreasPoint p = this.layer.findPoint(canvasX, canvasY, this.newPoint);
    var x = this.view.xToData(canvasX);
    var y = this.view.yToData(canvasY);

    this.data.movePoint(this.newPoint, x, y);

    var selection = [this.line, this.newPoint];
    if (p != null){
        selection.add(p);
    }
    else
    {
      Intersection s = this.layer.findSegment(canvasX, canvasY, this.newPoint);
      if (s != null)
      {
          selection.add(s.item);
      }
    }

    this.view.setSelected(selection);
    return Tool.STATUS_ACTIVE;
  }

  int mouseUp(canvasX,canvasY){
    var x = this.view.xToData(canvasX);
    var y = this.view.yToData(canvasY);
    AreasPoint p0 = this.layer.findPoint(canvasX, canvasY, this.newPoint);

    if (this.line != null)
    {
        this.startingPoint = null;

        if (p0 != null)
        {
            this.startingPoint = null;
            //finish segment
            this.data.mergePoints(p0, this.newPoint);
            this.view.setSelected(this.data.getLineSegments(this.line));
            this.line = null;
            this.newPoint = null;
            return Tool.STATUS_FINISHED;
        }
        else
        {
            Intersection s0 = this.layer.findSegment(canvasX, canvasY, this.newPoint);

            if (s0 != null)
            {
                this.data.splitSegment(s0.item, this.newPoint);
                this.view.setSelected(this.data.getLineSegments(this.line));
                this.line = null;
                this.newPoint = null;
                return Tool.STATUS_FINISHED;
            }
            else
            {
                //continue drawing next segment
                var pp = this.newPoint;
                this.newPoint = this.data.newPoint(x,y);
                this.line = this.data.newSegment(pp, this.newPoint);
                this.view.setSelected([this.line, this.newPoint]);
                return Tool.STATUS_ACTIVE;
            }
        }
    }
    else
    {
        //start drawing new segment
        if (p0 == null)
        {
            p0 = this.data.newPoint(x,y);
            this.startingPoint = p0;
        }

        this.newPoint = this.data.newPoint(x,y);
        this.line = this.data.newSegment(p0,this.newPoint);
        this.view.setSelected([this.line, this.newPoint]);
        return Tool.STATUS_ACTIVE;
    }

    return Tool.STATUS_SKIP;
  }

  int cancel(){
    if (this.line != null){
        if (this.startingPoint != null)
        {
            this.data.removePoint(this.startingPoint);
        }

        this.data.removeSegment(this.line);
        this.data.removePoint(this.newPoint);
        this.line = null;
        this.newPoint = null;
        this.startingPoint = null;
        this.view.setSelected([]);
    }
  }
}