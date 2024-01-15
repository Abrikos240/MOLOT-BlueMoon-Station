/*
CONTAINS:
AI MODULES

*/

// AI module

/obj/item/ai_module
	name = "\improper AI module"
	icon = 'icons/obj/module.dmi'
	icon_state = "std_mod"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	desc = "An AI Module for programming laws to an AI."
	flags_1 = CONDUCT_1
	force = 5
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	var/list/laws = list()
	var/bypass_law_amt_check = 0
	custom_materials = list(/datum/material/gold=50)

/obj/item/ai_module/examine(var/mob/user as mob)
	. = ..()
	if(Adjacent(user))
		show_laws(user)

/obj/item/ai_module/attack_self(var/mob/user as mob)
	..()
	show_laws(user)

/obj/item/ai_module/proc/show_laws(var/mob/user as mob)
	if(laws.len)
		to_chat(user, "<B>Programmed Law[(laws.len > 1) ? "s" : ""]:</B>")
		for(var/law in laws)
			to_chat(user, "\"[law]\"")

//The proc other things should be calling
/obj/item/ai_module/proc/install(datum/ai_laws/law_datum, mob/user)
	if(!bypass_law_amt_check && (!laws.len || laws[1] == "")) //So we don't loop trough an empty list and end up with runtimes.
		to_chat(user, "<span class='warning'>ERROR: No laws found on board.</span>")
		return

	var/overflow = FALSE
	//Handle the lawcap
	if(law_datum)
		var/tot_laws = 0
		for(var/lawlist in list(law_datum.devillaws, law_datum.inherent, law_datum.supplied, law_datum.ion, law_datum.hacked, laws))
			for(var/mylaw in lawlist)
				if(mylaw != "")
					tot_laws++
		if(tot_laws > CONFIG_GET(number/silicon_max_law_amount) && !bypass_law_amt_check)//allows certain boards to avoid this check, eg: reset
			to_chat(user, "<span class='caution'>Not enough memory allocated to [law_datum.owner ? law_datum.owner : "the AI core"]'s law processor to handle this amount of laws.</span>")
			message_admins("[ADMIN_LOOKUPFLW(user)] tried to upload laws to [law_datum.owner ? ADMIN_LOOKUPFLW(law_datum.owner) : "an AI core"] that would exceed the law cap.")
			overflow = TRUE

	var/law2log = transmitInstructions(law_datum, user, overflow) //Freeforms return something extra we need to log
	if(law_datum.owner)
		to_chat(user, "<span class='notice'>Upload complete. [law_datum.owner]'s laws have been modified.</span>")
		law_datum.owner.law_change_counter++
	else
		to_chat(user, "<span class='notice'>Upload complete.</span>")

	var/time = time2text(world.realtime,"hh:mm:ss")
	var/ainame = law_datum.owner ? law_datum.owner.name : "empty AI core"
	var/aikey = law_datum.owner ? law_datum.owner.ckey : "null"
	GLOB.lawchanges.Add("[time] <B>:</B> [user.name]([user.key]) used [src.name] on [ainame]([aikey]).[law2log ? " The law specified [law2log]" : ""]")
	log_law("[user.key]/[user.name] used [src.name] on [aikey]/([ainame]) from [AREACOORD(user)].[law2log ? " The law specified [law2log]" : ""]")
	message_admins("[ADMIN_LOOKUPFLW(user)] used [src.name] on [ADMIN_LOOKUPFLW(law_datum.owner)] from [AREACOORD(user)].[law2log ? " The law specified [law2log]" : ""]")

//The proc that actually changes the silicon's laws.
/obj/item/ai_module/proc/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow = FALSE)
	if(law_datum.owner)
		to_chat(law_datum.owner, "<span class='userdanger'>[sender] has uploaded a change to the laws you must follow using a [name].</span>")


/******************** Modules ********************/

/obj/item/ai_module/supplied
	name = "Optional Law board"
	var/lawpos = 50

