Flock flock_mikata;
Flock flock_teki;
int state = 0;

int MIKATA_NUM = 100;
int TEKI_NUM = 50;
int MIKATA_HP = 100;
int TEKI_HP = 1000;

int mikata_alive;
int teki_alive;

void setup() {
  size(640, 360);
  textSize(16);
  textAlign(CENTER);
  initFlock();
}

void draw() {
  background(50);
  switch(state) {
    case 0:
      text("Press Space Key to start", 320, 180);
      break;
      
    case 1:
      flock_teki.run();
      flock_mikata.run();
      for (int i = 0; i < flock_mikata.clickedArea.size(); i++) {
        ellipse(flock_mikata.clickedArea.get(i).x, flock_mikata.clickedArea.get(i).y, 10, 10);
      }
      text("You : "+mikata_alive + "   COM : "+teki_alive, 100, 30);
      break;
      
    case 2:
      text("You Win!!!", 320, 180);
      text("Press [Space] Key to restart", 320, 200);
      break;
      
    case 3:
      text("You Lose...", 320, 180);
      text("Press [Space] Key to restart", 320, 200);
      break;
      
    default:
      background(50);
      break;
  }
}

// Add a new boid into the System
void mousePressed() {
//  flock.addBoid(new Boid(mouseX,mouseY));
  if (mouseButton == LEFT) {
    flock_mikata.clickedArea.clear();
    flock_mikata.clickedArea.add(new PVector(mouseX,mouseY));
  }else if (mouseButton == RIGHT) {
    flock_mikata.clickedArea.clear();
  }
  println(flock_mikata.clickedArea);
}



// The Flock (a list of Boid objects)

class Flock {
  ArrayList<Boid> boids; // An ArrayList for all the boids
  ArrayList<PVector> clickedArea;
  Boolean ally;

  Flock(Boolean mikata) {
    ally = mikata;
    boids = new ArrayList<Boid>(); // Initialize the ArrayList
    clickedArea = new ArrayList<PVector>();
  }

  void run() {
    if (ally) {
      for (Boid b : boids) {
        if (b.alive){
          b.run(boids, flock_teki.boids);  // Passing the entire list of boids to each boid individually
        }
      }
    }else {
      for (Boid b : boids) {
        if (b.alive){
          b.run(boids, flock_mikata.boids);  // Passing the entire list of boids to each boid individually
        }
      }
    }
  }

  void addBoid(Boid b) {
    boids.add(b);
  }

}




// The Boid class

class Boid {

  PVector position;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed
  Boolean ally;
  int hp;
  Boolean alive;

  Boid(float x, float y, Boolean mikata) {
    acceleration = new PVector(0, 0);

    // This is a new PVector method not yet implemented in JS
    // velocity = PVector.random2D();
    ally = mikata;
    
    float angle;
    // Leaving the code temporarily this way so that this example runs in JS
    //float angle = random(TWO_PI);
    if(ally) {
      angle = TWO_PI;
    }else {
      angle = TWO_PI/2;
    }
    
    velocity = new PVector(cos(angle), sin(angle));

    position = new PVector(x, y);
    r = 2.0;
    maxspeed = 0.7;
    maxforce = 0.03;
    if (ally) {
      hp = MIKATA_HP;
    }else {
      hp = TEKI_HP;
    }
    alive = true;
  }

  void run(ArrayList<Boid> boids, ArrayList<Boid> teki_boids) {
    flock(boids, teki_boids);
    Boid b = battle(teki_boids); 
    if (b != null) {
      acceleration.mult(0);
    } else {
      update();
    }
    borders();
    render();
  }
  
  void applyForce(PVector force) {
    // We could add mass here if we want A = F / M
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids, ArrayList<Boid> teki_boids) {
    PVector sep = separate(boids);   // Separation
    PVector ali = align(boids);      // Alignment
    PVector coh = cohesion(boids);   // Cohesion
    // Arbitrarily weight these forces
    sep.mult(1.5);
    ali.mult(1.0);
    coh.mult(1.0);
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
    
    if(flock_mikata.clickedArea.size() != 0 && ally){
      double MIN = 10000000000.0;
      PVector MousePosition = new PVector(0,0);
      for(int i = 0; i < flock_mikata.clickedArea.size(); i++) {
        double l = (flock_mikata.clickedArea.get(i).x-position.x)*(flock_mikata.clickedArea.get(i).x-position.x) + (flock_mikata.clickedArea.get(i).y-position.y)*(flock_mikata.clickedArea.get(i).y-position.y);
        if (l < MIN) {
          MousePosition = new PVector(flock_mikata.clickedArea.get(i).x, flock_mikata.clickedArea.get(i).y);
          MIN = l;
        }
      }
      //println(MousePosition);
      MousePosition.sub(position);
      MousePosition.normalize();
      MousePosition.mult(0.05);
      applyForce(MousePosition);
    }
    
  }

