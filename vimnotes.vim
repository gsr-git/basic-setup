function! FindVimnotesFile()
	" '%' => current file path, ':p' => absolute path
	let l:dir_parts = split(expand('%:p'), '/')
	let l:curr_filepath = expand('%:p')
	let l:curr_filename = l:dir_parts[-1]
	let l:curr_path = ""
	let l:found_notes = 0

	" Go up the dir tree and look for vimnotes.out
	for i in range(1, len(l:dir_parts))
		let l:curr_path = '/' . join(l:dir_parts[0:-1 * i], '/')
		let l:flist = split(globpath(l:curr_path, 'vimnotes.out'), '\n')
		if len(l:flist) > 0
			let l:found_notes = 1
			break
		endif
	endfor

	if l:found_notes == 0
		return -1
	endif

	return l:curr_path
endfunction

function! AddBanner(fullpath)
	call append(line('$'), repeat(">", 4))
	call append(line('$'), "File: " . a:fullpath)
	call append(line('$'), repeat("<", 4))
	call append(line('$'), "")
	call append(line('$'), "")
	call append(line('$'), "")
endfunction

function! EndOfSection(line_nr)
	let l:body_start = search('^<<<<', 'zW')

	let l:body_end = search('^>>>>', 'zW')
	if l:body_end == 0
		let l:body_end = line('$') - 1
	else
		let l:body_end = l:body_end - 2
	endif

	let l:line_list = getbufline(bufnr('vimnotes.out'), l:body_start+1, l:body_end)
	for x in l:line_list
		if x != '>>>>' && x != ''
			let l:body_end = l:body_start + 1 + index(l:line_list, x)
		endif
	endfor
	execute l:body_end
	execute "normal! $"

endfunction

function! SeekToFilenotes(fullpath)
	let l:line_nr = search("^File: " . a:fullpath)
	if l:line_nr == 0
		" No entry for this file. Add one to the end
		execute "normal! GG"
		call AddBanner(a:fullpath)
	endif

	call EndOfSection(l:line_nr)
endfunction

function! OpenVimNotes(file)
	if bufname('%') == 'vimnotes.out'
		return
	endif

	let l:notes_win_nr = bufwinnr(bufnr('vimnotes.out'))
	if l:notes_win_nr > -1
		execute l:notes_win_nr " wincmd w"
	else
		let l:notes_path = FindVimnotesFile()
		if l:notes_path == -1
			echoerr "Did not find a vimnotes.out file. Add one in the root directory of the project and try again"
			return
		endif

		let l:fpath = l:notes_path . '/vimnotes.out'
		set splitright " Use &splitright to get current value and restore later
		execute "50vsplit " l:fpath
	endif

	call SeekToFilenotes(a:file)
	set nosplitright
endfunction

nmap <C-w>N :call OpenVimNotes(expand('%:p'))<CR>
