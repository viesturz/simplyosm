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
};

View.prototype={
    data:null,
    canvas: null,
    canvasWidth:0,
    canvasHeight:0,

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

    pan: function(canvasDx, canvasDy){
        this.centerX -= canvasDx / this.zoom;
        this.centerY -= canvasDy / this.zoom;
    },

    paint: function(){
        this.context.clearRect(0,0,this.canvasWidth, this.canvasHeight);

        for (var i = 0; i < this.data.points.length; i++){
            var p = this.data.points[i];
            var x = this.xToCanvas(p.x);
            var y = this.yToCanvas(p.y);
            this.context.beginPath();
            this.context.arc(x,y,5, 0, 2*Math.PI, false);
            this.context.fillStyle='#666666';
            this.context.fill();
            this.context.stroke();
        }
    },

    findPoint: function(canvasX, canvasY){
        for (var i = this.data.points.length -1; i >=0; i--){
            var p = this.data.points[i];
            var dx = this.xToCanvas(p.x) - canvasX;
            var dy = this.yToCanvas(p.y) - canvasY;
            if (dx * dx + dy* dy < 5*5)
            {
                return p;
            }
        }

        return null;
    },

    addTool: function(tool){
        this.tools.push(tool);
        tool.attach(this);
    },

    handleMouseDown: function(evt){
        var x = evt.offsetX;
        var y = evt.offsetY;

        this.activeTool = null;
        for(var i = this.tools.length - 1; i >= 0; i --)
        {
            var tool = this.tools[i];
            if (tool.mousedown(x,y))
            {
                this.activeTool = tool;
                this.paint();
                break;
            }
        }
    },

    handleMouseUp: function(evt){
        var x = evt.offsetX;
        var y = evt.offsetY;

        if (this.activeTool)
        {
            this.activeTool.mouseup(x,y);
        }
        else for(var i = this.tools.length - 1; i >= 0; i --)
        {
            var tool = this.tools[i];

            if (tool.mouseup(x,y))
            {
                this.paint();
                break;
            }
        }

        this.activeTool = null;
        evt.preventDefault();
    },

    handleMouseMove: function(evt){
        var x = evt.offsetX;
        var y = evt.offsetY;
        var buttons = evt.which;

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
            if (this.activeTool.mousemove(x,y,this.prevX,this.prevY, buttons))
            {
                this.paint();
            }
            else
            {
                this.activeTool = null;
            }
        }

        if (!this.activeTool)
        for(var i = this.tools.length - 1; i >= 0; i --)
        {
            var tool = this.tools[i];
            if (tool.mousemove(x,y,this.prevX, this.prevY, buttons))
            {
                this.activeTool = tool;
                this.paint();
                break;
            }
        }

        this.prevX = x;
        this.prevY = y;
     },


    handleMouseWheel: function(evt){
        var x = evt.offsetX;
        var y = evt.offsetY;
        var d = evt.wheelDeltaY;

        this.changeZoom(x,y,Math.pow(1.001,d));
        this.paint();
        evt.preventDefault();
    }
}