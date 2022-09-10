Red [
	Title:	"Red image viewer"
	Author:	"Koba-yu"
	File:	%image-viewer.red
	Needs:	'view
]

pager: make reactor! [
	page: 1
	max: 30
	column: 10
]
repo: #(base-folder: none img-files: none len: none)

go-back: func [pager [object!]][pager/page: pager/page - 1]
go-next: func [pager [object!]][pager/page: pager/page + 1]
set-filename: func [face [object!] index [integer!] base-folder [file!] /local file][
	file: repo/img-files/:index
	face/text: either file [mold replace copy file base-folder ""][""]
]

collect-files: func [path [string!] /local folders folder file base-folder img-files len][
	folders: append reduce [base-folder: to-red-file dirize path] collect [
		foreach file read base-folder [if dir? file [keep rejoin [base-folder file]]]
	]
	img-files: collect [foreach folder folders [
		foreach file read folder [if find [%.jpg %.jpeg] suffix? file [keep rejoin [folder file]]]]
	]
	len: length? img-files
	make map! compose/only [base-folder: (base-folder) img-files: (img-files) len: (len)]
]

calc-current: func [page [integer!] page-max [integer!]][page + ((page - 1) * page-max)]
v: layout compose [
	size 1200x400
	text "Folder:" 40x25 ff: field 800x25
	pf: field 50x25 react later [face/text: mold pager/page] total: text " / N" 80x25
	return
	button "load" [unless empty? ff/text [
			repo: collect-files ff/text
			total/text: rejoin [" / " to-integer round/ceiling (repo/len / pager/max)]
			pager/page: either any [none? pf/text (scan pf/text) <> integer!][1][to-integer pf/text]
			face/parent/selected: none
		]
	]
	return
	text "First file: " text 400x25 loose react later [set-filename face calc-current pager/page pager/max repo/base-folder]
	text "Last file: " text 400x25 loose react later [set-filename face min repo/len (calc-current pager/page pager/max) + pager/max repo/base-folder]
	return
	button "prev" [go-back pager] react [face/enabled?: pager/page <> 1] button "next" [go-next pager] react later [face/enabled?: pager/page <> repo/len]
	return
	img-area: panel 800x800 [] react later [
		blk: copy [space 50x50]
		repeat i pager/max [
			page: ((pager/page - 1) * pager/max) + i
			if repo/len < page [break]

			append blk compose [image (load repo/img-files/:page) loose]

			if (i % pager/column) = 0 [append blk 'return]
		]
		face/pane: layout/tight/only blk
	]
]

v/actors: context [
	on-resize: func [face event][img-area/size: v/size - 5x5]
	on-key: func [face event][
		unless face/selected = ff [
			switch event/key [
				#"p" [go-back pager]
				#"n" [go-next pager]
			]
		]
	]
]

view/no-wait/flags v ['resize]

make-config: func [pager [object!]][make map! compose [max: (pager/max) column: (pager/column)]]
set-pager-value: func [pager [object!] config [map!] word [word!]][
	unless (get in pager word) = val: select config word [set in pager word val]
]

config: make-config pager
config-view: view/no-wait/flags compose [
	size 200x200
	area (mold config) on-change [if all [
			not error? config: attempt [load face/text]
			map? config integer? config/max integer? config/column
			0 < config/max 0 < config/column
		][
			set-pager-value pager config 'max
			set-pager-value pager config 'column
		]
	] react later [
		face/text: mold config
	]
]['resize]
