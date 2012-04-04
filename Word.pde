class Word
{
  float wordBorn;
  float wordLife;
  boolean grabbed;
  int strokeColor;
  boolean placed;
  
  String word;
  
  PVector loc;
  
  float startTime;
  float deltaTime;
  
  Word()
  {
    wordBorn = 0;
    wordLife = 0;
    startTime = 0;
    deltaTime = 0;
    grabbed = false;
    placed = false;
    strokeColor = 255;
    word = "";
    loc = new PVector(0, 0, 0);
  }
  
  void reset()
  {
    startTime = 0;
    deltaTime = 0;
  }
}
