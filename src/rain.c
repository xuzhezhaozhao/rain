#include <stdio.h>
#include "rain.h"

int main(int argc, char *argv[])
{
	const char *prog = argv[0];
	const char *e_prog = NULL;
	int verbose = FALSE, check = FALSE;
	parser_state state;

	while (argc > 1 && argv[1][0] == '-') {
		const char *s = argv[1] + 1;
		while (*s) {
			switch (*s) {
				case 'v':
					verbose = TRUE;
					break;
				case 'c':
					check = TRUE;
					break;
				case 'e':
					if (s[1] == '\0') {
						e_prog = argv[2];
						--argc; ++argv;
					} else {
						e_prog = &s[1];
					}
					goto next_arg;
				default:
					fprintf(stderr, "%s: unknown option -%c\n", prog, *s);
			}
			++s;
		}
	next_arg:
		--argc; ++argv;
	}

	node_parse_init(&state);

	int n = 0;
	if (e_prog) {
		n = node_parse_string(&state, e_prog);
	} else if (argc == 1) {
		n = node_parse_input(&state, stdin, "stdin");
	} else {
		for (int i = 1; i < argc; i++) {
			n += node_parse_file(&state, argv[i]);
		}
	}

	if (n == 0) {
		if (verbose) {
			dump_node(state.lval, 0);
		}
		if (check) {
			puts("Syntax OK");
		} else {
			/* TODO */
		}
	} else if (check) {
		puts("Syntax NG");
	}

	node_parse_free(&state);
	
	/*return n > 0 ? EXIT_FAILURE :EXIT_SUCCESS;*/
	return n > 0 ? 1 : 0;
}
