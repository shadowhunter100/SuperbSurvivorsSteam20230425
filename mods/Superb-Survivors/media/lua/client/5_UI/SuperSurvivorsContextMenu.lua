
require "TimedActions/ISBaseTimedAction"

ISUnStuckAction = ISBaseTimedAction:derive("ISUnStuckAction");

function ISUnStuckAction:isValid()
	return true
end

function ISUnStuckAction:update()
    if self.character then
      
		self.character:getModData().felldown = true
    self.character:setMetabolicTarget(Metabolics.LightDomestic);
    end
end

function ISUnStuckAction:start()
	
	self:setActionAnim("Loot")
	self:setOverrideHandModels(nil, nil)
end

function ISUnStuckAction:stop()
	self.character:getModData().felldown = nil
    ISBaseTimedAction.stop(self);
end

function ISUnStuckAction:perform()
	self.character:getModData().felldown = nil
	ISBaseTimedAction.perform(self);
end

function ISUnStuckAction:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.stopOnWalk = false;
	o.stopOnRun = false;
	o.forceProgressBar = false;
	o.mul = 2;
	o.maxTime = 1;

	return o;
end









-- the job 'companion' has alot of embedding put into it to keep it from breaking away from main player
-- So if you add new commands for the npcs through here, make sure you keep in mind about companions
-- if you don't change the job along with the task, the npc will just return to the player
require ('CharacterSave_SaveLoad')

local function getJobText(text)
	return getContextMenuText("Job_" .. text)
end

LootTypes = {"Food","Weapon","Item","Clothing","Container","Literature"};

function SurvivorOrder(test,player,order,orderParam)
	if(player ~= nil) then
		local ASuperSurvivor = SSM:Get(player:getModData().ID)
		local TaskMangerIn = ASuperSurvivor:getTaskManager()
		ASuperSurvivor:setAIMode(order)
		TaskMangerIn:setTaskUpdateLimit(0)
		
		ASuperSurvivor:setWalkingPermitted(true)
		
		local followtask = TaskMangerIn:getTaskFromName("Follow") --giving an outright order should remove follow so that "needToFollow" function will not detect a follow task and calc followdistance >
		if(followtask) then followtask:ForceComplete() end
		
		if(order == "Loot Room") and (orderParam ~= nil) then 
			TaskMangerIn:AddToTop(LootCategoryTask:new(ASuperSurvivor,ASuperSurvivor:getBuilding(),orderParam,0)) 
		
		elseif(order == "Follow") then
			ASuperSurvivor:setAIMode("Follow") 
			ASuperSurvivor:setGroupRole("Follow") 
			TaskMangerIn:clear()
			ASuperSurvivor:setGroupRole(getJobText("Companion")) 
			TaskMangerIn:AddToTop(FollowTask:new(ASuperSurvivor,getSpecificPlayer(0)))
			ASuperSurvivor:setAIMode("Follow")
		
		elseif(order == "Pile Corpses") then 
			ASuperSurvivor:setGroupRole(getJobText("Dustman")) 
			local dropSquare = getSpecificPlayer(0):getCurrentSquare()
			local storagearea = ASuperSurvivor:getGroup():getGroupArea("CorpseStorageArea")
			if(storagearea[1] ~= 0) then 
				dropSquare = getCenterSquareFromArea(storagearea[1],storagearea[2],storagearea[3],storagearea[4],storagearea[5]) 
			end
			TaskMangerIn:AddToTop(PileCorpsesTask:new(ASuperSurvivor,dropSquare)) 
		
		elseif(order == "Guard") then 
			ASuperSurvivor:setGroupRole(getJobText("Guard"))
			local area = ASuperSurvivor:getGroup():getGroupArea("GuardArea")
			if(area) then 	
				ASuperSurvivor:Speak(getContextMenuText("IGoGuard"))
				TaskMangerIn:AddToTop(WanderInAreaTask:new(ASuperSurvivor,area)) 					
				TaskMangerIn:setTaskUpdateLimit(AutoWorkTaskTimeLimit)	
				TaskMangerIn:AddToTop(GuardTask:new(ASuperSurvivor,getRandomAreaSquare(area))) 
				ASuperSurvivor:Speak("And Where are you wanting me to guard at again? Show me an area to guard at.")
			else
				print("settubg player current square as guard sqwuarte")
				TaskMangerIn:AddToTop(GuardTask:new(ASuperSurvivor,getSpecificPlayer(0):getCurrentSquare()))				
			end
		
		elseif(order == "Patrol") then 
			ASuperSurvivor:setGroupRole(getJobText("Sheriff"))
			TaskMangerIn:AddToTop(PatrolTask:new(ASuperSurvivor,getSpecificPlayer(0):getCurrentSquare(),ASuperSurvivor:Get():getCurrentSquare())) 		
		
		elseif(order == "Return To Base") then 
			if (ASuperSurvivor:getGroupRole() == "Companion") then 	ASuperSurvivor:setGroupRole(getJobText("Worker"))	end-- To prevent follower companion tasks overwrite
			TaskMangerIn:clear()
			TaskMangerIn:AddToTop(ReturnToBaseTask:new(ASuperSurvivor)) 
		
		elseif(order == "Explore") then
			if (ASuperSurvivor:getGroupRole() == "Companion") then 	ASuperSurvivor:setGroupRole(getJobText("Worker"))	end
			TaskMangerIn:AddToTop(WanderTask:new(ASuperSurvivor)) 
		
		elseif(order == "Stop") then 
			if (ASuperSurvivor:getGroupRole() == "Companion") then 	ASuperSurvivor:setGroupRole(getJobText("Worker"))	end
			TaskMangerIn:clear()
		
		elseif(order == "Relax") and (ASuperSurvivor:getBuilding()~=nil) then 
			if (ASuperSurvivor:getGroupRole() == "Companion") then 	ASuperSurvivor:setGroupRole(getJobText("Worker"))	end
			TaskMangerIn:clear()
			TaskMangerIn:AddToTop(WanderInBuildingTask:new(ASuperSurvivor,ASuperSurvivor:getBuilding())) 
		
		elseif(order == "Relax") and (ASuperSurvivor:getBuilding()==nil) then 
			if (ASuperSurvivor:getGroupRole() == "Companion") then 	ASuperSurvivor:setGroupRole(getJobText("Worker"))	end
			TaskMangerIn:clear()
			TaskMangerIn:AddToTop(WanderInBuildingTask:new(ASuperSurvivor,nil)) 
			TaskMangerIn:AddToTop(FindBuildingTask:new(ASuperSurvivor)) 
		
		elseif(order == "Barricade") then 
			TaskMangerIn:AddToTop(BarricadeBuildingTask:new(ASuperSurvivor)) 
			ASuperSurvivor:setGroupRole(getJobText("Worker"))
		
		elseif(order == "Stand Ground") then 
			ASuperSurvivor:setGroupRole(getJobText("Guard"))	
			TaskMangerIn:AddToTop(GuardTask:new(ASuperSurvivor,getSpecificPlayer(0):getCurrentSquare()))
			ASuperSurvivor:setWalkingPermitted(false)
		
		elseif(order == "Forage") then
			TaskMangerIn:AddToTop(ForageTask:new(ASuperSurvivor))
			ASuperSurvivor:setGroupRole(getJobText("Junkman"))
		
		elseif(order == "Farming") then 
			if(true) then--if(ASuperSurvivor:Get():getPerkLevel(Perks.FromString("Farming")) >= 3) then
				TaskMangerIn:AddToTop(FarmingTask:new(ASuperSurvivor))
				ASuperSurvivor:setGroupRole(getJobText("Farmer")) 
			else
				ASuperSurvivor:Speak(getActionText("IDontKnowHowFarming"))
			end
		
		elseif(order == "Chop Wood") then 
			TaskMangerIn:AddToTop(ChopWoodTask:new(ASuperSurvivor))
			ASuperSurvivor:setGroupRole(getJobText("Timberjack"))
		
		elseif(order == "Hold Still") then 
			TaskMangerIn:AddToTop(HoldStillTask:new(ASuperSurvivor,true))
			if (ASuperSurvivor:getGroupRole() == "Companion") then 	ASuperSurvivor:setGroupRole(getJobText("Guard"))	end	
		
		elseif(order == "Gather Wood") then 
			ASuperSurvivor:setGroupRole(getJobText("Hauler"))
			local dropSquare = getSpecificPlayer(0):getCurrentSquare()
			local woodstoragearea = ASuperSurvivor:getGroup():getGroupArea("WoodStorageArea")
			if(woodstoragearea[1] ~= 0) then dropSquare = getCenterSquareFromArea(woodstoragearea[1],woodstoragearea[2],woodstoragearea[3],woodstoragearea[4],woodstoragearea[5]) end
			TaskMangerIn:AddToTop(GatherWoodTask:new(ASuperSurvivor,dropSquare))
		
		elseif(order == "Lock Doors") then TaskMangerIn:AddToTop(LockDoorsTask:new(ASuperSurvivor,true))
		elseif(order == "Sort Loot Into Base") then TaskMangerIn:AddToTop(SortLootTask:new(ASuperSurvivor,false))
		
		elseif(order == "Dismiss") then 
			ASuperSurvivor:setAIMode("Random Solo") 
			local group = SSGM:Get(ASuperSurvivor:getGroupID())
			if(group) then group:removeMember(ASuperSurvivor:getID()) end
			
			ASuperSurvivor:getTaskManager():clear()
			if(ZombRand(3) == 0) then 
				ASuperSurvivor:setHostile(true) 
				ASuperSurvivor:Speak(getSpeech("HowDareYou"))
			else
				ASuperSurvivor:Speak(getSpeech("IfYouThinkSo")) 
			end

		elseif(order == "Unlock Doors") 		then 	if (ASuperSurvivor:getGroupRole() == "Companion") then 	ASuperSurvivor:setGroupRole(getJobText("Worker"))	end		TaskMangerIn:AddToTop(LockDoorsTask:new(ASuperSurvivor,false))
		elseif(order == "Go Find Food") 		then 	if (ASuperSurvivor:getGroupRole() == "Companion") then 	ASuperSurvivor:setGroupRole(getJobText("Worker"))	end		TaskMangerIn:AddToTop(FindThisTask:new(ASuperSurvivor,"Food","Category",1))
		elseif(order == "Go Find Weapon") 		then 	if (ASuperSurvivor:getGroupRole() == "Companion") then 	ASuperSurvivor:setGroupRole(getJobText("Worker"))	end		TaskMangerIn:AddToTop(FindThisTask:new(ASuperSurvivor,"Weapon","Category",1))
		elseif(order == "Go Find Water") 		then 	if (ASuperSurvivor:getGroupRole() == "Companion") then 	ASuperSurvivor:setGroupRole(getJobText("Worker"))	end		TaskMangerIn:AddToTop(FindThisTask:new(ASuperSurvivor,"Water","Category",1))
		elseif(order == "Clean Up Inventory") 	then 	
			if (ASuperSurvivor:getGroupRole() == "Companion") then
				ASuperSurvivor:setGroupRole(getJobText("Worker"))	
			end		
			local group = ASuperSurvivor:getGroup()
			if(group) then 
				-- check containers in square
				local containerobj = group:getGroupAreaContainer("FoodStorageArea")
				TaskMangerIn:AddToTop(CleanInvTask:new(ASuperSurvivor,containerobj,false))
		
				--container = square:getContainer();
				--if(not container) then container = square:getItemContainer() end
			end
			
		elseif(order == "Doctor") and (ASuperSurvivor:Get():getPerkLevel(Perks.FromString("Doctor")) >= 1 or ASuperSurvivor:Get():getPerkLevel(Perks.FromString("First Aid")) >= 1) then 
			TaskMangerIn:AddToTop(DoctorTask:new(ASuperSurvivor))
			ASuperSurvivor:setGroupRole(getJobText("Doctor"))
		
		elseif(order == "Doctor") then
			ASuperSurvivor:Speak(getSpeech("IDontKnowHowDoctor"))
		end
		
		ASuperSurvivor:Speak(getSpeech("Roger")) 
		getSpecificPlayer(0):Say(OrderDisplayName[order]);
	end
