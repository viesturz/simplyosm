AreaTool = function(){};

AreaTool.prototype = {
    view: null,
    data: null,
    grabbedPoint: null,

    attach: function(view){
        this.view = view;
        this.data = view.data;
        this.grabbedPoint = null;
    },

    detach: function()
    {
    },

    mousedown: function(canvasX,canvasY){
        point = this.view.findPoint(canvasX, canvasY);

        if (point){
            this.grabbedPoint = point;
            return true;
        }
        else
        {
            this.grabbedPoint = null;
            return false;
        }
    },

    mousemove: function(canvasX, canvasY, canvasXPrev, canvasYPrev, dragging){
        x = this.view.xToData(canvasX);
        y = this.view.yToData(canvasY);

        if (dragging && this.grabbedPoint)
        {
            this.data.movePoint(this.grabbedPoint, x, y);
            return true;
        }
    },

    mouseup: function(canvasX,canvasY){
        if (this.grabbedPoint == null){
            x = this.view.xToData(canvasX);
            y = this.view.yToData(canvasY);
            p = DataStore.newPoint(x,y);
            this.data.addPoint(p);
            return true;
        }
    }
}