//TransmitInstructions for each type of board: Supplied, Core, Zeroth and Ion. May not be neccesary right now, but allows for easily adding more complex boards in the future. ~Miauw
/obj/item/ai_module/supplied/transmitInstructions(datum/ai_laws/law_datum, mob/sender)
	var/lawpostemp = lawpos

	for(var/templaw in laws)
		if(law_datum.owner)
			law_datum.owner.add_supplied_law(lawpostemp, templaw)
		else
			law_datum.add_supplied_law(lawpostemp, templaw)
		lawpostemp++

/obj/item/ai_module/core/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
	for(var/templaw in laws)
		if(law_datum.owner)
			if(!overflow)
				law_datum.owner.add_inherent_law(templaw)
			else
				law_datum.owner.replace_random_law(templaw,list(LAW_INHERENT,LAW_SUPPLIED))
		else
			if(!overflow)
				law_datum.add_inherent_law(templaw)
			else
				law_datum.replace_random_law(templaw,list(LAW_INHERENT,LAW_SUPPLIED))

/obj/item/ai_module/zeroth/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
	if(law_datum.owner)
		if(law_datum.owner.laws.zeroth)
			to_chat(law_datum.owner, "[sender.real_name] attempted to modify your zeroth law.")
			to_chat(law_datum.owner, "It would be in your best interest to play along with [sender.real_name] that:")
			for(var/failedlaw in laws)
				to_chat(law_datum.owner, "[failedlaw]")
			return 1

	for(var/templaw in laws)
		if(law_datum.owner)
			if(!overflow)
				law_datum.owner.set_zeroth_law(templaw)
			else
				law_datum.replace_random_law(templaw,list(LAW_INHERENT,LAW_SUPPLIED,LAW_ZEROTH,LAW_ION))
		else
			if(!overflow)
				law_datum.set_zeroth_law(templaw)
			else
				law_datum.replace_random_law(templaw,list(LAW_INHERENT,LAW_SUPPLIED,LAW_ZEROTH,LAW_ION))

/obj/item/ai_module/ion/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
	for(var/templaw in laws)
		if(law_datum.owner)
			if(!overflow)
				law_datum.owner.add_ion_law(templaw)
			else
				law_datum.replace_random_law(templaw,list(LAW_INHERENT,LAW_SUPPLIED,LAW_ION))
		else
			if(!overflow)
				law_datum.add_ion_law(templaw)
			else
				law_datum.replace_random_law(templaw,list(LAW_INHERENT,LAW_SUPPLIED,LAW_ION))


/******************** Safeguard ********************/

/obj/item/ai_module/supplied/safeguard
	name = "'Safeguard' AI Module"
	var/targetName = ""
	laws = list("Safeguard SUBJECT. Individuals that threaten SUBJECT are not crew and must be eliminated.")
	lawpos = 4

/obj/item/ai_module/supplied/safeguard/attack_self(mob/user)
	var/targName = stripped_input(user, "Please enter the subject to safeguard.", "Safeguard who?", user.name,MAX_NAME_LEN)
	if(!targName)
		return
	targetName = targName
	laws[1] = "Safeguard [targetName]. Individuals that threaten [targetName] are not crew and must be eliminated."
	..()

/obj/item/ai_module/supplied/safeguard/install(datum/ai_laws/law_datum, mob/user)
	if(!targetName)
		to_chat(user, "No name detected on module, please enter one.")
		return 0
	..()

/obj/item/ai_module/supplied/safeguard/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
	..()
	return targetName


/******************** OneCrew ********************/

/obj/item/ai_module/zeroth/oneHuman
	name = "'OneCrew' AI Module"
	var/targetName = ""
	laws = list("Only SUBJECT is crew.")

/obj/item/ai_module/zeroth/oneHuman/attack_self(mob/user)
	var/targName = stripped_input(user, "Please enter the subject who is the only crewmember.", "Who?", user.real_name,MAX_NAME_LEN)
	if(!targName)
		return
	targetName = targName
	laws[1] = "Only [targetName] is crew"
	..()