end

function MedicalCheckSurvivor(test,player)
	
	--ISTimedActionQueue.add(ISWalkToTimedAction:new(getSpecificPlayer(0), player:getCurrentSquare())); 
	--ISTimedActionQueue.add(ISMedicalCheckAction:new(getSpecificPlayer(0), player));
		if luautils.walkAdj(getSpecificPlayer(0), player:getCurrentSquare()) then
            ISTimedActionQueue.add(ISMedicalCheckAction:new(getSpecificPlayer(0), player))
        end	

end


function AskToJoin(test,player) -- When the NPC asks another npc to join a group

	local SS = SSM:Get(player:getModData().ID)
	local MySS = SSM:Get(0)
	getSpecificPlayer(0):Say(getActionText("CanIJoin"))		
	
	local Relationship = SS:getRelationshipWP()
	--player:Say(tostring(Relationship))
	local result = ((ZombRand(10) + Relationship) >= 8)
	
	if(result) then
		local group = SS:getGroup()
		print("join group " .. SS:getGroupID())
		
		if(group) then
			SS:Speak(getSpeech("Roger"));

			if (MySS:getGroup() ~= nil) then
				local members = MySS:getGroup():getMembers()
				for x=1, #members do
					if(members[x] and members[x].player ~= nil) then
						members[x]:Speak(getSpeech("Roger"));
						group:addMember(members[x], getJobText("Partner"))
					end
				end
			else
				group:addMember(MySS, getJobText("Partner"))
			--	group:addMember(MySS, getJobText("Companion"))
			end
		end
	else
		SS:Speak(getSpeech("No"))
	end
	
