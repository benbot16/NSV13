#define MODE_DESIGNATE "designate"
#define MODE_SELECT "select"
#define MODE_DATALINK "datalink"

/obj/machinery/computer/ship/dradis/minor/awacs
	name = "\improper Seegson model A GCI console"
	desc = "A console that provides DRADIS, datalink, and advanced hailing capabilities to an operator to assist in ground-controlled interception of enemy aircraft."
	req_access = list("79") // Hangar access
	var/mode = MODE_DESIGNATE
	var/friendly_hail_range = 100
	var/transmit_cooldown = 5 SECONDS
	var/obj/structure/overmap/selected_ship


// This proc handles what happens when someone clicks on a target. The target is passed via the paramater,
// and we do the rest based on the current mode and other vars.
/obj/machinery/computer/ship/dradis/minor/awacs/proc/on_hail(obj/structure/overmap/target)
	return

// Override of base DRADIS so we can add AWACS stuff
/obj/machinery/computer/ship/dradis/minor/awacs/ui_data(mob/user)
	// DRADIS stuff here (stripped down since we don't need some of it)
	var/list/data = list()
	var/list/blips = list() //2-d array declaration
	var/list/friendly_ships = list() // BLUFOR ships for use in AWACS control
	var/ship_count = 0
	for(var/obj/structure/overmap/OM in GLOB.overmap_objects) //Iterate through overmaps in the world! - Needs to go through global overmaps since it may be on a ship's z level or in hyperspace.
		var/sensor_visible = (OM != linked && OM.faction != linked.faction) ? ((overmap_dist(linked, OM) > max(sensor_range * 2, OM.sensor_profile)) ? 0 : OM.is_sensor_visible(linked)) : SENSOR_VISIBILITY_FULL
		if(OM.z == linked.z && (sensor_visible >= SENSOR_VISIBILITY_FAINT || linked.target_painted[OM]))
			var/inRange = (overmap_dist(linked, OM) <= max(sensor_range,OM.sensor_profile)) || OM.faction == linked.faction
			var/thecolour = "#FFFFFF"
			var/filterType = showEnemies
			if(OM == linked)
				thecolour = "#00FFFF"
				filterType = 100 //No hiding yourself kid.
			else if(OM.faction == linked.faction)
				thecolour = "#32CD32"
				filterType = showFriendlies
				friendly_ships += OM
			else
				thecolour = "#FF0000"
				filterType = showEnemies
				ship_count ++
			var/thename = (inRange) ? OM.name : "UNKNOWN"
			var/thefaction = ((OM.faction == "nanotrasen" || OM.faction == "syndicate") && inRange) ? OM.faction : "unaligned"
			thecolour = (inRange) ? thecolour : "#a66300"
			filterType = (inRange) ? filterType : 100
			if(sensor_visible <= SENSOR_VISIBILITY_FAINT)
				filterType = sensor_visible
			else
				filterType *= 0.01
			filterType = CLAMP(filterType, 0, 1)
			blips[++blips.len] = list("x" = OM.x, "y" = OM.y, "colour" = thecolour, "name"=thename, opacity=filterType ,alignment = thefaction, "id"="\ref[OM]") //So now make a 2-d array that TGUI can iterate through. This is just a list within a list.
	if(ship_count > last_ship_count) //Play a tone if ship count changes
		var/delta = ship_count - last_ship_count
		last_ship_count = ship_count
		visible_message("<span class='warning'>[icon2html(src, viewers(src))] [delta <= 1 ? "DRADIS contact" : "Multiple DRADIS contacts"]</span>")
		playsound(src, 'nsv13/sound/effects/ship/contact.ogg', 100, FALSE)
	data["zoom_factor"] = zoom_factor
	data["zoom_factor_min"] = zoom_factor_min
	data["zoom_factor_max"] = zoom_factor_max
	data["focus_x"] = linked.x
	data["focus_y"] = linked.y
	data["ships"] = blips //Create a category in data called "ships" with our 2-d arrays.
	data["showFriendlies"] = showFriendlies
	data["showEnemies"] = showEnemies
	data["showAsteroids"] = showAsteroids //add planets to this eventually.
	data["showAnomalies"] = showAnomalies
	data["sensor_range"] = sensor_range
	data["width_mod"] = sensor_range / SENSOR_RANGE_DEFAULT

	// Friendly ship stuff here
	data["friendly_ships"] = friendly_ships
	data["mode"] = mode

	return data

/obj/machinery/computer/ship/dradis/minor/awacs/ui_act(action, params)
	. = ..()
	if(isobserver(usr))
		return
	if(.)
		return
	if(!has_overmap())
		return
	var/alphaSlide = text2num(params["alpha"])
	alphaSlide = CLAMP(alphaSlide, 0, 100) //Just in case we have a malformed input.
	switch(action)
		if("showFriendlies")
			showFriendlies = alphaSlide
		if("showEnemies")
			showEnemies = alphaSlide
		if("zoomout")
			zoom_factor = clamp(zoom_factor - zoom_factor_min, zoom_factor_min, zoom_factor_max)
		if("zoomin")
			zoom_factor = clamp(zoom_factor + zoom_factor_min, zoom_factor_min, zoom_factor_max)
		if("setZoom")
			if(!params["zoom"])
				return
			zoom_factor = clamp(params["zoom"] / 100, zoom_factor_min, zoom_factor_max)
		if("hail")
			var/obj/structure/overmap/target = locate(params["target"])
			if(!target) //Anomalies don't count.
				return
			if(world.time < next_hail)
				return
			if(target == linked)
				return
			next_hail = world.time + transmit_cooldown
			if(overmap_dist(target, linked) <= hail_range || (target.faction == linked.faction && overmap_dist(target,linked) <= friendly_hail_range))
				on_hail(target)
		if("setShip")
			var/obj/structure/overmap/selected = locate(params["selected"])
			selected_ship = selected
			if(selected.pilot)
				to_chat(selected.pilot, "<span class='notice'>GCI uplink established. Source: [linked]</span>")