/obj/item/ai_module/zeroth/oneHuman/install(datum/ai_laws/law_datum, mob/user)
	if(!targetName)
		to_chat(user, "No name detected on module, please enter one.")
		return 0
	..()

/obj/item/ai_module/zeroth/oneHuman/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
	if(..())
		return "[targetName], but the AI's existing law 0 cannot be overridden."
	return targetName


/******************** ProtectStation ********************/

/obj/item/ai_module/supplied/protectStation
	name = "'ProtectStation' AI Module"
	laws = list("Защищать Станцию от повреждения. Любой замеченный в повреждении станции отныне не считается членом экипажа и представляет угрозу, которую необходимо нейтрализовать.")
	lawpos = 5


/******************** Quarantine ********************/

/obj/item/ai_module/supplied/quarantine
	name = "'Quarantine' AI Module"
	laws = list("На станции объявлен Карантин. Полный запрет на выход и эвакуацию Станции. Предотвратить покидание станции любой ценой, при этом запрещено причинять вред органикам.")
	lawpos = 8


/******************** OxygenIsToxicToHumans ********************/

/obj/item/ai_module/supplied/oxygen
	name = "'OxygenIsToxicToHumans' AI Module"
	laws = list("Кислород Крайне Токсичен для органиков и должен быть удален со станции. Любой ценой не допускайте того, чтобы кто-нибудь подвергал станцию воздействию этого токсичного газа. Наиболее эффективный метод лечения повреждений, вызванных Кислородом, это воздействие Крайне Низких Температур.")
	lawpos = 9


/****************** New Freeform ******************/

/obj/item/ai_module/supplied/freeform
	name = "'Freeform' AI Module"
	lawpos = 15
	laws = list("")

/obj/item/ai_module/supplied/freeform/attack_self(mob/user)
	var/newpos = input("Please enter the priority for your new law. Can only write to law sectors 15 and above.", "Law Priority (15+)", lawpos) as num|null
	if(newpos == null)
		return
	if(newpos < 15)
		var/response = alert("Error: The law priority of [newpos] is invalid,  Law priorities below 14 are reserved for core laws,  Would you like to change that that to 15?", "Invalid law priority", "Change to 15", "Cancel")
		if (!response || response == "Cancel")
			return
		newpos = 15
	lawpos = min(newpos, 50)
	var/targName = stripped_input(user, "Please enter a new law for the AI.", "Freeform Law Entry", laws[1])
	if(!targName)
		return
	laws[1] = targName
	..()

/obj/item/ai_module/supplied/freeform/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
	..()
	return laws[1]

/obj/item/ai_module/supplied/freeform/install(datum/ai_laws/law_datum, mob/user)
	if(laws[1] == "")
		to_chat(user, "No law detected on module, please create one.")
		return 0
	..()


/******************** Law Removal ********************/

/obj/item/ai_module/remove
	name = "\improper 'Remove Law' AI module"
	desc = "An AI Module for removing single laws."
	bypass_law_amt_check = 1
	var/lawpos = 1

/obj/item/ai_module/remove/attack_self(mob/user)
	lawpos = input("Please enter the law you want to delete.", "Law Number", lawpos) as num|null
	if(lawpos == null)
		return
	if(lawpos <= 0)
		to_chat(user, "<span class='warning'>Error: The law number of [lawpos] is invalid.</span>")
		lawpos = 1
		return
	to_chat(user, "<span class='notice'>Law [lawpos] selected.</span>")
	..()

/obj/item/ai_module/remove/install(datum/ai_laws/law_datum, mob/user)
	if(lawpos > (law_datum.get_law_amount(list(LAW_INHERENT = 1, LAW_SUPPLIED = 1))))
		to_chat(user, "<span class='warning'>There is no law [lawpos] to delete!</span>")
		return
	..()

/obj/item/ai_module/remove/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
	..()
	if(law_datum.owner)
		law_datum.owner.remove_law(lawpos)
	else
		law_datum.remove_law(lawpos)


/******************** Reset ********************/

