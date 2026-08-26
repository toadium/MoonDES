.PHONY: help build-frontend build-backend run-backend check test verify clean

help:
	@echo "MoonDES Full-Stack Project"
	@echo "========================="
	@echo ""
	@echo "Targets:"
	@echo "  make build-frontend  Build frontend JS bundle (Rabbita UI)"
	@echo "  make build-backend   Build backend native executable"
	@echo "  make run-backend     Run backend server on 127.0.0.1:8080"
	@echo "  make check           Run moon check for all targets"
	@echo "  make test            Run moon test for all targets"
	@echo "  make verify          Run check + test"
	@echo "  make clean           Remove build artifacts"
	@echo ""
	@echo "Workflow:"
	@echo "  1. make build-frontend"
	@echo "  2. make run-backend"
	@echo "  3. Open http://127.0.0.1:8080/"

build-frontend:
	moon build frontend --target js
	cp _build/js/frontend/frontend.js backend/frontend.js

build-backend:
	moon build backend --target native

run-backend: build-frontend
	moon run backend --target native

check:
	moon check --target wasm
	moon check --target native
	moon check --target js

test:
	moon test --target wasm

verify: check test

clean:
	rm -rf _build
	rm -f backend/frontend.js
