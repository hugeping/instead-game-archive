--$Name: Архив
--$Version: 0.1
--$Author:Пётр Косых

require "fmt"
require "link"

function set_mus(f)
end

if not instead.tiny then
require "autotheme"
require "timer"
require "sprite"
require "theme"
require "snd"
timer:set(350)
local h = instead.font_scaled_size(theme.get 'win.fnt.size')
local blank = sprite.new(1, h * 1.2)
local cur_on = false
function game:timer()
	if cur_on or mp.autohelp then
		mp.cursor = fmt.b '|' .. fmt.top(fmt.img(blank))
	else
		mp.cursor = fmt.top(fmt.img(blank));
	end
	cur_on = not cur_on
	return true, false
end
function set_mus(f)
	snd.music('mus/'..f..'.ogg')
end
end

fmt.dash = true
fmt.quotes = true

require 'parser/mp-ru'

function set_pic(f)
	game.pic = 'gfx/'..f..'.jpg'
end

game.dsc = [[{$fmt b|АРХИВ}^^Интерактивная новелла-миниатюра для
выполнения на средствах вычислительной техники.^^Для
помощи, наберите "помощь" и нажмите "ввод".]];

-- чтоб можно было писать "на кухню" вместо "идти на кухню"
game:dict {
	["Димидий/мр,C,но,ед"] = {
		"Димидий/им",
		"Димидий/вн",
		"Димидия/рд",
		"Димидию/дт",
		"Димидием/тв",
		"Димидии/пр",
	}
}

function game:before_Any(ev, w)
	if ev == "Ask" or ev == "Say" or ev == "Tell" or ev == "AskFor" or ev == "AskTo" then
		p [[Попробуйте просто поговорить.]];
		return
	end
	return false
end

function mp:pre_input(str)
	local a = std.split(str)
	if #a <= 1 or #a > 3 then
		return str
	end
	if a[1] == 'в' or a[1] == 'на' or a[1] == 'во' or
		a[1] == "к" or a[1] == 'ко' then
		return "идти "..str
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
		p ([[Ты можешь пойти в ]], std.ref(s.walk_to):noun('вн'), '.');
	end;
	default_Event = 'Walk';
}:attr'scenery,enterable';

Careful = Class {
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" or
	ev == 'Listen' or ev == 'Smell' then
			return false
		end
		p ("Лучше оставить ", s:noun 'вн', " в покое.")
	end;
}:attr 'scenery'

Distance = Class {
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" then
			return false
		end
		p ("Но ", s:noun(), " очень далеко.");
	end;
}:attr 'scenery'

