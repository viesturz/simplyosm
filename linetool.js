SelectOnClickTool = function(){};
SelectOnClickTool.prototype = {
    attach: function(view){
        this.view = view;
        this.data = view.data;
    },

    mousedown: function(canvasX,canvasY){
        var point = this.view.findPoint(canvasX, canvasY);

        if (point){
            this.view.setSelected([point]);
            return false;
        }

        return null;
    },

    mousemove: function(canvasX, canvasY, canvasXPrev, canvasYPrev, dragging){
        if (!dragging)
        {
            var p = this.view.findPoint(canvasX, canvasY);
            if (p)
            {
                this.view.setSelected([p]);
                return false;
            }
        }
    },

    mouseup: function(canvasX,canvasY){},
    cancel: function(){}
};

AddNodeOnLineTool = function(){};

AddNodeOnLineTool.prototype = {
    attach: function(view){
        this.view = view;
        this.data = view.data;
    },

    mousedown: function(canvasX,canvasY){
        var segment = this.view.findSegment(canvasX, canvasY);

        if (segment){
            var x = this.view.xToData(canvasX);
            var y = this.view.yToData(canvasY);
            var point = this.data.newPoint(x,y);
            this.data.splitSegment(segment.segment, point);
            this.view.setSelected([point]);
            return false;
        }

        return null;
    },

    mousemove: function(canvasX, canvasY, canvasXPrev, canvasYPrev, dragging){
        if (!dragging)
        {
            var segment = this.view.findSegment(canvasX, canvasY);
            if (segment)
            {
                this.view.setSelected([segment.segment]);
                return false;
            }
        }
    },

    mouseup: function(canvasX,canvasY){},
    cancel: function(){}

};

DragPointsTool = function(){};
DragPointsTool.prototype= {
    attach: function(view){
        this.isDragging = false;
        this.view = view;
        this.data = view.data;
        this.point = null;
        this.oldX = 0;
        this.oldY = 0;
    },

    mousedown: function(canvasX,canvasY){},

    mousemove: function(canvasX, canvasY, canvasXPrev, canvasYPrev, dragging){

        if (!dragging)
            return null;

        if (!this.isDragging)
        {
            var p = this.view.findPoint(canvasXPrev, canvasYPrev);
            if (dragging && p){
                this.oldX = p.x;
                this.oldY = p.y;
                this.isDragging = true;
                this.point = p;
            }
        }

        if (this.isDragging && dragging)
        {
            var x = this.view.xToData(canvasX);
            var y = this.view.yToData(canvasY);
            this.data.movePoint(this.point, x, y);
            var p = this.view.findPoint(canvasX, canvasY, this.point);
            var l = this.view.findSegment(canvasX, canvasY, this.point);
            if (p)
                this.view.setSelected([this.point, p]);
            else if (l)
                this.view.setSelected([this.point, l.segment]);
            else
                this.view.setSelected([this.point]);
            return true;
        }
    },

    mouseup: function(canvasX,canvasY){
        if (this.isDragging)
        {
            this.isDragging = false;

            var p = this.view.findPoint(canvasX, canvasY, this.point);

            if (p)
            {
                this.data.mergePoints(p, this.point);
            }
            else
            {
                var l = this.view.findSegment(canvasX, canvasY, this.point);
                this.data.splitSegment(l.segment, this.point);
            }

            this.view.setSelected([this.point]);

            this.isDragging = false;

            return false;
        }
    },

    cancel: function(){
        if (this.isDragging)
        {
            this.data.movePoint(this.point, this.oldX, this.oldY);
            this.isDragging = false;
            this.point = null;
        }
    }

};

CreatePointsTool = function(){};
CreatePointsTool.prototype = {
    attach: function(view){
        this.view = view;
        this.data = view.data;
    },


    mousedown: function(canvasX,canvasY){},
    mousemove: function(canvasX, canvasY, canvasXPrev, canvasYPrev, dragging){},

    mouseup: function(canvasX,canvasY){
        var p = this.view.findPoint(canvasX, canvasY, this.point);

        if (!p)
        {
            var x = this.view.xToData(canvasX);
            var y = this.view.yToData(canvasY);
            p = this.data.newPoint(x,y);
            this.view.setSelected([p]);
            return false;
        }

        //event not processed
        return null;
    },

    cancel: function(){}
};


CreateLinesTool = function(){};
CreateLinesTool.prototype = {
    attach: function(view){
        this.view = view;
        this.data = view.data;
        this.newPoint = null;
        this.line = null;
    },


    mousedown: function(canvasX,canvasY){
        if (!this.line)
            return null;

        //handle this event but do nothing
        return true;
    },

    mousemove: function(canvasX, canvasY, canvasXPrev, canvasYPrev, dragging){
        if (!this.line)
            return null;

        var p = this.view.findPoint(canvasXPrev, canvasYPrev, this.newPoint);
        var x = this.view.xToData(canvasX);
        var y = this.view.yToData(canvasY);

        this.data.movePoint(this.newPoint, x, y);

        var selection = [this.line, this.newPoint];
        if (p){
            selection.push(p);
        }

        this.view.setSelected(selection);

        return true;
    },

    mouseup: function(canvasX,canvasY){
        var x = this.view.xToData(canvasX);
        var y = this.view.yToData(canvasY);
        var p0 = this.view.findPoint(canvasX, canvasY, this.newPoint);

        if (this.line)
        {
            if (p0)
            {
                //finish segment
                this.data.mergePoints(p0, this.newPoint);
                this.view.setSelected(this.data.getLineSegments(this.line));
                this.line = null;
                this.newPoint = null;
                return false;
            }
            else
            {
                //continue drawing next segment
                var p0 = this.newPoint;
                this.newPoint = this.data.newPoint(x,y);
                this.line = this.data.newSegment(p0, this.newPoint);
                this.view.setSelected([this.line, this.newPoint]);
                return true;
            }
        }
        else
        {
            //start drawing new segment
            if (!p0)
            {
                p0 = this.data.newPoint(x,y);
            }

            this.newPoint = this.data.newPoint(x,y);
            this.line = this.data.newSegment(p0,this.newPoint);
            this.view.setSelected([this.line, this.newPoint]);
            return true;
        }
    },

    cancel: function(){
        if (this.line){
            this.data.removeSegment(this.line);
            this.data.removePoint(this.newPoint);
            this.line = null;
            this.newPoint = null;
            this.view.setSelected([]);
        }
    }
};