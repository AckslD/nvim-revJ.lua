TESTS_DIR=tests/plenary
TESTS_INIT=tests/init.lua

test:
	nvim --headless -c "PlenaryBustedDirectory ${TESTS_DIR} {minimal_init = '${TESTS_INIT}'}"

test-deps:
	git clone https://github.com/sgur/vim-textobj-parameter.git
