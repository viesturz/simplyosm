class Intersection{
  double x;
  double y;
  double distance;
  Object item;
  
  Intersection(x, y, distance){
    this.x = x;
    this.y = y;
    this.distance = distance;
  }
}

class Geometry {
  
  static Intersection distanceToSegment(double x1, double y1, double x2, double y2, double x0,double y0) {
    double dx = x2 - x1;
    double dy = y2 - y1;
    double along = ((dx * (x0 - x1)) + (dy * (y0 - y1))) / (dx*dx + dy*dy);
    double x, y;
    if(along <= 0.0) {
        x = x1;
        y = y1;
    } else if(along >= 1.0) {
        x = x2;
        y = y2;
    } else {
        x = x1 + along * dx;
        y = y1 + along * dy;
    }
    double dist = Math.sqrt((x - x0) * (x - x0) + (y - y0) * (y - y0));
    
    return new Intersection(x,y,dist);
  }
  
  static double distanceSquared(double x, double y, double x1, double y1){
    return (x - x1) * (x-x1) + (y-y1)* (y-y1);
  }
}
