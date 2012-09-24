class Intersection{
  double x;
  double y;
  double distance;
  Object item;

  Intersection(double x,double  y, double distance){
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
    double dist = sqrt((x - x0) * (x - x0) + (y - y0) * (y - y0));

    return new Intersection(x,y,dist);
  }


  static Intersection intersection(double s1x1, double s1y1, double s1x2, double s1y2, double s2x1,double s2y1, double s2x2,double s2y2) {
    var x11_21 = s1x1 - s2x1;
    var y11_21 = s1y1 - s2y1;
    var x12_11 = s1x2 - s1x1;
    var y12_11 = s1y2 - s1y1;
    var y22_21 = s2y2 - s2y1;
    var x22_21 = s2x2 - s2x1;
    var d = (y22_21 * x12_11) - (x22_21 * y12_11);
    var n1 = (x22_21 * y11_21) - (y22_21 * x11_21);
    var n2 = (x12_11 * y11_21) - (y12_11 * x11_21);

    if (d == 0){
      //parralel
      if (n1 == 0 && n2 == 0){
        //overlaps
      }
    }
    else{
      var along1 = n1 / d;
      var along2 = n2 / d;
      if(along1 >= 0 && along1 <= 1 && along2 >=0 && along2 <= 1) {
        // calculate the intersection point
        var x = s1x1 + (along1 * x12_11);
        var y = s1y1 + (along1 * y12_11);
        return new Intersection(x,y,0.0);
      }
    }

    return null;
  }

  static double distanceSquared(double x, double y, double x1, double y1){
    return (x - x1) * (x-x1) + (y-y1)* (y-y1);
  }
}