end
function InviteToParty(test,player) -- When the player offers an NPC to join the group
	local SS = SSM:Get(player:getModData().ID)
	getSpecificPlayer(0):Say(getActionText("YouWantToJoin"))
	SS:PlusRelationshipWP(1.0) -- Slight bonus to what existed, npcs are a bit rude 

	local Relationship = SS:getRelationshipWP()
	--player:Say(tostring(Relationship))
	local result = ((ZombRand(10) + Relationship) >= 8)
	
	local task = SS:getTaskManager():getTaskFromName("Listen")
	if(task ~= nil) and (task.Name == "Listen") then task:Talked() end
	
	if(result) then
		
		if(AchievementsEnabled) then
			if(not MyAchievementManager:isComplete("MakingFriends")) then MyAchievementManager:setComplete("MakingFriends",true) end
		end
	
		SS:Speak(getSpeech("Roger"))
		local GID, Group
		if(SSM:Get(0):getGroupID() == nil) then
			Group = SSGM:newGroup()
			Group:addMember(SSM:Get(0), getJobText("Leader"))
		else
			GID = SSM:Get(0):getGroupID()
			Group = SSGM:Get(GID)
		end
		
		if(Group) then Group:addMember(SS, getJobText("Companion")) -- was Partner
		else print("error could not find or create group") end
		
		local followtask = FollowTask:new(SS,getSpecificPlayer(0))
		local tm = SS:getTaskManager()

		tm:clear()
		tm:AddToTop(followtask)
		
		-- This will make sure the newly joined npc will default to follow, thus not run away when first join the group
		local ASuperSurvivor = SSM:Get(player:getModData().ID)
		ASuperSurvivor:setAIMode("Follow") 
		ASuperSurvivor:setGroupRole("Follow") 
			
		SS:setGroupRole("Companion") -- Newly added
	else
		SS:Speak(getSpeech("No"))
		SS:PlusRelationshipWP(-2.0) -- changed to -2 from -1
	end	
	
end
function OfferFood(test,player)
	local SS = SSM:Get(player:getModData().ID)
	
	local RSS = SSM:Get(0)
	local realPlayer = RSS:Get()
	realPlayer:Say(getActionText("WantSomeFood"))		
	local task = SS:getTaskManager():getTaskFromName("Listen")
	if(task ~= nil) and (task.Name == "Listen") then task:Talked() end
	
	local food = RSS:getFood()
	local foodcontainer = food:getContainer()
	local gift = RSS:getFacingSquare():AddWorldInventoryItem(food,0.5,0.5,0)
	
	if(foodcontainer ~= nil) then foodcontainer:DoRemoveItem(food) end
	--ISTimedActionQueue.add(ISInventoryTransferAction:new (getSpecificPlayer(0), food, food:getContainer(), SSM:Get(0):getFacingSquare():getContainerItem("floor"):getContainer(), 1))
			
	SS:getTaskManager():AddToTop(TakeGiftTask:new(SS,gift))
	SS:PlusRelationshipWP(2.0)
	
end
function OfferWater(test,player)
	local SS = SSM:Get(player:getModData().ID)
	getSpecificPlayer(0):Say(getActionText("YouWantWater"))		
	local task = SS:getTaskManager():getTaskFromName("Listen")
	if(task ~= nil) and (task.Name == "Listen") then task:Talked() end
	
	local food = SSM:Get(0):getWater()
	local foodcontainer = food:getContainer()
	local gift = SSM:Get(0):getFacingSquare():AddWorldInventoryItem(food,0.5,0.5,0)
	
	if(foodcontainer ~= nil) then foodcontainer:DoRemoveItem(food) end
	SS:getTaskManager():AddToTop(TakeGiftTask:new(SS,gift))
	SS:PlusRelationshipWP(1.0)
end
function OfferAmmo(test,player,ammo)
	local SS = SSM:Get(player:getModData().ID)
	getSpecificPlayer(0):Say(getActionText("YouWantAmmo"))		
	local task = SS:getTaskManager():getTaskFromName("Listen")
	if(task ~= nil) and (task.Name == "Listen") then task:Talked() end
	
	local container = ammo:getContainer()	
	local gift = SSM:Get(0):getFacingSquare():AddWorldInventoryItem(ammo,0.5,0.5,0)
	
	if(container ~= nil) then container:DoRemoveItem(ammo) end
	SS:getTaskManager():AddToTop(TakeGiftTask:new(SS,gift))
	SS:PlusRelationshipWP(1.0)
end

function offerORGMAmmo(test,player,ammoName)
	local SS = SSM:Get(player:getModData().ID)
	getSpecificPlayer(0):Say(getActionText("YouWantAmmo"))		
	local task = SS:getTaskManager():getTaskFromName("Listen")
	
	if(task ~= nil) and (task.Name == "Listen") then 
		task:Talked() 
	end
	
	local container = SSM:Get(0):Get():getInventory()
	ammoBox = SSM:Get(0):Get():getInventory():FindAndReturn(ammoName)
	if (ammoBox ~= nil) then
		local gift = SSM:Get(0):getFacingSquare():AddWorldInventoryItem(ammoBox,0.5,0.5,0)
		if(container ~= nil) then
			container:DoRemoveItem(ammoBox)
		end
	end		
	
	SS:getTaskManager():AddToTop(TakeGiftTask:new(SS,ammoBox))
	SS:PlusRelationshipWP(1.0)
end

function OfferWeapon(test,player)
	local SS = SSM:Get(player:getModData().ID)
	getSpecificPlayer(0):Say(getActionText("TakeMyWeapon"))	
	local task = SS:getTaskManager():getTaskFromName("Listen")
	if(task ~= nil) and (task.Name == "Listen") then task:Talked() end
	
	local wep = getSpecificPlayer(0):getPrimaryHandItem()
	local gift = SSM:Get(0):getFacingSquare():AddWorldInventoryItem(wep,0.5,0.5,0)
	getSpecificPlayer(0):setPrimaryHandItem(nil)
	getSpecificPlayer(0):getInventory():DoRemoveItem(wep)
	
	SS:getTaskManager():AddToTop(TakeGiftTask:new(SS,gift))
	SS:PlusRelationshipWP(3.0)
end

function AskToLeave(test,SS)
	getSpecificPlayer(0):Say("Scram! Or Die!");
	
	if(SS:getBuilding() ~= nil) then SS:MarkBuildingExplored(SS:getBuilding()) end
	if(SS.TargetBuilding ~= nil) then SS:MarkBuildingExplored(SS.TargetBuilding) end
	
	getSpecificPlayer(0):getModData().semiHostile = true
	SS.player:getModData().hitByCharacter = true
	SS:getTaskManager():clear()
	--print("FLEEFROM3 " .. SS:GetName())
	SS:getTaskManager():AddToTop(FleeFromHereTask:new(SS,getSpecificPlayer(0):getCurrentSquare()))
	
		local GroupID = SS:getGroupID()
		if(GroupID ~= nil) then
			local group = SSGM:Get(GroupID)
			if(group) then
			print("pvp alert being scrammed")
				group:PVPAlert(getSpecificPlayer(0))
			end		
		end
		SS.player:getModData().hitByCharacter = true
	
	SS:Speak("!!")
end
function AskToDrop(test,SS)
	getSpecificPlayer(0):Say("Drop your Loot!!");
	SS:Speak("Okay dont shoot!");
	if(SS:getBuilding() ~= nil) then SS:MarkBuildingExplored(SS:getBuilding()) end
	if(SS.TargetBuilding ~= nil) then SS:MarkBuildingExplored(SS.TargetBuilding) end
	getSpecificPlayer(0):getModData().semiHostile = true
	--SS.player:getModData().hitByCharacter = true
	SS:getTaskManager():clear()
	--print("FLEEFROM4 " .. SS:GetName())
	SS:getTaskManager():AddToTop(FleeFromHereTask:new(SS,getSpecificPlayer(0):getCurrentSquare()))
	SS:getTaskManager():AddToTop(CleanInvTask:new(SS, SS.player:getCurrentSquare(),true))
	
	local GroupID = SS:getGroupID()
		if(GroupID ~= nil) then
			local group = SSGM:Get(GroupID)
			if(group) then
				print("pvp alert being robbed")
				group:PVPAlert(getSpecificPlayer(0))
			end		
		end
		SS.player:getModData().hitByCharacter = true
	
	SS:Speak("!!")
