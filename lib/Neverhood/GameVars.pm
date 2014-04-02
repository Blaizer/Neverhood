class Neverhood::GameVars {

		# 2, 1, 4, 5, 3, 11, 8, 6, 7, 9, 10, 17, 16, 18, 19, 20, 15, 14, 13, 12
		# $nursery_1_window_open -- until jump down in nursery_2
		# $flytrap_place         -- only while in mail room, also remember if it has grabbed ring
		# %mail_done             -- from when the flytrap grabs the ring until willie dies
			# flytrap     -- when the flytrap grabs the ring
			# music_box   -- when the musicbox c starts
			# boom_sticks -- when the boom sticks are solved
			# weasel      -- when the weasel dying c starts
			# h           -- when the H is solved
			# beaker      -- when the beaker is picked up
			# foghorn_1   -- when the foghorn button thru the spikes is pressed
			# drink       -- when you drink from the foutain
			# notes       -- when the pipes are solved and the button is pressed
			# foghorn_2   -- when the foghorn button next to frenchie is pressed
			# foghorn_3   -- when the foghorn button in circles is pressed
			# locks       -- when the 3 locks are unlocked
			# drain_lake  -- when the cannon is shot to drain the lake
			# into_lake   -- when you go down the stairs
			# radio_on    -- when you go into the radio room with it on
			# radio_song  -- when you enter the lab
			# fast_door   -- when you get past the fast door
			# bear_lure   -- when you swing the bear around
			# cannon_1    -- when cannon code 1 is entered
			# bil_boom    -- when bil is shot
			# bil_sense   -- when willie dies

		# $spam_number -- as soon as spam is seen, undef when back to first and when willie dies
		# %disk        -- as soon as a disk is picked up
			# shack
			# h_house_1
			# h_house_2
			# thru_spikes
			# hall_end
			# note_house_1
			# note_house_2
			# note_house_3
			# radio_place
			# lab_middle_floor
			# lab_top_floor
			# whale_house_1
			# whale_house_2
			# trap_room
			# fun_house_left_1
			# fun_house_left_2
			# fun_house_right
			# willies_house
			# castle_key_room
			# castle_top_floor

		# @dummy_places -- init with (0, 1, 0, 2, 1, 1) when enter shack, undef when solved
			#   1     2636
			# 2 3 4   5124
			#  5 6    1345
		# $match            -- 1 when match is picked up, 2 when dummy is lit
		# $water_on         -- when the water in t2 is turned on, undef when turned off
		# @foghorn          -- when each foghorn button is pressed, undef when pressed again
		# @h                -- when the h house is entered, undef when solved h
		# $h_blank_top      -- when solved h, 1 for blank piece in h at top, 0 for bottom
		# $spikes_open      -- when spikes are open, undef when closed
		# $said_knock_knock -- when the dude in the box says knock knock, undef when foghorn pressed or disk taken
		# @cannon_code_1    -- when the first cannon code is changed, undef when back to original, empty list when solved
		# @cannon_code_2    -- ditto
		# @bridge_puzzle    -- when a bridge puzzle piece is moved, undef when none are on stack and when gone into lake
		# $bridge_down      -- when the bridge is moved down, undef when down the bridge and when moved up, redef when back up bridge
		# $raido_song       -- when either radio is seen
		# @safety_beakers   -- when either the safety beakers are seen or the safety lab is used
		# @beakers          -- when either the lake wall beakers are seen or the lab is used
		# @crystals         -- when the shrinking machine is used, roygbp, empty list when solved



		# and then here we have a buncha methods that set and get doing stuff
}
