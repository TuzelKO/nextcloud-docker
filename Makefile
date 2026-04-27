-include .env

.DEFAULT_GOAL:
	@echo "╔════════════════════════════════════════════════════════════════════╗"
	@echo "║                         Available Commands                         ║"
	@echo "╚════════════════════════════════════════════════════════════════════╝"
	@awk 'BEGIN { \
		FS = ":.*?## "; \
		section = "Other"; \
	} \
	/^#-+$$/ { \
		getline; \
		if ($$0 ~ /^# [^#]/) { \
			section = substr($$0, 3); \
		} \
		next; \
	} \
	/^[a-zA-Z_-]+:.*?## / { \
		if (!seen[section]++) { \
			print "\n\033[1m" section ":\033[0m"; \
		} \
		printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2; \
	}' $(MAKEFILE_LIST)
	@echo

help: .DEFAULT_GOAL
h: .DEFAULT_GOAL

.DEFAULT:
	@echo "[✘] ERROR! Unknown action or environment not configured."
	@echo "[?] Use 'help' to get more information."

#--------------------------------------------------
# Service
#--------------------------------------------------

define create-env
	@echo "[!] Initializing environment..."
	@cp .env.dist .env
	@echo "[✔] Done!"
endef

init: ## Initialize working environment
	$(create-env)

.env:
	$(create-env)

clean: ## Clean up Docker garbage
	@echo "[!] Cleaning up Docker..."
	@sleep 1
	@echo "[!] Removing all unused containers..."
	@docker container prune --force
	@echo "[!] Removing all unused images..."
	@docker image prune --all --force
	@echo "[!] Removing all unused networks..."
	@docker network prune --force
	@echo "[✔] Done!"

#--------------------------------------------------
# Container Image Management
#--------------------------------------------------

pull: ## Pull container images
	@echo "[!] Pulling container images..."
	@docker compose pull --ignore-buildable
	@echo "[✔] Done!"

build: ## Build container images
	@echo "[!] Building container images..."
	@docker compose build --pull
	@echo "[✔] Done!"

push: ## Push container images
	@echo "[!] Pushing container images..."
	@docker compose push
	@echo "[✔] Done!"

#--------------------------------------------------
# Service Management
#--------------------------------------------------

up: pull ## Start the service
	@echo "[!] Starting the service..."
	@docker compose up -d --remove-orphans
	@echo "[✔] Done!"

down: ## Stop the service
	@echo "[!] Stopping the service..."
	@docker compose down
	@echo "[✔] Done!"

down-with-volumes: ## Stop the service and remove volumes
	@echo "[!] Stopping the service and removing volumes..."
	@docker compose down -v
	@echo "[✔] Done!"

restart: down up ## Restart the service