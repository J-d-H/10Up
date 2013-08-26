package;

import kha.Button;
import kha.Color;
import kha.Font;
import kha.FontStyle;
import kha.Game;
import kha.HighscoreList;
import kha.Key;
import kha.Loader;
import kha.LoadingScreen;
import kha.math.Random;
import kha.Music;
import kha.Painter;
import kha.Scene;
import kha.Scheduler;
import kha.Score;
import kha.Configuration;
import kha.Sprite;
import kha.Tile;
import kha.Tilemap;

enum Mode {
	Loading;
	StartScreen;
	Game;
	Pause;
	Highscore;
	EnterHighscore;
}

class TenUp extends Game {
	public static var instance(default, null): TenUp;
	//var music : Music;
	var tileColissions : Array<Tile>;
	var map : Array<Array<Int>>;
	var originalmap : Array<Array<Int>>;
	var highscoreName : String;
	var shiftPressed : Bool;
	private var font: Font;
	public var level(default, null): Level;
	
	public var currentGameTime(default, null) : Float;
	public var currentTimeDiff(default, null) : Float;
	var lastTime : Float;
	
	public var mode(default, null) : Mode;
	
	public function new() {
		super("10Up", false);
		instance = this;
		shiftPressed = false;
		highscoreName = "";
		mode = Mode.Loading;
	}
	
	public static function getInstance(): TenUp {
		return instance;
	}
	
	public function pause(): Void {
		if (nextPlayer()) mode = Pause;
	}
	
	public override function init(): Void {
		Configuration.setScreen(new LoadingScreen());
		Loader.the.loadRoom("start", initStart);
	}
	
	public function enterLevel( level : String ) : Void {
		Configuration.setScreen( new LoadingScreen() );
		Loader.the.loadRoom( level, initLevel );
	}
	
	public function initStart(): Void {
		Random.init( Math.round( Scheduler.time() * 1000 ) );
		var logo = new Sprite( Loader.the.getImage( "10up-logo" ) );
		logo.x = 0.5 * width - 0.5 * logo.width;
		logo.y = 0.5 * height - 0.5 * logo.height;
		Scene.the.clear();
		Scene.the.setBackgroundColor(Color.fromBytes(0, 0, 0));
		Scene.the.addHero( logo );
		mode = StartScreen;
		Configuration.setScreen(this);
        //flash.Lib.current.stage.displayState = FULL_SCREEN;
	}

	public function initLevel(): Void {
		level = new levels.Level1();
		font = Loader.the.loadFont("Arial", new FontStyle(false, false, false), 12);
		tileColissions = new Array<Tile>();
		for (i in 0...140) {
			tileColissions.push(new Tile(i, isCollidable(i)));
		}
		var blob = Loader.the.getBlob("level.map");
		var levelWidth: Int = blob.readS32BE();
		var levelHeight: Int = blob.readS32BE();
		originalmap = new Array<Array<Int>>();
		for (x in 0...levelWidth) {
			originalmap.push(new Array<Int>());
			for (y in 0...levelHeight) {
				originalmap[x].push(blob.readS32BE());
			}
		}
		map = new Array<Array<Int>>();
		for (x in 0...originalmap.length) {
			map.push(new Array<Int>());
			for (y in 0...originalmap[0].length) {
				map[x].push(0);
			}
		}
		var spriteCount = blob.readS32BE();
		var sprites = new Array<Int>();
		for (i in 0...spriteCount) {
			sprites.push(blob.readS32BE());
			sprites.push(blob.readS32BE());
			sprites.push(blob.readS32BE());
		}
		//music = Loader.the.getMusic("level1");
		startGame(spriteCount, sprites);
	}
	
	public function startGame(spriteCount: Int, sprites: Array<Int>) {
		Scene.the.clear();
		Scene.the.setBackgroundColor(Color.fromBytes(255, 255, 255));
		Player.init();
		var tilemap : Tilemap = new Tilemap("sml_tiles", 32, 32, map, tileColissions);
		Scene.the.setColissionMap(tilemap);
		Scene.the.addBackgroundTilemap(tilemap, 1);
		var TILE_WIDTH : Int = 32;
		var TILE_HEIGHT : Int = 32;
		for (x in 0...originalmap.length) {
			for (y in 0...originalmap[0].length) {
				switch (originalmap[x][y]) {
				default:
					map[x][y] = originalmap[x][y];
				}
			}
		}
		
		for (i in 0...spriteCount) {
			var sprite : kha.Sprite;
			switch (sprites[i * 3]) {
			case 0:
				sprite = new PlayerAgent(sprites[i * 3 + 1], sprites[i * 3 + 2]);
				Scene.the.addHero(sprite);
			case 1:
				sprite = new PlayerProfessor(sprites[i * 3 + 1], sprites[i * 3 + 2]);
				Scene.the.addHero(sprite);
			case 2:
				sprite = new PlayerBullie(sprites[i * 3 + 1], sprites[i * 3 + 2]);
				Scene.the.addHero(sprite);
			case 3:
				sprite = new PlayerBlondie(sprites[i * 3 + 1], sprites[i * 3 + 2]);
				Scene.the.addHero(sprite);
			case 4:
				sprite = new Door(sprites[i * 3 + 1], sprites[i * 3 + 2]);
				level.doors.push( cast sprite );
				Scene.the.addOther(sprite);
			default:
				trace ("That should never happen! We are therefor going to ignore it.");
				continue;
			}
			if ( Std.is( sprite, DestructibleSprite ) ) {
				level.timeTravelSprites.push( cast sprite );
				level.destructibleSprites.push( cast sprite );
			} else if ( Std.is( sprite, TimeTravelSprite ) ) {
				level.timeTravelSprites.push( cast sprite );
			}
		}
		
		//music.play();
		Player.getPlayer(0).setCurrent();
		//Player.getInstance().reset();
		Configuration.setScreen(this);
		currentGameTime = 0;
		lastTime = Scheduler.time();
		mode = Pause;
	}
	