end

function DebugCharacterSwap(test,SS)
	SSM:switchPlayer(SS:getID())
end

function AnswerTriggerQuestionYes(test,SS)
	print("SSQM: Answered Yes to question of survivor " .. tostring(SS:getName()))
	if(SS.YesResultActions == nil) then print("warning AnswerTriggerQuestionYes detect nil YesResultActions") end
	SSQM:QuestionAnswered(SS.TriggerName,"YES",SS.NoResultActions ,SS.YesResultActions)
	SS.HasQuestion = false -- erase question option
	SS.HasBikuri = false -- erase question option
	SS.NoResultActions = nil -- erase question option
	SS.YesResultActions = nil -- erase question option
	SS.TriggerName = nil -- erase question option
end
function AnswerTriggerQuestionNo(test,SS)
	print("SSQM: Answered No to question of survivor " .. tostring(SS:getName()))
	if(SS.NoResultActions == nil) then print("warning AnswerTriggerQuestionNo detect nil NoResultActions") end
	SSQM:QuestionAnswered(SS.TriggerName,"NO",SS.NoResultActions ,SS.YesResultActions)
	SS.HasQuestion = false -- erase question option
	SS.HasBikuri = false -- erase question option
	SS.NoResultActions = nil -- erase question option
	SS.YesResultActions = nil -- erase question option
	SS.TriggerName = nil -- erase question option
end

function DebugCharacterKill(test,SS)
	local player = SS.player
	
	if(player:getBodyDamage():getInfectionLevel() <= 0) then
	
		local BPs = player:getBodyDamage():getBodyParts()
		for i=0, BPs:size()-1 do	
			
			BPs:get(i):SetBitten(true)
			BPs:get(i):generateZombieInfection(200)
			BPs:get(i):AddDamage(19)
			
			player:getBodyDamage():setInfectionLevel(1)  
			
		end
		
	end
	player:update();
end
function DebugCharacterToggleNPC(test,SS)
	SS:Get():setNPC(not SS:Get():isNPC())
end
function DebugCharacterToggleBM(test,SS)
	SS:Get():setBlockMovement(not SS:Get():isBlockMovement())
end


function DebugCharacterOutput(test,SS)
	SS.DebugMode = not SS.DebugMode
	local distance = getDistanceBetween(SS.player,getSpecificPlayer(0));
	print("SS Name:"..tostring(SS:getName()))
	print("SS ID:"..tostring(SS:getID()))
	print("isBlockMovement:"..tostring(SS:Get():isBlockMovement()))
	print("isNPC:"..tostring(SS:Get():isNPC()))
	print("isLocalPlayer:"..tostring(SS:Get():isLocalPlayer()))
	print("NPCRunning:"..tostring(SS:Get():NPCGetRunning()))
	print("isSneaking:"..tostring(SS:Get():isSneaking()))
	print("isAiming:"..tostring(SS:Get():isAiming()))
	print("infectionLevel:"..tostring(SS:Get():getBodyDamage():getInfectionLevel()))
	print("isinAction:"..tostring(SS:isInAction()))
	print("MDbWalking:"..tostring(SS.player:getModData().bWalking))
	print("bWalking:"..tostring(SS:Get():getVariableBoolean("bWalking")))
	print("isPathing:"..tostring(SS:Get():isPathing()))
	print("isBehaviourMoving:"..tostring(SS.player:isBehaviourMoving()))
	print("isMoving:"..tostring(SS.player:isMoving()))
	print("isPerformingAnAction:"..tostring(SS:Get():isPerformingAnAction()))
	print("AttackAnim:"..tostring(SS:Get():getVariableBoolean("AttackAnim")))
	print("ShoveAnim:"..tostring(SS:Get():getVariableBoolean("ShoveAnim")))
	print("isAttacking:"..tostring(SS:Get():getVariableBoolean("isAttacking")))
	print("StompAnim:"..tostring(SS:Get():getVariableBoolean("StompAnim")))
	print("IsUnloading:"..tostring(SS:Get():getVariableBoolean("IsUnloading")))
	print("IsRacking:"..tostring(SS:Get():getVariableBoolean("IsRacking")))		
	print("ignoreMovement:"..tostring(SS:Get():getVariableBoolean("ignoreMovement")))
	print("hideWeaponModel:"..tostring(SS:Get():getVariableBoolean("hideWeaponModel")))
	print("isAiming:"..tostring(SS:Get():getVariableBoolean("isAiming")))
	print("NPCisAiming:"..tostring(SS:Get():getVariableBoolean("NPCisAiming")))
	print("bAimAtFloor:"..tostring(SS:Get():getVariableBoolean("bAimAtFloor")))
	print("bUpdateModelTextures:"..tostring(SS:Get():getVariableBoolean("bUpdateModelTextures")))
	print("m_isBumpDone:"..tostring(SS:Get():getVariableBoolean("m_isBumpDone")))
	print("m_bumpFall:"..tostring(SS:Get():getVariableBoolean("m_bumpFall")))
	print("m_bumpStaggered:"..tostring(SS:Get():getVariableBoolean("m_bumpStaggered")))
	print("fallOnFront:"..tostring(SS:Get():getVariableBoolean("fallOnFront")))
	print("hitFromBehind:"..tostring(SS:Get():getVariableBoolean("hitFromBehind")))
	print("IgnoreStaggerBack:"..tostring(SS:Get():getVariableBoolean("IgnoreStaggerBack")))
	print("AttackWasSuperAttack:"..tostring(SS:Get():getVariableBoolean("AttackWasSuperAttack")))
	print("superAttack:"..tostring(SS:Get():getVariableBoolean("superAttack")))
	print("pathing:"..tostring(SS:Get():getVariableBoolean("pathing")))
	print("bSneaking:"..tostring(SS:Get():getVariableBoolean("bSneaking")))
	print("blockTurning:"..tostring(SS:Get():getVariableBoolean("blockTurning")))
	print("getCurrentState():"..tostring(SS:Get():getCurrentState()))
	print("IsInMeleeAttack:"..tostring(SS:Get():IsInMeleeAttack()))
	print("DistanceToMainPlayer:"..tostring(distance))
	print("AIMode:"..tostring(SS:getAIMode()))
	print("needToFollow:"..tostring(SS:needToFollow()))
	print("TaskManagerOutput:")
	SS:getTaskManager():Display()
	print("-------------------------End of NPC Debug---------------------------------")
	
	--SS:StopWalk()
end

