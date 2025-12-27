extends ResourceMgr

func _init():
	super("res://data/SpellDomain", ".json", true)
	load_all_data()
