local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Animations = ReplicatedStorage:WaitForChild("Animations")
local CombatConfig = require(ReplicatedStorage.Modules.Combat.Configuration)

return {
	NoobCap = 10,
	
	Health = 100,
	Walkspeed = 16,
	ChaseWalkspeed = 24,
	
	WalkAnimation = Animations.Movement.Walk,
	ChaseAnimation = Animations.Movement.Sprint,
	JumpAnimation = Animations.Movement.Jump,
	AttackLeftAnimation = Animations.Combat.JabLeft,
	AttackRightAnimation = Animations.Combat.JabRight,
	
	AggroRange = 40,
	ChaseRange = 80,
	ChasePathRate = 0.2,
	
	UpdateRate = 0.2,
	
	RoamRate = 2,
	RoamRadius = 15,

	AttackRange = 6,
	AttackCooldown = 1,
	
	Combat = CombatConfig,
	
	CorpseDespawn = 3,
	
	Names = {
		"Joe", "Midstrii", "John", "Mario", "Luigi", "Bobby", "Tom", "Jerry", "Rony", "Charlie"
	}
}