	public function victory() : Void {
		// TODO: Win!
		showHighscore();
	}
	
	public function defeat() : Void {
		// TODO: loose.
		showHighscore();
	}
	
	public function showHighscore() {
		Scene.the.clear();
		mode = Mode.EnterHighscore;
		//music.stop();
	}
	
	private static function isCollidable(tilenumber : Int) : Bool {
		switch (tilenumber) {
		case 1: return true;
		case 6: return true;
		case 7: return true;
		case 8: return true;
		default:
			return false;
		}
	}
	
	public override function update() {
		var currentTime = Scheduler.time();
		if (mode == Game) {
			var lastGameTime = currentGameTime;
			currentTimeDiff = currentTime - lastTime;
			currentGameTime += currentTimeDiff;
			Player.current().elapse(currentGameTime - lastGameTime);
			level.update(currentGameTime);
		}
		if (mode != Pause) {
			super.update();
		}
		if (mode == Game) {
			Scene.the.camx = Std.int(Player.current().x) + Std.int(Player.current().width / 2);
		}
		else if (mode == Pause) {
			var aimx = Std.int(Player.current().x) + Std.int(Player.current().width / 2);
			var camspeed: Int = 5;
			if (Scene.the.camx > aimx) {
				Scene.the.camx -= camspeed;
				if (Scene.the.camx < aimx) Scene.the.camx = aimx; 
			}
			else if (Scene.the.camx < aimx) {
				Scene.the.camx += camspeed;
				if (Scene.the.camx > aimx) Scene.the.camx = aimx; 
			}
		}
		lastTime = currentTime;
	}
	
	public override function render(painter : Painter) {
		//if (Player.getInstance() == null) return;
		painter.setFont(font);
		switch (mode) {
		case Highscore:
			painter.setColor(Color.fromBytes(255, 255, 255));
			painter.fillRect(0, 0, width, height);
			painter.setColor(Color.fromBytes(0, 0, 0));
			var i : Int = 0;
			while (i < 10 && i < getHighscores().getScores().length) {
				var score : Score = getHighscores().getScores()[i];
				painter.drawString(Std.string(i + 1) + ": " + score.getName(), 100, i * 30 + 100);
				painter.drawString(" -           " + Std.string(score.getScore()), 200, i * 30 + 100);
				++i;
			}
			//break;
		case EnterHighscore:
			painter.setColor(Color.fromBytes(255, 255, 255));
			painter.fillRect(0, 0, width, height);
			painter.setColor(Color.fromBytes(0, 0, 0));
			painter.drawString("Enter your name", width / 2 - 100, 200);
			painter.drawString(highscoreName, width / 2 - 50, 250);
			//break;
		case Game, Pause:
			super.render(painter);
			painter.translate(0, 0);
			//painter.setColor(Color.fromBytes(0, 0, 0));
			//painter.drawString("Score: " + Std.string(Player.getInstance().getScore()), 20, 25);
			//painter.drawString("Round: " + Std.string(Player.getInstance().getRound()), width - 100, 25);
			
			drawPlayerInfo(painter, 0, 20, 460, Color.fromBytes(255, 0, 0));
			drawPlayerInfo(painter, 1, 80, 460, Color.fromBytes(0, 255, 0));
			drawPlayerInfo(painter, 2, 140, 460, Color.fromBytes(0, 0, 255));
			drawPlayerInfo(painter, 3, 200, 460, Color.fromBytes(255, 255, 0));
			
			if (mode == Pause) {
				painter.setColor(Color.fromBytes(0, 0, 0));
				painter.setFont(font);
				painter.drawString("Pause", width / 2 - font.stringWidth("Pause") / 2, height / 2 - font.getHeight() / 2);
			}
		case Loading, StartScreen:
			super.render(painter);
		}
	}
	
