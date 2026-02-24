# ══════════════════════════════════════════════════════
#                       COLOURS
# ══════════════════════════════════════════════════════
RES		= "\033[0m"
RED		= "\033[91m"
GREEN	= "\033[92m"
YELLOW	= "\033[93m"
ORANGE	= "\033[38;5;208m"
CYAN	= "\033[96m"
GOLD	= "\033[38;5;220m"

# ══════════════════════════════════════════════════════
#                      VARIABLES
# ══════════════════════════════════════════════════════
LOGIN				?= ameechan
DB_DIR				:= /home/$(LOGIN)/data/mariadb
WP_DIR				:= /home/$(LOGIN)/data/wordpress

NAME				= Inception
DOCKER_COMPOSE_FILE	= srcs/docker-compose.yml
DC					= docker compose -f $(DOCKER_COMPOSE_FILE)

S_DB_ROOT			= secrets/db_root_password.txt
S_DB				= secrets/db_password.txt
S_CREDENTIALS		= secrets/credentials.txt
SECRET_FILES		= $(S_DB_ROOT) $(S_DB) $(S_CREDENTIALS)

ENV_FILE			= srcs/.env

# ══════════════════════════════════════════════════════
#                   HELPER MACROS
# ══════════════════════════════════════════════════════
define ensure_directories
	@mkdir -p $(DB_DIR)
	@mkdir -p $(WP_DIR)
	@echo $(GREEN)"✓ Data directories ensured!"$(RES)
endef

