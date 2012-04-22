PanTool = function(){};

PanTool.prototype = {
    view: null,
    data: null,

    attach: function(view){
        this.view = view;
        this.data = view.data;
    },

    detach: function()
    {
    },

    mousedown: function(canvasX,canvasY){
    },

    mousemove: function(canvasX, canvasY, canvasXPrev, canvasYPrev, dragging){
        if (dragging)
        {
            var dx = canvasX - canvasXPrev;
            var dy = canvasY - canvasYPrev;
            //drag canvas
            this.view.pan(dx, dy);
            return true;
        }
    },

    mouseup: function(canvasX,canvasY){
    }
}