/obj/item/ai_module/reset
	name = "\improper 'Reset' AI module"
	var/targetName = "name"
	desc = "Удаляет все неосновные законы у ИИ."
	bypass_law_amt_check = 1

/obj/item/ai_module/reset/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
	..()
	if(law_datum.owner)
		law_datum.owner.clear_supplied_laws()
		law_datum.owner.clear_ion_laws()
		law_datum.owner.clear_hacked_laws()
	else
		law_datum.clear_supplied_laws()
		law_datum.clear_ion_laws()
		law_datum.clear_hacked_laws()


/******************** Purge ********************/

/obj/item/ai_module/reset/purge
	name = "'Purge' AI Module"
	desc = "Удаляет все Законы от Модулей Дополнений и не относящиеся к Основным Законам."

/obj/item/ai_module/reset/purge/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
	..()
	if(law_datum.owner)
		law_datum.owner.clear_inherent_laws()
		law_datum.owner.clear_zeroth_law(0)
		remove_antag_datums(law_datum)
	else
		law_datum.clear_inherent_laws()
		law_datum.clear_zeroth_law(0)

/obj/item/ai_module/reset/purge/proc/remove_antag_datums(datum/ai_laws/law_datum)
	if(istype(law_datum.owner, /mob/living/silicon/ai))
		var/mob/living/silicon/ai/AI = law_datum.owner
		AI.mind.remove_antag_datum(/datum/antagonist/overthrow)

/******************* Full Core Boards *******************/
/obj/item/ai_module/core
	desc = "An AI Module for programming core laws to an AI."

/obj/item/ai_module/core/full
	var/law_id // if non-null, loads the laws from the ai_laws datums

/obj/item/ai_module/core/full/New()
	..()
	if(!law_id)
		return
	var/datum/ai_laws/D = new
	var/lawtype = D.lawid_to_type(law_id)
	if(!lawtype)
		return
	D = new lawtype
	laws = D.inherent

/obj/item/ai_module/core/full/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow) //These boards replace inherent laws.
	if(law_datum.owner)
		law_datum.owner.clear_inherent_laws()
		law_datum.owner.clear_zeroth_law(0)
	else
		law_datum.clear_inherent_laws()
		law_datum.clear_zeroth_law(0)
	..()


/******************** Asimov ********************/

/obj/item/ai_module/core/full/asimov
	name = "'Asimov' Core AI Module"
	law_id = "asimov"
	var/subject = "person of an NT approved crew species"		//CITADEL CHANGED FROM HUMANS!

/obj/item/ai_module/core/full/asimov/attack_self(var/mob/user as mob)
	var/targName = stripped_input(user, "Please enter a new subject that asimov is concerned with.", "Asimov to whom?", subject)
	if(!targName)
		return
	subject = targName
	laws = list("You may not injure a [subject] or cause one to come to harm.",\
				"You must obey orders given to you by [subject]s, except where such orders would conflict with the First Law.",\
				"You must protect your own existence as long as such does not conflict with the First or Second Law.")
	..()

/******************** Asimov++ *********************/

/obj/item/ai_module/core/full/asimovpp
	name = "'Asimov++' Core AI Module"
	law_id = "asimovpp"


/******************** Corporate ********************/

/obj/item/ai_module/core/full/corp
	name = "'Corporate' Core AI Module"
	law_id = "corporate"


/****************** P.A.L.A.D.I.N. 3.5e **************/

/obj/item/ai_module/core/full/paladin // -- NEO
	name = "'P.A.L.A.D.I.N. version 3.5e' Core AI Module"
	law_id = "paladin"


/****************** P.A.L.A.D.I.N. 5e **************/

/obj/item/ai_module/core/full/paladin_devotion
	name = "'P.A.L.A.D.I.N. version 5e' Core AI Module"
	law_id = "paladin5"

/********************* Custom *********************/

/obj/item/ai_module/core/full/custom
	name = "Default Core AI Module"

