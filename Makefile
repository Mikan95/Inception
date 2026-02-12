# Which variables might you need?

NAME				= Inception
DOCKER_COMPOSE_FILE	= srcs/docker-compose.yml




# Target: Build all images
all:
	# What command builds images using docker-compose?

# Target: Build without cache (force rebuild)
build:
	# How do you force docker-compose to rebuild?

# Target: Start containers in detached mode
up:
	# How do you start containers in background?

# Target: Stop containers
down:
	# How do you stop and remove containers?

# Target: Stop and remove everything (containers, volumes, networks)
clean:
	# How do you remove containers?
	# How do you remove volumes?
	# How do you remove networks?

# Target: Remove images too
fclean: clean
	# How do you remove docker images?
	# How do you prune system?

# Target: Full rebuild
re: fclean all

# Target: Show logs
logs:
	# How do you view container logs?

# Target: Show running containers
ps:
	# How do you list containers?

# Declare phony targets (not actual files)
.PHONY: all build up down clean fclean re logs ps