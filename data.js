var DataStore = {
    newStore: function(){
        return new DataStore.Store();
    },

    newPoint: function(x,y){
        return {x:x,y:y};
    },

    newLine: function(){
        return {points:[]};
    }
};

DataStore.Store = function(){};

DataStore.Store.prototype = {
    points:[],
    lines:[],
    shapes:[],

    addPoint: function(p){
        this.points.push(p);
        p.created = true;
    },

    movePoint: function(p, x, y){
        p.x = x;
        p.y = y;
        p.modified = true;
    }

};