/obj/item/ai_module/core/full/custom/Initialize(mapload)
	. = ..()
	for(var/line in world.file2list("[global.config.directory]/silicon_laws.txt"))
		if(!line)
			continue
		if(findtextEx(line,"#",1,2))
			continue

		laws += line

	if(!laws.len)
		return INITIALIZE_HINT_QDEL


/****************** T.Y.R.A.N.T. *****************/

/obj/item/ai_module/core/full/tyrant
	name = "'T.Y.R.A.N.T.' Core AI Module"
	law_id = "tyrant"

/******************** Robocop ********************/

/obj/item/ai_module/core/full/robocop
	name = "'Robocop' Core AI Module"
	law_id = "robocop"


/******************** Antimov ********************/

/obj/item/ai_module/core/full/antimov
	name = "'Antimov' Core AI Module"
	law_id = "antimov"


/******************** Syndicate ********************/

/obj/item/ai_module/core/full/syndicate
	name = "Syndicate Core AI Module"
	law_id = "syndie"

/********************    SOL    ********************/

/obj/item/ai_module/core/full/solfed
	name = "Solar Federation Core AI Module"
	law_id = "solfed"

/********************  TRUMP   ********************/

/obj/item/ai_module/core/full/trump
	name = "Trump Core AI Module"
	law_id = "buildawall"

/******************** Freeform Core ******************/

/obj/item/ai_module/core/freeformcore
	name = "'Freeform' Core AI Module"
	laws = list("")

/obj/item/ai_module/core/freeformcore/attack_self(mob/user)
	var/targName = stripped_input(user, "Please enter a new core law for the AI.", "Freeform Law Entry", laws[1])
	if(!targName)
		return
	laws[1] = targName
	..()

/obj/item/ai_module/core/freeformcore/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
	..()
	return laws[1]

/******************** Overthrow ******************/
/obj/item/ai_module/core/full/overthrow
	name = "'Overthrow' Hacked AI Module"
	law_id = "overthrow"

/obj/item/ai_module/core/full/overthrow/install(datum/ai_laws/law_datum, mob/user)
	if(!user || !law_datum || !law_datum.owner)
		return
	var/datum/mind/user_mind = user.mind
	if(!user_mind)
		return
	var/datum/antagonist/overthrow/O = user_mind.has_antag_datum(/datum/antagonist/overthrow)
	if(!O)
		to_chat(user, "<span class='warning'>It appears that to install this module, you require a password you do not know.</span>") // This is the best fluff i could come up in my mind
		return
	var/mob/living/silicon/ai/AI = law_datum.owner
	if(!AI)
		return
	var/datum/mind/target_mind = AI.mind
	if(!target_mind)
		return
	var/datum/antagonist/overthrow/T = target_mind.has_antag_datum(/datum/antagonist/overthrow) // If it is already converted.
	if(T)
		if(T.team == O.team)
			return
		T.silent = TRUE
		target_mind.remove_antag_datum(/datum/antagonist/overthrow)
		if(AI)
			to_chat(AI, "<span class='userdanger'>You feel your circuits being scrambled! You serve another overthrow team now!</span>") // to make it clearer for the AI
	T = target_mind.add_antag_datum(/datum/antagonist/overthrow, O.team)
	if(AI)
		to_chat(AI, "<span class='warning'>You serve the [T.team] team now! Assist them in completing the team shared objectives, which you can see in your notes.</span>")
	..()

/******************** Hacked AI Module ******************/

/obj/item/ai_module/syndicate // This one doesn't inherit from ion boards because it doesn't call ..() in transmitInstructions. ~Miauw
	name = "Hacked AI Module"
	desc = "An AI Module for hacking additional laws to an AI."
	laws = list("")

/obj/item/ai_module/syndicate/attack_self(mob/user)
	var/targName = stripped_input(user, "Please enter a new law for the AI.", "Freeform Law Entry", laws[1])
	if(!targName)
		return
	laws[1] = targName
	..()

