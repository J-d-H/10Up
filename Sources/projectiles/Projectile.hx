package projectiles;

import kha.Direction;
import kha.Image;
import kha.Scene;
import kha.Sprite;

enum PiercingMode {
	WORLD;
	DESTRUCTIBLE_STRUCTURES;
	CREATURES;
	OTHER_SPRITES;
}

class Projectile extends Sprite {
	var isPiercing : haxe.EnumFlags<PiercingMode> = 0;
	public var isTimeWeapon(default, null) : Bool = false;
	public var stuctureDamage(default, null) : Int = 0;
	public var creatureDamage(default, null) : Int = 0;
	
	public function new(image:Image, width:Int=0, height:Int=0, z:Int=1) {
		super(image, width, height, z);
	}
	
	private function remove() {
		Scene.the.removeProjectile( this );
	}
	
	override public function hit(sprite:Sprite): Void {
		if ( Std.is( sprite, DestructibleSprite ) ) {
			var destructible : DestructibleSprite = cast sprite;
			if (destructible.isStucture) {
				if ( !isPiercing.has(DESTRUCTIBLE_STRUCTURES) ) {
					remove();
				}
			} else {
				if ( !isPiercing.has(CREATURES) ) {
					remove();
				}
			}
		} else {
			if ( !isPiercing.has(OTHER_SPRITES) ) {
				remove();
			}
		}
	}
	
	override public function hitFrom(dir:Direction): Void {
		if ( !isPiercing.has(WORLD) ) {
			remove();
		}
	}
}