NAME = inception

all:
	docker compose -f srcs/docker-compose.yml up --build

down:
	docker compose -f srcs/docker-compose.yml down

clean:
	docker system prune -f

fclean: down
	docker system prune -af --volumes

re: fclean all