﻿class Game.Physics
  
  @SCALE: 20.0
  @GRAVITY: {x: 0, y: 50}
  
  _instance = undefined
  
  @instance: =>
    _instance ?= new Game.PhysicsImpl()
    
  @init: =>
    @instance().init()
    
  @update: (elapsed) =>
    @instance().update(elapsed)
  
  @createBody: (body) =>
    @instance().createBody(body)
  
class Game.PhysicsImpl
  
  fixedTick: 1 / 60
  
  proccessTime: 0
  
  showDebug: false
  
  init: =>
    @world = new Box2D.Dynamics.b2World(Game.Physics.GRAVITY, true)
    @world.SetContactListener(new CustomContactListener())
    
    @debugDraw = new Box2D.Dynamics.b2DebugDraw()
    @debugDraw.SetSprite(document.getElementById("debugCanvas").getContext("2d"))
    @debugDraw.SetDrawScale(Game.Physics.SCALE)
    @debugDraw.SetFillAlpha(0.5)
    @debugDraw.SetLineThickness(1.0)
    @debugDraw.SetFlags(Box2D.Dynamics.b2DebugDraw.e_shapeBit)
    @world.SetDebugDraw(@debugDraw)
    @createBoundingBox()
    
  update: (elapsed) =>
    
    @showDebug = !@showDebug if Game.Input.isKeyDown("d")
    
    @proccessTime += elapsed
    fixedTickMs = @fixedTick * 1000
    while(@proccessTime > fixedTickMs)
      @world.Step(@fixedTick, 10, 10)
      @world.ClearForces()
      @proccessTime -= fixedTickMs
      
    if @showDebug
      @world.DrawDebugData()
      $("#debugCanvas").show()
    else
      $("#debugCanvas").hide()

  createBody: (body) =>
    @world.CreateBody(body)

  createBoundingBox: =>
    scale = Game.Physics.SCALE
    fixDef = new Box2D.Dynamics.b2FixtureDef()
    fixDef.shape = new Box2D.Collision.Shapes.b2PolygonShape()
    fixDef.shape.SetAsBox(32 / scale, 400 / scale)
    fixDef.density = 0.0
    fixDef.friction = 0.0
    fixDef.restitution = 0
    bodyDef = new Box2D.Dynamics.b2BodyDef()
    bodyDef.type = Box2D.Dynamics.b2Body.b2_staticBody
    bodyDef.position.Set(-32 / scale, 0 / scale)
    @body = Game.Physics.createBody(bodyDef)
    @body.CreateFixture(fixDef)
    
class CustomContactListener extends Box2D.Dynamics.b2ContactListener
    
    BeginContact: (contact) =>
        fixtureA = contact.GetFixtureA()
        fixtureB = contact.GetFixtureB()
        userDataA = fixtureA.GetBody().GetUserData()
        userDataB = fixtureB.GetBody().GetUserData()
        if @checkReciprocrate(userDataA, userDataB, "player", "princess")
          Game.Instances.getPlayer().touchPrincess()
        if @checkReciprocrate(userDataA, userDataB, "player", "enemy")
          Game.Instances.getPlayer().die()
    
    PreSolve: (contact, oldManifold) =>
        fixtureA = contact.GetFixtureA()
        fixtureB = contact.GetFixtureB()
        userDataA = fixtureA.GetBody().GetUserData()
        userDataB = fixtureB.GetBody().GetUserData()
        #Player is dead, ignore collisions and let it fall
        if (userDataA == "player" || userDataB == "player")
          if (Game.Instances.getPlayer().isDead())
            contact.SetEnabled(false)    
        #Cloud platform (one-way platforms)
        if @checkReciprocrate(userDataA, userDataB, "player", "cloud")
          playerBody = fixtureA.GetBody()
          cloudBody = fixtureB.GetBody()
          [playerBody, cloudBody] = [cloudBody, playerBody] unless userDataA == "player"
          playerPosition = playerBody.GetPosition().y
          playerRadius = playerBody.GetFixtureList().GetShape().GetRadius()
          cloudPosition = cloudBody.GetPosition().y
          cloudVertices = cloudBody.GetFixtureList().GetShape().GetVertices()
          cloudHeight = cloudVertices[2].y - cloudVertices[0].y 
          if playerPosition - cloudPosition > -(playerRadius + (cloudHeight / 2) - 0.1)
            contact.SetEnabled(false)
            
      checkReciprocrate: (var1, var2, value1, value2) =>
        (var1 == value1 && var2 == value2) || (var1 == value2 && var2 == value1)