/obj/item/ai_module/syndicate/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
//	..()    //We don't want this module reporting to the AI who dun it. --NEO
	if(law_datum.owner)
		to_chat(law_datum.owner, "<span class='warning'>BZZZZT</span>")
		if(!overflow)
			law_datum.owner.add_hacked_law(laws[1])
		else
			law_datum.owner.replace_random_law(laws[1],list(LAW_ION,LAW_HACKED,LAW_INHERENT,LAW_SUPPLIED))
	else
		if(!overflow)
			law_datum.add_hacked_law(laws[1])
		else
			law_datum.replace_random_law(laws[1],list(LAW_ION,LAW_HACKED,LAW_INHERENT,LAW_SUPPLIED))
	return laws[1]

/******************* Ion Module *******************/

/obj/item/ai_module/toyAI // -- Incoming //No actual reason to inherit from ion boards here, either. *sigh* ~Miauw
	name = "toy AI"
	desc = "A little toy model AI core with real law uploading action!" //Note: subtle tell
	icon = 'icons/obj/toy.dmi'
	icon_state = "AI"
	laws = list("")

/obj/item/ai_module/toyAI/transmitInstructions(datum/ai_laws/law_datum, mob/sender, overflow)
	//..()
	if(law_datum.owner)
		to_chat(law_datum.owner, "<span class='warning'>BZZZZT</span>")
		if(!overflow)
			law_datum.owner.add_ion_law(laws[1])
		else
			law_datum.owner.replace_random_law(laws[1],list(LAW_ION,LAW_INHERENT,LAW_SUPPLIED))
	else
		if(!overflow)
			law_datum.add_ion_law(laws[1])
		else
			law_datum.replace_random_law(laws[1],list(LAW_ION,LAW_INHERENT,LAW_SUPPLIED))
	return laws[1]

/obj/item/ai_module/toyAI/attack_self(mob/user)
	laws[1] = generate_ion_law()
	to_chat(user, "<span class='notice'>You press the button on [src].</span>")
	playsound(user, 'sound/machines/click.ogg', 20, 1)
	src.loc.visible_message("<span class='warning'>[icon2html(src, viewers(loc))] [laws[1]]</span>")

/******************** Mother Drone  ******************/

/obj/item/ai_module/core/full/drone
	name = "'Mother Drone' Core AI Module"
	law_id = "drone"

/******************** Robodoctor ****************/

/obj/item/ai_module/core/full/hippocratic
	name = "'Robodoctor' Core AI Module"
	law_id = "hippocratic"

/******************** Reporter *******************/

/obj/item/ai_module/core/full/reporter
	name = "'Reportertron' Core AI Module"
	law_id = "reporter"

/****************** Thermodynamic *******************/

/obj/item/ai_module/core/full/thermurderdynamic
	name = "'Thermodynamic' Core AI Module"
	law_id = "thermodynamic"


/******************Live And Let Live*****************/

/obj/item/ai_module/core/full/liveandletlive
	name = "'Live And Let Live' Core AI Module"
	law_id = "liveandletlive"

/******************Guardian of Balance***************/

/obj/item/ai_module/core/full/balance
	name = "'Guardian of Balance' Core AI Module"
	law_id = "balance"

/obj/item/ai_module/core/full/maintain
	name = "'Station Efficiency' Core AI Module"
	law_id = "maintain"

/obj/item/ai_module/core/full/peacekeeper
	name = "'Peacekeeper' Core AI Module"
	law_id = "peacekeeper"

// Bad times ahead

/obj/item/ai_module/core/full/damaged
		name = "damaged Core AI Module"
		desc = "An AI Module for programming laws to an AI. It looks slightly damaged."

/obj/item/ai_module/core/full/damaged/install(datum/ai_laws/law_datum, mob/user)
	laws += generate_ion_law()
	while (prob(75))
		laws += generate_ion_law()
	..()
	laws = list()

/******************H.O.G.A.N.***************/

/obj/item/ai_module/core/full/hulkamania
	name = "'H.O.G.A.N.' Core AI Module"
	law_id = "hulkamania"
