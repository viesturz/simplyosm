class Tool {

  static final int STATUS_SKIP = 0;
  static final int STATUS_ACTIVE = 1;
  static final int STATUS_FINISHED = 2;

  View view;

  void attach(View _view){
    this.view = _view;
  }

  int mouseDown(double canvasX, double canvasY){return STATUS_SKIP;}
  int mouseUp(double canvasX, double canvasY){return STATUS_SKIP;}
  int mouseMove(double canvasX,double  canvasY, double canvasXPrev, double canvasYPrev, MouseEvent evt){return STATUS_SKIP;}
  void cancel(){}
  
}

