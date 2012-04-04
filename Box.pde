class Box
{
  int x;
  int y;
  int width;
  int height;
  
  boolean active;
  
  float startTime;
  float deltaTime;
  
  Box()
  {
    x = 0;
    y = 0;
    width = 1;
    height = 1;
    startTime = 0;
    deltaTime = 0;
    active = false;
  }
  
  Box(int x, int y, int width, int height)
  {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    startTime = 0;
    deltaTime = 0;
    active = false;
  }
  
  boolean inBox(PVector vec)
  {
    if(vec.x > x && vec.x < (x + width) && vec.y > y && vec.y < (y + height))
    {
      return true;
    }
    else
    {
      return false;
    }
  }
  
  void reset()
  {
    startTime = 0;
    deltaTime = 0;
  }
}