function DebugCharacterUnStuck(test,SS)

	SS.player:getAdvancedAnimator():SetState("idle")
			--	SS:StopWalk()		
			--	SS.player:NPCSetAttack(true);w
			--	SS.player:NPCSetMelee(true);  
			--	SS.player:AttemptAttack(10.0);
	--SS.player:AttemptAttack(10)		
	--SS.player:setVariable("bDoShove", true)	
	--SS.player:setForceShove(true);
	--SS.player:setVariable("initiateAttack", true)
	--SS.player:setVariable("attackStarted", true)
	--SS.player:setVariable("attackType", nil)
	
	--when frozen - these appear to always be set this way
	--SS:isInAction() == false
	--SS.player:getModData().bWalking == true
	--isMoving SS:Get():isMoving() == true
	--SS:Get():getVariableBoolean("AttackAnim") == false
	--SS:Get():getVariableBoolean("ShoveAnim") == false
	
	--SS.player:PlayAnimWithSpeed("Run",999);
	--SS.player:clearVariable("TimedActionType");
	--SS.player:clearVariable("BumpFallType");
	--SS.player:clearVariable("WeaponReloadType");
	--SS.player:setPerformingAnAction(true)
	--SS.player:clearVariable("bdoshove")
	--SS.player:clearVariable("isattacking")
	--SS.player:clearVariable("AttackAnim")
	--clearVariable("bShoveAiming");
	--clearVariable("bShoveAiming");
	--
	--[[
	SS.player:setNPC(false)
	SS.player:setBlockMovement(false)
	SS.player:update()
	SS.player:setNPC(true)
	SS.player:setBlockMovement(true)
	ISTimedActionQueue.add(ISGetHitFromBehindAction:new(SS.player,getSpecificPlayer(0)))
	
	
	local xoff = SS.player:getX() + ZombRand(-3,3)
    local yoff = SS.player:getY() + ZombRand(-3,3)	
    SS:DebugSay("CheckForIfStuck is about to trigger a StopWalk!")
    SS:StopWalk()
	ISTimedActionQueue.add(ISGetHitFromBehindAction:new(SS.player,getSpecificPlayer(0)))
    SS:WalkToPoint(xoff,yoff,SS.player:getZ())
	ISTimedActionQueue.add(ISGetHitFromBehindAction:new(SS.player,getSpecificPlayer(0)))
	
	SS.player:setPerformingAnAction(true)
	SS.player:setVariable("bPathfind", true)	
	SS.player:setVariable("bKnockedDown", true)
	SS.player:setVariable("AttackAnim", true)
	SS.player:setVariable("BumpFall", true)
	
	ISTimedActionQueue.add(ISGetHitFromBehindAction:new(SS.player,getSpecificPlayer(0)))
	--]]
	
end

function DebugSpawnSoldier()
	local ss = SuperSurvivorSoldierSpawn(getSpecificPlayer(0):getCurrentSquare())
end
function DebugSpawnSoldierMelee()
	local ss = SuperSurvivorSoldierSpawnMelee(getSpecificPlayer(0):getCurrentSquare())
end

function DebugSpawnSoldierHostile()
	local ss = SuperSurvivorSoldierSpawnHostile(getSpecificPlayer(0):getCurrentSquare())
end
function DebugSpawnSoldierMeleeHostile()
	local ss = SuperSurvivorSoldierSpawnMeleeHostile(getSpecificPlayer(0):getCurrentSquare())
end



function OfferArmor(test,SS,item)
	local player = SS:Get()
	getSpecificPlayer(0):Say(getActionText("TakeArmor"))	
	local task = SS:getTaskManager():getTaskFromName("Listen")
	if(task ~= nil) and (task.Name == "Listen") then task:Talked() end
	
	local gift = SSM:Get(0):getFacingSquare():AddWorldInventoryItem(item,0.5,0.5,0)
	
	getSpecificPlayer(0):getInventory():DoRemoveItem(item)
	
	SS:getTaskManager():AddToTop(TakeGiftTask:new(SS,gift))
	SS:PlusRelationshipWP(1.5)
end

function SwapWeaponsSurvivor(test,SS, Type)
	
	local player = SS:Get()
	local PP = getSpecificPlayer(0):getPrimaryHandItem();
	local PS = getSpecificPlayer(0):getSecondaryHandItem();
	
	local toPlayer 
	
	if(Type == "Gun") then 
		toPlayer = SS.LastGunUsed
		SS:setGunWep(PP)
	else 
		toPlayer = SS.LastMeleUsed
		SS:setMeleWep(PP)
	end
	
	--player:setPrimaryHandItem(nil);
	--player:setSecondaryHandItem(nil);
	
	local PNW ;
	if(toPlayer) then PNW = getSpecificPlayer(0):getInventory():AddItem(toPlayer); end
	getSpecificPlayer(0):setPrimaryHandItem(PNW);
	if(PNW) and (PNW:isTwoHandWeapon()) then getSpecificPlayer(0):setSecondaryHandItem(PNW); end
	if(toPlayer) then 
		player:getInventory():Remove(toPlayer)
		if(SS:getBag():contains(toPlayer)) then SS:getBag():Remove(toPlayer) end
	end
	
	if(PP == PS) then getSpecificPlayer(0):setSecondaryHandItem(nil); end
	local SNW = player:getInventory():AddItem(PP);
	
	player:setPrimaryHandItem(SNW)
	if(SNW:isTwoHandWeapon()) then player:setSecondaryHandItem(SNW) end
	if(player:getSecondaryHandItem() == toPlayer) then 
		player:setSecondaryHandItem(nil) 
		player:removeFromHands(nil) 
	end
	getSpecificPlayer(0):getInventory():Remove(PP);
	
	if SNW and SNW:getBodyLocation() ~= "" then
		player:removeFromHands(nil)
		player:setWornItem(item:getBodyLocation(), SNW);
	end	
	triggerEvent("OnClothingUpdated", player)
	player:initSpritePartsEmpty();
	
	if PNW and PNW:getBodyLocation() ~= "" then
		getSpecificPlayer(0):removeFromHands(nil)
		getSpecificPlayer(0):setWornItem(item:getBodyLocation(), PNW);
	end	
	triggerEvent("OnClothingUpdated", getSpecificPlayer(0))
	getSpecificPlayer(0):initSpritePartsEmpty();

end

function ForceWeaponType(test,SS,useMele)
	
	if(not useMele) then
		SS:reEquipMele()
	else
		SS:reEquipGun()
	end

end

function ViewSurvivorInfo(test,ss)

	mySurvivorInfoWindow:Load(ss)
	mySurvivorInfoWindow:setVisible(true)

end

function TalkToSurvivor(test,SS)

	if(SS.HasQuestion or SS.HasBikuri) then	
		SSQM:TalkedTo(SS:getName())
	else
		
		getSpecificPlayer(0):Say(getSpeech("HelloThere"))		
			
		if SS:Get():CanSee(getSpecificPlayer(0)) then 
			if(SS:Get():getModData().Greeting ~= nil) then SS:Speak(SS:Get():getModData().Greeting)
			else SS:Speak(getSpeech("IdleChatter")) end
		else 
			SS:Speak(getDialogue("WhoSaidThat"));
		end
	end
end
function CallSurvivor(test,player)
	
	if(getDistanceBetween(getSpecificPlayer(0),player) > 3) then 
		getSpecificPlayer(0):Say(getActionText("OverHere"))		
	else
		getSpecificPlayer(0):Say(getDialogue("HelloThere"))		
	end
	
	local SS = SSM:Get(player:getModData().ID)
	
	SS:getTaskManager():AddToTop(ListenTask:new(SS,getSpecificPlayer(0),false))
end

