--$Name: Архив
--$Version: 0.1
--$Author:Пётр Косых

require "fmt"

fmt.dash = true
fmt.quotes = true

require 'parser/mp-ru'


-- чтоб можно было писать "на кухню" вместо "идти на кухню"

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

room {
	-"рубка|Резвый|корабль";
	title = "рубка";
	nam = 'main';
	dsc = [[В рубке "Резвого" тесно. Сквозь узкие окна в кабину
	проникают косые лучи звезды 51 Peg, освещая приборную
	панель. Всё подготовлено, чтобы сделать прыжок. Но всё-таки,
	ты хочешь ещё раз осмотреть приборы.]];
	out_to = function(s)
		p [[Не время гулять по кораблю. Ты готовишься совершить прыжок. Все приборы
находятся в рубке.]]
	end;
	obj = {
		Distance {
			-"звезда|Peg";
			description = [[Она так похожа на Солнце... Не
смотря на то, что "51 Peg" находится всего в 50 световых годах от Земли,
только сейчас, в 2220-м, началось освоение ресурсов "Димидия". На
этой экзопланете были найдены огромные запасы нефти.^^
Твой полу-годовой контракт завершился, пора возвращаться домой. ]];
		};
	}
}

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
