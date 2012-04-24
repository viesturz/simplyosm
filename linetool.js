LinesTool = function(){};

LinesTool.prototype = {
    view: null,
    data: null,
    lastPoint: null,
    newPoint: null,
    isDragging: false,

    attach: function(view){
        this.view = view;
        this.data = view.data;
        this.lastPoint = null;
        this.newPoint = null;
    },

    detach: function()
    {
    },

    cancel: function()
    {
        this.lastPoint = null;
        if (this.activeLine)
        {
            //TODO: cancel last point?
            this.activeLine = null;
        }
    },

    mousedown: function(canvasX,canvasY){
        this.isDragging = false;

        if (this.activeLine)
        {
            return true;
        }
        else
        {
            var point = this.view.findPoint(canvasX, canvasY);

            if (point){
                this.lastPoint = point;
                this.view.setSelected(point);
                return true;
            }
            else
            {
                this.lastPoint = null;
                return false;
            }
        }
    },

    mousemove: function(canvasX, canvasY, canvasXPrev, canvasYPrev, dragging){
        var x = this.view.xToData(canvasX);
        var y = this.view.yToData(canvasY);
        var p = this.view.findPoint(canvasX, canvasY);
        var processed = false;

        if (dragging && this.newPoint)
        {
            this.newPoint.x = x;
            this.newPoint.y = y;

            this.view.setSelected(this.lastPoint);
            processed = true;
        }
        else if (dragging && this.lastPoint)
        {
            this.data.pointMove(this.lastPoint, x, y);
            this.isDragging = true;

            this.view.setSelected(this.lastPoint);
            processed = true;
        }
        else if (!dragging && !this.isDragging)
        {
            if (this.lastPoint && !this.newPoint)
            {
                this.newPoint = DataStore.newPoint(x,y);

                if (!this.activeLine)
                {
                    this.activeLine = this.data.addLine([this.lastPoint, this.newPoint]);
                }
                else
                {
                    var points = this.activeLine.points.slice(0);
                    points.push(this.newPoint);
                    this.data.lineSetPoints(this.activeLine, points);
                }

                this.view.setSelected(this.activeLine);
                processed = true;
            }
            else if (this.newPoint && this.activeLine)
            {
                this.data.pointMove(this.newPoint, x, y);
                this.view.setSelected(this.activeLine);
                processed = true;
            }
        }

        if (p && processed)
        {
            this.view.addSelected(p);
        }

        return processed;
    },

    mouseup: function(canvasX,canvasY){
        if (this.isDragging)
        {
            this.isDragging = false;
            this.activeLine = null;
            this.lastPoint = null;
            this.newPoint = null;

            var p = this.view.findPoint(canvasX, canvasY);

            if (p)
            {

            }

            return false;
        }
        else if (!this.lastPoint)
        {
            var x = this.view.xToData(canvasX);
            var y = this.view.yToData(canvasY);
            var p = this.data.newPoint(x,y);
            this.view.setSelected(p);
            this.lastPoint = p;
            return true;
        }
        else if (this.activeLine)
        {
            //add new point or connect to existing
            var p = this.view.findPoint(canvasX, canvasY);

            if (p)
            {
                if (p == this.lastPoint && this.activeLine.points.length == 2)
                {
                    this.data.removeLine(this.activeLine);
                }
                else
                {
                    var points = this.activeLine.points.slice(0, this.activeLine.points.length - 1);
                    points.push(p);
                    this.data.lineSetPoints(this.activeLine, points);
                }
                this.activeLine = null;
                this.lastPoint = null;
                this.newPoint = null;
                //drawing finished
                return false;
            }
            else
            {
                this.data.addPoint(this.newPoint);
                this.lastPoint = this.newPoint;
                this.newPoint = null;
                return true;
            }
        }

        return false;
    }
};