local Animations = game:GetService("ReplicatedStorage"):WaitForChild("Animations"):WaitForChild("Combat")

return {
	Jab = {
		Damage = 8,
		Cooldown = 0,
		StaminaCost = 3,
		RightAnim = Animations.JabRight,
		LeftAnim = Animations.JabLeft,
	},
	
	Hook = {
		Damage = 15,
		Cooldown = 3,
		StaminaCost = 5,
		RightAnim = Animations.HookRight,
		LeftAnim = Animations.HookLeft,
	},
	
	Uppercut = {
		Damage = 20,
		Cooldown = 4,
		StaminaCost = 8,
		RightAnim = Animations.UppercutRight,
		LeftAnim = Animations.UppercutLeft,
	},
	
	Bodyshot = {
		Damage = 15,
		Cooldown = 2,
		StaminaCost = 5,
		RightAnim = Animations.BodyshotRight,
		LeftAnim = Animations.BodyshotLeft,
	},
	
	Overhand = {
		Damage = 25,
		Cooldown = 5,
		StaminaCost = 10,
		RightAnim = Animations.OverhandRight,
		LeftAnim = Animations.OverhandLeft,
	},
	
	Block = {
		Cooldown = 1,
		StaminaCost = 0,
		MaxBlockStrength = 100,
		BlockStrengthRegenRate = 5,
		BlockStrengthRegenDelay = 3,
		Anim = Animations.Block
	}
}