NAME = inception

all:
	mkdir -p /home/yolaidi-/data/mariadb
	mkdir -p /home/yolaidi-/data/wordpress
	sudo rm -rf /home/yolaidi-/data/mariadb/*
	sudo rm -rf /home/yolaidi-/data/wordpress/*
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down -v

clean:
	docker system prune -f

fclean: clean
	docker system prune -af --volumes
	sudo rm -rf /home/yolaidi-/data/*

re: fclean all