  // Method to update position
  void update() {
    // Update velocity
    velocity.add(acceleration);
    // Limit speed
    velocity.limit(maxspeed);
    position.add(velocity);
    // Reset accelertion to 0 each cycle
    acceleration.mult(0);
  }

  // A method that calculates and applies a steering force towards a target
  // STEER = DESIRED MINUS VELOCITY
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, position);  // A vector pointing from the position to the target
    // Scale to maximum speed
    desired.normalize();
    desired.mult(maxspeed);

    // Above two lines of code below could be condensed with new PVector setMag() method
    // Not using this method until Processing.js catches up
    // desired.setMag(maxspeed);

    // Steering = Desired minus Velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    return steer;
  }

  void render() {
    // Draw a triangle rotated in the direction of velocity
    float theta = velocity.heading2D() + radians(90);
    // heading2D() above is now heading() but leaving old syntax until Processing.js catches up
    
    fill(200, 100);
    stroke(255);
    if (!ally) {
      stroke(255,0,0);
    }
    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    beginShape(TRIANGLES);
    vertex(0, -r*2);
    vertex(-r, r*2);
    vertex(r, r*2);
    endShape();
    popMatrix();
  }

  // Wraparound
  void borders() {
    if (position.x < -r) position.x = width+r;
    if (position.y < -r) position.y = height+r;
    if (position.x > width+r) position.x = -r;
    if (position.y > height+r) position.y = -r;
  }

  // Separation
  // Method checks for nearby boids and steers away
  PVector separate (ArrayList<Boid> boids) {
    float desiredseparation = 25.0f;
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    // For every boid in the system, check if it's too close
    for (Boid other : boids) {
      if (other.alive){
        float d = PVector.dist(position, other.position);
        // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
        if ((d > 0) && (d < desiredseparation)) {
          // Calculate vector pointing away from neighbor
          PVector diff = PVector.sub(position, other.position);
          diff.normalize();
          diff.div(d);        // Weight by distance
          steer.add(diff);
          count++;            // Keep track of how many
        }
      }
    }
    // Average -- divide by how many
    if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.mag() > 0) {
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // steer.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }

  // Alignment
  // For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids) {
    float neighbordist = 50;
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) {
      if(other.alive){
        float d = PVector.dist(position, other.position);
        if ((d > 0) && (d < neighbordist)) {
          sum.add(other.velocity);
          count++;
        }
      }
    }
    if (count > 0) {
      sum.div((float)count);
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // sum.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } 
    else {
      return new PVector(0, 0);
    }
  }

  // Cohesion
  // For the average position (i.e. center) of all nearby boids, calculate steering vector towards that position
  PVector cohesion (ArrayList<Boid> boids) {
    float neighbordist = 50;
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all positions
    int count = 0;
    for (Boid other : boids) {
      if(other.alive){
        float d = PVector.dist(position, other.position);
        if ((d > 0) && (d < neighbordist)) {
          sum.add(other.position); // Add position
          count++;
        }
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);  // Steer towards the position
    } 
    else {
      return new PVector(0, 0);
    }
  }
  
  Boid battle(ArrayList<Boid> teki_boids) {
    float distance = 30;
    float min_boids = 100000000;
    Boid battle_boid = null;
    for (Boid other : teki_boids) {
      if (other.alive){
        float d = PVector.dist(position, other.position);
        if ((d > 0) && (d < distance)) {
          if (min_boids > d) {
            battle_boid = other;
            min_boids = d;
          }
        }
      }
    }
    if (battle_boid != null) {
      battle_boid.hp -= 1;
      if (battle_boid.hp <= 0) {
        battle_boid.alive = false;
        if (battle_boid.ally) {
          mikata_alive -= 1;
        } else {
          teki_alive -= 1;
        }
        if (aliveNum(flock_teki) == 0) {
          state = 2;
        } else if(aliveNum(flock_mikata) == 0) {
          state = 3;
        }
      }
    }
    return battle_boid;
  }
}

void initFlock() {
  flock_mikata = new Flock(true);
  flock_teki = new Flock(false);
  // Add an initial set of boids into the system
  for (int i = 0; i < MIKATA_NUM; i++) {
    flock_mikata.addBoid(new Boid(width/4,height/4+i*(float(height)/(2.0*MIKATA_NUM)), flock_mikata.ally));
  }
  for (int i = 0; i < TEKI_NUM; i++) {
    flock_teki.addBoid(new Boid(width*3/4,height/4+i*(float(height)/(2.0*TEKI_NUM)), flock_teki.ally));
  }
  mikata_alive = MIKATA_NUM;
  teki_alive = TEKI_NUM;
}

int aliveNum(Flock flock) {
  int num = 0;
  for (int i = 0; i < flock.boids.size(); i++) {
    if (flock.boids.get(i).alive) {
      num += 1;
    }
  }
  return num;
}



void keyPressed() {
  if (keyCode == ENTER){
    save("sample.png");
  } else if (keyCode == ' ') {
    initFlock();
    state = 1;
  }
}
