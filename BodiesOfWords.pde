import java.util.regex.*;

class BodiesOfWords
{  
  // NOTE: twitter4j.jar is currently in the Code folder (not library).

  String OAuthConsumerKey = "<insert>";
  String OAuthConsumerSecret = "<insert>";

  // This is where you enter your Access Token info
  String AccessToken = "<insert";
  String AccessTokenSecret = "<insert>";

  PVector[] hand;
  boolean[] hold;

  PFont font, font2;

  final int WORDCOUNT = 140; // This determines the maximum allowed character count of message
  
  String queryStr;

  Twitter twitter;
  String[] wordPool;
  int randomWord;
  String wholeSentence;
  int wordCount;
  int wordlifebase;
  
  int threshold = 2000;

  ArrayList tweet;
  ArrayList words;
  Box wordBin;
  Box undo;
  Box send;

  BodiesOfWords(String query)
  {
    hand = new PVector[4];
    hand[0] = new PVector(720, 720, 0);
    hand[1] = new PVector(720, 720, 0);
    hand[2] = new PVector(720, 720, 0);
    hand[3] = new PVector(720, 720, 0);
    hold = new boolean[4];
    hold[0] = false;
    hold[1] = false;
    hold[2] = false;
    hold[3] = false;
    tweet = new ArrayList();
    words = new ArrayList();
    wordBin = new Box(0, 0, 640, 100); //creates word bin x, y, width, height
    undo = new Box(100, 400, 75, 25); //creates undo box
    send = new Box(450, 400, 75, 25); //creates send box

    queryStr = query;
    twitter = new TwitterFactory().getInstance();
    connectTwitter();
    wordCount = WORDCOUNT;
    getNewPool();
    wholeSentence = "";
    
    for(int i = 0; i < 5; i++) // This here determines the number of word to appear on the screen
    {
      words.add(new Word());
      getNewWord(i);
    }
    print("Bodies of Words initialized");
    
    wordlifebase = 8000; //base amount of time before word changes

    font = loadFont("Georgia-24.vlw");
    textFont(font);
    //font2 = loadFont("Serif-36.vlw");
  }

  void connectTwitter()
  { 
    twitter.setOAuthConsumer(OAuthConsumerKey, OAuthConsumerSecret);
    AccessToken accessToken = loadAccessToken();
    twitter.setOAuthAccessToken(accessToken);
    println("Twitter connected");
  }

  private AccessToken loadAccessToken()
  {
    return new AccessToken(AccessToken, AccessTokenSecret);
  }

  void getNewWord(int index)
  {
    if(index >= 5)
    {
      words.remove(index);
      return;
    }
    randomWord = int(random(wordPool.length));
    while((wordCount - wordPool[randomWord].length()) < 0 && wordPool[randomWord] != "")
    {
      randomWord = int(random(wordPool.length));
    }
    Word temp = (Word) words.get(index);
    temp.word = wordPool[randomWord];
    temp.wordBorn = millis();
    temp.wordLife = 0;
    temp.grabbed = false;
    temp.loc = new PVector((index + 1) * ((width/5)-30), 150 + (index%2 * 25), 0);
    words.set(index, temp);
  }

  void getNewPool()
  {
    try
    {
      Query query = new Query(queryStr);
      query.setRpp(20);
      QueryResult result = twitter.search(query);
      ArrayList tweets = (ArrayList)result.getTweets();
      StringBuilder sb = new StringBuilder();

      for(int i = 0; i < tweets.size(); i++)
      {
        Tweet t = (Tweet)tweets.get(i);
        String temp = t.getText();
        temp = temp.replaceAll("#[A-Za-z0-9]*[^A-Za-z0-9#]*|@[A-Za-z0-9]*[^A-Za-z0-9@]*|http://[A-Za-z0-9.]*/?", " ");
        temp = temp.replaceAll("[^A-Za-z0-9' ]", " ");
        temp = temp.toLowerCase();
        sb.append(temp);
        sb.append(" ");
      }

      wordPool = sb.toString().split("[ \t]+");
      print("Word Pool populated");
    }
    catch(TwitterException e)
    {
      println("Search tweets: " + e);
    }
  }

  boolean isNear(PVector word, PVector hand, int radius)
  {
    if(sqrt(sq(word.x - hand.x) + sq(word.y - hand.y)) <= radius)
    {
      return true;
    }
    else
    {
      return false;
    }
  }
  
  boolean isClicked(PVector hand)
  {
    if(hand.z <= threshold)
    {
      return true;
    }
    else
    {
      return false;
    }
  }

  void addHand(int ID, float x, float y, float z)
  {
    hand[ID] = new PVector(x, y, z);
  }
  
  void setThreshold(int i)
  {
    threshold += i;
  }

  void updateSentence()
  {
    StringBuilder sb = new StringBuilder();
    for(int i = 0; i < tweet.size(); i++)
    {
      Word word = (Word) tweet.get(i);
      sb.append(word.word);
    }
    if(sb.toString().length() > 140)
      print("Tweet too long");
    else
      wholeSentence = sb.toString();
  }
  
