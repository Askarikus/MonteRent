# -------- VARIABLES ---------
APP_CONTAINER_NAME = monte-rent-app-fpm
APP_CLI_CONTAINER_NAME = monte-rent-app-cli
NODE_CONTAINER_NAME = monte-rent-nodejs
# ------ VARIABLES END -------

# -------- DOCKER CLI ---------
up:
	docker-compose up -d
down:
	docker-compose down --remove-orphans
build:
	docker-compose build --pull
pull:
	docker-compose pull
# -------- DOCKER CLI END ---------

# ---------- COMPOSER -----------
composer-install:
	docker exec  $(APP_CLI_CONTAINER_NAME) sh -c 'composer install --no-scripts'
composer-update:
	docker exec  $(APP_CLI_CONTAINER_NAME) sh -c 'composer update'
composer-require:
	docker exec  $(APP_CLI_CONTAINER_NAME) sh -c 'composer require ${name}'
composer-dump-autoload:
	docker exec  $(APP_CLI_CONTAINER_NAME) sh -c 'composer dump-autoload'
# ----------- COMPOSER END -----------

# PHP CS FIXER commands: ----------------------------------------
cs-check:
	docker exec  $(APP_CLI_CONTAINER_NAME) sh -c 'vendor/bin/php-cs-fixer fix -vvv --dry-run --show-progress=dots --allow-risky=yes'

cs-fix:
	docker exec  $(APP_CLI_CONTAINER_NAME) sh -c 'vendor/bin/php-cs-fixer fix -vvv --show-progress=dots --allow-risky=yes'
# _______________________________________________________________

# PHP_STAN commands: --------------------------------------------
static-analyse:
	docker exec  $(APP_CLI_CONTAINER_NAME) sh -c "vendor/bin/phpstan --memory-limit=-1 --configuration=./phpstan.neon"
# _______________________________________________________________

# PHPUnit commands: ---------------------------------------------
phpunit:
	docker exec  $(APP_CLI_CONTAINER_NAME) sh -c 'vendor/bin/phpunit'

phpunit-coverage:
	docker exec  $(APP_CLI_CONTAINER_NAME) sh -c 'vendor/bin/phpunit --coverage-text'
# _______________________________________________________________

# ---------- NODE JS -----------
node-install:
	docker exec $(NODE_CONTAINER_NAME) sh -c 'cd frontend/admin && yarn install'

npm-run-dev:
	docker exec $(NODE_CONTAINER_NAME) sh -c 'cd frontend/admin && yarn run dev'

npm-run-build:
	docker exec $(NODE_CONTAINER_NAME) sh -c 'cd frontend/admin && yarn run build'
# ---------- NODE JS -----------


fixture-load:
	docker exec $(APP_CONTAINER_NAME) sh -c 'php bin/console doctrine:fixtures:load --append'

doctrine-schema-update:
	docker exec $(APP_CONTAINER_NAME) sh -c 'php bin/console doctrine:schema:update --force'

zsh:
	docker exec -it $(APP_CLI_CONTAINER_NAME) /bin/zsh

cache-clear:
	docker exec -it $(APP_CLI_CONTAINER_NAME) sh -c 'php bin/console cache:clear'
