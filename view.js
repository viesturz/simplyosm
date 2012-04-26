View = function(canvas, data){
    this.canvas = canvas;
    this.data = data;
    this.canvasWidth = canvas.width;
    this.canvasHeight = canvas.height;
    this.context = canvas.getContext('2d');

    var obj = this;

    canvas.addEventListener('mousedown', function(e){obj.handleMouseDown(e);});
    canvas.addEventListener('mouseup', function(e){obj.handleMouseUp(e);});
    canvas.addEventListener('mousemove', function(e){obj.handleMouseMove(e);});
    canvas.addEventListener('mousewheel', function(e){obj.handleMouseWheel(e)});
    window.addEventListener('keydown', function(e){obj.handleKeyDown(e)}, true);
};

View.prototype={
    canvas: null,
    canvasWidth:0,
    canvasHeight:0,

    data:null,
    selection:[],

    context: null,
    prevX: null,
    prevY: null,
    mouseX: 0,
    mouseY: 0,

    zoom: 1,
    centerX: 0, //in data coords
    centerY: 0, //in data coords

    tools:[],
    activeTool: null,

    xToCanvas: function(x){
        return (x - this.centerX) * this.zoom + this.canvasWidth/2;
    },
    yToCanvas: function(y){
        return (y - this.centerY) * this.zoom + this.canvasHeight/2;
    },

    xToData: function(x){
        return (x - this.canvasWidth/2) / this.zoom + this.centerX;
    },
    yToData: function(y){
        return (y - this.canvasHeight/2) / this.zoom + this.centerY;
    },

    changeZoom: function(canvasX, canvasY, scale){
        var x = this.xToData(canvasX);
        var y = this.yToData(canvasY);
        this.zoom *= scale;
        var x1 = this.xToData(canvasX);
        var y1 = this.yToData(canvasY);
        this.centerX += x - x1;
        this.centerY += y - y1;
    },

    setSelected: function(list){
        this.selection = list;
    },

    pan: function(canvasDx, canvasDy){
        this.centerX -= canvasDx / this.zoom;
        this.centerY -= canvasDy / this.zoom;
    },

    paint: function(){
        this.context.clearRect(0,0,this.canvasWidth, this.canvasHeight);
        var i;
        var x;
        var y;

        for (i = 0; i < this.data.segments.length; i++){
            var s = this.data.segments[i];

            this.context.beginPath();
            this.context.moveTo(this.xToCanvas(s.p0.x),this.yToCanvas(s.p0.y));
            this.context.lineTo(this.xToCanvas(s.p1.x),this.yToCanvas(s.p1.y));

            this.context.lineWidth = 2;
            if (this.selection.indexOf(s) != -1)
                this.context.strokeStyle='#F33';
            else
                this.context.strokeStyle='#666666';
            this.context.stroke();
        }

        for (i = 0; i < this.data.points.length; i++){
            var p = this.data.points[i];
            x = this.xToCanvas(p.x);
            y = this.yToCanvas(p.y);
            this.context.beginPath();
            this.context.arc(x,y,5, 0, 2*Math.PI, false);

            if (this.selection.indexOf(p) != -1)
                this.context.fillStyle='#F33';
            else
                this.context.fillStyle='#666666';
            this.context.fill();
        }
    },

    findPoint: function(canvasX, canvasY, ignoreThis){
        var treshold = 5*5;
        if (ignoreThis)
          treshold *= 4;

        for (var i = this.data.points.length -1; i >=0; i--){
            var p = this.data.points[i];

            if (p == ignoreThis)
                continue;

            var dx = this.xToCanvas(p.x) - canvasX;
            var dy = this.yToCanvas(p.y) - canvasY;
            if (dx * dx + dy* dy < treshold)
            {
                return p;
            }
        }

        return null;
    },

    findSegment: function(canvasX, canvasY, ignoreThis){
        var treshold = 7/this.zoom;
        var x = this.xToData(canvasX);
        var y = this.yToData(canvasY);

        var best = null;

        for (var i = this.data.segments.length - 1; i >= 0; i--){
            var seg = this.data.segments[i];

            if (ignoreThis && ignoreThis.segments.indexOf(seg) != -1)
                continue;

            var dst = Geometry.distanceToSegment(seg.p0.x, seg.p0.y,seg.p1.x, seg.p1.y, x, y);

            if (dst.distance < treshold)
            {
                if (!best || best.distance > dst.distance){
                    best = dst;
                    best.segment = seg;
                }
            }
        }

        return best;
    },

    addTool: function(tool){
        this.tools.push(tool);
        tool.attach(this);
    },

    handleMouseDown: function(evt){
        var x = evt.offsetX;
        var y = evt.offsetY;
        var handled = false;
        var r;

        if (this.activeTool)
        {
            r = this.activeTool.mousedown(x,y);
            if (r == false)
                this.activeTool = null;
            if (r == true || r == false)
                handled = true;
        }

        if (!handled)
        for(var i = this.tools.length - 1; i >= 0; i --)
        {
            var tool = this.tools[i];
            r = tool.mousedown(x,y);
            if (r == true)
                this.activeTool = tool;
            if (r == true || r == false)
            {
                handled = true;
                break;
            }
        }

        if (handled)
        {
            this.paint();
        }

        evt.preventDefault();
    },

    handleMouseUp: function(evt){
        var x = evt.offsetX;
        var y = evt.offsetY;
        var handled = false;

        if (this.activeTool)
        {
            var r = this.activeTool.mouseup(x,y);
            if (r == false)
                this.activeTool = null;
            if (r == true || r == false)
                handled = true;
        }

        if (!handled) for(var i = this.tools.length - 1; i >= 0; i --)
        {
            var tool = this.tools[i];
            var r = tool.mouseup(x,y);
            if (r == true)
                this.activeTool = tool;
            if (r == true || r == false)
            {
                handled = true;
                break;
            }
        }

        if (handled)
        {
            this.paint();
        }

        evt.preventDefault();
    },

    handleMouseMove: function(evt){
        var x = evt.offsetX;
        var y = evt.offsetY;
        var buttons = evt.which;
        var handled = false;

        //drag delay - do not react on tiny drags.
        if (buttons && !this.activeTool  && this.prevX != null)
        {
            //TODO: use some geometry library
            var dx = this.prevX - x;
            var dy = this.prevY - y;
            if (dx*dx + dy*dy < 5*5)
            {
                return;
            }
        }

        if (this.activeTool)
        {
            var r = this.activeTool.mousemove(x,y,this.prevX,this.prevY, buttons);
            if (r == false)
                this.activeTool = null;
            if (r == true || r == false)
                handled = true;
        }

        if (!handled)
        for(var i = this.tools.length - 1; i >= 0; i --)
        {
            var tool = this.tools[i];
            var r = tool.mousemove(x,y,this.prevX, this.prevY, buttons);
            if (r == true)
                this.activeTool = tool;
            if (r == true || r == false)
            {
                handled = true;
                break;
            }
        }

        if (handled)
        {
            this.paint();
        }

        this.prevX = x;
        this.prevY = y;
        evt.preventDefault();
    },


    handleMouseWheel: function(evt){
        var x = evt.offsetX;
        var y = evt.offsetY;
        var d = evt.wheelDeltaY;

        this.changeZoom(x,y,Math.pow(1.001,d));
        this.paint();
        evt.preventDefault();
    },

    handleKeyDown: function(evt){
        log.debug("key pressed " + evt.keyCode);

        if (evt.keyCode == 27)  //escape
        {
            if (this.activeTool){
                this.activeTool.cancel();
                this.activeTool = new CancelTool();
                this.paint();
            }
        }
        else if (evt.keyCode == 68 || evt.keyCode == 46)  //delete
        {
            if (this.selection.length > 0)
            {
                if (this.activeTool)
                    this.activeTool.cancel();
                this.activeTool = null;
                this.data.deleteItems(this.selection);
                this.paint();
            }
        }
    }
};

//Cancel tool for cancelling out all actions until mouse is released.
CancelTool = function(){};
CancelTool.prototype = {
    attach: function(view){},
    mousedown: function(canvasX,canvasY){return false;},
    mousemove: function(canvasX, canvasY, canvasXPrev, canvasYPrev, dragging){return dragging != 0;},
    mouseup: function(canvasX,canvasY){return false},
    cancel: function(){}
};
