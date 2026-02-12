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



NAME					= Inception
DOCKER_COMPOSE_FILE		= srcs/docker-compose.yml
# DOCKER_COMPOSE_COMMAND	= docker compose -f


BUILD			= docker compose -f $(DOCKER_COMPOSE_FILE) build
FORCE_REBUILD	= $(BUILD) --no-cache



# Build all images
all:
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
	@echo $(YELLOW) "Starting containers in detached mode" $(RES)
	docker compose up --detach

# Stop containers
down:
	@echo $(RED) "Removing and shutting down containers" $(RES)

	@docker compose down

	@echo $(GREEN) "Containers successfully shut down and removed" $(RES)

# Stop and remove everything (containers, volumes, networks)
clean:
	@echo $(RED) "Removing Containers and Volumes" $(RES)
	@echo $(ORANGE " WARNING: this will erase all data in MariaDB!")

	@docker compose down -v

	@echo $(GREEN) "Containers and Volumes successfully removed" $(RES)


# Target: Remove images too
fclean: clean
	@echo $(RED) "Removing images.." $(RES)

	@docker compose down -rmi

# Target: Full rebuild
re: fclean all

# Target: Show logs
volumes:
	docker compose volumes --format table

# Target: Show running containers
ps:
	docker compose ps --format table

# Declare phony targets (not actual files)
.PHONY: all build up down clean fclean re logs ps

