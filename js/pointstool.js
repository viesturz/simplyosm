PointsTool = function(){};

PointsTool.prototype = {
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
        var point = this.view.findPoint(canvasX, canvasY);

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
        var x = this.view.xToData(canvasX);
        var y = this.view.yToData(canvasY);

        if (dragging && this.grabbedPoint)
        {
            this.data.movePoint(this.grabbedPoint, x, y);
            return true;
        }
    },

    mouseup: function(canvasX,canvasY){
        if (this.grabbedPoint == null){
            var x = this.view.xToData(canvasX);
            var y = this.view.yToData(canvasY);
            var p = DataStore.newPoint(x,y);
            this.data.addPoint(p);
            return true;
        }
    }
}