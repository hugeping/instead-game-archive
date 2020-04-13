--$Name: Архив
--$Version: 0.1
--$Author:Пётр Косых

require "fmt"

fmt.dash = true
fmt.quotes = true

require 'parser/mp-ru'

game.dsc = [[{$fmt b|АРХИВ}^^Интерактивная новелла-миниатюра для
выполнения на ПЭВМ.^^Для
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
	if a[1] == 'в' or a[1] == 'на' or a[1] == 'во' or a[1] == "к" or a[1] == 'ко' then
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
	['before_Push,Pull,Transfer,Take'] = "Пусть лучше стоит там, где {#if_hint/#first,plural,стоят,стоит}.";
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
приблизил звёзды. Для открытия тоннелей требуется огромное количество
энергии.]];
	obj = {
		'stars';
	}
}:attr 'scenery';

global 'radio_ack' (false)

Careful {
	nam = 'windows';
	-"окна|иллюминаторы";
	description = function(s)
		if here() ^ 'burnout' then
			p [[Сквозь толстые окна ты видишь
	сияние гиперпространства.]];
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
твоей дочери Лизы, когда её было всего 9 лет.]];
	found_in = { 'ship1', 'burnout' };
};

Careful {
	nam = 'panel';
	-"приборы|панель";
	description = function(s)
		if here() ^ 'ship1' then
			p [[Все системы корабля в
норме. Можно толкнуть рычаг тяги.]];
		elseif here() ^ 'burnout' then
			if here().flames then
				p [[Пожар главного двигателя! Это очень
	опасно. Нужно срочно что-то делать!]]
			else
				p [[Пожара нет.]]
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
				if here() ^ 'ship1' then
					p [[Массивный
рычаг тяги стоит на нейтральной позиции.]];
				elseif here() ^ 'burnout' then
					if s.ff then
						p [[Тяга включена.]];
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
					if not s.ff then
						p [[Ты передвинул рычаг вперёд.]]
					end
					s.ff = true
					p [[Рычаг установлен в позиции
	максимальной тяги.]];
				end
			end;
			before_Pull = function(s)
				if here() ^ 'ship1' then
					return false
				elseif here() ^ 'burnout' then
					if s.ff then
						if s:once() then
							p
	[[Перемещение в туннеле возможно только с постоянным
	ускорением -- аналога равномерного движения в нашем
	мире. Остановка двигателей будет означать непредсказуемое
	движение под действием "ветра гиперпространства" или сил
	"смещения покоя",  которые вытолкнут корабль за пределы
	туннеля и тогда -- пути назад уже не будет!]];
							return
						end
						p [[Ты тянешь рычаг на себя.]]
					end
					s.ff = false
					p [[Рычаг тяги на нейтральной позиции.]]
				end
			end;
		}:attr'fixed';
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
					p [[Автоматика и так уже шлёт
	"SOS", а также передаёт все показания приборов. Возможно, это поможет
	комиссии разобраться в причинах аварии. "Возможно" -- так как
	ещё ни один инцидент в гиперпространстве не заканчивался возвращением
	корабля.]]
				else
					p [[Ты уже
получил разрешение на вылет.]]
				end
			end;
		}:attr 'switchable,fixed';
	};
}:attr'supporter';

room {
	-"рубка|Резвый|корабль";
	title = "рубка";
	nam = 'ship1';
	dsc = [[В рубке "Резвого" тесно. Сквозь узкие окна в кабину
	проникают косые лучи звезды 51 Peg, освещая приборную
	панель. Прямо по курсу -- ворота перехода.^^
Всё подготовлено, чтобы сделать прыжок. Но всё-таки,
	ты хочешь ещё раз осмотреть приборы.]];
	out_to = function(s)
		p [[Не время гулять по кораблю. Ты готовишься совершить прыжок. Все приборы
находятся в рубке.]]
	end;
	obj = {
		'space',
		'panel',
		Distance {
			-"звезда|солнце|Peg";
			description = [[Несмотря на то, что 51 Peg
находится всего в 50 световых годах от Земли,
только сейчас, в 2220-м, началось освоение ресурсов Димидия. На
этой экзопланете были найдены большие месторождения урана.^^
Твой полугодовой контракт на Димидии завершился, пора возвращаться домой. ]];
		};
		'windows';
		Distance {
			-"планета|Димидий";
			description = [[Пол года ты работал по контракту на
"Димидии", занимаясь разведкой месторождений урана. Но теперь контракт
завершён.]];
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
вращающееся в пустоте. Для первоначальной прокладки тоннеля в гиперпространстве
требуется огромное количество энергии.]];
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
было случайно открыто 120 лет назад, во время эксперимента
на Большом Струнном Резонаторе. Несколько миссий бесследно пропали,
пока учёные не научились
правильно синхронизировать континуум в двух точках.]];
				}:attr 'scenery';
			}
		};
	}
}

cutscene {
	nam = "transfer";
	title = "Переход";
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
	россыпью огней. А за окнами, вместо черной бездны
	космоса -- алое свечение.]];
	};
	next_to = 'burnout';
}

room {
	-"рубка|Резвый|корабль";
	title = "рубка";
	nam = 'burnout';
	flames = true;
	Listen = function(s)
		p [[Рубка заполнена сигналом тревоги.]]
	end;
	dsc = function(s)
		if s.flames then
			p [[Рубка "Резвого" заполнена сигналом
	тревоги. Нужно осмотреть приборы, чтобы выяснить что
	происходит.]];
		else
			p [[В рубке "Резвого" тесно. Сквозь окна ты
	видишь сияние гиперпространства.]]
		end
		p [[^^Ты можешь выйти из рубки.]]
	end;
	out_to = 'room';
	obj = {
		Distance {
			-"гиперпространство|сияние";
			description =
				[[Переход ещё не завершён. Эта мысль
мешает тебе наслаждаться великолепным сиянием.]];
		};
		'panel';
		'windows';
	};
}

room {
	-'коридор';
	title = 'в коридоре';
	nam = 'room';
	dsc = [[Отсюда ты можешь попасть в рубку и к двигателям.]];
	obj = {
		Path {
			nam = '#livingroom';
			-"рубка";
			walk_to = 'burnout';
			desc = [[Ты можешь пойти в рубку.]];
		};
	}
}

function game:after_Taste()
	p [[Что за странные идеи?]]
end

function game:after_Smell()
	p [[Ничего интересного.]]
end

obj {
	-"борода,щетина";
	nam = "beard";
	description = [[Тебе просто лень бриться. Ты совсем не следишь
за своим внешним видом.]];
}:attr 'static';

pl.description = [[Ты -- геолог-разведчик объектов дальнего
космоса. Пробивающаяся седина в бороде, усталый взгляд и морщины на
лице выдают в тебе мужчину средних лет.]]
pl.scope = std.list { 'beard' }

function init()
	mp.togglehelp = true
	mp.autohelp = false
	mp.autohelp_limit = 8
	mp.compl_thresh = 1
	walk 'ship1'
end
