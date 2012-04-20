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

    //TODO: maybe use a stack of tools. Should make zooming and panning go away to separate tool.
    tool:null,
    isPanning: false,
    toolActive: false,

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
        x = this.xToData(canvasX);
        y = this.yToData(canvasY);
        this.zoom *= scale;
        x1 = this.xToData(canvasX);
        y1 = this.yToData(canvasY);
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
            p = this.data.points[i];
            x = this.xToCanvas(p.x);
            y = this.yToCanvas(p.y);
            this.context.beginPath();
            this.context.arc(x,y,5, 0, 2*Math.PI, false);
            this.context.fillStyle='#666666';
            this.context.fill();
            this.context.stroke();
        }
    },

    findPoint: function(canvasX, canvasY){
        //TODO: search in reverse order
        for (var i = 0; i < this.data.points.length; i++){
            p = this.data.points[i];
            dx = this.xToCanvas(p.x) - canvasX;
            dy = this.yToCanvas(p.y) - canvasY;
            if (dx * dx + dy* dy < 5*5)
            {
                return p;
            }
        }

        return null;
    },

    setTool: function(tool){
        if (this.tool != null)
        {
            this.tool.detach();
        }
        this.tool = tool;
        this.tool.attach(this);
    },

    handleMouseDown: function(evt){

        this.isPanning = false;

        x = evt.offsetX;
        y = evt.offsetY;
        if (this.tool != null && this.tool.mousedown(x,y))
        {
            this.toolActive = true;
            this.paint();
        } else {
            this.toolActive = false;
        }
    },

    handleMouseUp: function(evt){

        x = evt.offsetX;
        y = evt.offsetY;
        if (this.tool != null && !this.isPanning)
            if (this.tool.mouseup(x,y))
        {
            this.paint();
        }

        this.isPanning = false;
        this.toolActive = false;
        evt.preventDefault();
    },

    handleMouseMove: function(evt){

        x = evt.offsetX;
        y = evt.offsetY;
        if (this.tool != null && this.toolActive && this.tool.mousemove(x,y, this.prevX, this.prevY, evt.which))
        {
            this.paint();
        } else if (evt.which && this.prevX != null) {
            //drag canvas
            this.pan(x - this.prevX, y - this.prevY);
            this.paint();
            this.isPanning = true;
        }

        this.prevX = x;
        this.prevY = y;
     },


    handleMouseWheel: function(evt){
        //if (this.tool == null) return;

        x = evt.offsetX;
        y = evt.offsetY;
        d = evt.wheelDeltaY;

        this.changeZoom(x,y,Math.pow(1.001,d));
        this.paint();
        evt.preventDefault();
    }
}