  void cleanTweet()
  {
    Word word;
    int totalWords = 0;
    int offsetW = 0;
    int offsetY = 30; // Size of line
    int offsetX = 10; // Size of space
    for(int i = 0; i < tweet.size(); i++)
    {
      word = (Word) tweet.get(i);
      if((word.loc.x + textWidth(word.word)/2) > width)
      {
        offsetY += 30;
      }
      word.loc.set(offsetX + offsetW + textWidth(word.word)/2, offsetY, 0);
      offsetW += textWidth(word.word) + 10;
      totalWords += word.word.length();
    }
    wordCount = WORDCOUNT - totalWords;
  }
      
  
  void updateTweet(Word word)
  {
    if(tweet.size() > 0)
    {
      int index = 0;
      for(int i = 0; i < tweet.size(); i++)
      {
        Word lastWord = (Word) tweet.get(i);
        if(word.loc.x > lastWord.loc.x)
        {
          index++;
        }
      }
      tweet.add(index, word);
    }
    else
    {
      tweet.add(word);
    }
    print(tweet.size());
    cleanTweet();
  }
        
  void update(int radius)
  {
    hold[0] = false;
    hold[1] = false;
    hold[2] = false;
    hold[3] = false;

    //This huge for loop checks the location of each word compared to
    //anything it can interact with
    for(int i = 0; i < words.size(); i++)
    {
      Word word = (Word) words.get(i);
      if(word.wordLife >= (i * 1000) + wordlifebase && !word.grabbed && !word.placed)
      {
        getNewWord(i);
      } 

      if(wordBin.inBox(word.loc)) //Is the held word in the word bin?
      {
        if(!wordBin.active && word.grabbed)
        {
          wordBin.active = true;
        }
        else if(word.word.length() <= wordCount && !word.placed && !word.grabbed)
        {
          word.placed = true;
          updateTweet(word);
          words.add(i, new Word());
          getNewWord(i);
          i++;
        }
      }     
      else
      {
        word.placed = false;
        if(tweet.contains(word) && !word.placed)
        {
          tweet.remove(tweet.indexOf(word));
          words.remove(i);
          cleanTweet();
        }
      } 
      for(int j = 0; j < 4; j++) //let's check if the word is near each hand
      {
        if(isNear(word.loc, hand[j], radius))
        {
          word.strokeColor = int((hand[j].z - threshold)) * 2;
          if(isClicked(hand[j]) && !hold[j])
          {
            hold[j] = true;
            word.loc.set(hand[j].x, hand[j].y, 0);
            word.grabbed = true;
            word.placed = false;
            word.strokeColor = 0;
            j = 4;
          }
        }
        else
        {
          word.grabbed = false;
          word.wordLife = millis() - word.wordBorn;
        }
        
      }
    }

    //This loop checks if a person's hand is inside one of the buttons
    for(int i = 0; i < hand.length; i++)
    {
      //Undo box detection
      if(undo.inBox(hand[i]) && tweet.size() > 0)
      {
        undo.active = true;
        if(undo.startTime == 0)
        {
          undo.startTime = millis();
        }
        else if(undo.deltaTime >= 2000)
        {
          updateSentence();
          undo.reset();
        }
        else
        {
          undo.deltaTime = millis() - undo.startTime;
        }
      }

      //Send box detection
      if(send.inBox(hand[i]) && tweet.size() > 0)
      {
        send.active = true;
        if(send.startTime == 0)
        {
          send.startTime = millis();
        }
        else if(send.deltaTime >= 2000)
        {
          /*try
          {
            twitter.updateStatus(wholeSentence);
          }
          catch(TwitterException e)
          {
            println("Send tweet failed");
          }*/
          updateSentence();
          print(wholeSentence);
          tweet.clear();
          tweet.trimToSize();
          send.reset();
          getNewPool();
          for(int w = 0; w < 5; w++) // This here determines the number of word to appear on the screen
          {
            words.add(new Word());
            getNewWord(w);
          }
        }
        else
        {
          send.deltaTime = millis() - send.startTime;
        }
      }
    }
    if(undo.active == false)
    {
      undo.reset();
    }
    if(send.active == false)
    {
      send.reset();
    }
  }

  void draw()
  {
    //Draw word bin
    if(wordBin.active)
      fill(162, 205, 90);
    else
      fill(162, 205, 90, 75);
    rect(wordBin.x, wordBin.y, wordBin.width, wordBin.height);
    wordBin.active = false;

    //Draw undo and send button
    textSize(18);
    fill(255 - int(undo.deltaTime/10));
    rect(undo.x, undo.y, undo.width, undo.height);
    fill(0 + int(undo.deltaTime/10));
    text("UNDO", undo.x + undo.width/2, undo.y + 20);
    
    fill(255 - int(send.deltaTime/10));
    rect(send.x, send.y, send.width, send.height);
    fill(0 + int(send.deltaTime/10));
    text("SEND", send.x + send.width/2, send.y + 20);
    
    undo.active = false;
    send.active = false;

    //Text for the words you grab
    textSize(24);// Grabbable word size
    textAlign(CENTER);
    for(int i = 0; i < words.size(); i++)
    {
      Word word = (Word) words.get(i);
      fill(50, 100, 250, 200); // ellipse color
      noStroke();
      ellipse(word.loc.x, word.loc.y, 20, 20); // ellipse near each word
      fill(255, word.strokeColor, word.strokeColor);
      text(word.word, word.loc.x, word.loc.y);
      word.strokeColor = 255;
      words.set(i, word);
    }
    textAlign(LEFT);
    textSize(24); //Twitter sentence size
    text(wholeSentence, 10, 10, 630, 100); // Prints the current twitter message
    textSize(24); //Word count size
    textAlign(CENTER);
    if(wordCount <= 20)
      fill(255, 0, 0);
    else
      fill(255);
    text("Characters Remaining: " + wordCount, width/2, height-10); // Print characters remaining
  }
}

