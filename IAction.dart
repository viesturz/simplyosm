interface IAction {
  void paint(View view);
  bool hit(View view, double canvasX, double canvasY);

  void mouseMove(View view, double canvasX, double canvasY);
  void click(View view, double canvasX, double canvasY);
}

class ActionsTool extends Tool{
  AreasLayer layer;
  IAction active;
  
  ActionsTool(AreasLayer layer){
    this.layer = layer;
    this.active = null;
  }
  
  int mouseDown(double canvasX, double canvasY){
    if (this.active == null){
      return Tool.STATUS_SKIP;
    }
    
    return Tool.STATUS_ACTIVE;
  }
  
  int mouseUp(double canvasX, double canvasY){
    if (this.active == null)
      return Tool.STATUS_SKIP;
    
    this.active.click(this.view, canvasX, canvasY);

    if (this.layer.actions.indexOf(this.active) == -1)
    {
      return Tool.STATUS_ACTIVE;
    }
    else
    {
      this.active = findNewAction(canvasX, canvasY);
      return this.active != null ? Tool.STATUS_ACTIVE : Tool.STATUS_FINISHED;
    }
  }

  IAction findNewAction(double canvasX,double  canvasY)
  {
    for(IAction action in this.layer.actions)
    {
      if (action.hit(this.view, canvasX, canvasY))
      {
        action.mouseMove(this.view, canvasX, canvasY);
        return action;
      }
    }
    
    return null;
  }
  
  int mouseMove(double canvasX,double  canvasY, double canvasXPrev, double canvasYPrev, MouseEvent evt){
    
    if (this.active != null && this.active.hit(this.view, canvasX, canvasY)){
      this.active.mouseMove(this.view, canvasX, canvasY);
      return Tool.STATUS_ACTIVE;
    }
    
    this.active = findNewAction(canvasX, canvasY);
    return this.active != null ? Tool.STATUS_ACTIVE : Tool.STATUS_SKIP;
  }

  void cancel(){
    this.active = null;
  }


}