--$Name: The Archive$
--$Version: 0.9$
--$Author:Peter Kosyh$

require "fmt"
require "link"
if instead.tiny then
	function iface:tab()
		return '    '
	end
end
function mus_play(f)
end
function mus_stop(f)
end
function snd_play(f)
end
function snd_stop()
end
function snd_start()
end

if not instead.tiny then
require "autotheme"
require "timer"
require "sprite"
require "theme"
require "snd"
timer:set(350)
local w, h = sprite.fnt(theme.get 'inv.fnt.name',
	tonumber(theme.get 'inv.fnt.size')):size("|")
local blank = sprite.new(w, h)
local cur_on = false
require "fading"
function game:timer()
	if cur_on or mp.autohelp then
		mp.cursor = fmt.b '|'
	else
		mp.cursor = fmt.top(fmt.img(blank));
	end
	cur_on = not cur_on
	return true, false
end
function mus_play(f)
	snd.music('mus/'..f..'.ogg')
end
function mus_stop(f)
	snd.stop_music()
end

function snd_stop(f)
	if not f then
		instead.stop_sound() -- halt all
	else
		_'sound':stop(f)
	end
end

function snd_play(f, loop)
	if loop then
		_'sound':play(f, 0)
	else
		snd.play ('snd/'..f..'.ogg', -1, 1)
	end
end

obj {
	nam = 'sound';
	sounds = {
	};
	play = function(s, name, loop)
		if s.sounds[name] then
			return
		end
		local chan = {}
		for k, v in pairs(s.sounds) do
			table.insert(chan, v[2])
		end
		table.sort(chan)
		local free
		for k, v in ipairs(chan) do
			if k ~= v then
				free = k
				break
			end
		end
		if not free then
			free = #chan + 1
		end
--		print("play ", name, free)
		s.sounds[name] = { name, free, loop }
		snd.play('snd/'..name..'.ogg', free, loop)
	end;
	start = function(s)
		for k, v in pairs(s.sounds) do
			snd.play('snd/'..v[1]..'.ogg', v[2], v[3])
		end
	end;
	stop = function(s, name)
		if not s.sounds[name] then
			return
		end
--		print("stop ", name, s.sounds[name][2])
		snd.stop(s.sounds[name][2])
		s.sounds[name] = nil
	end;
}
function snd_start()
	instead.stop_sound() -- halt all
	_'sound':start()
	snd.music_fading(1000)
end
end

fmt.dash = true
fmt.quotes = true

require 'parser/mp-en'

function set_pic(f)
	game.pic = 'gfx/'..f..'.jpg'
end

function get_pic(f)
	local r = game.pic:gsub("^gfx/", ""):gsub("%.jpg$", "")
	return r
end

game.dsc = [[{$fmt b|THE ARCHIVE}^^An interactive novel for
execution on computers.^^For help, type "help" and press "enter".]];

function game:before_Any(ev, w)
	if ev == "Ask" or ev == "Say" or ev == "Tell" or ev == "AskFor" or ev == "AskTo" then
		p [[Just try to talk.]];
		return
	end
	return false
end

function mp:pre_input(str)
	local a = std.split(str)
	if #a <= 1 or #a > 3 then
		return str
	end
	if a[1] == 'to' or a[1] == 'in' or a[1] == 'into' or
		a[1] == "on" then
		return "walk "..str
	end
	return str
end

Path = Class {
	['before_Walk,Enter'] = function(s)
		if mp:check_inside(std.ref(s.walk_to)) then
			return
		end
		walk(s.walk_to)
	end;
	before_Default = function(s)
		if s.desc then
			p(s.desc)
			return
		end
		p ([[You can go to ]], std.ref(s.walk_to):the_noun(), '.');
	end;
	default_Event = 'Walk';
}:attr'scenery,enterable';

Careful = Class {
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" or
	ev == 'Listen' or ev == 'Smell' then
			return false
		end
		p ("Better to be careful with ", s:the_noun(), ".")
	end;
}:attr 'scenery'

Distance = Class {
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" then
			return false
		end
		p ("But ", s:the_noun(), " ", s:hint'plural' and 'are' or 'is', " far away.");
	end;
}:attr 'scenery'

