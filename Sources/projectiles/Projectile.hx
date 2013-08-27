package projectiles;

import kha.Direction;
import kha.Image;
import kha.math.Vector2;
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
	public var structureDamage(default, null) : Int = 0;
	public var creatureDamage(default, null) : Int = 0;
	
	public function new(image:Image, width:Int=0, height:Int=0, z:Int=1) {
		super(image, width, height, z);
	}
	
	public function remove(): Void {
		Scene.the.removeProjectile( this );
	}
	
	public function canShootSleepers(): Bool {
		return false;
	}
	
	override public function hit(sprite:Sprite): Void {
		if ( sprite.collides && this.collides ) {
			if (!canShootSleepers()) {
				if (Std.is(sprite, Player) && cast(sprite, Player).isSleeping()) return;
			}
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
				
				if (this.isTimeWeapon) {
					destructible.timeLeap();
				}
				
				if (destructible.isStucture) {
					destructible.health -= this.structureDamage;
				} else {
					destructible.health -= this.creatureDamage;
				}
			} else {
				if ( !isPiercing.has(OTHER_SPRITES) ) {
					remove();
				}
			}
		}
	}
	
	override public function hitFrom(dir:Direction): Void {
		if ( !isPiercing.has(WORLD) ) {
			remove();
		}
	}
}