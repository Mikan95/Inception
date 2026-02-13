# COLOURS
RES		=	"\033[0m"
BLACK	=	"\033[30m"
RED		=	"\033[91m"
GREEN	=	"\033[92m"
YELLOW	=	"\033[93m"
BLUE	=	"\033[38;2;0;0;255m"
MAGENTA	=	"\033[95m"
CYAN	=	"\033[96m"
WHITE	=	"\033[97m"
ORANGE	=	"\033[38;5;208m"
LIME	=	"\033[38;5;154m"
PURPLE	=	"\033[38;5;129m"
GOLD	=	"\033[38;5;220m"


# DOCKER
NAME					= Inception
DOCKER_COMPOSE_FILE		= srcs/docker-compose.yml
DOCKER_COMPOSE_COMMAND	= docker compose -f $(DOCKER_COMPOSE_FILE)
BUILD					= $(DOCKER_COMPOSE_COMMAND) build
FORCE_REBUILD			= $(BUILD) --no-cache

# SECRETS_PATH	= secrets/
S_DB_ROOT		= secrets/db_root_password.txt
S_DB			= secrets/db_password.txt
S_CREDENTIALS	= secrets/credentials.txt
SECRET_FILES		= $(S_DB_ROOT) $(S_DB) $(S_CREDENTIALS)



# Build all images
all: setup
	@echo $(GOLD) "Building Docker Images" $(RES)
	@$(BUILD)
	@echo $(GREEN) "Build Successful!" $(RES)

# Rebuild all docker images from scratch (without cache)
rebuild:
	@echo $(ORANGE) "REBUILDING FROM ZERO" $(RES)
	@$(FORCE_REBUILD)
	@echo $(GREEN) "Total Rebuild Successful!" $(RES)


# Start containers in detached mode (keep running in background)
up:
# need to make sure that mariadb(1) then wordpress(2) then nginx(3) is done in that order.
	@echo $(YELLOW) "Starting containers in detached mode" $(RES)

	$(DOCKER_COMPOSE_COMMAND) up -d --build --pull never mariadb

	@echo $(GREEN) "Containers successfully started in detached mode" $(RES)

setup:

	@echo $(CYAN)"Setting up environment files.."$(RES)
	@if [ ! -f srcs/.env]; then \
		cp srcs/.env.example srcs/.env; \
		echo $(GREEN)"✓ Created srcs/.env from template"; \
		echo $(ORANGE) "⚠ Please edit srcs/.env with your values before starting!"
	else \
		echo "✓ srcs/.env already exists"


# Get MariaDB Root password and store in $(S_DB_ROOT)
	@if [ ! -f $(S_DB_ROOT) ]; then \
		while true; do \
			read -p "Please define MariaDB Root password: " pwd; \
			if [ $${#pwd} -ge 4 ] && [ $${#pwd} -le 20 ]; then \
				echo "$$pwd" > $(S_DB_ROOT); \
				echo $(GREEN)"Password Confirmed!" $(RES); \
				break; \
			else \
				echo "Password must be between 4 and 20 characters!"; \
			fi; \
		done; \
	fi;

# Get WordPress Database user password and store in $(S_DB)
	@if [ ! -f $(S_DB) ]; then \
		while true; do \
			read -p "Please define WordPress database User password: " pwd; \
			if [ $${#pwd} -ge 4 ] && [ $${#pwd} -le 20 ]; then \
				echo "$$pwd" > $(S_DB); \
				echo $(GREEN)"Password Confirmed!" $(RES); \
				break; \
			else \
				echo "Password must be between 4 and 20 characters!"; \
			fi; \
		done; \
	fi;


# Get Credentials password and store in $(S_CREDENTIALS)
	@if [ ! -f $(S_CREDENTIALS) ]; then \
		while true; do \
			read -p "Please define WordPress admin password: " pwd; \
			if [ $${#pwd} -ge 4 ] && [ $${#pwd} -le 20 ]; then \
				echo "$$pwd" > $(S_CREDENTIALS); \
				echo $(GREEN)"Password Confirmed!" $(RES); \
			else \
				echo "Password must be between 4 and 20 characters!"; \
				continue; \
			fi; \

			read -p "Please define WordPress admin password: "
		done; \
	fi;

# Stop containers
down:
	@echo $(RED) "Removing and shutting down containers" $(RES)

	@$(DOCKER_COMPOSE_COMMAND) down

	@echo $(GREEN) "Containers successfully shut down and removed" $(RES)

# Stop and remove everything (containers, volumes, networks)
clean:
	@echo $(RED) "Removing Containers and Volumes" $(RES)
	@echo $(ORANGE " WARNING: this will erase all data in MariaDB!")

	@$(DOCKER_COMPOSE_COMMAND) down -v
	rm -rf $(S_DB_ROOT)
	@echo $(GREEN) "Containers and Volumes successfully removed" $(RES)


# Remove images
fclean: clean
	@echo $(RED) "Removing images.." $(RES)

	@$(DOCKER_COMPOSE_COMMAND) down -rmi

	@echo $(GREEN) "Images successfully removed" $(RES)




# Target: Full rebuild
re: fclean all


# Show volumes
volumes:
	$(DOCKER_COMPOSE_COMMAND) volumes --format table


# Target: Show running containers
ps:
	$(DOCKER_COMPOSE_COMMAND) ps --format table



.PHONY: all build up down clean fclean re volumes ps setup

