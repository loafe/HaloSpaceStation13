/obj/effect/overmap/ship/unsclightbrigade
	name = "UNSC Light Brigade"
	desc = "Halberd Class Destroyer."

	icon = 'Heavycorvette.dmi'
	icon_state = "ship"
	fore_dir = WEST
	vessel_mass = 4
	faction = "UNSC"
	flagship = 1

	map_bounds = list(3,57,116,101)

	parent_area_type = /area/destroyer/unsclightbrigade

/obj/machinery/button/toggle/alarm_button/destroyer
	area_base = /area/destroyer/unsclightbrigade