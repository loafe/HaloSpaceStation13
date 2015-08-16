//Zlevel where overmap objects should be
#define OVERMAP_ZLEVEL 1
//How far from the edge of overmap zlevel could randomly placed objects spawn
#define OVERMAP_EDGE 7

//see code\modules\overmap

var/global/datum/controller/process/overmap/overmap_controller
var/global/list/map_sectors = list()
var/global/list/cached_spacepre = list()

/datum/controller/process/overmap
	name = "overmap controller"
	var/list/cached_space = list()
	var/list/moving_levels = list()
	var/list/map_sectors_reference
	var/list/cached_space_prec

/datum/controller/process/overmap/proc/toggle_move_stars(zlevel, direction)
	if(!zlevel)
		return

	var/gen_dir = null
	if(direction & (NORTH|SOUTH))
		gen_dir += "ns"
	else if(direction & (EAST|WEST))
		gen_dir += "ew"
	if(!direction)
		gen_dir = null

	if (moving_levels["zlevel"] != gen_dir)
		moving_levels["zlevel"] = gen_dir
		for(var/x = 1 to world.maxx)
			for(var/y = 1 to world.maxy)
				var/turf/space/T = locate(x,y,zlevel)
				if (istype(T))
					if(!gen_dir)
						T.icon_state = "[((T.x + T.y) ^ ~(T.x * T.y) + T.z) % 25]"
					else
						T.icon_state = "speedspace_[gen_dir]_[rand(1,15)]"
						for(var/atom/movable/AM in T)
							if (!AM.anchored)
								AM.throw_at(get_step(T,reverse_direction(direction)), 5, 1)

/datum/controller/process/overmap/proc/overmap_spacetravel(var/turf/space/T, var/atom/movable/A)
	var/obj/effect/map/M = map_sectors["[T.z]"]

	if (!M)
		return
	var/mapx = M.x
	var/mapy = M.y
	var/nx = 1
	var/ny = 1
	var/nz = M.map_z

	if(T.x <= TRANSITIONEDGE)
		nx = world.maxx - TRANSITIONEDGE - 2
		ny = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)
		mapx = max(1, mapx-1)

	else if (A.x >= (world.maxx - TRANSITIONEDGE - 1))
		nx = TRANSITIONEDGE + 2
		ny = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)
		mapx = min(world.maxx, mapx+1)

	else if (T.y <= TRANSITIONEDGE)
		ny = world.maxy - TRANSITIONEDGE -2
		nx = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)
		mapy = max(1, mapy-1)

	else if (A.y >= (world.maxy - TRANSITIONEDGE - 1))
		ny = TRANSITIONEDGE + 2
		nx = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)
		mapy = min(world.maxy, mapy+1)

	testing("[A] moving from [M] ([M.x], [M.y]) to ([mapx],[mapy]).")

	var/turf/map = locate(mapx,mapy,OVERMAP_ZLEVEL)
	var/obj/effect/map/TM = locate() in map
	if(TM)
		nz = TM.map_z
		testing("Destination: [TM]")
	else
		if(cached_space.len)
			var/obj/effect/map/sector/temporary/cache = cached_space[cached_space.len]
			cached_space -= cache
			nz = cache.map_z
			cache.x = mapx
			cache.y = mapy
			testing("Destination: *cached* [TM]")
		else
			world.maxz++
			nz = world.maxz
			TM = new /obj/effect/map/sector/temporary(mapx, mapy, nz)
			testing("Destination: *new* [TM]")

	var/turf/dest = locate(nx,ny,nz)
	if(dest)
		A.loc = dest

	if(istype(M, /obj/effect/map/sector/temporary))
		var/obj/effect/map/sector/temporary/source = M
		if (source.can_die())
			testing("Catching [M] for future use")
			source.loc = null
			cached_space += source

/datum/controller/process/overmap/proc/load_prepared_sector(var/name = input("Sector name: "), var/storname = input("Storage Name: "), var/xpos = input("Enter X-Coordinates (optional): ") as num, var/ypos = input("Enter Y-Coordinates (optional): ") as num)
	if(cached_spacepre["[name]"])
		var/obj/effect/mapinfo/precreated/data = cached_spacepre["[name]"]
		data.mapx = xpos ? xpos : data.mapx
		data.mapy = ypos ? ypos : data.mapy
		map_sectors["[storname]"] = new data.obj_type(data)
		for(var/obj/machinery/computer/helm/H in machines)
			H.reinit()
		return TRUE
	else
		return FALSE
	return FALSE

/datum/controller/process/overmap/proc/unload_prepared_sector(var/name = input("Sector Name: "), var/storname = input("Storage Name: "))
	if(map_sectors["[storname]"] && cached_spacepre["[name]"])
		var/obj/effect/map/data = map_sectors["[storname]"]
		qdel(data)
		map_sectors -= storname
		for(var/obj/machinery/computer/helm/H in machines)
			H.reinit()
		return TRUE
	else
		return FALSE
	return FALSE

/datum/controller/process/overmap/doWork()
	cached_space_prec = cached_spacepre