	@:access(Player) 
	private function drawPlayerInfo(painter: Painter, index: Int, x: Float, y: Float, color: Color): Void {
		if (Player.getPlayerIndex() == index) {
			painter.setColor(Color.fromBytes(255, 255, 255));
			painter.fillRect(x - 5, y - 5, 50, 50);
		}
		painter.setColor(color);
		painter.fillRect(x, y, 40, 40);
		painter.setColor(Color.fromBytes(50, 50, 50));
		painter.fillRect(x, y + 30, 40, 10);
		painter.setColor(Color.fromBytes(150, 0, 0));
		painter.fillRect(x, y + 20, 40 * Player.getPlayer(index).health / Player.getPlayer(index).maxHealth, 10);
		painter.setColor(Color.fromBytes(0, 255, 255));
		painter.fillRect(x, y + 30, Player.getPlayer(index).timeLeft() * 4, 10);
	}

	override public function buttonDown(button : Button) : Void {
		switch (mode) {
		case Game:
			switch (button) {
			case UP:
				Player.current().setUp();
			case LEFT:
				Player.current().left = true;
			case RIGHT:
				Player.current().right = true;
			case BUTTON_1:
				Player.current().prepareSpecialAbilityA(currentGameTime);
			case BUTTON_2:
				Player.current().prepareSpecialAbilityB(currentGameTime);
			default:
			}
		case Pause:
			switch (button) {
				case LEFT:
					prevPlayer();
				case RIGHT:
					nextPlayer();
				default:
			}
		default:
		}
	}
	
	override public function buttonUp(button : Button) : Void {
		switch (mode) {
		case Game:
			switch (button) {
			case UP:
				Player.current().up = false;
			case LEFT:
				Player.current().left = false;
			case RIGHT:
				Player.current().right = false;
			case BUTTON_1:
				Player.current().useSpecialAbilityA(currentGameTime);
			case BUTTON_2:
				Player.current().useSpecialAbilityB(currentGameTime);
			default:
			}
		default:
		}
	}
	
	private function nextPlayer(): Bool {
		var count: Int = 0;
		var index = Player.getPlayerIndex();
		while (true) {
			++index;
			if (index > 3) index = 0;
			var player = Player.getPlayer(index);
			++count;
			if (!player.isSleeping() && !player.isTimeLeaping) {
				player.setCurrent();
				return true;
			}
			if (count > 4) return false;
		}
		return false;
	}
	
	private function prevPlayer(): Bool {
		var count: Int = 0;
		var index = Player.getPlayerIndex();
		while (true) {
			--index;
			if (index < 0) index = 3;
			var player = Player.getPlayer(index);
			++count;
			if (!player.isSleeping() && !player.isTimeLeaping) {
				player.setCurrent();
				return true;
			}
			if (count > 4) return false;
		}
		return false;
	}
	
	override public function keyDown(key : Key, char : String) : Void {
		if (key == Key.CHAR) {
			if (mode == Mode.Game) {
				if (char == " ") {
					mode = Pause;
					Player.current().right = false;
					Player.current().left = false;
					Player.current().up = false;
				}
			}
			else if (mode == Mode.Pause) {
				if (char == " ") {
					mode = Game;
				}
			}
			else if (mode == Mode.EnterHighscore) {
				if (highscoreName.length < 20) highscoreName += shiftPressed ? char.toUpperCase() : char.toLowerCase();
			}
		}
		else {
			if (highscoreName.length > 0) {
				switch (key) {
				case ENTER:
					//getHighscores().addScore(highscoreName, Player.getInstance().getScore());
					mode = Mode.Highscore;
				case BACKSPACE:
					highscoreName = highscoreName.substr(0, highscoreName.length - 1);
				default:
				}
			}
			if (key == SHIFT) shiftPressed = true;
		}
	}
	
	override public function keyUp(key : Key, char : String) : Void {
		if (key != null && key == Key.SHIFT) shiftPressed = false;
		
		if (mode == StartScreen) {
			enterLevel( "level1" );
		}
	}
	
	public var mouseX(default, null) : Float;
	public var mouseY(default, null) : Float;
	override public function mouseMove(x:Int, y:Int) : Void {
		mouseX = x + Scene.the.screenOffsetX;
		mouseY = y + Scene.the.screenOffsetY;
	}
	
	override public function mouseDown(x: Int, y: Int): Void {
		mouseX = x + Scene.the.screenOffsetX;
		mouseY = y + Scene.the.screenOffsetY;
		if (mode == Game) {
			if (shiftPressed) {
				Player.current().prepareSpecialAbilityB(currentGameTime);
				mouseUpAction = Player.current().useSpecialAbilityB;
			}
			else {
				Player.current().prepareSpecialAbilityA(currentGameTime);
				mouseUpAction = Player.current().useSpecialAbilityA;
			}
		}
	}
	
	private var mouseUpAction : Float->Void;
	override public function mouseUp(x: Int, y: Int): Void {
		mouseX = x + Scene.the.screenOffsetX;
		mouseY = y + Scene.the.screenOffsetY;
		switch (mode) {
		case Game:
			if (mouseUpAction != null) {
				mouseUpAction( currentGameTime );
				mouseUpAction = null;
			}
		case StartScreen:
			enterLevel( "level1" );
		default:
		}
	}
}