TESTS_DIR=tests/plenary
TESTS_INIT=tests/init.lua

test:
	nvim --headless -c "PlenaryBustedDirectory ${TESTS_DIR} {minimal_init = '${TESTS_INIT}'}"
