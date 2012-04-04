/* --------------------------------------------------------------------------
 * Bodies of Words v2
 * Ryan Kornheisl and Johndan Johnson-Eilola
 * --------------------------------------------------------------------------
 */

import SimpleOpenNI.*;
//import fullscreen.*;

SimpleOpenNI kinect;
BodiesOfWords bow;

// NITE
XnVSessionManager sessionManager;
XnVFlowRouter flowRouter;

PointDrawer pointDrawer;

boolean screenToggle;

int offset;

//FullScreen fs;

void setup()
{
  kinect = new SimpleOpenNI(this);
  
  bow = new BodiesOfWords("johndan"); // Give bodies of words the query for twitter search
  screenToggle = false;
  
  // mirror is by default enabled
  kinect.setMirror(true);
  
  // enable depthMap generation 
  kinect.enableDepth();
  kinect.enableRGB();
  
  // enable the hands + gesture
  kinect.enableGesture();
  kinect.enableHands();
 
  // setup NITE 
  sessionManager = kinect.createSessionManager("Click,Wave", "RaiseHand");

  pointDrawer = new PointDrawer();
  flowRouter = new XnVFlowRouter();
  flowRouter.SetActive(pointDrawer);
  
  //fs = new FullScreen(this);
  
  sessionManager.AddListener(flowRouter);
  
  size(640, 520); //size of program window
  offset = (height-40) - kinect.depthHeight();
  smooth();
  //fs.enter(); // turn on full screen
}

void draw()
{
  background(0,0,0);
  // update the cam
  kinect.update();
  
  // update nite
  kinect.update(sessionManager);
  
  bow.update(40);
  
  // draw depthImageMap
  if(screenToggle)
    image(kinect.rgbImage(), 0, offset);
  else
    image(kinect.depthImage(), 0, offset);
  
  // draw the list
  pointDrawer.draw();
  
  bow.draw();
}

void keyPressed()
{
  switch(key)
  {
  case 'e':
    // end sessions
    sessionManager.EndSession();
    println("end session");
    break;
  case 't':
    screenToggle = !screenToggle;
    break;
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// session callbacks

void onStartSession(PVector pos)
{
  println("onStartSession: " + pos);
}

void onEndSession()
{
  println("onEndSession: ");
}

void onFocusSession(String strFocus,PVector pos,float progress)
{
  println("onFocusSession: focus=" + strFocus + ",pos=" + pos + ",progress=" + progress);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// PointDrawer keeps track of the handpoints

class PointDrawer extends XnVPointControl
{
  HashMap    _pointLists;
  int        _maxPoints;
  color[]    _colorList = { color(255,0,0),color(0,255,0),color(0,0,255),color(255,255,0)};
  
  public PointDrawer()
  {
    _maxPoints = 30;
    _pointLists = new HashMap();
  }
	
  public void OnPointCreate(XnVHandPointContext cxt)
  {
    // create a new list
    addPoint(cxt.getNID(),new PVector(cxt.getPtPosition().getX(),cxt.getPtPosition().getY(),cxt.getPtPosition().getZ()));
    
    println(int(cxt.getNID()%4));
    bow.addHand(int(cxt.getNID()%4), cxt.getPtPosition().getX(), cxt.getPtPosition().getY() + offset, cxt.getPtPosition().getZ());
    
    println("OnPointCreate, handId: " + cxt.getNID());
  }
  
  public void OnPointUpdate(XnVHandPointContext cxt)
  {
    //println("OnPointUpdate " + cxt.getPtPosition());   
    addPoint(cxt.getNID(),new PVector(cxt.getPtPosition().getX(),cxt.getPtPosition().getY(),cxt.getPtPosition().getZ()));
    
    PVector screenpos = new PVector();
    PVector v = new PVector(cxt.getPtPosition().getX(),cxt.getPtPosition().getY(), cxt.getPtPosition().getZ());
    kinect.convertRealWorldToProjective(v, screenpos);
    bow.addHand(int(cxt.getNID()%4), screenpos.x, screenpos.y + offset, cxt.getPtPosition().getZ());
  }
  
  public void OnPointDestroy(long nID)
  {
    println("OnPointDestroy, handId: " + nID);
    
    // remove list
    if(_pointLists.containsKey(nID))
       _pointLists.remove(nID);
       
    bow.addHand(int(nID%4), 720, 720, 0);
  }
  
  public ArrayList getPointList(long handId)
  {
    ArrayList curList;
    if(_pointLists.containsKey(handId))
      curList = (ArrayList)_pointLists.get(handId);
    else
    {
      curList = new ArrayList(_maxPoints);
      _pointLists.put(handId,curList);
    }
    return curList;  
  }
  
  public void addPoint(long handId,PVector handPoint)
  {
    ArrayList curList = getPointList(handId);
    
    curList.add(0,handPoint);      
    if(curList.size() > _maxPoints)
      curList.remove(curList.size() - 1);
  }
  
  public void draw()
  {
    if(_pointLists.size() <= 0)
      return;
      
    pushStyle();
      noFill();
      
      PVector vec;
      PVector firstVec;
      PVector screenPos = new PVector();
      int colorIndex=0;
      
      // draw the hand lists
      Iterator<Map.Entry> itrList = _pointLists.entrySet().iterator();
      while(itrList.hasNext()) 
      {
        strokeWeight(2);
        stroke(_colorList[colorIndex % (_colorList.length - 1)]);

        ArrayList curList = (ArrayList)itrList.next().getValue();     
        
        // draw line
        firstVec = null;
        Iterator<PVector> itr = curList.iterator();
        beginShape();
          while (itr.hasNext()) 
          {
            vec = itr.next();
            if(firstVec == null)
              firstVec = vec;
            // calc the screen pos
            kinect.convertRealWorldToProjective(vec,screenPos);
            vertex(screenPos.x,screenPos.y + offset);
          } 
        endShape();   
  
        // draw current pos of the hand
        if(firstVec != null)
        {
          strokeWeight(8);
          kinect.convertRealWorldToProjective(firstVec,screenPos);
          point(screenPos.x,screenPos.y + offset);
        }
        colorIndex++;
      }
      
    popStyle();
  }

}
