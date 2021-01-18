/*
	Cyborg ClickOn()

	Cyborgs have no range restriction on attack_robot(), because it is basically an AI click.
	However, they do have a range restriction on item use, so they cannot do without the
	adjacency code.
*/

/mob/living/silicon/robot/ClickOn(atom/A, params)
	if(check_click_intercept(params,A))
		return

	if(stat || locked_down || IsParalyzed() || IsStun() || IsUnconscious())
		return

	var/list/modifiers = params2list(params)
	if(modifiers["shift"] && modifiers["ctrl"])
		return CtrlShiftClickOn(A)
	if(modifiers["shift"] && modifiers["middle"])
		return ShiftMiddleClickOn(A)
	if(modifiers["middle"])
		return MiddleClickOn(A)
	if(modifiers["shift"])
		return ShiftClickOn(A)
	if(modifiers["alt"]) // alt and alt-gr (rightalt)
		return AltClickOn(A)
	if(modifiers["ctrl"])
		return CtrlClickOn(A)

	if(!CheckActionCooldown(immediate = TRUE))
		return

	face_atom(A) // change direction to face what you clicked on

	/*
	cyborg restrained() currently does nothing
	if(restrained())
		RestrainedClickOn(A)
		return
	*/
	if(aicamera.in_camera_mode) //Cyborg picture taking
		aicamera.camera_mode_off()
		INVOKE_ASYNC(aicamera, /obj/item/camera.proc/captureimage, A, usr)
		return

	var/obj/item/W = get_active_held_item()

	if(!W && A.Adjacent(src) && (isobj(A) || ismob(A)))
		var/atom/movable/C = A
		if(C.can_buckle && C.has_buckled_mobs())
			INVOKE_ASYNC(C, /atom/movable.proc/precise_user_unbuckle_mob, src)
			return

	if(!W && (get_dist(src,A) <= interaction_range))
		A.attack_robot(src)
		return

	if(W)
		// buckled cannot prevent machine interlinking but stops arm movement
		if( buckled || incapacitated())
			return

		if(W == A)
			W.attack_self(src)
			return

		// cyborgs are prohibited from using storage items so we can I think safely remove (A.loc in contents)
		if(A == loc || (A in loc) || (A in contents))
			. = W.melee_attack_chain(src, A, params)
			if(!(. & NO_AUTO_CLICKDELAY_HANDLING) && ismob(A))
				DelayNextAction(CLICK_CD_MELEE)
			return

		if(!isturf(loc))
			return

		// cyborgs are prohibited from using storage items so we can I think safely remove (A.loc && isturf(A.loc.loc))
		if(isturf(A) || isturf(A.loc))
			if(A.Adjacent(src)) // see adjacent.dm
				. = W.melee_attack_chain(src, A, params)
				if(!(. & NO_AUTO_CLICKDELAY_HANDLING) && ismob(A))
					DelayNextAction(CLICK_CD_MELEE)
				return
			else
				return W.afterattack(A, src, 0, params)

//Middle click cycles through selected modules.
/mob/living/silicon/robot/MiddleClickOn(atom/A)
	cycle_modules()
	return

//Give cyborgs hotkey clicks without breaking existing uses of hotkey clicks
// for non-doors/apcs
/mob/living/silicon/robot/CtrlShiftClickOn(atom/A)
	A.BorgCtrlShiftClick(src)
/mob/living/silicon/robot/ShiftClickOn(atom/A)
	A.BorgShiftClick(src)
/mob/living/silicon/robot/CtrlClickOn(atom/A)
	A.BorgCtrlClick(src)
/mob/living/silicon/robot/AltClickOn(atom/A)
	A.BorgAltClick(src)

/atom/proc/BorgCtrlShiftClick(mob/living/silicon/robot/user) //forward to human click if not overridden
	CtrlShiftClick(user)

/obj/machinery/door/airlock/BorgCtrlShiftClick(mob/living/silicon/robot/user) // Sets/Unsets Emergency Access Override Forwards to AI code.
	if(get_dist(src,user) <= user.interaction_range)
		AICtrlShiftClick()
	else
		..()


/atom/proc/BorgShiftClick(mob/living/silicon/robot/user) //forward to human click if not overridden
	ShiftClick(user)

/obj/machinery/door/airlock/BorgShiftClick(mob/living/silicon/robot/user)  // Opens and closes doors! Forwards to AI code.
	if(get_dist(src,user) <= user.interaction_range)
		AIShiftClick()
	else
		..()


/atom/proc/BorgCtrlClick(mob/living/silicon/robot/user) //forward to human click if not overridden
	CtrlClick(user)

/obj/machinery/door/airlock/BorgCtrlClick(mob/living/silicon/robot/user) // Bolts doors. Forwards to AI code.
	if(get_dist(src,user) <= user.interaction_range)
		AICtrlClick()
	else
		..()

/obj/machinery/power/apc/BorgCtrlClick(mob/living/silicon/robot/user) // turns off/on APCs. Forwards to AI code.
	if(get_dist(src,user) <= user.interaction_range)
		AICtrlClick()
	else
		..()

/obj/machinery/turretid/BorgCtrlClick(mob/living/silicon/robot/user) //turret control on/off. Forwards to AI code.
	if(get_dist(src,user) <= user.interaction_range)
		AICtrlClick()
	else
		..()

/atom/proc/BorgAltClick(mob/living/silicon/robot/user)
	return AltClick(user)

/obj/machinery/door/airlock/BorgAltClick(mob/living/silicon/robot/user) // Eletrifies doors. Forwards to AI code.
	if(get_dist(src,user) <= user.interaction_range)
		return AIAltClick()
	return ..()

/obj/machinery/turretid/BorgAltClick(mob/living/silicon/robot/user) //turret lethal on/off. Forwards to AI code.
	if(get_dist(src,user) <= user.interaction_range)
		return AIAltClick()
	return ..()

/*
	As with AI, these are not used in click code,
	because the code for robots is specific, not generic.

	If you would like to add advanced features to robot
	clicks, you can do so here, but you will have to
	change attack_robot() above to the proper function
*/
/mob/living/silicon/robot/UnarmedAttack(atom/A, proximity, intent = a_intent, flags = NONE)
	A.attack_robot(src)

/mob/living/silicon/robot/RangedAttack(atom/A)
	A.attack_robot(src)

/atom/proc/attack_robot(mob/user)
	attack_ai(user)
	return