function survivorMenu(context,o)
	if(instanceof(o, "IsoPlayer") and o:getModData().ID ~= nil and o:getModData().ID ~= SSM:getRealPlayerID()) then -- make sure its a valid survivor
		local ID = o:getModData().ID
		local SS = SSM:Get(o:getModData().ID)
		local survivorOption = context:addOption(SS:getName(), worldobjects, nil);
		local submenu = context:getNew(context);
				
		if(SS.player:getModData().surender) then submenu:addOption("Scram!", nil, AskToLeave, SS, nil) end
		if(SS.player:getModData().surender) then submenu:addOption("Drop Your loot!", nil, AskToDrop, SS, nil) end
		if (o:getModData().isHostile ~= true) then
			local medicalOption = submenu:addOption(getText("ContextMenu_Medical_Check"), nil, MedicalCheckSurvivor, o, nil);
			local toolTip = makeToolTip(medicalOption, getContextMenuText("AidCheck"), getContextMenuText("AidCheckDesc"));							
			
			if(SS.HasQuestion) then	makeToolTip(submenu:addOption("Answer 'YES'", nil, AnswerTriggerQuestionYes, SS, nil),"Answer YES to the following NPC Question",tostring(SS.player:getModData().lastThingIsaid)) end
			if(SS.HasQuestion) then	makeToolTip(submenu:addOption("Answer 'NO'", nil, AnswerTriggerQuestionNo, SS, nil),"Answer NO to the following NPC Question",tostring(SS.player:getModData().lastThingIsaid))  end
			if (DebugOptions) then submenu:addOption(getContextMenuText("Debug_Character_Swap"), nil, DebugCharacterSwap, SS, nil)end -- debut character swap
			if (DebugOptions) then submenu:addOption(getContextMenuText("Debug_Infect&Murder_Character"), nil, DebugCharacterKill, SS, nil) end -- debut character swap
			--if (DebugOptions) then submenu:addOption("Debug Toggle isBM ("..tostring(o:getModData().ID)..")", nil, DebugCharacterToggleBM, SS, nil) end -- debut character swap
			--if (DebugOptions) then submenu:addOption("Debug Toggle isNPC ("..tostring(o:getModData().ID)..")", nil, DebugCharacterToggleNPC, SS, nil) end -- debut character swap
			if (DebugOptions) then submenu:addOption(getContextMenuText("Debug_Character_Output"), nil, DebugCharacterOutput, SS, nil) end -- debut character swap
			if (DebugOptions) then submenu:addOption(getContextMenuText("Debug_Unstuck"), nil, DebugCharacterUnStuck, SS, nil) end -- debut character swap
		end		
		if (o:getModData().isHostile ~= true) and ( (SS:getTaskManager():getCurrentTask() == "Listen") or (SS:getTaskManager():getCurrentTask() == "Take Gift") or (getDistanceBetween(SS:Get(),getSpecificPlayer(0)) < 2) ) then
			local selectOption = submenu:addOption(		getContextMenuText("TalkOption"), nil, TalkToSurvivor, SS, nil);
			local toolTip = makeToolTip(selectOption,	getContextMenuText("TalkOption"), getContextMenuText("TalkOption_Desc"));
			if((SS:getGroupID() ~= SSM:Get(0):getGroupID()) or SS:getGroupID() == nil) then -- not in group
				if (o:getModData().NoParty ~= true) then
					submenu:addOption(getContextMenuText("InviteToGroup"), nil, InviteToParty, o, nil);
				end
				if ((SS:getGroup() ~= nil) and (SS:getGroupID() ~= SSM:Get(0):getGroupID())) --[[and (o:getModData().NoParty ~= true)]] then
					submenu:addOption(getContextMenuText("AskToJoin"), nil, AskToJoin, o, nil);
				end				
				if ((o:getPrimaryHandItem() == nil) and (getSpecificPlayer(0):getPrimaryHandItem() ~= nil) ) then
					submenu:addOption(getContextMenuText("OfferWeapon"), nil, OfferWeapon, o, nil);
				end				
			elseif((SS:getGroupID() == SSM:Get(0):getGroupID()) and SS:getGroupID() ~= nil) then
				---orders
				local i = 1;
				local orderOption = submenu:addOption(getContextMenuText("GiveOrder"), worldobjects, nil);
				local subsubmenu = submenu:getNew(submenu);
				while(Orders[i]) do
					if(Orders[i] == "Loot Room") then
						local subsubsubmenu = subsubmenu:getNew(subsubmenu);
						local lootTypeOption = subsubmenu:addOption(OrderDisplayName[Orders[i]], nil, SurvivorOrder, o, Orders[i])
						local q = 1;
						while(LootTypes[q]) do
							subsubsubmenu:addOption(getText("IGUI_ItemCat_"..LootTypes[q]), nil, SurvivorOrder, o, Orders[i], LootTypes[q]);
							q = q + 1;
						end
						subsubmenu:addSubMenu(lootTypeOption, subsubsubmenu);
					else
						makeToolTip(subsubmenu:addOption(OrderDisplayName[Orders[i]], nil, SurvivorOrder, o, Orders[i]), getContextMenuText("OrderDescription"),OrderDesc[Orders[i]]);
					end
					i = i + 1;
				end
				submenu:addSubMenu(orderOption, subsubmenu)
				
				if (getSpecificPlayer(0):getPrimaryHandItem() ~= nil) and (instanceof(getSpecificPlayer(0):getPrimaryHandItem(),"HandWeapon")) then
				
					local OfferWeapon = getSpecificPlayer(0):getPrimaryHandItem()
					local Type = "Gun"
					local Label = ""
					local SurvivorWeaponName = getActionText("Nothing") 
					if(o:getPrimaryHandItem() ~= nil) then SurvivorWeaponName = o:getPrimaryHandItem():getDisplayName() end
					if(not OfferWeapon:isAimedFirearm()) then Type = "Mele" end
					local swapweaponsOption, tooltipText
					if(Type == "Gun") then 
						
						if SS.LastGunUsed == nil then 
							Label = getContextMenuText("GiveGun") 
							--tooltipText = "Give your "..getSpecificPlayer(0):getPrimaryHandItem():getDisplayName() .. " to this Survivor to be his Gun type Weapon"
						else 
							Label = getContextMenuText("SwapGuns") 
							--tooltipText = "Trade your "..getSpecificPlayer(0):getPrimaryHandItem():getDisplayName().." with ".. o:getForname().."\'s ".. SurvivorWeaponName						
						end
						swapweaponsOption = submenu:addOption(Label, nil, SwapWeaponsSurvivor, SS, "Gun");
					
					else
						
						if SS.LastMeleUsed == nil then 
							Label = getContextMenuText("GiveWeapon")
							--tooltipText = "Give your "..getSpecificPlayer(0):getPrimaryHandItem():getDisplayName() .. " to this Survivor to be his Mele type Weapon"
						else 
							Label = getContextMenuText("SwapWeapons")
							--tooltipText = "Trade your "..getSpecificPlayer(0):getPrimaryHandItem():getDisplayName().." with ".. o:getForname().."\'s ".. SurvivorWeaponName
						end
						swapweaponsOption = submenu:addOption(Label, nil, SwapWeaponsSurvivor, SS, "Mele");
						
					end
					--local tooltip = makeToolTip(swapweaponsOption,Label,tooltipText);
				
				
				end
								
				
				if (o:getPrimaryHandItem() ~= SS.LastMeleUsed) and (SS.LastMeleUsed ~= nil) then
				
					local ForceMeleOption = submenu:addOption(getContextMenuText("UseMele"), nil, ForceWeaponType, SS, false)
					
					local tooltip = makeToolTip(ForceMeleOption,getContextMenuText("UseMele"),getContextMenuText("UseMeleDesc"))
				end
				if (o:getPrimaryHandItem() ~= SS.LastGunUsed) and (SS.LastGunUsed ~= nil) then
				
					local ForceMeleOption = submenu:addOption(getContextMenuText("UseGun"), nil, ForceWeaponType, SS, true)
					
					local tooltip = makeToolTip(ForceMeleOption,getContextMenuText("UseGun"),getContextMenuText("UseGunDesc"))
				end
						
				local SetNameOption = submenu:addOption(getContextMenuText("SetName"), nil, SetName, SS, true)
			end
			
			local viewinfoOption = submenu:addOption(		getContextMenuText("ViewSurvivorInfo"), nil, ViewSurvivorInfo, SS, nil)				
			local tooltip = makeToolTip(viewinfoOption,	getContextMenuText("ViewSurvivorInfo"),getContextMenuText("ViewSurvivorInfoDesc"))
				
			if (SSM:Get(0):hasFood()) then
				submenu:addOption(getContextMenuText("OfferFood"), nil, OfferFood, o, nil);
			end
			if (SSM:Get(0):hasWater()) then
				submenu:addOption(getContextMenuText("OfferWater"), nil, OfferWater, o, nil);
			end
			
			
			local armors = SSM:Get(0):getUnEquipedArmors()
			if(armors) then
				--getSpecificPlayer(0):Say("hereiam2")
				local selectOption = submenu:addOption(getContextMenuText("OfferArmor"), worldobjects, nil);
				local armormenu = submenu:getNew(submenu);

				for i=1, #armors do
					--getSpecificPlayer(0):Say("hereiam2" .. armors[i]:getDisplayName())
					armormenu:addOption(armors[i]:getDisplayName(), nil, OfferArmor, SS, armors[i])
				end
				
				submenu:addSubMenu(selectOption, armormenu);
			
			end
			
			
			local ammoBox 
			for i=1,#SS.AmmoBoxTypes do			
				ammoBox = SSM:Get(0):FindAndReturn(SS.AmmoBoxTypes[i])
				if(ammoBox) then break end
			end
			
			if (ammoBox ~= nil) then
				submenu:addOption(getContextMenuText("OfferAmmoBox"), nil, OfferAmmo, o, ammoBox);
			end
			
			local ammoRound
			for i=1,#SS.AmmoTypes do			
				ammoRound = SSM:Get(0):FindAndReturn(SS.AmmoTypes[i])
				if(ammoRound) then break end
			end
			
			if (ammoRound ~= nil) then
				submenu:addOption(getContextMenuText("OfferAmmoRound"), nil, OfferAmmo, o, ammoRound);
			end
			
		end
		if (o:getModData().isHostile ~= true) and (SS:getDangerSeenCount() == 0) and (SS:getTaskManager():getCurrentTask() ~= "Listen") then
			local selectOption = submenu:addOption(		getContextMenuText("CallOver"), nil, CallSurvivor, o, nil);
			local toolTip = makeToolTip(selectOption,	getContextMenuText("CallOver"), getContextMenuText("CallOverDesc"));
		end
		
		
		
		context:addSubMenu(survivorOption, submenu);
	end
