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

prev-action: func [pager [object!]][pager/page: pager/page - 1]
next-action: func [pager [object!]][pager/page: pager/page + 1]
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

v: layout compose [
	size 1200x400
	text "Folder:" 40x25 f: field 1000x25 button "load" [unless empty? f/text [
			repo: collect-files f/text
			pager/page: 1
			face/parent/selected: none
		]
	] return
	text "N / N" 80x25 react later [face/text: rejoin [pager/page " / " to-integer round/ceiling (repo/len / pager/max)]]
	text "First file: " text 400x25 loose react later [set-filename face pager/page + ((pager/page - 1) * pager/max) repo/base-folder]
	text "Last file: " text 400x25 loose react later [set-filename face min repo/len pager/page * pager/max repo/base-folder] return
	button "prev" [prev-action pager] react [face/enabled?: pager/page <> 1] button "next" [next-action pager] react later [face/enabled?: pager/page <> repo/len] return
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
		unless face/selected = f [
			switch event/key [
				#"p" [prev-action pager]
				#"n" [next-action pager]
			]
		]
	]
]

view/no-wait/flags v ['resize]

make-config: func [pager [object!]][make map! compose [page: (pager/page) max: (pager/max) column: (pager/column)]]
set-pager-value: func [pager [object!] config [map!] word [word!]][
	unless (get in pager word) = val: select config word [set in pager word val]
]

config: make-config pager
config-view: view/no-wait/flags compose [
	size 200x200
	area (mold config) on-change [if all [
			not error? config: attempt [load face/text]
			map? config integer? config/page integer? config/max integer? config/column
			0 < config/page 0 < config/max 0 < config/column
		][
			set-pager-value pager config 'page
			set-pager-value pager config 'max
			set-pager-value pager config 'column
		]
	] react later [
		config/page: pager/page
		face/text: mold config
	]
]['resize]