Furniture = Class {
	['before_Push,Pull,Transfer,Take'] = [[Пусть лучше
	{#if_hint/#first,plural,стоят,стоит} там, где
	{#if_hint/#first,plural,стоят,стоит}.]];
}:attr 'static'

Prop = Class {
	before_Default = function(s, ev)
		p ("Тебе нет дела до ", s:noun 'рд', ".")
	end;
}:attr 'scenery'

Distance {
	-"звёзды/мн,но,жр";
	nam = 'stars';
	description = [[Звёзды смотрят на тебя.]];
}

obj {
	-"космос|пустота";
	nam = 'space';
	description = [[Выход человечества в гиперпространство не сильно
приблизил звёзды. Ведь прежде чем построить ворота у новой звёздной системы,
нужно добраться до неё. Полёт до неисследованной звезды по
прежнему занимает годы или даже десятки лет.]];
	obj = {
		'stars';
	}
}:attr 'scenery';

global 'radio_ack' (false)
global 'rain' (true)

Careful {
	nam = 'windows';
	-"окна|иллюминаторы";
	description = function(s)
		if here().planet then
			if rain then
				p [[Всё что ты видишь из рубки, это поле
	пшеничного цвета и дождливое небо.]]
			elseif bomb_cancel then
				p [[Как странно, в окнах ты не видишь пейзаж планеты!]];
			else
				p [[Всё что ты видишь из рубки, это поле
	пшеничного цвета и бирюзовое небо.]]
			end
		elseif here() ^ 'burnout' then
			p [[Сквозь толстые окна ты видишь
	сияние гиперпространства.]];
			if not _'engine'.flame then
				_'hyper2':description()
			end
		elseif here() ^ 'ship1' then
			p [[Сквозь толстые окна ты видишь
фиолетовую планету. Это -- Димидий.]];
		end
	end;
	found_in = { 'ship1', 'burnout' };
};

obj {
	-"фото|фотография";
	nam = 'photo';
	init_dsc = [[К углу одного из окон прикреплена
фотография.]];
	description = [[Это фотография
твоей дочери Лизы, когда её было всего 9 лет. Сейчас она совсем взрослая.]];
	found_in = { 'ship1', 'burnout' };
};

Careful {
	nam = 'panel';
	-"приборы|панель";
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
			p [[Все системы корабля в
норме. Можно толкнуть рычаг тяги.]];
		elseif here() ^ 'burnout' then
			if _'burnout'.planet then
				p [[Анализ атмосферы показывает, что
	воздух пригоден для дыхания.]]
			end
			if _'engine'.flame then
				p [[Пожар в машинном отсеке!]];
			end
			if s.till > 20 then
				p [[Неполадки во 2-м
	двигателе.]];
			elseif s.till > 15 then
				p [[1-й и 2-й двигатель отказали. Сбой системы стабилизации.]];
			else
				p [[Все двигатели вышли из
	строя.]]
				s.stop = true
			end
			if _'engine'.flame then
				p [[Это очень опасно!]]
			end
			if s.till and not _'burnout'.planet then
				p ([[^^До конца перехода ]], s.till,
	[[ сек.]])
			end
			_'throttle':description()
		end
	end;
	found_in = { 'ship1', 'burnout' };
	obj = {
		obj {
			-"рычаг|тяга|рычаг тяги";
			nam = 'throttle';
			ff = false;
			['before_SwitchOn,SwitchOff'] = [[Рычаг тяги можно
	тянуть или толкать.]];
			description = function(s)
				if here() ^ 'ship1' or bomb_cancel then
					p [[Массивный
рычаг тяги стоит на нейтральной позиции.]];
				elseif here() ^ 'burnout' then
					if s.ff then
						pr [[Тяга включена]];
						if _'panel'.stop then
							pr [[, только
	двигатели больше не работают]]
						end
						pr '.'
					else
						p [[Тяга выключена.]]
					end
				end
			end;
			before_Push = function(s)
				if not radio_ack then
					p [[Ты совсем
забыл связаться с диспетчерской. Для этого нужно включить радио.]];
				elseif here() ^ 'ship1' then
					s.ff = true
					walk 'transfer'
				elseif here() ^ 'burnout' then
					if bomb_cancel then
						if _'outdoor':has'open' then
							p [[Может, сначала стоит задраить шлюз?]]
							return
						end
						walk 'happyend'
						set_mus 'jump-memories'
						return
					end
					if not s.ff then
						p [[Ты передвинул рычаг вперёд.]]
					end
					s.ff = true
					p [[Рычаг установлен в позиции
	максимальной тяги.]];
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
					if s.ff then
						if not _'panel'.stop then
							p
	[[Выход из гиперпространства возможен только при достижении кораблём опередлённой скорости.
Остановка двигателей будет означать прерванный переход. И тогда -- пути назад уже не будет!]];
							return
						end
						p [[Ты тянешь рычаг на себя.]]
					end
					s.ff = false
					p [[Рычаг тяги на нейтральной позиции.]]
				end
			end;
		}:attr'static';
		obj {
				-"радио";
			description = [[Радио встроено
в панель управления.]];
			before_SwitchOn = function(s)
				if s:once() then
					p [[-- PEG51,
борт FL510, запрашиваю разрешение на вылет.^
-- ... FL510, вылет разрешаю. Ворота свободны. Счастливого пути!^
-- Принято.]];
					radio_ack = true;
				elseif here() ^ 'burnout' then
					if _'burnout'.planet then
						p [[Одни помехи. Ты
	выключаешь радио.]]
					else
						p [[Радио в
	гиперпространстве не работает.]]
					end
				else
					p [[Ты уже
получил разрешение на вылет.]]
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
			pn [[Ты достаёшь фотографию дочери и закрепляешь её в углу окна. Затем, кладёшь руку на рычаг тяги.]];
		else
			pn [[Ты кладёшь руку на рычаг тяги.]]
		end
	end;
	text = {
		[[Двигаешь ручку от себя до упора.]];
		[[Всполохи гиперпространства за окном оживают...^
На приборной панели начинается (продолжается?) обратный отсчет.]];
		[[25, 24, 23...]],
		[[10, 9, 8, 7...]],
		[[3, 2, 1...]];
		[[Я СКОРО БУДУ!]];
	};
	next_to = 'titles';
}

cutscene {
	noparser = true;
	nam = 'titles';
	title = false;
	enter = function(s)
		set_pic 'crash'
	end;
	dsc = fmt.c[[
{$fmt b|АРХИВ}^^
{$fmt em|Пётр Косых^Май 2020}^
{$fmt em|Музыка: Jump Memories / Keys of Moon}^^
Спасибо вам за прохождение этой небольшой игры!^
Если вам понравилось, вы можете найти похожие игры на:^^
{$link|http://instead-games.ru}^
{$link|https://instead.itch.io}^
{$link|https://metaparser.syscall.ru}^^
А если хотите написать свою историю,^добро пожаловать на:^
{$link|https://instead3.syscall.ru}^^
{$fmt b|КОНЕЦ}
]];
}

room {
	-"рубка|Резвый|корабль";
	title = "рубка";
	nam = 'ship1';
	dsc = [[В рубке "Резвого" тесно. Сквозь узкие окна в кабину
	проникают косые лучи звезды 51 Peg, освещая приборную
	панель. Прямо по курсу -- ворота перехода, парящие над Димидием.^^
Всё подготовлено, чтобы начать переход. Но всё-таки,
	ты хочешь ещё раз осмотреть приборы.]];
	out_to = function(s)
		p [[Не время гулять по кораблю. Ты готовишься совершить переход. Все приборы
находятся в рубке.]]
	end;
	obj = {
		'space',
		'panel',
		Distance {
			-"звезда|солнце|Peg";
			description = [[О том, что вокруг 51 Peg
вращается экзопланета похожая на Землю, было известно очень давно.
И только в 2220-м году здесь были открыты ворота в гиперпространство.
До Земли -- 50 световых лет или 4 перехода. 120 лет экспансии
человечества в дальний космос...]];

		};
		'windows';
		Distance {
			-"планета|Димидий,димиди*";
			description = [[
Димидий стал первой достигнутой планетой, условия жизни на которой
были пригодны для человека. Как только в 2220-м здесь были
установлены ворота, в поисках новой жизни на Димидий ринулись первопроходцы.^^
А ещё через 5 лет на планете были обнаружены богатейшие залежи
урана. Старый мир страдал от нехватки ресурсов, но в нём были
сосредоточены деньги и власть. Поэтому Димидию не суждено было стать
Новой Землёй. Он превратился в колонию.^^
Твой полугодовой контракт на Димидии завершился, пора возвращаться домой.]];
		};
		obj {
			-"лучи";
			description = [[Это лучи местного
солнца. Они скользят по приборной панели.]];
		}:attr'scenery';
		Distance {
			-"ворота|переход";
			description = function(s)
				if s:once() then
					p [[Ворота -- так называется вход
в гиперпространство. Выглядят ворота как 40-метровое кольцо, медленно
вращающееся в пустоте. Ворота в системе 51 Peg открыли в 2220-м. Они
стали 12-ми воротами, построенными за 125 летнюю историю экспансии
		человечества в дальний космос.]];
				else
					p [[Сквозь ворота ты видишь
всполохи гиперпространства.]];
				end
			end;
			obj = {
				Distance {
					-"гиперпространство|всполохи";
					description =
						[[Гиперпространство
было открыто в 2095-м, во время экспериментов
на БСР. Ещё 4 года понадобилось на то, чтобы найти способ
синхронизировать континуум между выходами из гиперпространства.]]
				}:attr 'scenery';
			}
		};
	}
}

cutscene {
	nam = "transfer";
	title = "Переход";
	enter = function()
		set_pic "hyper"
	end;
	text = {
		[[Перед тем, как положить руку на массивный рычаг,
	ты бросил взгляд на фото своей дочери.^
-- С Богом...]];
		[[Ты плавно передвигаешь массивную ручку вперёд и
	наблюдаешь за приближением ворот. За свою 20-летнюю карьеру,
	ты делал это не раз. Корабль вздрагивает, гигантская сила
	втягивает его и вот, ты уже наблюдаешь причудливое
	переплетение огней. Ещё несколько секунд и... БАМ!!!]];
		[[Корабль сотрясает вибрация. Что-то не так? Вибрация
	нарастает. Удар. Ещё удар. Приборная панель расцветает
	россыпью огней.]];
	};
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
	-"рубка|Резвый|корабль";
	title = "рубка";
	nam = 'burnout';
	planet = false;
	transfer = 0;
	enter = function(s)
		if bomb_cancel then
			if s:once 'wow' then
				p [[Войдя в рубку ты заметил странное. Сквозь окна вместо пейзажа ты видишь гиперпространство!]];
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
			"В кабину проникает свет от огней.";
			"Кабина заполняется белым светом.";
			"Кабину заполнил ослепительно-белый свет.";
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
			p [[Рубка заполнена сигналом тревоги.]]
		else
			return false
		end
	end;
	dsc = function(s)
		if s.planet then
			if rain then
				p [[В рубке "Резвого" светло. Приборная панель
бледно отражается в покрытых дождевыми каплями окнах.]];
			else
				if bomb_cancel then
					p [[В рубке "Резвого" тесно. Сквозь окна ты
	видишь сияние гиперпространства.]]
					p [[Показатели приборов -- в норме.]]
				else
					p [[В рубке "Резвого" светло. Сквозь
окна видно золотисто-жёлтое поле под ясным небом.]];
				end
			end
		elseif _'engine'.flame then
			p [[Рубка "Резвого" заполнена сигналом
	тревоги. Нужно осмотреть приборы, чтобы выяснить что
	происходит.]];
		else
			p [[В рубке "Резвого" тесно. Сквозь окна ты
	видишь сияние гиперпространства. Приборная панель неярко
помигивает в тусклом свете.]]
			if not _'engine'.flame and _'panel'.stop and
			not isDaemon('burnout') then
				p [[^^{$fmt em|За окнами ты замечаешь нечто странное...}]]
			end
		end
		p [[^^Ты можешь выйти из рубки.]]
	end;
	out_to = 'room';
	obj = {
		Distance {
			nam = 'hyper2';
			-"гиперпространство,странн*|огни/мн,мр|сияние";
			description = function(s)
				if not _'engine'.flame and _'panel'.stop then
					p [[Ты видишь три сверкающих огня,
которые танцуя приближаются к твоему кораблю. Или это ты
движешься к ним?]]
					enable '#trinity'
					DaemonStart("burnout");
					set_pic 'trinity'
				else
					p [[Переход ещё не завершён. Эта мысль
мешает тебе наслаждаться великолепным сиянием.]];
				end
			end;
			obj = {
				Distance {
					nam = '#trinity';
						-"свет";
					description = [[Ослепительно белый свет
заполняет кабину.]];
				}:disable();
			};
		};
		'panel';
		'windows';
	};
}

room {
	-"трюм";
	title = 'трюм';
	nam = 'storage';
	u_to = function(s)
		if ill > 0 then
			p [[У тебя нет сил, чтобы подняться наверх.]]
			return
		end
		return  'room';
	end;
	dsc = [[Отсюда ты можешь подняться наверх или выйти в шлюз.]];
	out_to = 'gate';
	obj = {
		Path {
			-"шлюз";
			walk_to = 'gate';
			desc = [[Ты можешь выйти в шлюз.]];
		};
		Furniture {
			-"контейнеры,ящики";
			description = [[Это контейнеры с оборудованием.]];
			before_Open = [[Контейнеры опечатаны. Не стоит
их открывать.]];
		}:attr'openable';
	};
}

door {
	-"дверь,шлюзовая дверь";
	nam = 'outdoor';
	['before_Close,Open,Lock,Unlock'] = [[Дверь
открывается и закрывается с помощью рычага.]];
	door_to = function(s)
		if here() ^ 'gate' then
			return 'planet'
		else
			return 'gate'
		end
	end;
	description = function()
		p [[Массивная шлюзовая
дверь.]];
		return false
	end;
	obj = {
		obj {
			-"красный рычаг,рычаг/но";
			nam = '#lever';
			description = [[Ярко-красный массивный
рычаг.]];
			dsc = [[Справа от двери -- красный рычаг.]];
			before_Pull = function(s)
				if not _'burnout'.planet then
					p [[Открыть шлюзовую дверь во
время перехода? Это самоубийство!]]
					return
				end
				if _'outdoor':has'open' then
					_'outdoor':attr'~open'
					p
					[[С шипящим звуком шлюзовая дверь закрылась.]]
				else
					_'outdoor':attr'open'
					p
					[[С шипящим звуком шлюзовая
дверь открылась.]]
					start_ill()
				end
			end;
		}:attr 'static';
	}
}:attr 'locked,openable,static,transparent';
global 'onair' (false)
room {
	-"шлюз";
	nam = 'gate';
	title = "шлюз";
	dsc = [[Ты находишься в шлюзовом отсеке.^^Ты можешь вернуться в
трюм или выйти наружу.]];
	in_to = "storage";
	out_to = "outdoor";
	onexit = function(s, to)
		onair = not (to ^ 'storage')
		if to ^ 'storage' and false then
			if _'outdoor':has'open' then
				p [[Сначала нужно закрыть шлюзовую
дверь.]]
				return false
			end
		end
	end;
	obj = {
		obj {
			-"шкаф";
			locked = true;
			description = function(s)
				p [[Это шкаф для хранения скафандра.]]
				return false
			end;
			obj = {
				obj {
					-"скафандр";
					nam = "suit";
					description = [[Скафандр
выглядит массивным, но на самом деле он довольно лёгкий.]];
					before_Disrobe = function(s)
						if here().flame then
							p [[И
задохнуться от пожара?]]
							return
						end
						return false
					end;
					after_Disrobe = function(s)
						if onair and s:once 'skaf' then
							p [[Не без
опасения ты снимаешь скафандр. Вдыхаешь воздух полной
грудью. Кажется, всё в порядке!]];
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
			-"трюм";
			walk_to = 'storage';
			desc = [[Ты можешь вернуться в трюм.]];
		};
	};
}
room {
	-"коридор";
	title = 'коридор';
	nam = 'room';
	dsc = [[Отсюда ты можешь попасть в рубку и к двигателям.]];
	d_to = "#trapdoor";
	before_Sleep = [[Не время спать.]];
	before_Smell = function(s)
		if _'engine'.flame then
			p [[Пахнет гарью.]];
		else
			return false
		end
	end;
	obj = {
		Furniture {
			-"кровать";
			description = [[Стандартная кровать. Такая
стоит почти во всех небольших судах, типа "Резвого".]];
		}:attr 'enterable,supporter';
		door {
			-"люк";
			nam = "#trapdoor";
			description = function(s)
				p [[Люк ведёт вниз.]]
			end;
			door_to = 'storage';
		}:attr 'static,openable';
		Prop { -"стена|стены/мн,но,жр" };
		obj {
			-"огнетушитель,баллон";
			full = true;
			init_dsc = [[На стене закреплён огнетушитель.]];
			nam = "огнетушитель";
			description = function(s)
				p [[Баллон ярко-красного
цвета. Разработан специально для использования на космическом
флоте.]];
				if not s.full then
					p
					[[Огнетушитель пуст.]]
				end
			end;
		};
		Path {
			-"рубка";
			walk_to = 'burnout';
			desc = [[Ты можешь пойти в рубку.]];
		};
		Path {
			-"двигатели|машинный отсек";
			walk_to = 'engine';
			desc = [[Ты можешь пойти к двигателям.]];
		};
	}
}

room {
	-"машинный отсек,отсек";
	title = "Машинный отсек";
	nam = 'engine';
	flame = true;
	before_Smell = function(s)
		if s.flame then
			p [[Пахнет гарью.]];
		else
			return false
		end
	end;
	onenter = function(s)
		if s.flame and _'suit':hasnt 'worn' then
			p [[В машинном отсеке пожар! Ты не можешь
находиться там из-за едкого дыма.]]
			return false
		end
	end;
	dsc = function(s)
		if s.flame then
			p [[В машинном отсеке пылает огонь! Всё в дыму!]];
		elseif bomb_cancel then
			p [[Ты находишься в машинном
отсеке. Контрольный блок мерцает индикаторами.]]
		else
			p [[Ты находишься в машинном
отсеке. Обгоревший контрольный блок полностью разрушен.]]
		end
		p [[^^Ты можешь выйти из машинного отсека.]]
	end;
	out_to = 'room';
	after_Exting = function(s, w)
		if not s.flame then
			p [[Пожар уже потушен.]]
			return
		end
		if not w or w ^ '#flame' or w == s or w ^ '#control' then
			_'огнетушитель'.full = false
			s.flame = false
			p [[Ты яростно борешься с пламенем. Наконец,
пожар потушен!]]
			remove '#flame'
		else
			return false
		end
	end;
	obj = {
		obj {
			nam = '#flame';
			-"огонь,пожар|пламя|дым";
			before_Exting = function()
				return false
			end;
			before_Default = [[Пожар в машинном
отсеке!]];
		}:attr 'scenery';
		obj {
			nam="#control";
			-"контрольный блок,блок,индикатор*";
			description = function(s)
				if here().flame then
					p [[Контрольный блок скрыт в
пламени!]];
				elseif bomb_cancel then
					p [[Контрольный блок
функционирует!]]
				else
					p [[Контрольный блок -- система
управления двигателями корабля. Он сильно обгорел, но не это
привлекает твоё внимание. В центре блока зияет дыра!]];
					enable '#дыра'
					if _'осколки':has 'concealed' then
						_'осколки':attr
						'~concealed';
						p [[^^Ты замечаешь осколки.]]
					end
				end
			end;
			obj = {
				obj {
					nam = '#дыра';
					-"дыра|отверстие";
					description = [[Похоже,
здесь произошёл взрыв...]];
				}:attr 'scenery':disable();
			};
		}:attr 'static,concealed';
		obj {
			nam = 'осколки';
			-"осколки/но|куски/но|кусочки/но";
			after_Smell = [[Странный запах...]];
			after_Touch = [[Края оплавлены. Не похоже на дюраль.]];
			description = function(s)
				if have(s) then
					p [[Оплавленные
осколки. Тяжёлые. Странно, не похоже на дюраль... ]];
				else
					p [[Небольшие чёрные кусочки металла.]]
				end
			end;
		}:attr 'concealed';
		Path {
			-"коридор";
			walk_to = 'room';
			desc = [[Ты можешь выйти в коридор.]];
		};
	}
}

Distance {
	nam = "sky2";
	-"небо|дождь|дымка";
	description = function(s)
		if rain then
			p [[Небо затянуто дождливой
	дымкой.]]
		else
			p [[Небо ясное, залито голубой бирюзой.]]
		end
		p [[Время от времени, небо озаряется всполохами.]];
	end;
	before_Listen = function(s)
		if rain then
			p [[Ты слышишь шум дождя.]];
			return
		elseif s:multi_alias() == 2 then
			p [[Но дождь закончился!]]
			return
		end
		p [[Ты не слышишь ничего необычного.]]
	end;
	obj = {
		Distance {
			-"всполохи|гиперпространство";
			description = [[Планета в гиперпространстве? Невероятно!]];
		};
		obj {
			-"солнце";
			before_Default = [[Странно, но ты не видишь
	солнца, хотя сейчас день.]];
		}:attr 'scenery';
	}
};

Distance {
	nam = 'planet_scene';
	-"планета|ландшафт|поле|дымка|горизонт";
	description = function()
		if rain then
			p [[Края поля золотисто-пшеничного цвета
	скрываются в дождливой дымке.]];
		else
			p [[Золотисто-пшеничное поле простирается до горизонта.]];
		end
	end;
	obj = {
		'sky2';
		obj {
			-"капли";
			description = function(s)
				if rain then
					p [[Некоторое время ты отрешённо
	следишь за каплями, скатывающимися по стеклу.]];
				else
					p [[Но сейчас не идёт дождь.]]
				end
			end;
		}:attr'scenery';
	};
}

cutscene {
	nam = "transfer2";
	title = "...";
	enter = function(s)
		set_pic 'flash'
	end;
	text = {
		[[Ослепительный свет заполнил всё вокруг. Ты потерялся
	в нём, растворился -- словно тебя никогда и не было... Корабль
	содрогается от удара. Это конец?]];
		[[Тишина...]];
		[[Капли на стекле. Крупные. Медленно стекают по косым
	окнам, заливают обшивку корабля. Шум дождя -- почему ты его не
	слышишь?]];
	};
	exit = function(s)
		_'burnout'.planet = true
		remove 'hyper2'
		p [[Ты медленно приходишь в себя. Ну конечно, ты внутри "Резвого" и его
	обшивка не пропустит такой слабый звук, как удар капель. Как жаль...]];
		move('planet_scene', 'burnout')
		set_pic 'crash'
	end;
}

obj {
	nam = 'ship';
	-"корабль,Резвый,резв*";
	description =  function(s)
		p [[Не очень мягкая посадка, если судить по борозде,
	которую он оставил позади себя в земле. Но корабль
	цел.]]
	end;
	before_Enter = function(s)
		mp:xaction("Enter", _'outdoor')
	end;
	obj = {
		obj {
			-"борозда";
			description = [[Не очень глубокая. Каким-то
	образом, корабль выбросило прямо на поле...]];
		}:attr'scenery';
	}
}:attr 'scenery,enterable';

obj {
	nam = 'wheat';
	-"зёрна/мн|зерно";
	description = [[Жёлтые крупные зёрна, похожие на
	пшеничные. Кажется, что в них сосредоточена энергия.]];
	['after_Smell'] = function(s)
		if rain then
			p [[Тебе нравится запах мокрого зерна.]];
		else
			p [[Тебе нравится запах зерна.]];
		end
	end;
	after_Eat = function(s)
		if ill > 0 then
			DaemonStop 'planet'
			if ill > 1 then
				p [[Ты съедаешь зёрна. Через некоторое время
	ты чувствуешь, как странная слабость отступает.]]
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
	title = "В поле";
	-"поле";
	description = function(s)
		if rain then
			p [[Края поля золотисто-пшеничного цвета
	скрываются в дождливой дымке.]]
		else
			p [[Поле выглядит бескрайним.]]
		end
		p [[Ты видишь как колосья, похожие
	на пшеницу, колышутся под несильным ветром.]];
		return false
	end;
	obj = {
		obj {
			-"колосья,колоски/мр,мн|пшеница";
			description = [[Ты видишь как колосья
	колышутся под несильным ветром.]];
			["before_Eat,Tear,Take,Pull"] = function(s)
				p [[Ты сорвал несколько колосоков и
	растёр их в ладонях, собрав зёрна.]];
				take 'wheat'
			end;
		}:attr 'concealed';
	};
	before_LetIn = function(s, w)
		if w == pl and here() ^ 'planet' then
			p "Ты зашел в заросли желтых колосьев."
			move(pl, s)
			return
		end
		return false
	end;
--	scope = { 'ship' };
	after_LetIn = function(s, w)
		p ([[Ты бросаешь ]], w:noun 'вн', [[ в поле.]])
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
		p [[Неподалёку на западе ты видишь дерево.]];
		p [[На севере ты
	замечаешь высокий шпиль, устремлённый в небо.]];
	end;
	n_to = 'tower';
	w_to = '#tree';
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
	востоке от башни растёт одинокое дерево.]];
		if not visited 'tree' then
			p (fmt.em [[Ты видишь рядом с деревом
	человеческую фигурку в плаще!]])
		end
		p [[^^Ты можешь вернуться на юг.]];
	end;
	exit = function(s, t)
		if t ^ 'planet' then
			p [[Ты покинул странную башню и отправился на
юг, к своему кораблю.]];
			if rain then
				p [[Пока ты шёл, небо очистилось и дождь
закончился.]];
				rain = false
			end
		end
	end;
	enter = function(s, f)
		if f ^ 'planet' then
			p [[Ты направился на север. Прошло по меньшей времени
пол часа, прежде, чем ты оказался у подножия странного сооружения.]];
			if rain then
				p [[Пока ты шёл, небо очистилось и дождь
закончился.]];
				rain = false
			end
		end
	end;
	s_to = "planet";
	in_to = '#tower';
	e_to = '#tree';
	obj = {
		'sky2';
		Distance {
			nam = 'human';
			-"человек|фигурка",
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
	before_Listen = [[Шум моря ласкает твой слух.]];
	before_Smell = [[От запаха соли и водорослей кружится
голова.]];
	before_Swim = [[Не лучшее время для этого.]];
	dsc = [[Ты стоишь на берегу моря. На юге от тебя, прямо на берегу
	растет странное дерево.]];
	s_to = '#tree';
	out_to = '#tree';
	obj = {
		door {
			nam = '#tree';
			-"дерево,ветв*";
			description = [[Одинокое дерево кажется здесь совсем
	лишним.]];
			door_to = 'tree';
		}:attr 'scenery,open';
		obj {
			-"море";
			description = [[Бескрайний простор. Волны,
накатываясь одна на другую, пенятся и разбиваются о берег.]];
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
	-"скала,вид*,край*";
	nam = 'rock';
	title = "У скалистого обрыва";
	before_Listen = [[Ты слышишь свист ветра в скалах.]];
	yes = 0;
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
	out_to = '#tree';
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
	w_to = function(s)
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
			walk 'planet'
			return
		elseif s.ff ^ 'шпиль' then
			if t == 'e_to' then
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
	e_to = function(s)
		if s.ff ^ 'planet' then
			return 'planet';
		end
		return false
	end;
	dsc = function(s)
		p [[Ты стоишь у старого дерева. Его сухие узловатые ветви
	почти лишены листьев.]]
		if s.ff ^ 'шпиль' then
			p [[^^Шпиль башни находится на западе.]];
		elseif s.ff ^ 'planet' then
			p [[^^Твой корабль находится на востоке.]];
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
	text = {
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
		[[-- Хуан, ты уже полетел на Демидий?]];
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
		bomb_cancel = true
	end;
}

cutscene {
	nam = 'photo_call';
	title = "звонок";
	text = {
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
	exit = function(s)
		p [[Взволнованный, ты кладёшь трубку. Это была Лиза! 10 лет назад!]];
	end;
}

room {
	title = "Смотровая комната";
	nam = "top";
	before_Walk = function(s, to)
		if to ^ '@d_to' then
			if not pl:inside'platform' then
				move(pl, 'platform')
			end
			p [[Ты нажимаешь на кнопку и платформа,
с неожиданно высоким ускорением, начинает свой спуск.]]
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
				walk 'photo_call'
			end
		elseif w == '9333451239' then -- осколки
			if visited 'bomb_call' then
				p [[Не стоит беспокоить бедного Хуана.]];
			else
				walk 'bomb_call'
			end
		else
			return false
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
			inside_dsc = "Ты стоишь на платформе.";
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
			-"шпили|башни";
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

room {
	-"комната";
	title = "Компьютерная комната";
	dsc = [[Ты находишься в полутёмной комнате. Единственный
источник света здесь -- включённый компьютер. Компьютер стоит на столе. Рядом со столом стоит кресло.]];
	nam = "under";
	before_Listen  = [[Ты слышишь едва уловимое гудение.]];
	before_Walk = function(s, to)
		if to ^ '@u_to' then
			if not pl:inside'platform' then
				move(pl, 'platform')
			end
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
			p [[...Ты сорвал несколько колосоков и
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
угнетателей будет положено! Демидий должен стать свободным, новым, счастливым
миром! Пусть ради новой жизни он станет убийцей, но на себя Хуану -- наплевать!...]];
			p [[^^... Когда Хуан из новостей узнал что бомба
взорвалась позже, уже после входа корабля в гиперпространство, за одну
секунду его мир был разрушен... Он убийца, без оправданий. Он, словно
мёртвый, шёл по улице не разбирая пути...]];
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
	Exit = function(s)
		move(pl, 'under')
		move(pl, '#chair')
	end;
}

Verb ({"пом/ощь", "Help" }, _'computer')
Verb ({"вых/од,выйти,встать", "Exit" }, _'computer')
Verb ({"скан/ировать", "Scan" }, _'computer')
Verb ({"поиск,иск/ать", "* :Search" }, _'computer')
Verb ({"осм/отреть", "Look" }, _'computer')

room {
	-"комната";
	title = "В башне";
	nam = "intower";
	out_to = "#pass";
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
		if not pl:inside'platform' and (to ^ '@u_to' or to ^
		'@d_to') then
			move(pl, 'platform')
		end
		if to ^ '@u_to' then
			p [[Ты нажимаешь на кнопку и платформа,
с неожиданно высоким ускорением, начинает свой подъём.]]
			if s:once 'up' then
				set_pic 'tower'
				p [[^^
Перед твоими глазами мелькают этажи: 10, 50, 100.. Сколько их всего? Ты пытаешься
рассмотреть хоть что-то и, кажется, видишь полки с
книгами.^^
Книги, бесконечная череда книжных полок! Потом скорость
возрастает настолько, что ты перестаешь что-либо различать... Проходят
минуты, платформа замедляет свой ход и вот -- ты оказываешься на вершине
башни.]];
			end
			move('platform', 'top')
			return
		elseif to ^ '@d_to' then
			p [[Ты нажимаешь на кнопку и платформа,
с неожиданно высоким ускорением, начинает свой спуск.]]
			if s:once 'down' then
				set_pic 'comp'
				p [[^^В шахте темно, и ты не видишь
что находится на этажах, которые ты пролетаешь так быстро. Ты видишь
лишь тысячи разноцветных огоньков. Словно светлячки, они проносятся
мимо тебя. Наконец, платформа замедляет свой ход и ты оказываешься в
полутёмной комнате.]]
			end
			move('platform', 'under')
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
	p [[Что за странные идеи?]]
end

function game:after_Smell()
	p [[Ничего интересного.]]
end

game['before_Taste,Eat,Talk'] = function()
	if _'suit':has'worn' then
		p [[В скафандре это невозможно.]]
	else
		return false
	end
end

function game:before_Listen()
	if _'suit':has'worn' then
		p [[В скафандре ты плохо слышишь внешний мир.]]
	else
		return false
	end
end

function game:before_Shout()
	if _'suit':has'worn' then
		p [[В скафандре ты так оглохнешь.]]
	else
		return false
	end
end

function game:after_Sing()
	p [[Ты напеваешь какую-то мелодию себе под нос.]]
end

function game:after_Shout()
	p [[Ты решил выпустить пар, немного прооравшись.]]
end

function game:before_Smell()
	if _'suit':has'worn' then
		p [[В скафандре ты не чувствуешь запаха.]]
	else
		return false
	end
end

function game:Touch()
	if _'suit':has'worn' then
		p [[В скафандре это делать неудобно.]]
	else
		return false
	end
end

obj {
	-"борода,щетина";
	nam = "beard";
	description = [[Тебе просто лень бриться. Ты совсем не следишь
за своим внешним видом.]];
	after_Touch = [[Ты не без удовольствия почесал бороду.]];
}:attr 'static';

pl.description = function(s)
	if ill > 0 then
		p [[Ты смотришь на свои руки и видишь странное. Они
	становятся прозрачными. Пропускают свет. Ты... Исчезаешь?]];
		return
	end
	p [[Ты -- геолог-разведчик объектов дальнего
космоса. Пробивающаяся седина в бороде, усталый взгляд и морщины на
лице выдают в тебе мужчину средних лет.]]
	if _'suit':has'worn' then
		p [[Сейчас ты в скафандре.]]
	end
	if here() ^ 'ship1' then
		p [[
Пол года ты работал по контракту на
"Димидии", занимаясь разведкой месторождений урана. Но теперь контракт
завершён.]]
	end;
end
pl.scope = std.list { 'beard' }

VerbExtendWord {
	"#Climb",
	"подняться,поднимись";
}

VerbExtendWord {
	"#Touch",
	"[|по]чесать/,[|по]чеши/";
}

VerbExtendWord {
	"#Exit",
	"вернуться"
}

Verb {
	"покин/уть",
	"{noun}/вн,scene : Exit",
}

function mp:before_Exting(w)
	if not have 'огнетушитель' then
		p [[Тебе нечем тушить.]]
		return
	end
	return false
end

function mp:after_Exting(w)
	if not w then
		p [[Тут нечего тушить.]]
	else
		p ([[Тушить ]], w:noun 'вн', "?")
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

function mp:after_Ring(w)
	p [[Не отвечает...]]
end

Verb {
	"туши/ть,[по|за]туши/ть";
	": Exting";
	"{noun}/вн,scene: Exting";
}

Verb {
	"[|за|по|кри]чать,крикн/уть,[|за]орать";
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

	walk 'ship1'
end