end

function SurvivorsSquareContextHandle(square,context)
	if(square ~= nil) then
	
		for i=0,square:getMovingObjects():size()-1 do
			local o = square:getMovingObjects():get(i)
			if(instanceof(o, "IsoPlayer")) and (o:getModData().ID ~= SSM:getRealPlayerID()) then
				survivorMenu(context,o);
			end			
		end		
	end
end


function StartSelectingArea(test,area)

	for k, v in pairs(SuperSurvivorSelectArea) do
		SuperSurvivorSelectArea[k] = false
	end
	
	SuperSurvivorSelectArea[area] = true
	SuperSurvivorSelectAnArea = true
	
	local mySS = SSM:Get(0)
	local gid = mySS:getGroupID()
	if(not gid) then return false end
	local group = SSGM:Get(gid)
	if(not group) then return false end
	
	if(area == "BaseArea") then
			
		local baseBounds = group:getBounds(baseBounds)
		HighlightX1 = baseBounds[1]
		HighlightX2 = baseBounds[2]
		HighlightY1 = baseBounds[3]
		HighlightY2 = baseBounds[4]
		HighlightZ = baseBounds[5]
			
	else
	
		local bounds = group:getGroupArea(area)
		HighlightX1 = bounds[1]
		HighlightX2 = bounds[2]
		HighlightY1 = bounds[3]
		HighlightY2 = bounds[4]
		HighlightZ = bounds[5]
	end

end
function SelectingArea(test,area,value)
	-- value 0 means cancel, -1 is clear, 1 is set
	if (value ~= 0) then
	
		if(value == -1) then
			HighlightX1 = 0
			HighlightX2 = 0
			HighlightY1 = 0
			HighlightY2 = 0
		end
	
		local mySS = SSM:Get(0)
		local gid = mySS:getGroupID()
		if(not gid) then return false end
		local group = SSGM:Get(gid)
		if(not group) then return false end
	
		if(area == "BaseArea") then
			
			local baseBounds = {
				math.floor(HighlightX1),
				math.floor(HighlightX2),
				math.floor(HighlightY1),
				math.floor(HighlightY2),
				math.floor(getSpecificPlayer(0):getZ())
			}
			group:setBounds(baseBounds)
			print("set base bounds:"..tostring(HighlightX1)..","..tostring(HighlightX2).." : "..tostring(HighlightY1)..","..tostring(HighlightY2))			
			
		
		else		
			group:setGroupArea(area,math.floor(HighlightX1),math.floor(HighlightX2),math.floor(HighlightY1),math.floor(HighlightY2),getSpecificPlayer(0):getZ())			
		end
		
	end
	
	SuperSurvivorSelectArea[area] = false	
	SuperSurvivorSelectAnArea = false
	
end

SuperSurvivorSelectArea = {}
function SuperSurvivorsAreaSelect(context, area, Display)

	local selectOption = context:addOption(Display, worldobjects, nil);
	local submenu = context:getNew(context);

	if(SuperSurvivorSelectArea[area]) then 
		submenu:addOption(getContextMenuText("SetAreaConfirm"), nil, SelectingArea, area, 1)
		submenu:addOption(getContextMenuText("SetAreaCancel"), nil, SelectingArea, area, 0)
		submenu:addOption(getContextMenuText("SetAreaClear"), nil, SelectingArea, area, -1)
	else 
		makeToolTip(submenu:addOption(getContextMenuText("SetAreaSelect"), nil, StartSelectingArea, area),getContextMenuText("SetAreaSelect"),getContextMenuText("SetAreaSelectDesc"))
	end
		
	context:addSubMenu(selectOption, submenu);
end