Furniture = Class {
	['before_Push,Pull,Transfer,Take'] = [[Better to stand where
	{#if_hint/#first,plural,they are,it is}.]];
}:attr 'static'

Prop = Class {
	before_Default = function(s, ev)
		p ("You don't care about ", s:the_noun(), ".")
	end;
}:attr 'scenery'

Distance {
	"stars/plural";
	nam = 'stars';
	description = [[The stars are watching you.]];
}

obj {
	"space,void";
	nam = 'space';
	description = [[Humanity's reaching hyperspace did not bring the stars much closer.
	After all, before you can build a gate at a new star system, you need to get to it.
	The flight to an unexplored star system still takes years or even decades.]];
	obj = {
		'stars';
	}
}:attr 'scenery';

global 'radio_ack' (false)
global 'rain' (true)
global 'know_bomb' (false)

Careful {
	nam = 'windows';
	-"windows|portholes";
	description = function(s)
		if here().planet then
			if rain then
				p [[All you see from the cabin is a wheat-colored field and a rainy sky.]]
			elseif bomb_cancel then
				p [[How strange, you do not see the planet landscape!]];
			else
				p [[All you see from the cabin is a wheat-colored field and a cyan sky]]
			end
		elseif here() ^ 'burnout' then
			p [[Through the thick windows you see the glow of hyperspace.]];
			if not _'engine'.flame then
				_'hyper2':description()
			end
		elseif here() ^ 'ship1' then
			p [[Through thick windows you see a purple planet. This is Dimidius.]];
		end
	end;
	found_in = { 'ship1', 'burnout' };
};

obj {
	"photo|photography";
	nam = 'photo';
	init_dsc = [[The photo is attached to the corner of one of the windows.]];
	description = [[This is a photo of your daughter Lisa when she was only 9 years old.
	She is adult now.]];
	found_in = { 'ship1', 'burnout' };
};

Careful {
	nam = 'panel';
	"dashboard,panel|controls,devices/plural|equipment";
	till = 27;
	stop = false;
	daemon = function(s)
		s.till = s.till - 1
		if s.till == 0 then
			DaemonStop(s)
		end
	end;
	description = function(s)
		if here() ^ 'ship1' or bomb_cancel then
			p [[All ship systems are functional. You may push the thrust lever.]];
		elseif here() ^ 'burnout' then
			if _'burnout'.planet then
				p [[Analysis of the atmosphere shows that the air is breathable.]]
			end
			if _'engine'.flame then
				p [[Fire in the engine room!]];
			end
			if s.till > 20 then
				p [[Problems in the 2nd engine.]];
			elseif s.till > 15 then
				p [[1st and 2nd engines failed. Failure of the stabilization system.]];
			else
				p [[All engines are out of order.]]
				s.stop = true
			end
			if _'engine'.flame then
				p [[It is very dangerous!]]
			end
			if s.till and not _'burnout'.planet then
				p ([[^^Until the end of the transition ]], s.till,
	[[ second(s) left.]])
			end
			_'throttle':description()
		end
	end;
	found_in = { 'ship1', 'burnout' };
	obj = {
		obj {
			-"lever|thrust";
			nam = 'throttle';
			ff = false;
			['before_SwitchOn,SwitchOff'] = [[The thrust lever can be pulled or pushed.]];
			description = function(s)
				if here() ^ 'ship1' or bomb_cancel then
					p [[The heavy thrust lever is in neutral position.]];
				elseif here() ^ 'burnout' then
					if s.ff then
						pr [[Thrust is on]];
						if _'panel'.stop then
							pr [[, but the engines are no longer running.]]
						end
						pr '.'
					else
						p [[Thrust is off.]]
					end
				end
			end;
			before_Push = function(s)
				if not radio_ack then
					p [[You completely forgot to contact the traffic control room. To do this you need to switch on the radio.]];
				elseif here() ^ 'ship1' then
					s.ff = true
					walk 'transfer'
				elseif here() ^ 'burnout' then
					if bomb_cancel then
						if _'outdoor':has'open' then
							p [[Maybe it's better to batten down the airlock first?]]
							return
						end
						walk 'happyend'
						return
					end
					if not s.ff then
						p [[You moved the lever forward.]]
					end
					s.ff = true
					p [[The lever is set to the maximum thrust.]];
				end
			end;
			before_Transfer = function(s, w)
				if w == pl then
					return mp:xaction("Pull", s)
				end
				return false
			end;
			before_Pull = function(s)
				if here() ^ 'ship1' then
					return false
				elseif here() ^ 'burnout' then
					if s.ff and not bomb_cancel then
						if not _'panel'.stop then
							p [[Exit from hyperspace is possible only when the ship reaches a certain speed.
Stopping the engines will lead to an interrupted transition. And then -- there will no way to return!]];
							return
						end
						p [[You pull the lever.]]
					end
					s.ff = false
					p [[The thrust lever is in neutral position.]]
				end
			end;
		}:attr'static';
		obj {
				"radio";
			description = [[The radio is built into the dashboard.]];
			before_SwitchOn = function(s)
				if s:once() then
					--mus_stop()
					snd_play 'sfx_radio'
					p [[-- PEG51,
board FL510, request for transition.^
-- ...FL510, you are cleared to enter the gates. Good luck!^
-- Confirmed.]];
					radio_ack = true;
				elseif here() ^ 'burnout' then
					if _'burnout'.planet then
						p [[You're getting radio interference. You turn off the radio.]]
					else
						p [[Radio cannot work in hyperspace.]]
					end
				else
					p [[You have already received your departure clearance.]]
				end
			end;
		}:attr 'switchable,static';
	};
}:attr'supporter';
cutscene {
	nam = 'happyend';
	enter = function(s)
		set_pic 'hyper'
		if have 'photo' then
			pn [[You take out a photo of your daughter and clip it to the corner of the window.
			Then, put your hand on the thrust lever.]];
		else
			pn [[You put your hand on the thrust lever.]]
		end
	end;
	text = function(s, n)
		local t = {
		[[You push the lever away to maximum position.]];
		[[Flashes of hyperspace outside the window come to life...^
The countdown begins (or continues?) on the dashboard.]];
		[[25, 24, 23...]],
		[[10, 9, 8, 7...]],
		[[3, 2, 1...]];
		[[I'll be back soon!]];
		};
--		if n == 6 then
--			snd_play 'sfx_explosion_3'
--		end
		return t[n]
	end;
	next_to = 'titles';
}

cutscene {
	noparser = true;
	nam = 'titles';
	title = false,
	enter = function(s)
		if not instead.tiny then
			fading.set { 'fadewhite', delay = 60, max = 64 }
		end
		set_pic 'crash'
		mus_play 'jump-memories'
	end;
	dsc = fmt.c[[{$fmt b|THE ARCHIVE}^
{$fmt em|Peter Kosyh / May 2020}^
{$fmt em|Music, sound: Alexander Soborov}^
{$fmt em|Jump Memories / Keys of Moon}^
{$fmt em|Testing: Khaelenmore Thaal, Oleg Bosh}^^
Thank you for playing this little game!^
If you liked it, you can find similar games at:^^
{$link|http://instead-games.ru}^
{$link|https:/parser.hugeping.ru}^
{$link|https://instead.itch.io}^^
And if you want to write your own story,^welcome to:^
{$link|https://instead.hugeping.ru}^^
{$fmt b|THE END}
]];
}

room {
	"cabin|cockpit|Frisky|ship|spaceship";
	title = "cockpit";
	nam = 'ship1';
	dsc = [[The cabin of "Frisky" is cramped. The oblique rays of the 51 Peg star
	penetrate through the narrow windows into the cockpit, illuminating the dashboard.
	Directly on the course -- transition gates, floating over Dimidius.^^
	Everything is ready to start the transition. But anyway, you want to take 
	another look at the dashboard.]];
	out_to = function(s)
		p [[This is not the time for walking on the ship. You are going to make the transition. And
		all controls are located in the cockpit.]]
	end;
	obj = {
		'space',
		'panel',
		Distance {
			"star|sun|Peg";
			description = [[It was known for a long time that an exoplanet
			similar to the Earth orbits around 51 Peg.
			And only in 2220 hyperspace gates were opened here.
			To the Earth -- 50 light years or 4 transition jumps.
			120 years of human expansion into deep space...]];
		};
		'windows';
		Distance {
			"planet|Dimidius";
			description = [[
Dimidius became the first reached planet with suitable living conditions. .^^
As soon as the gates were installed here in 2220, pioneers rushed to Dimidius in search of a new life.
And 5 years later, the richest deposits of uranium were discovered on the planet.
The old world suffered from a lack of resources, but money and power were concentrated in it.
Therefore, Dimidius was not destined to become New Earth.
It became a colony..^^
Your six-month contract for Dimidius is over, it's time to get home.]];
		};
		obj {
			"rays/plural";
			description = [[These are the rays of the local sun. They move across the dashboard.]];
		}:attr'scenery';
		Distance {
			"gates/plural|transition";
			description = function(s)
				if s:once() then
					p [[The gates -- this is the entrance to hyperspace. 
					The gates looks like a 40-meter ring slowly rotating in the void.
					The 51 Peg gates were opened in 2020. 
					They became the 12th gates built over the 125-year history of mankind's expansion into deep space.]];
				else
					p [[You see flashes of hyperspace through the gates.]];
				end
			end;
			obj = {
				Distance {
					-"hyperspace|flashes/plural";
					description =
						[[Hyperspace was discovered in 2095 during experiments on the BSR.
						It took another 4 years to find a way to synchronize the continuum
						between exit points from hyperspace.]]
				}:attr 'scenery';
			}
		};
	}
}

cutscene {
	nam = "transfer";
	title = "Transition";
	enter = function()
		set_pic "hyper"
	end;
	text = function(s, i)
		local txt = {
		[[Before placing your hand on the massive lever, you looked at your daughter's photo.^
-- Well, with God's help...^^
		You carefully move the massive lever forward and watch the gates approach.
		You have done this many times in your 20-year career.
		The ship shudders, a gigantic force pulls it in and, behold, you are observing the bizarre intertwining of lights.
		There are only a few seconds and... ]];
		[[BOOM!!! Vibration shakes the ship. Something is wrong?]];
		[[The vibration is increasing. Bang!. Another blow. The dashboard blooms with a scattering of lights.]];
		};
		if i == 2 then
			mus_stop()
			snd_play('sfx_ship_malfunction_ambience_loop', true)
			snd_play 'sfx_explosion_1'
			snd_stop('sfx_ship_ambience_loop')
			snd_stop('sfx_ready_blip_loop')
		elseif i == 3 then
			mus_play 'bgm_emergency'
			snd_play('sfx_siren_loop', true)
			snd_play 'sfx_explosion_2'
		end
		return txt[i]
	end;
	next_to = 'burnout';
	exit = function(s)
		DaemonStart 'panel'
		if _'photo':has 'moved' and not have 'photo' then
			move('photo', 'burnout')
		end
	end;
}
function start_ill()
	--[[
	if _'planet':once 'ill' and _'suit':hasnt 'worn' then
		DaemonStart 'planet'
	end
	]]--
end
room {
	"cabin|cockpit|Frisky|ship|spaceship";
	title = "cockpit";
	nam = 'burnout';
	planet = false;
	transfer = 0;
	exit = function(s)
		if _'engine'.flame then
			snd_stop 'sfx_siren_loop'
			snd_play ('sfx_siren_dampened_loop', true)
		else
			snd_stop 'sfx_ship_ambience_loop'
		end
	end;
	enter = function(s)
		if _'engine'.flame then
			snd_stop 'sfx_siren_dampened_loop'
			snd_play ('sfx_siren_loop', true)
		elseif not s.planet then
			snd_stop 'sfx_ship_malfunction_ambience_loop'
			snd_play ('sfx_ship_ambience_loop', true)
		end
		if bomb_cancel then
			if s:once 'wow' then
				p [[Entering the cockpit, you noticed something strange.
				Instead of a landscape, you see hyperspace through the windows!]];
				_'panel'.stop = false
				place 'hyper2'
				remove 'sky2'
			end
		end
	end;
	daemon = function(s)
		if here() ~= s then
			return
		end
		local txt = {
			"The lights illuminate the cockpit.";
			"White light fills the cockpit.";
			"A dazzling white light filled the cockpit.";
		};
		s.transfer = s.transfer + 1
		pn(fmt.em(txt[s.transfer]))
		if s.transfer > 3 then
			s:daemonStop()
			walk 'transfer2'
		end
	end;
	Listen = function(s)
		if _'engine'.flame then
			p [[The sound of alarm fills the cockpit.]]
		else
			return false
		end
	end;
	dsc = function(s)
		if s.planet then
			if rain then
				p [[It's light in the cabin of "Frisky".
				The dashboard reflects faintly in the rain-covered window.]];
			else
				if bomb_cancel then
					p [[The cabin of "Frisky" is cramped.
					Through the windows you see the glow of hyperspace.]]
					p [[All ship systems are functional.]]
				else
					p [[It's light in the cabin of "Frisky".
					Through the windows you can see a golden yellow field under a clear sky.]];
				end
			end
		elseif _'engine'.flame then
			p [[The cockpit is filled with the sound of alarm.
			You need to examine the dashboard to find out what is happening.]];
		else
			p [[The cabin of "Frisky" is cramped.
			Through the windows you see the glow of hyperspace
			The dashboard blink in the dim light.]]
			if not _'engine'.flame and _'panel'.stop and
			not isDaemon('burnout') then
				p [[^^{$fmt em|You notice something strange outside the windows...}]]
			end
		end
		p [[^^You can exit the cabin.]]
	end;
	out_to = 'room';
	obj = {
		Distance {
			nam = 'hyper2';
			-"hyperspace,someth*,strang*|lights/plural|radiance";
			description = function(s)
				if not _'engine'.flame and _'panel'.stop then
					p [[You see three sparkling lights dancing approaching your ship.
					Or are you moving towards them?]]
					enable '#trinity'
					DaemonStart("burnout");
					set_pic 'trinity'
					snd_play ('sfx_blinding_lights', true)
				else
					p [[The transition is not yet completed.
					This thought prevents you from enjoying the magnificent view.]];
				end
			end;
			obj = {
				Distance {
					nam = '#trinity';
						-"свет";
					description = [[A dazzling white light fills the cockpit.]];
				}:disable();
			};
		};
		'panel';
		'windows';
	};
}
_'@u_to'.word = "up,above,upstairs" -- add upstairs

room {
	"cargo hold,hold";
	title = 'cargo hold';
	nam = 'storage';
	u_to = function(s)
		if ill > 0 then
			p [[You don't have the strength to go upstairs.]]
			return
		end
		return  'room';
	end;
	dsc = [[You can go upstairs or go out to the airlock.]];
	out_to = 'gate';
	obj = {
		Path {
			"airlock";
			walk_to = 'gate';
			desc = [[You can go out to the airlock.]];
		};
		Furniture {
			-"containers,boxes/plural|cargo|equipment";
			description = [[These are containers with equipment.]];
			before_Open = [[The containers are sealed.
			You shouldn't open them.]];
		}:attr'openable';
	};
}

door {
	-"door,airlock door,gateway door";
	nam = 'outdoor';
	['before_Close,Open,Lock,Unlock'] = [[The door is opened and closed with a lever.]];
	door_to = function(s)
		if here() ^ 'gate' then
			return 'planet'
		else
			return 'gate'
		end
	end;
	description = function()
		p [[Massive airlock door.]];
		return false
	end;
	obj = {
		obj {
			"red lever,lever";
			nam = '#lever';
			description = [[A bright red massive lever.]];
			dsc = [[To the right of the door is a red lever.]];
			before_Pull = function(s)
				if not _'burnout'.planet then
					p [[Open the airlock door during the transition? This is suicide!]]
					return
				end
				if _'outdoor':has'open' then
					_'outdoor':attr'~open'
					p [[With a hissing sound, the airlock closed.]]
					if not onair then
						snd_stop 'sfx_rain_loop'
					end
					snd_play 'sfx_door_opens'
					if bomb_cancel and here() ^ 'gate' then
						mus_play 'the_end'
					end
				else
					_'outdoor':attr'open'
					p [[With a hissing sound, the airlock opened.]]
					if rain then
						snd_play ('sfx_rain_loop', true)
					end
					snd_play 'sfx_door_opens'
					start_ill()
				end
			end;
		}:attr 'static';
	}
}:attr 'locked,openable,static,transparent';
global 'onair' (false)
room {
	"airlock,gateway";
	nam = 'gate';
	title = "airlock";
	dsc = [[You are in the airlock.^^
		You can return to the cargo hold or go outside.]];
	in_to = "storage";
	out_to = "outdoor";
	enter = function(s, from)
		if rain and _'outdoor':has'open' then
			snd_play ('sfx_rain_loop', true)
		end
	end;
	exit = function(s, to)
		onair = not (to ^ 'storage')
		if not onair then
			snd_stop ('sfx_rain_loop')
		end
	end;
	obj = {
		obj {
			"closet,cabinet,wardrobe";
			locked = true;
			description = function(s)
				p [[This is a spacesuit closet.]]
				return false
			end;
			obj = {
				obj {
					"spacesuit,suit,space suit";
					nam = "suit";
					description = [[The suit looks massive, but it's actually quite light.]];
					before_Disrobe = function(s)
						if here().flame then
							p [[And suffocate from the fire?]]
							return
						end
						return false
					end;
					after_Disrobe = function(s)
						if onair and s:once 'skaf' then
							p [[Not without fear you take off your spacesuit.
							You take a deep breath. All seems to be alright!]];
							start_ill()
						elseif here() ^ 'gate'
							and _'outdoor':has 'open' then
							start_ill()
							return false
						else
							return false
						end
					end;
				}:attr'clothing';
			};
		}:attr 'static,openable,container';
		'outdoor',
		Path {
			"cargo hold,hold,cargo";
			walk_to = 'storage';
			desc = [[You can return to the cargo hold.]];
		};
	};
}
room {
	"corridor,hallway";
	title = 'corridor';
	nam = 'room';
	dsc = [[From here you can get to the cabin and to the engines]];
	d_to = "#trapdoor";
	before_Sleep = [[It's not time to sleep.]];
	before_Smell = function(s)
		if _'engine'.flame then
			p [[It smells like burning.]];
		else
			return false
		end
	end;
	obj = {
		Furniture {
			"bed";
			description = [[Standard bed.
			This is found in almost all small vessels, such as "Frisky".]];
		}:attr 'enterable,supporter';
		door {
			"trapdoor,hatch,door";
			nam = "#trapdoor";
			description = function(s)
				p [[The trapdoor leads down.]]
			end;
			door_to = 'storage';
		}:attr 'static,openable';
		Prop { -"wall|walls/plural" };
		obj {
			"fire extinguisher,extinguisher,balloon,fire bottle";
			full = true;
			init_dsc = [[A fire extinguisher is attached to the wall.]];
			nam = "огнетушитель";
			description = function(s)
				p [[Looks like bright red balloon.
				Designed specifically for use in the space fleet.]];
				if not s.full then
					p [[The fire extinguisher is empty.]]
				end
			end;
		};
		Path {
			"cabin,cockpit";
			walk_to = 'burnout';
			desc = [[You can go to the cabin.]];
		};
		Path {
			-"engines/plural|engine|engine room";
			walk_to = 'engine';
			desc = [[You can go to the engines.]];
		};
	}
}

room {
	"engine room,room";
	title = "engine room";
	nam = 'engine';
	flame = true;
	before_Smell = function(s)
		if s.flame then
			p [[Smells like burning.]];
		else
			return false
		end
	end;
	onenter = function(s)
		if s.flame and _'suit':hasnt 'worn' then
			p [[There's a fire in the engine room!
			You cannot be there because of the acrid smoke.]]
			return false
		end
	end;
	dsc = function(s)
		if s.flame then
			p [[A fire is burning in the engine room! Smoke is everywhere!]];
		elseif bomb_cancel then
			p [[You are in the engine room.
			The control unit blinks with indicators.]]
		else
			p [[You are in the engine room.
			The burned-out control unit is completely destroyed.]]
		end
		p [[^^You can exit the engine room.]]
	end;
	out_to = 'room';
	after_Exting = function(s, w)
		if not s.flame then
			p [[The fire has already been extinguished.]]
			return
		end
		if not w or w ^ '#flame' or w == s or w ^ '#control' then
			_'огнетушитель'.full = false
			s.flame = false
			p [[You fight the flames fiercely.
			Finally, the fire is extinguished!]]
			remove '#flame'
			mus_stop()
			snd_stop 'sfx_siren_dampened_loop'
		else
			return false
		end
	end;
	obj = {
		obj {
			nam = '#flame';
			"fire,flame|flames/plural|smoke";
			["before_Attack,Take"] = function(s)
				mp:xaction("Exting")
			end;
			before_Exting = function()
				return false
			end;
			before_Default = [[Fire in the engine room!]];
		}:attr 'scenery';
		obj {
			nam="#control";
			"control unit,unit,indicator*";
			description = function(s)
				if here().flame then
					p [[The control unit is in flames!]];
				elseif bomb_cancel then
					p [[The control unit is functional!]]
				else
					p [[The control unit is the ship's engine control system.
					It's burned-out, but that's not what gets your attention.
					There's a hole in the center of the unit!]];
					enable '#дыра'
					if _'осколки':has 'concealed' then
						_'осколки':attr
						'~concealed';
						p [[^^You notice the shards.]]
					end
				end
			end;
			obj = {
				obj {
					nam = '#дыра';
					"hole";
					description = function()
						p [[It looks like there was an explosion...]];
						return false;
					end;
					before_LetIn = function(s, w)
						if w == pl then
							p [[Too narrow for you. Too narrow for you.]]
							return
						end
						return false
					end;
				}:attr 'scenery,container,open,enterable':disable();
			};
		}:attr 'static,concealed';
		obj {
			nam = 'осколки';
			"shards,debris/plural";
			after_Smell = [[It smells strange.]];
			after_Touch = [[The edges are fused. Doesn't look like duralumin.]];
			description = function(s)
				if have(s) then
					p [[Fused shards. They are heavy. 
					Strange, it doesn't look like duralumin...]];
				else
					p [[Small black pieces of metal.]]
				end
			end;
		}:attr 'concealed';
		Path {
			"corridor,hallway";
			walk_to = 'room';
			desc = [[You can go out into the corridor.]];
		};
	}
}

Distance {
	nam = "sky2";
	"sky,turquoise|rain|haze";
	description = function(s)
		if rain then
			p [[The sky is covered with rainy haze.]]
		else
			p [[The sky is clear, filled with blue turquoise.]]
		end
		p [[From time to time, the sky lights up with flashes.]];
	end;
	before_Listen = function(s)
		if rain then
			p [[You hear the sound of the rain.]];
			return
		elseif s:multi_alias() == 2 then
			p [[But the rain is over!]]
			return
		end
		p [[You do not hear anything unusual.]]
	end;
	obj = {
		Distance {
			"hyperspace|flashes/plural";
			description = [[A planet in hyperspace? Incredible!]];
		};
		obj {
			"sun,star";
			before_Default = [[Strange, but you do not see the sun, although it is day.]];
		}:attr 'scenery';
	}
};

Distance {
	nam = 'planet_scene';
	"planet|landscape|field,wheat|horizon";
	description = function()
		if rain then
			p [[The edges of a wheat-golden field hide in a rainy haze.]];
		else
			p [[The golden wheat field stretches to the horizon..]];
		end
	end;
	obj = {
		'sky2';
		obj {
			"drops,droplets/plural";
			description = function(s)
				if rain then
					p [[For a while, you watch the droplets rolling down the glass.]];
				else
					p [[But it's not raining now.]]
				end
			end;
		}:attr'scenery';
	};
}

cutscene {
	nam = "transfer2";
	title = "...";
	enter = function(s)
		snd_play 'sfx_explosion_3'
		snd_stop 'sfx_blinding_lights'
		snd_stop 'sfx_ship_malfunction_ambience_loop'
		set_pic 'flash'
	end;
	text = {
		[[A blinding light filled everything around.
		You were lost in it, dissolved -- as if you never existed ... 
		The ship shudders on impact. This is the end?]];
		[[Silence...]];
		[[Drops of water on the glass. Big drops.
		They slowly flow down the slanting windows, fill the ship's skin.
		The noise of the rain -- why can't you hear it?]];
	};
	exit = function(s)
		_'burnout'.planet = true
		remove 'hyper2'
		p [[You slowly come to your senses.
		Well, of course, you are inside "Frisky" and its casing will not miss such a faint sound as the impact of drops. What a pity...]];
		move('planet_scene', 'burnout')
		set_pic 'crash'
		mus_play 'bgm_plains'
	end;
}

obj {
	nam = 'ship';
	"ship,Frisky,frisk*";
	description =  function(s)
		p [[Not a very soft landing, judging by the furrow the ship left behind in the ground.
		But the ship survived!]]
	end;
	before_Enter = function(s)
		mp:xaction("Enter", _'outdoor')
	end;
	obj = {
		obj {
			"furrow,track";
			description = [[Not very deep.
			Somehow, the ship was thrown right into the field...]];
		}:attr'scenery';
	}
}:attr 'scenery,enterable';

obj {
	nam = 'wheat';
	"grains/plural|grain";
	description = [[Large yellow grains, similar to wheat.
	You feel like energy is concentrated in them.]];
	['after_Smell'] = function(s)
		if rain then
			p [[You like the smell of wet grain.]];
		else
			p [[You like the smell of grain.]];
		end
	end;
	after_Eat = function(s)
		if ill > 0 then
			DaemonStop 'planet'
			if ill > 1 then
				p [[You eat the grains. After a while, you feel a strange weakness recede.]]
				ill = 0
				return
			end
			ill = 0;
		end
		return false
	end;
}:attr 'edible'

obj {
	nam = 'field';
	title = "In the field";
	"field";
	description = function(s)
		if rain then
			p [[The edges of the field, a golden wheat color, hide in a rainy haze.]]
		else
			p [[The field looks endless.]]
		end
		p [[You see how the wheat-like ears sway in the gentle wind.]];
		return false
	end;
	obj = {
		obj {
			-"ears,spiklets/plural|wheat";
			description = [[You see how the ears sway in the gentle wind.]];
			["before_Eat,Tear,Take,Pull"] = function(s)
				p [[You plucked a few spikelets and rubbed them in your palms, collecting the grains.]];
				take 'wheat'
			end;
		}:attr 'concealed';
	};
	before_LetIn = function(s, w)
		if w == pl and here() ^ 'planet' then
			p "You entered a thicket of yellow ears."
			move(pl, s)
			return
		end
		return false
	end;
--	scope = { 'ship' };
	after_LetIn = function(s, w)
		p ([[You drop ]], w:the_noun(), [[ in the field.]])
	end;
}:attr 'scenery,enterable,container,open'

global 'ill' (0)

room {
	nam = 'planet';
	title = "У корабля";
	in_to = 'outdoor';
	after_Listen = function(s)
		if rain then
			p [[Ты слышишь как капли барабанят по обшивке
	корабля.]]
			return
		end
		return false
	end;
	daemon = function(s)
		local txt = {
			"Внезапно, ты чувствуешь слабость.";
			"Ты чувствуешь слабость во всем теле.";
			"Странная слабость усиливается.";
			"Ты чувствуешь страшную усталость.";
		};
		ill = ill + 1
		local i = ill - 1
		if i > #txt then i = #txt end
		if i <= 0 then
			return
		end
		p (fmt.em(txt[i]))
	end;
	onenter = function(s)
		start_ill()
	end;
	dsc = function(s)
		p [[Ты стоишь у "Резвого", уткнувшегося носом в землю
	посреди золотисто-жёлтого поля.]]
		if rain then
			p [[Идёт дождь.]];
		end
		p [[Неподалёку на востоке ты видишь дерево.]];
		p [[На севере ты
	замечаешь высокий шпиль, устремлённый в небо.]];
	end;
	n_to = 'tower';
	e_to = '#tree';
	obj = {
		'sky2';
		'outdoor';
		'ship';
		'field';
		'tower';
		door {
			nam = '#tree';
			-"дерево,ветв*";
			description = [[Одинокое дерево кажется здесь совсем
	лишним.]];
			door_to = 'tree';
		}:attr 'scenery,open';
	}
}

Distance {
	-"шпиль/мр,ед,С|башня,вершина";
	nam = 'tower';
	["before_Enter,Walk"] = function()
		if ill > 0 then
			p [[Ты не дойдешь в таком состоянии.]]
			return
		end
		walk 'шпиль';
	end;
	description = function(s)
		if rain then
			p [[Вершина шпиля теряется в дымке дождя.]]
		else
			p [[Шпиль очень высокий. Словно тонкая чёрная игла он
	пронзает небо.]];
		end
	end;
};

room {
	nam = "шпиль";
	-"равнина";
	title = "у шпиля";
	before_Listen = [[Ты слышишь, как поёт ветер.]];
	before_Shout = [[Ты кричишь, но ничего не происходит.]];
	dsc = function(s)
		p [[Ты находишься у подножия высокой башни. Её
чёрный шпиль устремлен в небо. Вокруг простирается зелёная равнина. На
	западе от башни растёт одинокое дерево.]];
		if not disabled 'human' then
			p (fmt.em [[Ты видишь рядом с деревом
	человеческую фигурку в плаще!]])
		end
		p [[^^Ты можешь вернуться на юг.]];
	end;
	exit = function(s, t)
		if t ^ 'planet' then
			p [[Ты покинул странную башню и отправился на
юг, к своему кораблю.]];
			set_pic 'crash'
			if rain then
				p [[Пока ты шёл, небо очистилось и дождь
закончился.]];
				rain = false
				snd_stop 'sfx_rain_loop'
			end
		elseif t ^ 'tree' then
			set_pic 'sky'
		end
	end;
	enter = function(s, f)
		if f ^ 'planet' then
			p [[Ты направился на север. Прошло по меньшей мере
полчаса, прежде, чем ты оказался у подножия странного сооружения.]];
			if rain then
				p [[Пока ты шёл, небо очистилось и дождь
закончился.]];
				rain = false
				snd_stop 'sfx_rain_loop'
			end
		end
		set_pic 'neartower'
	end;
	s_to = "planet";
	in_to = '#tower';
	w_to = '#tree';
	obj = {
		'sky2';
		Distance {
			nam = 'human';
			-"человек|фигурка,фигура",
			description = [[Отсюда не разглядеть. Кажется,
	это человек! Он не обращает на тебя внимания.]];
		};
		obj {
			nam = '#tower';
			-"башня|шпиль|подножие";
			description = [[Поверхность башни матовая,
	чёрного цвета, без единого шва. Похоже, что это металл.]];
			before_Touch = [[Ты чувствуешь вибрацию.]];
			before_Attack = [[Силы слишком неравные.]];
			before_Enter = function(s)
				p [[Ты обошёл подножие башни, но так
	и не заметил никакого входа.]]
			end;
		}:attr 'scenery,enterable';
		door {
			nam = '#tree';
			-"дерево,ветки*,листья*";
			description = function()
				p [[Дерево выглядит старым. Его
	огромные узловатые ветви почти лишены листьев.]];
			end;
			door_to = 'tree';
		}:attr 'scenery,open';
	};
}

room {
	-"берег";
	nam = 'sea';
	title = "У моря";
	old_pic = false;
	before_Listen = [[Шум моря ласкает твой слух.]];
	before_Smell = [[От запаха соли и водорослей кружится
голова.]];
	before_Swim = [[Не лучшее время для этого.]];
	dsc = [[Ты стоишь на берегу моря. На юге от тебя, прямо на берегу
	растет странное дерево.]];
	s_to = '#tree';
	out_to = '#tree';
	exit = function(s)
--		set_pic(s.old_pic)
	end;
	enter = function(s, f)
		if get_pic() ~= 'sky' then
			s.old_pic = get_pic()
			set_pic 'sky'
		end
		snd_stop 'sfx_rain_loop'
		mus_stop()
		snd_play ('sfx_ocean_waves_loop', true)
	end;
	obj = {
		door {
			nam = '#tree';
			-"дерево,ветв*";
			description = [[Одинокое дерево кажется здесь совсем
	лишним.]];
			door_to = 'tree';
		}:attr 'scenery,open';
		obj {
			-"море|вода";
			description = [[Бескрайний простор. Волны,
накатываясь одна на другую, пенятся и разбиваются о берег.]];
			before_Drink = [[Пить морскую воду?]];
		}:attr 'scenery';
		obj {
			-"волны";
			description = [[Ты можешь вечно смотреть на
то, как волны разбиваются о берег.]];
		}:attr 'scenery';
		'sky2';
	};
}

obj {
	-"старик,человек";
	nam = 'oldman';
	init_dsc = function(s)
		if visited 'oldman_talk' then
			p [[Старик ждёт от тебя ответа: {$fmt em|да}
или {$fmt em|нет}?]];
		else
			p [[Ты видишь старика, который стоит у самого края и
смотрит вдаль.]];
		end
	end;
	description = [[Морщинистое лицо старика скрывает седая, почти
полностью белая борода. Он одет в длинный чёрный плащ с капюшоном,
который сейчас не покрывает его голову и седые волосы свободно треплет
ветер.]];
	before_Talk = function(s)
		walk 'oldman_talk';
	end;
	['before_Attack,Push'] = function(s)
		if visited 'oldman_talk' then
			p [[Не стоит этого делать, друг мой! -- старик
предостерегающе поднял руку.]]
		else
			p [[Старик
предостерегающе поднял руку и укоризненно покачал головой.]]
		end
	end;
}
cutscene {
	title = false;
	nam = 'oldman_talk';
	text = {
		[[-- Здравствуйте! Я не знаю, понимаете ли вы меня или
нет, но ... гм... Вы кто?^]];
		[[Старик повернул голову в твою сторону и
улыбнулся.^Тебе ничего не оставалось, кроме как улыбнуться в
ответ. Некоторое время вы стояли так.]];
		[[-- Я -- человек с Земли как и ты. И я -- один из
хранителей Архива.]];
		[[-- Что такое Архив?]];
		[[-- Мой друг, если я отвечу на этот вопрос, ты
останешься здесь навсегда. Как только ты познаешь суть происходящего,
путь назад будет для тебя закрыт. Поэтому я должен спросить тебя, готов ли ты
стать одним из нас? {$fmt em|Да} или {$fmt em|нет}?]];
	}
}

cutscene {
	title = false;
	nam = 'oldman_talk2';
	text = {
		[[-- Я так и думал.^^
С этими словами старик встал и медленно направился к дереву.^^
--  Ну что же, несмотря на то, что ты
не способен  проникнуть в реальность Архива, всё-таки, твоё сознание
пытается передать её через привычные образы, и поэтому, ты можешь
	многое изменить, пока находишься здесь...]];
		[[-- Пока нахожусь здесь?]];
		[[Но старик не ответил. Он уже скрылся за стволом
	странного дерева.]];
	}
}

room {
	-"скала,вид*,край*,обрыв*";
	nam = 'rock';
	title = "У скалистого обрыва";
	before_Listen = [[Ты слышишь свист ветра в скалах.]];
	yes = 0;
	before_Jump = [[Решил решить все проблемы разом?]];
	last = [[-- Поэтому я должен спросить тебя, готов ли ты
стать одним из нас?]];
	['before_Yes,No'] = function(s)
		if not visited 'oldman_talk' or not seen 'oldman' then
			return false
		end
		local txt = {
			{ "-- Ты уверен?", "Yes" };
			{ [[-- В таком случае, ты не сможешь вернуться в
привычный мир. Ты точно хочешь этого?]], "Yes" };
			{ [[-- Ты хорошо подумал?]], "Yes" };
			{ [[-- Ты хочешь узнать тайну?]], "Yes" };
			{ [[-- Ты считаешь, что готов познать реальность?]], "Yes" };
			{ [[-- Ты думаешь, что это твоё призвание?]],
				"Yes" };
			{ [[-- Не боишься пожалеть о своём выборе?]],
				"Yes" };
			{ [[-- Ты думаешь, что это просто паршивая
приключенческая игра?]], "No" };
			{ [[-- А вот сейчас было обидно. И ты всё-равно
настаиваешь?]], "Yes" };
			{ [[-- Ты упорный, да?]], "Yes" };
			{ [[-- Ты понимаешь, что не сможешь никому
передать то, что откроется тебе?]], "Yes" };
			{ [[-- Может, передумаешь?]], "Yes" };
			{ [[-- Так и будем разговаривать вечно?]],
				"No" };
			{ [[-- Ладно, я повторю всё с самого
начала.]],
				"Yes" };
		}
		local i = (s.yes % #txt) + 1
		local ans = txt[i][2]
		if mp.event == ans then
			s.last = txt[i][1]
			p(txt[i][1])
			s.yes = s.yes + 1
		else
			pn (s.last)
			if mp.event == "Yes" then
				pn [[-- Да!]];
			else
				pn [[-- Нет!]];
			end
			walk 'oldman_talk2'
			remove 'oldman'
		end
	end;
	before_WaveHands = function(s)
		if seen 'oldman' then
			p [[Старик многозначительно хмыкнул и помахал
тебе в ответ.]]
			return
		end
		return false
	end;
	dsc = [[Ты стоишь на вершине скалы. Перед тобой
внизу открывается величественный вид. Далеко-далеко, за горизонтом виднеется чёрный
шпиль. На севере от
	тебя находится странное дерево.]];
	n_to = '#tree';
	out_to = function(s)
		if mp.words[1]:find "прыг" then
			mp:xaction ("Jump")
			return
		end
		return '#tree';
	end;
	compass_look = function(s, t)
		if t == 'd_to' then
			mp:xaction("Exam", _'#view')
			return
		end
		return false
	end;
	d_to = function(s)
		p [[Ты не можешь спуститься со скалистого обрыва.]];
	end;
	obj = {
		door {
			nam = '#tree';
			-"дерево,ветв*";
			description = [[Одинокое дерево кажется здесь совсем
	лишним.]];
			door_to = 'tree';
		}:attr 'scenery,open';
		Distance {
			-"вид|скалы,обломк*";
			nam = "#view";
			description = [[Внизу ты видишь долину
усеянную обломками скал.]];
		};
		Distance {
			-"шпиль|башня";
			description = [[Высокий тонкий шпиль едва
заметен отсюда.]];
		};
		'sky2';
		'oldman';
	};
}:attr 'supporter';

room {
	title = "Дерево";
	nam = 'tree';
	trans = false;
	ff = false;
	exit = function(s)
		if s.trans then
			p ([[Ты выбираешь направление на ]],s.trans:noun(),
				".")
			p [[Сделав всего несколько шагов ты вдруг
	замечаешь, что оказался совсем в другом месте...]];
			if s:once 'trans' then
				p [[Твой
	вестибулярный аппарат сходит с ума, ты спотыкаешься и
	падаешь. Наконец, головокружение проходит и ты с удивлением
	осматриваешься вокруг.]]
			end
		end
	end;
	enter = function(s, f)
		s.ff = f;
		s.trans = false
		if f ^ 'шпиль' and s:once'visit' then
			p [[Ты поспешил к дереву. Тем временем фигурка
	человека, которого ты заметил, скрылась за стволом. Когда ты,
	немного уставший, оказался у дерева, ты никого здесь не
	обнаружил...]]
			disable 'human'
		end
	end;
	out_to = function(s)
		return s.ff
	end;
	n_to = function(s)
		if s.ff ^ 'sea' then
			return 'sea';
		end
		return false
	end;
	e_to = function(s)
		if s.ff ^ 'шпиль' then
			return 'шпиль';
		end
		return false
	end;
	s_to = function(s)
		if s.ff ^ 'rock' then
			return 'rock';
		end
		return false
	end;
	d_to = function(s)
		p [[Зарыться в землю?]];
	end;
	cant_go = function(s, t)
		s.trans = _('@'..t)
		if s.ff ^ 'planet' then -- 'w'
			walk 'sea'
			return
		elseif s.ff ^ 'sea' then
			if rain then
				snd_play ('sfx_rain_loop', true)
			end
			mus_play 'bgm_plains'
			snd_stop 'sfx_ocean_waves_loop'
			set_pic(_'sea'.old_pic)
			walk 'planet'
			return
		elseif s.ff ^ 'шпиль' then
			if t == 'w_to' then
				walk 'rock'
			else
				walk 'intower'
			end
			return
		elseif s.ff ^ 'rock' then
			if t == 'n_to' then
				walk 'intower'
			else
				walk 'шпиль'
			end
			return
		end
	end;
	w_to = function(s)
		if s.ff ^ 'planet' then
			return 'planet';
		end
		return false
	end;
	dsc = function(s)
		p [[Ты стоишь у старого дерева. Его сухие узловатые ветви
	почти лишены листьев.]]
		if s.ff ^ 'шпиль' then
			p [[^^Шпиль башни находится на востоке.]];
		elseif s.ff ^ 'planet' then
			p [[^^Твой корабль находится на западе.]];
		elseif s.ff ^ 'sea' then
			p [[^^Море находится на севере.]];
		elseif s.ff ^ 'rock' then
			p [[^^Обрыв находится на юге.]];
		end
		p [[В остальных направлениях - равнина.]];
	end;
	u_to = '#tree';
	obj = {
		obj {
			nam = '#tree';
			-"дерево,лист*,ветв*,ветк*";
			before_Touch = [[Кора дерева шершавая. Словно морщины.]];
			description = [[На дереве почти нет листвы, но
	оно живо.]];
			['before_Climb,Enter'] = [[Ты не горишь
	желанием сломать себе шею.]];
		}:attr 'scenery,enterable,supporter';
		obj {
			-"равнина";
			description = [[Ты не видишь ничего
	примечательного, кроме пустынной равнины.]];
		}:attr 'scenery';
	};
}

Distance {
	nam = "clouds";
	-"облака";
	description = [[Ты видишь, как внизу проплывают белоснежные облака.]];
}

Distance {
	nam = "sky3";
	-"небо";
	description = [[Бирюзовое небо озаряется переливающимися всем спектром всполохами.]];
	obj = {
		Distance {
			-"всполохи|гиперпространство";
			description = [[Тебя захватывает красота
	сияния гиперпространства.]];
		};
	}
}
global 'bomb_cancel' (false)
cutscene {
	nam = 'bomb_call';
	title = "звонок";
	enter = function(s)
		mus_stop()
	end;
	text = function(s, n)
		local t = {
		[[Где-то в закоулках подсознания у тебя возникла
	идея. Боясь спугнуть странную, но захватывающую мысль, ты
	схватил трубку и набрал номер.]];
		[[-- Они не должны были так делать! Они не должны были
	так со мной поступать! -- резкий, незнакомый голос в трубке напугал тебя.]];
		[[-- Хуан? Это ты?]];
		[[-- Черт! Кто это? Это ваши шуточки? Убирайся из
	моей башки!]];
		[[-- Хуан, слушай меня внимательно! Слушай меня,
	дружище!]];
		[[-- Кто ты, чёрт тебя подери?]];
		[[-- Хуан, ты уже полетел на Димидий?]];
		[[-- Нет! Откуда ты знаешь, что я туда собрался? Кто
	ты?]];
		[[-- Не перебивай! Слушай внимательно! На Димидии ты
	устроишься на работу техником и попытаешься совершить теракт,
	подложив бомбу на "Резвый". Теракт... не удастся. Не делай этого, Хуан! Это
	раздавит тебя. Ты убъёшь пилота корабля зря, но ты ведь не убийца!]];
		[[-- Откуда ты это знаешь? Кто ты?]];
		[[-- Считай меня своим внутренним голосом. Я буду
	присматривать за тобой.]];
		[[-- Пошел к чёрту! Я сошёл с ума?]];
		[[-- Если всё-таки не послушаешь меня. В кабине пилота
	ты увидишь фотографию девочки. Это Лиза -- дочь пилота. Ты
	понял? Не забывай.]];
		[[-- Вон! Вон из моей башки!]];
		};
		if n == 2 then
			snd_stop()
			snd_play 'sfx_phone_call_2'
		end
		return t[n]
	end;
	exit = function(s)
		p [[Ты кладёшь трубку. Интересно, послушается ли тебя
	Хуан?^^Что же хранит в себе башня? Записанные события давно
	минувших дней, которые можно проигрывать словно старые пластинки? А может
	быть, башня -- приёмник и всё действительно происходит в
	реальности, только в другом времени?]];
		if have 'осколки' then
			p [[^^Вдруг, ты почувствовал, что у тебя с собой
	больше нет осколков бомбы!]];
		end
		remove 'осколки'
		_"огнетушитель".full = true
		bomb_cancel = true
		mus_play 'bgm_plains'
	end;
}

cutscene {
	nam = 'bomb_call2';
	title = "звонок";
	enter = function(s)
		mus_stop()
	end;
	text = function(s, n)
		local t = {
		[[Точно не понимая что именно происходит, ты набираешь номер...]];
		[[-- Они не должны были так делать! Они не должны были
	так со мной поступать! -- резкий, незнакомый голос в трубке напугал тебя.]];
		[[-- Алло...]];
		[[-- Черт! Этого ещё не хватало! Кто это?]];
		[[-- Я...]];
		[[-- Пошёл вон из моей головы, убирайся! Слышишь?]];
		};
		if n == 2 then
			snd_stop()
			snd_play 'sfx_phone_call_2'
		end
		return t[n]
	end;
	exit = function(s)
		p [[Ты поспешно кладёшь трубку.]];
		mus_play 'bgm_plains'
	end;
}

cutscene {
	nam = 'photo_call';
	title = "звонок";
	enter = function(s)
		mus_stop()
	end;
	text = function(s, n)
		local t = {
		[[Ты взял трубку и набрал номер. Отчаяние и надежда на
	чудо сменяли друг друга, пока...]];
		[[-- Пап, это ты?]];
		[[-- Да, это я! Лиза? Ты... Где ты?]];
		[[-- Дома, конечно же. А я
	разговариваю с тобой в воображении?]];
		[[-- Наверное, я ... не знаю точно. Лиза... Послушай, сколько
	тебе лет?]];
		[[-- Почти десять! Ты что, забыл? Ты когда вернёшься?]];
		[[-- Скоро... Передай маме, что я вас люблю.]];
                [[-- Ты уже звонил нам по обычной связи, но я
	передам. Ну всё, мы идём гулять. Пока!]];
                [[-- Да, до встречи!]];
		};
		if n == 2 then
			snd_stop()
			snd_play 'sfx_phone_call_2'
		end
		return t[n]
	end;
	exit = function(s)
		p [[Взволнованный, ты кладёшь трубку. Это была Лиза! 10 лет назад!]];
		mus_play 'bgm_plains'
	end;
}

room {
	-"комната";
	title = "Смотровая комната";
	nam = "top";
	before_Walk = function(s, to)
		if to ^ '@u_to' then
			p [[Рельс заканчивается здесь.]]
			return
		elseif to ^ '@d_to' then
			if not pl:inside'platform' then
				move(pl, 'platform')
			end
			p [[Ты нажимаешь на кнопку и платформа,
с неожиданно высоким ускорением, начинает свой спуск.]]
			snd_play 'sfx_platform'
			move('platform', 'intower')
			return
		end
		return false
	end;
	before_Ring = function(s, w)
		w = tostring(tel_number(w))

		if w == '7220342721' then --photo
			if visited 'photo_call' then
				p [[У тебя не хватает духу ещё раз
	звонить дочери в прошлое. У неё всё хорошо, и это главное.]];
			else
				snd_play 'sfx_phone_call_loop'
				walk 'photo_call'
			end
		elseif w == '9333451239' then -- осколки
			if visited 'bomb_call' then
				p [[Не стоит беспокоить бедного Хуана.]];
			else
				snd_play 'sfx_phone_call_loop'
				if know_bomb then
					walk 'bomb_call'
				else
					walk 'bomb_call2'
				end
			end
		elseif w == '17' or w == '8703627531' or w == '9236123121' or w == '7691' then
			snd_play 'sfx_phone_call_loop'
			return false
		else
			snd_play 'sfx_phone_wrong_number'
			p [[В трубке раздался женский голос: "Объект с таким идентификатором не найден в картотеке."]]
			return
		end
	end;
	out_to = 'balk';
	dsc = [[Ты находишься в небольшой круглой комнате, залитой
	дневным светом. Вдоль всего периметра стен расположены
	окна. На стене закреплён старинный телефон.^^Ты можешь выйти на смотровую площадку.]];
	obj = {
		obj {
			-"телефон,трубк*";
			description = [[Антиквариат. Стационарный
	телефон. В древности такие стояли в телефонных будках. Ты
	можешь попробовать {$fmt em|набрать <номер>}.]]
		}:attr 'static,concealed';
		Prop { -"стена" };
		Careful {
			-"окна";
			description = [[За окнами ты видишь смотровую площадку.]];
		};
		Path {
			-"площадка,смотровая площадка,смотровая";
			walk_to = 'balk';
			desc = [[Ты можешь выйти на смотровую площадку.]];
		};
		obj {
			-"платформа";
			nam = 'platform';
			inside_dsc = "Ты стоишь на платформе. Внутри платформы ты видишь кнопки.";
			description = [[Платформа перемещается по
рельсу, уходящему вертикально вверх и вниз.]];
			after_LetIn = function(s, w)
				if w == pl then
					p [[Ты заходишь на
платформу и осматриваешься. Управление предельно простое, здесь всего
две кнопки. Теперь ты можешь {$fmt em|ехать вверх или вниз}.]]
					return
				end
				return false
			end;
			obj = {
				obj {
					-"кнопки";
					description = [[Ты можешь
{$fmt em|ехать вверх или вниз}.]];
					['before_Push,Touch'] =
						[[Просто {$fmt em|вверх}
или {$fmt em|вниз}?]];
				}:attr 'static,concealed';
			};
		}:attr 'supporter,open,enterable,static';
	};
}
room {
	nam = "balk";
	title = "Смотровая площадка";
	out_to = 'top';
	in_to = 'top';
	before_Listen = [[Ветер завывает в решетчатой конструкции
	смотровой площадки.]];
	dsc = [[Всё вокруг заполняет глубокое бирюзовое небо, освещаемое
	спектральными всполохами. Под ногами -- белоснежные облака,
	проплывающие над лоскутным одеялом полей. А на горизонте ты видишь шпили
	других башен!^^Ты можешь уйти со смотровой площадки.]];
	obj = {
		'clouds';
		'sky3';
		Distance {
			-"горизонт|шпили|башни";
			description = [[Ты видишь тонкие шпили башен,
	пронзающие белоснежные облака. Ты обошел смотровую площадку и
	насчитал 5 таких шпилей. Но сколько их всего?]]
		};
		Distance {
			-"планета,земля|поля";
			description = [[Как же далеко башня
	возвышается над поверхностью?]];
		};
	};
}:attr'supporter';

function check_sit(w)
	if pl:where() ~= _'#chair' then
		if not w then
			return false
		end
		p(w)
	else
		walk 'computer'
	end
end
obj {
	nam = '$char';
	act = function(s,w)
		return w
	end;
}
room {
	-"комната";
	title = "Компьютерная комната";
	enter = function(s, f)
		if f ^ 'intower' then
			snd_play ('sfx_computer_ambience_loop', true)
			mus_stop()
			set_pic 'comp'
		end
		if not disabled 'crash' then
			p [[{$char|^^}{$fmt em|Спустившись в комнату, ты с ужасом обнаружил,
что странный компьютер снова стоит на проклятом столе!}]];
			disable 'crash'
			enable '#chair'
			enable 'table'
		end
	end;
	exit = function(s, to)
		if to ^ 'intower' then
			snd_stop 'sfx_computer_ambience_loop'
			mus_play 'bgm_plains'
		end
	end;
	dsc = function()
		p [[Ты находишься в полутёмной комнате.]]
		if disabled 'crash' then
			p [[Единственный
источник света здесь -- включённый компьютер. Компьютер стоит на
столе. Рядом со столом стоит кресло.]];
		else
			p [[В комнате валяются обломки мебели и компьютера.]]
		end
	end;
	nam = "under";
	before_Attack = function(s, w)
		if pl:inside '#chair' then
			p [[Может, сначала хотя бы с кресла встать?]];
			return
		end
		if not disabled 'crash' then
			p [[Ты уже сделал это.]]
			return
		end
		local list = {}
		for _, v in ipairs(objs 'table') do
			if not v ^ 'comp' then
				table.insert(list, v)
			end
		end
		for _, v in ipairs(list) do
			move(v, here())
		end
		p [[В порыве внезапной ярости ты начинаешь крушить всё
вокруг.]]
		if have 'огнетушитель' then
			p [[Тут очень пригодился огнетушитель, который
ты зачем-то таскал всё это время с собой.]]
		end
		p [[Через минуту -- всё было кончено.]]
		disable '#chair'
		disable 'table'
		enable 'crash'
	end;
	before_Listen  = [[Ты слышишь едва уловимое гудение.]];
	before_Walk = function(s, to)
		if to ^ '@d_to' then
			p [[Рельс заканчивается здесь.]]
			return
		elseif to ^ '@u_to' then
			if not pl:inside'platform' then
				move(pl, 'platform')
			end
			snd_play 'sfx_platform'
			move('platform', 'intower')
			return
		end
		return false
	end;
	obj = {
		Furniture {
			-"кресло";
			nam = "#chair";
			title = "в кресле";
			description = function()
				p [[Кресло выглядит
старым. Сделано из дерева.]];
				return false
			end;
			inside_dsc = [[Ты сидишь в кресле.]];
			after_LetIn = function(s, w)
				if w == pl then
					p [[Ты садишься в кресло.]]
					return
				end
				return false
			end;
		}:attr 'concealed,supporter,enterable';
		Furniture {
			nam = "table";
			-"стол,поверхност*";
			description = function(s)
				p [[Матовая поверхность стола отражает
свечение монитора.]];
				return false
			end;
			obj = {
				Furniture {
					nam = "comp";
					-"компьютер";
					description = [[Это какая-то
рухлядь. Пузатый монитор мерцает в темноте зелёным. Большая клавиатура
является частью компьютера.]];
					["before_Search,LookAt"] =
						function(s)
							return check_sit()
						end;
					before_SwitchOff = [[Ты не
видишь никакого выключателя. Да и проводов не видно...]];
					obj = {
					Furniture {
						nam = '#keyboard';
						-"клавиатура|клавиши/мн,жр";
						description =
							[[На
клавиатуре высокие квадратные клавиши.]];
						['before_Push,Touch,Take'] =
							function(s)
								check_sit
									[[В
кресле будет удобнее.]]
							end
						};
						Furniture {
							-"монитор";
							before_SwitchOff
								=
								[[Ты не замечаешь никакой кнопки.]];
							description =
								function()
									check_sit [[Наверное,
он вреден для глаз.]];
									end
						}:attr'switchable,on';
					};
				}:attr'switchable,on'
			};
		}:attr 'concealed,supporter';
		Prop {
			nam = "crash";
			-"обломки|хлам";
		}:disable();
	};
}
local ids = {
	['comp'] = 17;
	['photo'] = 7220342721;
	['огнетушитель'] = 8703627531;
	['suit'] = 9236123121;
	['осколки'] = 9333451239;
	['wheat'] = 7691;
}
function search_stat(total, n)
	p (fmt.b([[Всего ]] .. tostring(total)..[[ совпадений.]]))
	if n == 1 then
		pn (fmt.b([[Показано ]] .. tostring(n) ..[[
 важное.]]))
	else
		pn (fmt.b([[Показано ]] .. tostring(n) ..[[
важных.]]))
	end
	pn()
end
room {
	title = false;
	nam = "computer";
	OnError = function(s)
		p [[Синтаксическая ошибка. Для помощи введите: {$fmt b|помощь}.]];
	end;
	out_to = "under";
	default_Verb = "осмотреть";
	total = 32174;
	dsc = function(s)
		p [[ДОБРО ПОЖАЛОВАТЬ В "АРХИВ"^^]];
		pn ([[Всего карточек: ]], s.total, "* E23")
		s.total = s.total + rnd(15);
		p [[Выбран язык: {$fmt
em|Русский}^^Для помощи введите: {$fmt b|помощь}.]];
	end;
	Look = function()
		pl:need_scene(true)
	end;
	Help = [[^^
{$fmt c|СИСТЕМА "АРХИВ" v1.1}^^
{$fmt b|выход} {$fmt tab,50%}-- выйти^
{$fmt b|искать <идентификатор>} {$fmt tab,50%}-- поиск по картотеке^
{$fmt b|скан} {$fmt tab,50%}-- начать сканирование артефакта.]];
	Scan = function(s)
		snd_play 'sfx_scan'
		if not instead.tiny then
			fading.set { 'null', delay = 30, max = 60, now = true }
		end
		pn [[{$fmt b|Предметы на столе:}]]
		for k, v in ipairs(objs 'table') do
			pn (v:noun(), '{$fmt tab,30%|}',' -- ',
			   ids[v.nam] or [[неизвестный идентификатор]])
		end
	end;
	Search = function(s, w)
		if w == '17' then -- comp
			search_stat(1, 1)
			p ([[...Хранитель архива поставил компьютер на стол
и включил его...]])
		elseif w == '8703627531' then -- огнетушитель
			search_stat(213, 1)
			p [[...Ты яростно борешься с пламенем. Наконец, пожар потушен!...]]
		elseif w == '7691' then -- wheat
			search_stat(5, 1)
			p [[...Ты сорвал несколько колосков и
	растёр их в ладонях, собрав зёрна...]];
		elseif w == '9236123121' then -- suit
			search_stat(507, 1)
			p [[..Не без
опасения ты снимаешь скафандр. Вдыхаешь воздух полной
грудью. Кажется, всё в порядке!..]]
		elseif w == '7220342721' then
			search_stat(173, 1)
			p [[... -- Пап, а ты когда вернёшься? -- Лиза
крутилась в кресле пилота, разглядывая приборы.^
-- Через месяц буду дома. А пока меня нет, слушайся маму. Хорошо?^
-- Я всегда слушаюсь маму!^
-- Я знаю, но все-таки...^
-- О, а это моя фотография! Зачем она тут?^
-- Ну, просто я тебя очень люблю...]]
		elseif w == '9333451239' then
			search_stat(12, 2)
			if bomb_cancel then
			p [[... Хуан вскрыл крышку контрольного блока и
заложил бомбу глубоко внутрь. Потом аккуратно закрепил крышку на
месте. ^^Ему очень не нравилось то, что он был вынужден делать. Особенно, после того
как побывал в рубке и увидел фото. В тот момент, уже забытые воспоминания о странном голосе
в голове нахлынули на него с новой силой.]];
			p [[^^... Царапая руки и чертыхаясь Хуан вытаскивал
бомбу обратно из контрольного блока. Наконец, бомба была извлечена и Хуан положил её в сумку с инструментом.^^Хуан -- не
убийца!]];
			else
			p [[... Хуан вскрыл крышку контрольного блока и
заложил бомбу глубоко внутрь. Потом аккуратно закрепил крышку на
месте. ^^Ему не очень нравилось то, что он был вынужден делать. Особенно, после того
как побывал в рубке и увидел фото. Но он старался гнать
подобные мысли.^^Когда ворота будут взорваны, начало борьбы против
угнетателей будет положено! Димидий должен стать свободным, новым, счастливым
миром! Пусть ради новой жизни он станет убийцей, но на себя Хуану -- наплевать!...]];
			p [[^^... Когда Хуан из новостей узнал что бомба
взорвалась позже, уже после входа корабля в гиперпространство, за одну
секунду его мир был разрушен... Он убийца, без оправданий. Он, словно
мёртвый, шёл по улице не разбирая пути...]];
			know_bomb = true
			end
		else
			if tonumber(w) then
				p [[Информация в картотеке для данного
объекта отсутствует.]]
			else
				p [[Неверный идентификатор.]];
			end
		end
	end;
	enter = function()
		_'@compass':disable()
	end;
	ExitComp = function(s)
		move(pl, 'under')
		move(pl, '#chair')
		_'@compass':enable()
	end;
}

Verb ({"пом/ощь", "Help" }, _'computer')
Verb ({"вых/од,выйти,встать", "ExitComp" }, _'computer')
Verb ({"скан/ировать", "Scan" }, _'computer')
Verb ({"поиск,иск/ать", "* :Search" }, _'computer')
Verb ({"осм/отреть", "Look" }, _'computer')
Verb {
	"push,move,press,shift",
	"{noun} forward: Push",
}

room {
	-"комната";
	title = "В башне";
	nam = "intower";
	out_to = "#pass";
	old_pic = false;
	enter = function(s, f)
		if f ^ 'tree' then
			s.old_pic = get_pic()
		end
		set_pic 'intower'
	end;
	exit = function(s, t)
		if t ^ 'шпиль' then
		--	set_pic(s.old_pic)
		end
	end;
	dsc = [[Ты находишься внутри просторной комнаты цилиндрической
формы. В полу комнаты ты видишь круглую огороженную шахту, сквозь центр которой
проходит рельс. В стене есть проход, сквозь который ты видишь зелёное
поле и одинокое дерево на нём.]];
	compass_look = function(s, t)
		if t == 'd_to' then
			mp:xaction("Exam", _'#hole')
			return
		end
		if t == 'u_to' then
			mp:xaction("Exam", _'#rail')
			return
		end
		return false
	end;
	before_Walk = function(s, to)
		if not seen 'platform' then
			return false
		end
		if not pl:inside'platform' and (to ^ '@u_to' or to ^
		'@d_to') then
			move(pl, 'platform')
		end
		if to ^ '@u_to' then
			p [[Ты нажимаешь на кнопку и платформа,
с неожиданно высоким ускорением, начинает свой подъём.]]
			set_pic 'tower'
			if s:once 'up' then
				p [[^^
Перед твоими глазами мелькают этажи: 10, 50, 100.. Сколько их всего? Ты пытаешься
рассмотреть хоть что-то и, кажется, видишь полки с
книгами.^^
Книги, бесконечная череда книжных полок! Потом скорость
возрастает настолько, что ты перестаешь что-либо различать... Проходят
минуты, платформа замедляет свой ход и вот -- ты оказываешься на вершине
башни.]];
			end
			snd_play 'sfx_platform'
			move('platform', 'top')
			return
		elseif to ^ '@d_to' then
			p [[Ты нажимаешь на кнопку и платформа,
с неожиданно высоким ускорением, начинает свой спуск.]]

			if s:once 'down' then
				p [[^^В шахте темно, и ты не видишь
что находится на этажах, которые ты пролетаешь так быстро. Ты видишь
лишь тысячи разноцветных огоньков. Словно светлячки, они проносятся
мимо тебя. Наконец, платформа замедляет свой ход и ты оказываешься в
полутёмной комнате.]]
			end
			move('platform', 'under')
			snd_play 'sfx_platform'
			return
		end
		return false
	end;
	obj = {
		door {
			nam = '#pass';
			-"проход,дерев*,поле*";
			door_to = 'шпиль';
			description = [[Ты понимаешь, что оказался
внутри башни.]];
		}:attr 'scenery,open';
		obj {
			-"рычаг";
			description = [[Рычаг установлен рядом с
шахтой.]];
			before_Push = function(s)
				p [[Ничего не происходит.]]
			end;
			before_Pull = function(s)
				if not seen 'platform' then
					p [[Ты дёргаешь за рычаг и
сразу же слышишь нарастающий шум откуда-то сверху. Через
несколько минут в комнату по рельсу спускается платформа.]]
					snd_play 'sfx_platform'
					move('platform', here())
				else
					p [[Ничего не происходит.]]
				end
			end;
		}:attr'static';
		obj {
			-"шахта,дыра,загражд*|отверстие";
			nam = '#hole';
			description = [[Шахта огорожена невысоким заграждением. Ты подходишь к краю и
смотришь вниз, но видишь только бесконечную череду перегородок.]];
			before_LetIn = function(s, w)
				if w == pl then
					p [[Шахта глубокая!]]
					return
				end
				return false
			end;
			after_LetIn = function(s, w)
				p ([[Ты выбрасываешь ]], w:noun(), " в шахту.")
				move(w, 'under')
			end;
		}:attr 'scenery,container,open,enterable';
		obj {
			-"рельс/мр";
			nam = '#rail';
			description = [[Зубчатый рельс ведёт
из шахты наверх. Ты задираешь голову и видишь бесконечную череду переборок.]];
		}:attr'static,concealed';
	};
}

function game:after_Taste()
	p [[What are strange ideas?]]
end

function game:after_Smell()
	p [[Nothing interesting.]]
end

game['before_Taste,Eat,Talk'] = function()
	if _'suit':has'worn' then
		p [[It's impossible in a spacesuit.]]
	else
		return false
	end
end

function game:before_Listen()
	if _'suit':has'worn' then
		p [[In a spacesuit, you can't hear the outside world well.]]
	else
		return false
	end
end

function game:before_Shout()
	if _'suit':has'worn' then
		p [[In a spacesuit you will go deaf.]]
	else
		return false
	end
end

function game:after_Sing()
	p [[You hum a melody to yourself.]]
end

function game:after_Shout()
	p [[You decided to chill out by screaming a little.]]
end

function game:before_Smell()
	if _'suit':has'worn' then
		p [[You don't smell in a spacesuit.]]
	else
		return false
	end
end

function game:Touch()
	if _'suit':has'worn' then
		p [[It is inconvenient to do this in a spacesuit.]]
	else
		return false
	end
end

obj {
	"beard";
	nam = "beard";
	description = [[You're just too lazy to shave. You don't care about your appearance at all]];
	after_Touch = [[You scratched your beard, not without pleasure.]];
}:attr 'static';

pl.description = function(s)
	if ill > 0 then
		p [[You look at your hands and you see something strange.
		They become transparent. Let the light through. Are you... Disappearing?]];
		return
	end
	p [[You are a deep space exploration geologist.
	The gray hair in the beard, the tired look and the wrinkles on the face proclaimed you a middle-aged man.]]
	if _'suit':has'worn' then
		p [[You're in a spacesuit now.]]
	end
	if here() ^ 'ship1' then
		p [[Your six-month contract for Dimidius is over, it's time to get home.
		For six months you worked under a contract at Dimidius, exploring uranium deposits. 
        But now the contract is over.]]
	end;
end
pl.scope = std.list { 'beard' }

VerbExtendWord {
	"#Touch",
	"scratch";
}

VerbExtendWord {
	"#Walk",
	"return to"
}

Verb {
	"leave",
	"{noun} : Exit",
}

function mp:before_Exting(w)
	if not have 'огнетушитель' then
		p [[You have nothing to extinguish.]]
		return
	end
	return false
end

function mp:after_Exting(w)
	if not w then
		p [[There is nothing to extinguish.]]
	else
		p ([[Extinguish ]], w:the_noun(), "?")
	end
end
function tel_number(w)
	w = w:gsub("[^0-9]+", "")
	return tonumber(w)
end

function mp:before_Ring(w)
	if not here() ^ 'top' then
		p [[Тут нет телефона.]]
		return
	end
	if _'suit':has'worn' then
		p [[В скафандре?]]
		return
	end
	if w and not tel_number(w) then
		p ([[Неправильный номер: ]]..w, ".")
		return
	end
	if not w then
		p [[Попробуй {$fmt em|набрать <номер>}. Например,
	{$fmt em|набрать 12345}.]];
		return
	end
	return false
end

function game:before_Attack(w)
	if w == pl then
		if _'suit':has'worn' then
			p [[Скафандр защищает тебя.]]
			return
		end
		p [[Сдаешься? Так просто?]]
		return
	end
	return false
end

function mp:after_Ring(w)
	p [[Не отвечает...]]
end

Verb {
	"extinguish,put out";
	": Exting";
	"{noun}/scene: Exting";
}

Verb {
	"shout,cry";
	": Shout";
}

Verb {
	"набрать,[|по]звон/ить";
	"* : Ring";
};

function init()
	mp.togglehelp = true
	mp.autohelp = false
	mp.autohelp_limit = 8
	mp.compl_thresh = 1
	set_pic "gate"
	mus_play 'bgm_going_home'
	snd_play('sfx_ship_ambience_loop', true)
	snd_play('sfx_ready_blip_loop', true)
	walk 'ship1'
end
function start()
	snd_start()
	if not instead.tiny then
--		fading.set { 'crossfade', now = true }
	end
end
if not instead.tiny then
function mp:onedit(...)
	if here() ^ 'computer' then
		snd.play('snd/sfx_keyboard_key_press.ogg', 4, 1)
	end
end
end
