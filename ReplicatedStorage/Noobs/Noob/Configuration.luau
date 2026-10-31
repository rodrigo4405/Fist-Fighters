local Animations = game:GetService("ReplicatedStorage"):WaitForChild("Animations")

return {
	DefaultSpawn = CFrame.new(0, 0, 0),
	NoobCap = 10,
	
	Health = 100,
	
	Walkspeed = 16,
	ChaseWalkspeed = 24,
	
	WalkAnimation = Animations.Movement.Walk,
	ChaseAnimation = Animations.Movement.Sprint,
	JumpAnimation = Animations.Movement.Jump,
	AttackLeftAnimation = Animations.Combat.JabLeft,
	AttackRightAnimation = Animations.Combat.JabRight,
	
	AggroRange = 40, -- minimum distance until zombie starts chasing
	ChaseRange = 80, -- maximum distance until zombie stops chasing
	ChasePathRate = 0.5,
	
	UpdateRate = 0.5,
	
	RoamRate = 2,
	RoamRadius = 15,
	
	-- Attack settings
	AttackRange = 6, -- studs
	AttackCooldown = 1, -- seconds
	
	-- Attack configurations (mirroring Combat module)
	Jab = {
		Damage = 8,
		Cooldown = 1,
		RightAnim = Animations.Combat.JabRight,
		LeftAnim = Animations.Combat.JabLeft,
	},
}
