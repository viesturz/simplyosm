AreasData = function(){};

AreasData.prototype = {
    points:[],
    segments:[],
    shapes:[],

    newPoint: function(x,y){
        var p = {type: "point",x:x, y:y, segments: [], created: true};
        this.points.push(p);
        return p;
    },

    newSegment: function(p0, p1){
        var l = new LineSegment(p0, p1);
        l.created = true;
        this.segments.push(l);
        return l;
    },

    removeSegment: function(segment){
        var i = this.lines.indexOf(segment);
        if (i != -1){
            this.segments.remove(i);
        }

        segment.disconnect();
    },

    movePoint: function(p, x, y){
        p.x = x;
        p.y = y;
        p.modified = true;
    },

    mergePoints: function(p0,p1){
        for (var i = 0; i < p1.segments.length; i ++){
            var s = p1.segments[i];
            var pp = s.otherEnd(p1);
            if (pp == p0){
                this.removeSegment(s);
            }
            else
            {
                s.changeEnd(p1, p0);
            }
        }
        return p0;
    }


};

LineSegment = function(p0,p1){
    this.type = "segment";
    this.p0 = p0;
    this.p1 = p1;
    this.p0.segments.push(this);
    this.p1.segments.push(this);
};

LineSegment.prototype = {
    otherEnd: function(p){
        if (p == this.p0)
          return this.p1;
        if (p == this.p1)
            return this.p0;
        throw new Error("No other end");
    },

    changeEnd: function(from, to){
        if (from == this.p0)
        {
            var pos = this.p0.segments.indexOf(this);
            this.p0.segments.splice(pos, 1);

            this.p0 = to;

            this.p0.segments.push(this);
        }
        if (from == this.p1)
        {
            pos = this.p1.segments.indexOf(this);
            this.p1.segments.splice(pos, 1);

            this.p1 = to;

            this.p1.segments.push(this);
        }
        throw new Error("From not found");
    },

    disconnect: function(){
        var pos = this.p0.segments.indexOf(this);
        this.p0.segments.splice(pos, 1);
        pos = this.p1.segments.indexOf(this);
        this.p1.segments.splice(pos, 1);
    }
};