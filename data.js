var DataStore = {
    newStore: function(){
        return new DataStore.Store();
    },

    newPoint: function(x,y){
        return {type:"point",x:x,y:y};
    },

    newLine: function(){
        return {type:"line",points:[]};
    }
};

DataStore.Store = function(){};

DataStore.Store.prototype = {
    points:[],
    lines:[],
    shapes:[],

    addPoint: function(p){
        p.created = true;
        this.points.push(p);
    },

    newPoint: function(x,y){
        var p = DataStore.newPoint(x,y);
        this.addPoint(p);
        return p;
    },

    addLine: function(points){
        var l = DataStore.newLine();
        l.points = points;
        l.created = true;
        this.lines.push(l);
        return l;
    },

    lineSetPoints: function(l, points){
        l.points = points;
        l.modified = true;
    },

    pointMove: function(p, x, y){
        p.x = x;
        p.y = y;
        p.modified = true;
    }

};