TESTS_DIR=tests/plenary
TESTS_INIT=tests/init.lua
MINIMAL_INIT=tests/minimal_init.vim

test:
	nvim --headless --noplugin -u ${MINIMAL_INIT} -c "PlenaryBustedDirectory ${TESTS_DIR} {minimal_init = '${TESTS_INIT}'}"
