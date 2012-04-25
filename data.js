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

    removePoint: function(p){
        var i = this.points.indexOf(p);
        if (i != -1){
            this.points.splice(i,1);
        }

        while (p.segments.length > 0){
            this.removeSegment(p.segments[p.segments.length - 1]);
        }
    },

    removeSegment: function(segment){
        var i = this.segments.indexOf(segment);
        if (i != -1){
            this.segments.splice(i,1);
        }

        segment.disconnect();
    },

    deleteItems: function(itemList){

        //first remove segments
        for(var i = 0; i < itemList.length; i ++){
            if (itemList[i].type == "segment"){
                this.removeSegment(itemList[i]);
            }
        }

        //now remove points, otherwise segments will be affected by removed points
        for(var i = 0; i < itemList.length; i ++){
            if (itemList[i].type == "point"){
                this.removePoint(itemList[i]);
            }
        }
    },

    movePoint: function(p, x, y){
        p.x = x;
        p.y = y;
        p.modified = true;
    },

    mergePoints: function(p0,p1){
        if (p0 == p1)
            throw new Error("Cannot merge point to itself.");

        //remove direct segments
        for (var i = 0; i < p1.segments.length; i ++){

            var s = p1.segments[i];
            var pp = s.otherEnd(p1);
            if (pp == p0){
                this.removeSegment(s);
                i --;
            }
        }

        var neighborPoints = [];
        var neighborSegments = [];

        //collect neighbor points of p0;
        for (var i = 0; i < p0.segments.length; i ++){
            neighborPoints.push(p0.segments[i].otherEnd(p0));
            neighborSegments.push(p0.segments[i]);
        }


        //merge remaining segments
        while (p1.segments.length > 0){
            var s = p1.segments[p1.segments.length - 1];
            var pp = s.otherEnd(p1);
            var segI = neighborPoints.indexOf(pp);

            s.changeEnd(p1, p0);

            if (segI != -1)
            {
                this._mergeSegments(neighborSegments[segI], s);
            }
            else
            {
                neighborPoints.push(pp);
                neighborSegments.push(s);
            }
        }

        this.removePoint(p1);

        return p0;
    },

    _mergeSegments: function(s1,s2){
        //TODO: merge properties

        this.removeSegment(s2);
    },

    splitSegment: function(segment, point){
        var seg1 = this.newSegment(segment.p1, point);
        segment.changeEnd(segment.p1, point);
        return seg1;
    },

    getLineSegments: function(seg){
        var result = [seg];

        var s = seg;
        var p = seg.p0;

        while(p.segments.length == 2){
            if (p.segments[0] == s)
            {
                s = p.segments[1];
            }
            else
            {
                s = p.segments[0];
            }

            p = s.otherEnd(p);

            //prevent infinite loops
            if (result.indexOf(s) != -1)
                break;
            result.push(s);
        }

        s = seg;
        p = seg.p1;


        while(p.segments.length == 2){
            if (p.segments[0] == s)
            {
                s = p.segments[1];
            }
            else
            {
                s = p.segments[0];
            }

            p = s.otherEnd(p);

            //prevent infinite loops
            if (result.indexOf(s) != -1)
                break;

            result.push(s);
        }

        return result;
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
        else if (from == this.p1)
        {
            pos = this.p1.segments.indexOf(this);
            this.p1.segments.splice(pos, 1);

            this.p1 = to;

            this.p1.segments.push(this);
        }
        else
        {
            throw new Error("From not found");
        }
    },

    disconnect: function(){
        var pos = this.p0.segments.indexOf(this);
        this.p0.segments.splice(pos, 1);
        pos = this.p1.segments.indexOf(this);
        this.p1.segments.splice(pos, 1);
    }
};