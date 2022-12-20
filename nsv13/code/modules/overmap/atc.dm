#define MODE_DESIGNATE "designate"
#define MODE_SELECT "select"
#define MODE_DATALINK "datalink"

/obj/machinery/computer/ship/dradis/minor/awacs
	name = "\improper Seegson model A GCI console"
	desc = "A console that provides DRADIS, datalink, and advanced hailing capabilities to an operator to assist in ground-controlled interception of enemy aircraft."
	req_access = list("79") // Hangar access
	hail_range = 200
	var/mode = MODE_DESIGNATE

// Override of base DRADIS so we can add AWACS stuff
/obj/machinery/computer/ship/dradis/ui_data(mob/user)
	// DRADIS stuff here (stripped down since we don't need some of it)
	var/list/data = list()
	var/list/blips = list() //2-d array declaration
	var/list/friendly_ships = list() // BLUFOR ships for use in AWACS control
	var/ship_count = 0
	for(var/obj/effect/overmap_anomaly/OA in linked?.current_system?.system_contents)
		if(OA && istype(OA) && OA.z == linked?.z)
			blips.Add(list(list("x" = OA.x, "y" = OA.y, "colour" = "#eb9534", "name" = "[(OA.scanned) ? OA.name : "anomaly"]", opacity=showAnomalies*0.01, alignment = "uncharted")))
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