function SurvivorsFillWorldObjectContextMenu(player, context, worldobjects, test)

	--only player 1 can manipulate survivors
	if player ~= 0 then 
        return
    end
	
	local selectOption = context:addOption(getContextMenuText("AreaSelecting"), worldobjects, nil);
	local submenu = context:getNew(context);
		
		SuperSurvivorsAreaSelect(submenu, "BaseArea", 					getContextMenuText("BaseArea"))
		SuperSurvivorsAreaSelect(submenu, "ChopTreeArea", 			getContextMenuText("ChopTreeArea"))		
		SuperSurvivorsAreaSelect(submenu, "TakeCorpseArea", 		getContextMenuText("TakeCorpseArea"))		
		SuperSurvivorsAreaSelect(submenu, "CorpseStorageArea", 	getContextMenuText("CorpseStorageArea"))
		SuperSurvivorsAreaSelect(submenu, "TakeWoodArea", 			getContextMenuText("TakeWoodArea"))		
		SuperSurvivorsAreaSelect(submenu, "WoodStorageArea", 		getContextMenuText("WoodStorageArea"))
		SuperSurvivorsAreaSelect(submenu, "FoodStorageArea", 		getContextMenuText("FoodStorageArea"))
		SuperSurvivorsAreaSelect(submenu, "WeaponStorageArea", 	getContextMenuText("WeaponStorageArea"))		
		SuperSurvivorsAreaSelect(submenu, "ToolStorageArea", 		getContextMenuText("ToolStorageArea"))		
		SuperSurvivorsAreaSelect(submenu, "MedicalStorageArea", getContextMenuText("MedicalStorageArea"))
		SuperSurvivorsAreaSelect(submenu, "FarmingArea", 			getContextMenuText("FarmingArea"))		-- Farming does not work
		SuperSurvivorsAreaSelect(submenu, "ForageArea", 				getContextMenuText("ForageArea"))
		SuperSurvivorsAreaSelect(submenu, "GuardArea", 					getContextMenuText("GuardArea"))
		
	context:addSubMenu(selectOption, submenu);
	
	
	local square = getMouseSquare(player);
					
	SurvivorsSquareContextHandle(square,context);	
	if(square ~= nil) then
		local osquare = square:getN();
		if(osquare ~= nil) then
		SurvivorsSquareContextHandle(osquare:getE(),context);
		SurvivorsSquareContextHandle(osquare:getW(),context);
		SurvivorsSquareContextHandle(osquare,context);
		end
		osquare = square:getS();
		if(osquare ~= nil) then
		SurvivorsSquareContextHandle(osquare:getE(),context);
		SurvivorsSquareContextHandle(osquare:getW(),context);
		SurvivorsSquareContextHandle(osquare,context);
		end
		osquare = square:getE();
		if(osquare ~= nil) then
		SurvivorsSquareContextHandle(osquare,context);
		end
		osquare = square:getW();
		if(osquare ~= nil) then
		SurvivorsSquareContextHandle(osquare,context);
		end
	end
	
	local SurvivorOptions =context:addOption(getContextMenuText("SurvivorOptions"), worldobjects, nil);
	local submenu = context:getNew(context);
	
	local RulesOfEngagementOption = submenu:addOption(getContextMenuText("RulesOfEngagement"), worldobjects, nil);
	local subsubmenu = submenu:getNew(submenu);
	
	makeToolTip(subsubmenu:addOption(getContextMenuText("AttackAnyoneOnSight"), nil, SetRulesOfEngagement, 4),"Rules of Engagement","Shoot or Attack on sight Anything that may come along. Zombies, hostile survivors, friendly survivors neutral. Only party members are the exception");
	makeToolTip(subsubmenu:addOption(getContextMenuText("AttackHostilesOnSight"), nil, SetRulesOfEngagement, 3),"Rules of Engagement","Shoot or Attack on sight Anything hostile that may come along. Zombies or obviously hostile survivors");
	--makeToolTip(subsubmenu:addOption("Attack Zombies", nil, SetRulesOfEngagement, 2),"Rules of Engagement","Shoot or Attack on sight Any zombies that may come along.");
	--makeToolTip(subsubmenu:addOption("No Attacking", nil, SetRulesOfEngagement, 1),"Rules of Engagement","Do not shoot or attack anything or anyone. Just avoid when possible.");
	
	submenu:addSubMenu(RulesOfEngagementOption, subsubmenu);
	
	local MeleOrGunOption = submenu:addOption(getContextMenuText("CallToArms"), worldobjects, nil);
	subsubmenu = submenu:getNew(submenu);
	
	makeToolTip(subsubmenu:addOption(getContextMenuText("UseMele"), nil, SetMeleOrGun, 'mele'),	getContextMenuText("UseMele"),getContextMenuText("UseMeleDesc"));
	makeToolTip(subsubmenu:addOption(getContextMenuText("UseGun"), nil, SetMeleOrGun, 'gun'),		getContextMenuText("UseGun"),	getContextMenuText("UseGunDesc"));

	if (DebugOptions) then 
		submenu:addOption(getContextMenuText("Debug_Spawn_Soldier"), nil, DebugSpawnSoldier)  -- debug spawn soldier
		submenu:addOption(getContextMenuText("Debug_Spawn_Soldier").." - Melee", nil, DebugSpawnSoldierMelee)  -- debug spawn soldier melee
		submenu:addOption(getContextMenuText("Debug_Spawn_Soldier").. " - Hostile", nil, DebugSpawnSoldierHostile)  -- debug spawn soldier
		submenu:addOption(getContextMenuText("Debug_Spawn_Soldier").." - Hostile Melee", nil, DebugSpawnSoldierMeleeHostile)  -- debug spawn soldier melee

		
		submenu:addOption(getContextMenuText("Debug_PlayerStats"), nil, ISPlayerStatsUI.OnOpenPanel)  --use debug mod to change player name
	end	
	submenu:addSubMenu(MeleOrGunOption, subsubmenu);
	
	context:addSubMenu(SurvivorOptions, submenu);  --Add ">"
	
end

function SetRulesOfEngagement(test,value)
	getSpecificPlayer(0):getModData().ROE = value ;
	
	local SS = SSM:Get(0)
	local group = SS:getGroup()
	if(group) then
		group:setROE(value)
		getSpecificPlayer(0):Say(getContextMenuText("ROESet"));
	end
end

function SetMeleOrGun(test,value)
	local mySS = SSM:Get(0)
	if(mySS:getGroupID() ~= nil) then 
	
		local myGroup = SSGM:Get(mySS:getGroupID())
		if(myGroup) then 
			if(value == "gun") then 
				mySS:Get():Say(getContextMenuText("EveryOneUseGun"))
			else
				mySS:Get():Say(getContextMenuText("EveryOneUseMele"))
			end
			myGroup:UseWeaponType(value) 
		end
		
	end
	
end

function OnSetName(test, button, SS)
    if button.internal == "OK" then
        if button.parent.entry:getText() and button.parent.entry:getText() ~= "" then
			SS:setName(button.parent.entry:getText())
        end
    end
end

function SetName(test, SS)
	
	local name = SS:getName()
	local modal = ISTextBox:new(0, 0, 280, 180, getContextMenuText("SetName"), name, nil, OnSetName, 0, SS)
    modal:initialise()
    modal:addToUIManager()
end
--Own Name Setting Section--
--function OnSetOwnName(test, button, character)
--   if button.internal == "OK" then
--        if button.parent.entry:getText() and button.parent.entry:getText() ~= "" then
--			character:SetOwnName(button.parent.entry:getText())
--        end
--    end
--end
--function SetOwnName(test, character)
--	local name = character:getDescriptor():getForename()
--	local modal = ISTextBox:new(0, 0, 280, 180, getContextMenuText("SetOwnName"), name, nil, OnSetOwnName, 0, character)
--   modal:initialise()
--   modal:addToUIManager()
--end
--Section Complete--

Events.OnFillWorldObjectContextMenu.Add(SurvivorsFillWorldObjectContextMenu);