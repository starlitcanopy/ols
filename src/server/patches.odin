package server

import "core:os"

odin_files_glob :: proc(path: string) -> (matches: []string, ok: bool) {
	dmatches := make([dynamic]string, 0, 0, context.temp_allocator)
	odin_files_glob_impl(path, &dmatches) or_return

	return dmatches[:], true
}

@(private = "file")
odin_files_glob_impl :: proc(path: string, out: ^[dynamic]string) -> (ok: bool) {
	dmatches := make([dynamic]string, 0, 0, context.temp_allocator)

	fh, err := os.open(path)
	if err != 0 {return false}
	defer os.close(fh)

	if files, err := os.read_dir(fh, 0, context.temp_allocator); err == 0 {
		for file in files {
			if file.is_dir {
				odin_files_glob_impl(file.fullpath, out)
			} else {
				append(out, file.fullpath)
			}
		}
	}

	return true
}