# Usage: $(call ask_password,path_to_file,prompt_string)
define ask_password
	@if [ ! -f $(1) ]; then \
		while true; do \
			read -p "$(2)" pwd; \
			if [ $${#pwd} -ge 4 ] && [ $${#pwd} -le 20 ]; then \
				echo "$$pwd" > $(1); \
				chmod 600 $(1); \
				printf $(GREEN)"✓ Password saved!\n"$(RES); \
				break; \
			else \
				printf "Password must be 4-20 characters!\n"; \
			fi; \
		done; \
	else \
		echo $(GREEN)"✓"$(YELLOW)" $(1)"$(GREEN)" already exists, skipping."$(RES); \
	fi
endef

# Usage: $(call ask_credentials,path_to_file)
define ask_credentials
	@if [ ! -f $(1) ]; then \
		while true; do \
			read -p "Enter WordPress admin username: " user; \
			if [ -z "$$user" ]; then \
				printf "Username cannot be empty!\n"; continue; \
			fi; \
			lower_user=$$(printf "%s" "$$user" | tr '[:upper:]' '[:lower:]'); \
			case "$$lower_user" in \
				*admin*) \
					echo $(RED)"Username cannot contain 'admin' (case-insensitive)!\n"$(RES); \
					continue ;; \
			esac; \
			read -p "Enter WordPress admin password: " pwd; \
			if [ $${#pwd} -lt 4 ] || [ $${#pwd} -gt 20 ]; then \
				printf "Password must be 4-20 characters!\n"; continue; \
			fi; \
			echo "$$user:$$pwd" > $(1); \
			chmod 600 $(1); \
			printf $(GREEN)"✓ Credentials saved!\n"$(RES); \
			printf $(ORANGE)"⚠ Don't forget to set WP_ADMIN_USER_ENV in the .env file, so it matches the username you just defined!\n"$(RES); \
			break; \
		done; \
	else \
		echo $(GREEN)"✓"$(YELLOW)" $(1)"$(GREEN)" already exists, skipping."$(RES); \
	fi
endef


define validate_admin
	@echo $(CYAN)"<Validating WordPress admin username>"$(RES)
	@WP_ADMIN_USER=$$(cut -d: -f1 secrets/credentials.txt); \
	WP_ADMIN_USER_ENV=$$(grep WP_ADMIN_USER_ENV= $(ENV_FILE) | cut -d= -f2); \
	LOWER_USER=$$(printf "%s" "$$WP_ADMIN_USER" | tr '[:upper]' '[:lower]'); \
	if [ "$$WP_ADMIN_USER" != "$$WP_ADMIN_USER_ENV" ]; then \
		echo $(RED)"Error: WP_ADMIN_USER_ENV in $(ENV_FILE) does not match credentials.txt"$(RES); \
		echo $(CYAN)"$(ENV_FILE):"$(RES)"   $$WP_ADMIN_USER_ENV\n"$(CYAN)"credentials: "$(RES)"$$WP_ADMIN_USER"; \
		exit 1; \
	fi; \
	case "$$LOWER_USER" in \
		*admin*) \
			echo $(RED)"Error: Username cannot contain 'admin' (case-insensitive)!"$(RES); \
			exit 1 ;; \
	esac; \
	echo $(GREEN)"✓ Admin Username validation passed."$(RES)
endef


define check_env_file
	@if diff -q srcs/.env srcs/.env.example > /dev/null; then \
		echo $(ORANGE)"It appears your .env file is a copy of .env.example\nPlease modify it before proceeding."$(RES); \
		exit 1; \
	else \
		echo $(GREEN)"✓ .env is different from .env.example"$(RES); \
	fi
endef

# ══════════════════════════════════════════════════════
#                   MAIN TARGETS
# ══════════════════════════════════════════════════════

# Build all images (runs setup first to ensure secrets/dirs exist)
all: setup
	$(check_env_file)
	$(validate_admin)
	@echo $(GOLD)"<Building Docker Images>"$(RES)
	@$(DC) build
	@echo $(GREEN)"Build Successful!"$(RES)

# Start containers in detached mode
up: setup
	$(check_env_file)
	$(validate_admin)
	@echo $(YELLOW)"<Starting containers>"$(RES)
	@$(DC) up -d --pull never
	@echo $(GREEN)"Containers started!"$(RES)

# Start containers in detached mode
up-build: setup
	$(check_env_file)
	$(validate_admin)
	@echo $(YELLOW)"<Starting containers>"$(RES)
	@$(DC) up -d --build
	@echo $(GREEN)"Containers started!"$(RES)

# Stop containers (keeps volumes and images)
down:
	@echo $(RED)"<Stopping containers>"$(RES)
	@$(DC) down
	@echo $(GREEN)"Containers stopped!"$(RES)

downv:
#	Remove volumes (permanent data)
	@$(DC) down -v

# Full rebuild from scratch (no cache)
rebuild:
	$(check_env_file)
	$(validate_admin)
	@echo $(ORANGE)"<Rebuilding from zero (no cache)>"$(RES)
	@$(DC) build --no-cache
	@echo $(GREEN)"Rebuild Successful!"$(RES)

# ══════════════════════════════════════════════════════
#                  CLEANUP TARGETS
# ══════════════════════════════════════════════════════

# Remove secrets and .env only
clean:
	@echo $(ORANGE)"<Cleaning secrets and environment>"$(RES)
	@rm -rf $(SECRET_FILES)
	@rm -rf srcs/.env
	@echo $(CYAN)"Secrets and .env removed!"$(RES)

# Remove EVERYTHING: containers, images, volumes, data, secrets
# Order matters! Docker must read .env BEFORE we delete it
fclean:
	@echo $(RED)"<Removing everything>"$(RES)
	@$(DC) down --rmi all -v 2>/dev/null || true
	@sudo rm -rf $(DB_DIR) $(WP_DIR)
	@$(MAKE) --no-print-directory clean
	@echo $(GREEN)"Everything removed!"$(RES)

# Full clean then rebuild
re: nuke all

nuke:
	@echo $(CYAN)"<Stopping all containers>"$(RES)
	-@docker stop $$(docker ps -qa) 2>/dev/null || true
	@echo $(ORANGE)">> Removing all containers..."$(RES)
	-@docker rm $$(docker ps -qa) 2>/dev/null || true
	@echo $(ORANGE)">> Removing all images..."$(RES)
	-@docker rmi -f $$(docker images -qa) 2>/dev/null || true
	@echo $(ORANGE)">> Removing all volumes..."$(RES)
	-@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@echo $(ORANGE)">> Removing all networks..."$(RES)
	-@docker network rm $$(docker network ls -q) 2>/dev/null || true
	@echo $(GREEN)"✓ Done!"$(RES)

# ══════════════════════════════════════════════════════
#                  UTILITY TARGETS
# ══════════════════════════════════════════════════════

# Show running containers
ps:
	@$(DC) ps --format table

# Show logs (optionally: make logs s=mariadb to filter by service)
logs:
	@$(DC) logs -f $(s)

# Show volumes
volumes:
	@$(DC) ls

# ══════════════════════════════════════════════════════
#                     SETUP TARGET
# ══════════════════════════════════════════════════════
setup:
	$(ensure_directories)
	@echo $(CYAN)"<Setting up environment files and secrets>"$(RES); \
	if [ ! -f srcs/.env ]; then \
		cp srcs/.env.example srcs/.env; \
		echo $(GREEN)"✓ Created srcs/.env from template"$(RES); \
		echo $(ORANGE)"⚠ Please edit srcs/.env before starting!\n"$(RES); \
	else \
		echo $(GREEN)"✓"$(YELLOW)" srcs/.env"$(GREEN)" already exists, skipping."$(RES); \
	fi;
	$(call ask_password,$(S_DB_ROOT),Please define MariaDB root password: )
	$(call ask_password,$(S_DB),Please define WordPress DB user password: )
	$(call ask_credentials,$(S_CREDENTIALS))

.PHONY: all up up-build down rebuild clean fclean re ps logs volumes setup nuke