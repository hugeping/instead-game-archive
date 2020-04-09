--$Name: Архив
--$Version: 0.1
--$Author:Пётр Косых

require "fmt"

fmt.dash = true
fmt.quotes = true

require 'parser/mp-ru'

game.dsc = [[{$fmt b|АРХИВ}^^Интерактивная новелла.^^Для
помощи, наберите "помощь" и нажмите "ввод".]];

-- чтоб можно было писать "на кухню" вместо "идти на кухню"
game:dict {
	["Димидий/мр,C,но"] = {
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

Careful = Class {
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" then
			return false
		end
		p ("Лучше оставить ", s:it 'вн', " в покое.")
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

room {
	-"рубка|Резвый|корабль";
	title = "рубка";
	nam = 'main';
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
		Distance {
			-"звезда|солнце|Peg";
			description = [[Несмотря на то, что "51 Peg"
находится всего в 50 световых годах от Земли,
только сейчас, в 2220-м, началось освоение ресурсов "Димидия". На
этой экзопланете были найдены большие месторождения урана.^^
Твой полугодовой контракт на "Димидии" завершился, пора возвращаться домой. ]];
		};
		Careful {
			-"окна|иллюминаторы";
			description = [[Сквозь толстые окна ты видишь
фиолетовую планету. Это -- Димидий.]];
		};
		Distance {
			-"планета|Димидий";
			description = [[Пол года ты работал по контракту на
"Димидии", занимаясь разведкой месторождений урана. Но теперь контракт
завершён.]];
		};
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
end
