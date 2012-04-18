package ca.esdot.runnermark
{
	import ca.esdot.runnermark.sprites.EnemySprite;
	import ca.esdot.runnermark.sprites.GenericSprite;
	import ca.esdot.runnermark.sprites.RunnerSprite;
	import ca.esdot.stats.FastStats;
	
	import com.gskinner.zoe.utils.CachedClip;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	
	import swc.Runner;
	
	public class RunnerEngine
	{	
		[Embed(source="assets/bg1.png")]
		protected static var Bg1:Class;
		public static var bg1Data:BitmapData = new Bg1().bitmapData;
		
		[Embed(source="assets/bg2.png")]
		protected static var Bg2:Class;
		public static var bg2Data:BitmapData = new Bg2().bitmapData;
		
		[Embed(source="assets/groundTop.png")]
		protected static var GroundTop:Class;
		public static var groundData:BitmapData = new GroundTop().bitmapData;
		
		[Embed(source="assets/cloud.png")]
		protected static var Cloud:Class;
		public static var cloudData:BitmapData = new Cloud().bitmapData;
		
		protected var _root:*;
		
		protected const SPEED:Number = .33;
		
		public var sky:GenericSprite;
		public var bgStrip1:GenericSprite;
		public var bgStrip2:GenericSprite;
		public var runner:RunnerSprite;
		
		protected var spritePool:Object = {};
		
		protected var lastGroundPiece:GenericSprite;
		
		protected var groundList:Array = [];
		protected var particleList:Array = [];
		protected var enemyList:Array = [];
		
		protected var ticks:int = 0;
		
		protected var stageWidth:int;
		protected var stageHeight:int;
		protected var groundY:int;
		
		protected var currentLoad:int = 20;
		
		public function RunnerEngine(root:*, stageWidth:int, stageHeight:int){
			super();
			this._root = root;
			
			createChildren();
			
			this.stageWidth = stageWidth;
			this.stageHeight = stageHeight;
			
			sky.width = stageWidth;
			sky.height = stageHeight;
			
			//BG1
			bgStrip1.height = stageHeight * .7;
			bgStrip1.scaleX = bgStrip1.scaleY;
			bgStrip1.y = stageHeight - bgStrip1.height;
			
			//BG2
			bgStrip2.height = stageHeight * .7;
			bgStrip2.scaleX = bgStrip2.scaleY;
			bgStrip2.y = stageHeight - bgStrip2.height;
			
			//Create Runner
			groundY = stageHeight - runner.height - 75;
			runner.x = stageWidth * .2;
			runner.y = groundY;
			runner.groundY = groundY;
			runner.enemyList = enemyList;
			
			//Add Ground
			addGround(3);
			
			//Add Particles
			addParticles(32);
		}
		
	/**
	 * CREATE METHODS
	 * Override these to create a new type of testSuite
	 **/
		public function createChildren():void {
			
			var skyData:BitmapData = createSkyData();			
			sky = new GenericSprite(new Bitmap(skyData));
			_root.addChild(sky.display);
			
			var bitmap1:Bitmap, bitmap2:Bitmap;
			var sprite:Sprite = new Sprite();
			
			//BG Strip 1
			bitmap1 =  new Bg1();
			sprite.addChild(bitmap1);
			bitmap2 = new Bg1();
			bitmap2.x = bitmap1.width;
			sprite.addChild(bitmap2);
			bgStrip1 = new GenericSprite(sprite);
			_root.addChild(bgStrip1.display);
			
			//BG Strip 2
			sprite = new Sprite();
			bitmap1 =  new Bg2();
			sprite.addChild(bitmap1);
			bitmap2 = new Bg2();
			bitmap2.x = bitmap1.width;
			sprite.addChild(bitmap2);
			bgStrip2 = new GenericSprite(sprite);
			_root.addChild(bgStrip2.display);
			
			//Runner
			runner = new RunnerSprite(new CachedClip(swc.Runner, 70, 140));
			_root.addChild(runner.display);
		}
		
		protected function createGroundPiece():GenericSprite {
			var sprite:GenericSprite = getSprite("ground");
			if(!sprite){
				sprite = new GenericSprite(new Bitmap(groundData), "ground");
			}
			_root.addChildAt(sprite.display, _root.getChildIndex(bgStrip2.display) + 1);
			return sprite; 
		}
		
		
		protected function createParticle():GenericSprite {
			var sprite:GenericSprite = getSprite("particle");
			if(!sprite){
				sprite = new GenericSprite(new Bitmap(cloudData), "particle");
			}
			_root.addChild(sprite.display);
			return sprite;
		}
		
		protected function createEnemy():EnemySprite {
			var sprite:EnemySprite = getSprite("enemy") as EnemySprite;
			if(!sprite){
				sprite = new EnemySprite(new CachedClip(swc.Enemy, 100, 113), "enemy");
			}
			_root.addChildAt(sprite.display, _root.getChildIndex(runner.display) - 1);
			return sprite;
		}
		
		
	/**
	 * UPDATE METHODS
	 * You shouldn't need to override any of these, unless you're doing some advanced optimizations.
	 **/
		protected function updateRunner(elapsed:Number){
			runner.update();
			if(runner.display is CachedClip){
				runner.display.step();
			}
		}
		
		protected function updateBg(elapsed:Number):void {
			bgStrip1.x -= elapsed * SPEED * .25;
			if(bgStrip1.x < -bgStrip1.width/2){ bgStrip1.x = 0; }
			
			bgStrip2.x -= elapsed * SPEED * .5;
			if(bgStrip2.x < -bgStrip2.width/2){ 
				bgStrip2.x = 0; 
			}
		}
		
		protected function updateGround(elapsed:Number){
			//Add platforms
			if(ticks % Math.round(100 - currentLoad * 2) == 0){
				addGround(1, stageHeight * .25 + stageHeight * .5 * Math.random());
			}
			
			//Move Ground
			var ground:GenericSprite;
			for(var i:int = groundList.length - 1; i >= 0; i--){
				ground = groundList[i];
				ground.x -= elapsed * SPEED;
				//Remove ground
				if(ground.x < -ground.width){
					groundList.splice(i, 1);
					putSprite(ground);
					if(ground.display.parent){
						ground.display.parent.removeChild(ground.display);
					}
				}
			}
			//Add Ground
			var lastX:int = (lastGroundPiece)? lastGroundPiece.x + lastGroundPiece.width : 0;
			if(lastX < stageWidth){
				addGround(1, 0);
			}
		}
		
		protected function updateParticles(elapsed:Number):void {
			if(ticks % 3 == 0){
				addParticles(3);
			}
			//Move Particls
			var p:GenericSprite;
			for(var i:int = particleList.length-1; i >= 0; i--){
				p = particleList[i];
				p.x -= elapsed * SPEED * .5;
				p.alpha -= .02;
				p.scaleX -= .02; 
				p.scaleY = p.scaleX;
				//Remove Particle
				if(p.alpha < 0 || p.scaleX < 0){
					particleList.splice(i, 1);
					putSprite(p);
					if(p.display.parent){
						p.display.parent.removeChild(p.display);
					}
				}
			}
		}
		
		protected function updateEnemies(elapsed:Number):void { 
			var enemy:EnemySprite;
			for(var i:int = enemyList.length-1; i >= 0; i--){
				enemy = enemyList[i];
				enemy.x -= elapsed * .33;
				enemy.update();
				if(enemy.display is CachedClip){
					enemy.display.step();
				}
				//Loop to other edge of screen
				if(enemy.x < -enemy.width){
					enemy.x = stageWidth + 20;
				}
			}
		}
		
		
	/**
	 * CORE ENGINE
	 * You shouldn't need to override anything below this.
	 **/
		public function step(elapsed:Number):void {
			ticks++;
			FastStats.numChildren = _root.numChildren;
			
			updateRunner(elapsed);
			updateBg(elapsed);
			
			if(enemyList){
				updateEnemies(elapsed);
			}
			
			if(groundList){
				updateGround(elapsed);
			}
			updateParticles(elapsed);
		}
		
		protected function removeEnemy(enemy:GenericSprite):void {
			if(enemy.display.parent){
				enemy.display.parent.removeChild(enemy.display);
			}
		}
		
		protected function addGround(numPieces:int, height:int = 0):void {
			var lastX:int = 0;
			if(lastGroundPiece){
				lastX = lastGroundPiece.x + lastGroundPiece.width;
			}
			var piece:GenericSprite;
			for(var i:int = 0; i < numPieces; i++){
				piece = createGroundPiece(); 
				piece.y = groundY + runner.height * .9 - height;
				piece.x = lastX;
				lastX += piece.width;
				groundList.push(piece);
			}
			if(height == 0){ lastGroundPiece = piece; }
		}
		
		protected function addParticles(numParticles:int):void {
			for(var i:int = 0; i < numParticles; i++){
				var p:GenericSprite = createParticle(); 
				p.x = runner.x - 10;
				p.y = runner.y + runner.height * .65 + runner.height * .25 * Math.random();
				particleList.push(p);
			}
		}
		
		public function addEnemies(numEnemies:int = 1):void {
			var enemy:EnemySprite;
			for(var i:int = 0; i < numEnemies; i++){
				enemy = createEnemy(); 
				enemy.y = groundY + runner.height - enemy.height;
				enemy.x = stageWidth;
				enemy.groundY = enemy.y;
				enemy.y = -enemy.height;
				enemyList.push(enemy);
			}
		}
		
		public function increaseLoad():void {
			currentLoad++;
			if(currentLoad > 50){ currentLoad = 50; }
		}
		
		protected function createSkyData():BitmapData {
			var m:Matrix = new Matrix();  m.createGradientBox(64, 64, Math.PI/2);
			var rect:Sprite = new Sprite();
			rect.graphics.beginGradientFill(GradientType.LINEAR, [0x0, 0x1E095E], [1, .5], [0, 255], m);
			rect.graphics.drawRect(0, 0, 128, 128);
			var skyData:BitmapData = new BitmapData(128, 128, false, 0x0);
			skyData.draw(rect);
			return skyData;
		}
		
		public function get numEnemies():int {
			return enemyList.length;
		}
		
		//Simple Pooling Functions
		public function getSprite(type:String):GenericSprite {
			var a:Array = spritePool[type];
			if(a && a.length){
				return a.pop();
			}
			return null;
		}
		
		public function putSprite(sprite:GenericSprite):void {
			//Rewind before we return ;)
			sprite.x = sprite.y = 0;
			sprite.scaleX = sprite.scaleY = 1;
			sprite.alpha = 1;
			sprite.rotation = 0;
			
			//Put in pool
			if(!spritePool[sprite.type]){
				spritePool[sprite.type] = [];
			}
			spritePool[sprite.type].push(sprite);
		}
		
		
	}
}