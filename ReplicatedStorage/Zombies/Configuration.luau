local Animations = game:GetService("ReplicatedStorage"):WaitForChild("Animations")

return {
	DefaultSpawn = CFrame.new(0, 0, 0),
	ZombieCap = 10,
	
	Health = {40,60},
	
	Walkspeed = {5,8},
	ChaseWalkspeed = {10,16},
	
	WalkAnimation = Animations.Movement.Walk,
	ChaseAnimation = Animations.Movement.Sprint,
	JumpAnimation = Animations.Movement.Jump,
	
	Damage = {8,14},
	AttackCooldown = 1.3,
	AttackRange = 5,
	
	AggroRange = 40, -- minimum distance until zombie starts chasing
	ChaseRange = 80, -- maximum distance until zombie stops chasing
	ChasePathRate = 0.5,
	
	CorpseLifetime = 3, 
	
	UpdateRate = 0.5,
	
	RoamRate = 2,
	RoamRadius = 15,
}