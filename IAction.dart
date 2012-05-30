interface IAction {
  static final int STATUS_SKIP = 0; //did not click on
  static final int STATUS_ACTIVE = 1; ///clicked on
  static final int STATUS_FINISHED = 2; //clicked on and this action should be removed: TODO: is this needed?

  void paint(View view);
  bool hit(View view, double canvasX, double canvasY);

  int mouseMove(View view, double canvasX, double canvasY);
  int click(View view, double canvasX, double canvasY);
}
