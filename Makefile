# Jenkins CI Test Makefile

.PHONY: test test-quick clean logs help setup

# Default target
help:
	@echo "Available targets:"
	@echo "  setup      - Make test script executable and prepare environment"
	@echo "  test       - Run full Jenkins configuration test suite"
	@echo "  test-quick - Run quick test (authentication and basic connectivity)"
	@echo "  logs       - Show service logs"
	@echo "  clean      - Stop containers and clean up"
	@echo "  help       - Show this help message"

setup:
	chmod +x test-jenkins.sh
	@echo "Test script is now executable"

test: setup
	./test-jenkins.sh

test-quick: setup
	./test-jenkins.sh quick

logs:
	./test-jenkins.sh logs

clean:
	./test-jenkins.sh cleanup
