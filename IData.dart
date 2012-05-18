interface IData{

  void deleteItems(Collection<Object> items);
  
  void undo();
  void redo();
  void toOsm();
  void fromOsm();

  //TODO: more stuff...

}