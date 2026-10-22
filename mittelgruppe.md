---
layout: page
title: Mittelgruppe
permalink: /mittelgruppe.html
---

Nachdem der Sphärenschänder in die Ewigkeit verbannt wurde, nachdem das Schicksal nach uns gegriffen hat und das Geheimnis des Erzes den Dienern des Geschädelten verborgen geblieben ist, ist es an der Zeit die letzten Waffen zu sammeln, um auch dieses Zeitalter vor dem Weltenbrand zu retten.

**Wenn es einfach wäre, könnte es ja jeder machen!**

Hier kannst du mehr erfahren über **DIE GEFÄHRTEN**! - Streiter für die alte Welt, die Zwölfe und das Kaiserreich. Und bei Gelegenheit auch für Hexen und Zwerge. Feinde allem Namenlosen und Heptsphärischen und Helden des neuen Zeitalters:

<!-- characters:start -->

{% assign members = site.pages | where: "type", "character" | where: "group", "mittelgruppe" | where: "status", "active" | sort: "author" -%}
{% for c in members -%}
* [{{ c.author }}]({{ c.url | remove: ".html" }}) {{ c.tagline }}
{% endfor %}
<!-- characters:end -->


## Ehemalige Gefährten

Mehrfach haben sich Gefährten neu gefunden oder auch für immer trennen müssen. Wie gesagt -- manch einer schreckt schon vor der Höhe des Berges zurück, wenn er an dessen Fuße steht. Eine kurze Erinnerung:

* In ewig guter Erinnerung werden wir _Wesdragon_ behalten, der im verfluchten Eis von uns hat gehen müssen. Ruhe in Frieden.
* Mit geringerer Trauer wird uns der Tot von _Silia_ in unseren Erinnerungen begleiten. Wir enttarnten sie als Schwarzmagierin.
* _Chesus_ -- die Ratte -- hatte uns elendig verraten und entkam mit der Hilfe der in seinem Pakt gefundenen Mächte. Seine Buße wird kommen!
* Für nur kurze Zeit war _Trautmann_ unser Begleiter. Er hat den tiefen Berg nicht wieder verlassen. Mögest du zu Kor gerufen werden.
* [Coran](/mittelgruppe/coran) Drachenblut, Rondrageweihter und Anhänger Famerlors war lange Jahre Gefährte und ist zum Freund geworden. Gerne sitzen wir an seiner Tafel in Perricum und von Zeit zu Zeit kreuzen sich unsere Pfade.
* _Lariel_ wurde ja ab dem ersten Tag an seine Freiheit geschenkt. Dass er uns wirklich verlassen würde -- nun jeder geht seinen eigenen Weg. Seine Schankstube in Gareth scheint ihm das Reisen nicht mehr erstrebenswert zu machen.
* Einer gar hat sich schlicht eine gute Partie gesucht und wurde im Horasiat fündig. _Wahnfried_ -- möge dein Wunsch nach Müsiggang, Annehmlichkeit und Frieden stets überwiegen und in Erfüllung gehen.
* _Ragnar_ -- hmmm -- irgendwo in einem dunklen Wald könnte man wohl auch ihn wieder treffen.
