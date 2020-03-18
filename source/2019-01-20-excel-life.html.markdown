---

title: Excel life
date: 2019-01-20 18:46 GMT
tags: tech

---
This isn't actually all that new - I hacked this together during a
[global day of coderetreat](https://www.coderetreat.org/) in Melbourne in 2012 - but I've mentioned it
to a few people, and thought it'd be fun to put here:

[Conway's Game of Life in Excel](/2019-01-20-excel-life-files/life_in_excel.xslx)

Yes, it's a functioning chunk of [Conway's Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) cellular automaton in
fairly vanilla Excel spreadsheets.

You enter your initial life pattern as cells in tab 1:

![r pentomino pattern 0](2019-01-20-excel-life-files/r_pentomino_0.png)

You then go to tab 2, enter a `0` in the init cell: ![instructions](2019-01-20-excel-life-files/instructions.png) then
recalculate to show the first generation:

![the first generation](2019-01-20-excel-life-files/r_pentomino_1.png)

Then set the init cell to `1` and keep hitting recalculate:

![the second generation](2019-01-20-excel-life-files/r_pentomino_2.png)

and eventually you get a whole pattern:

![a later generation](2019-01-20-excel-life-files/r_pentomino_n.png)

There are far cooler excel hacks out there - but I had fun building this,
especially as it is really quite trivial - just a huge number of cells on two sheets, calculating each life generation based on their neighbours:

```
=IF($B$1=0,IF(SUM(Sheet1!BK12:Sheet1!BM14)=3,1,IF(AND(Sheet1!BL13=1,SUM(Sheet1!BK12:Sheet1!BM14)=4),1,0)),IF(SUM(Sheet3!BK12:Sheet3!BM14)=3,1,IF(AND(Sheet3!BL13=1,SUM(Sheet3!BK12:Sheet3!BM14)=4),1,0)))
```

Also - I have a strange fondness for spreadsheets.  Yes, they can be abhorrent
monstrosities when overused - but they can also be very useful, and very simple,
and the basics of how they are structured and how they operate hasn't really changed
since my dad showed me VisiCalc on his Apple II 35 years ago.  It's the
one programming language that I've used that has that much longevity and consistency!
