PROJECT_PATH_OUTSIDE_DOCKER := $(shell grep ^PROJECT_PATH_OUTSIDE_DOCKER= ./.env | cut -d '=' -f 2-)
BACKSRC := $(PROJECT_PATH_OUTSIDE_DOCKER)

WITH_DB=$(shell grep ^WITH_DB ./.env | cut -d '=' -f 2-)

COMPOSE_FILE_PATH := -f docker-compose.yml
ifeq ($(WITH_DB), 1)
COMPOSE_FILE_PATH := $(COMPOSE_FILE_PATH) -f docker-compose-db.yml
endif

PROJECT_NAME=$(shell grep ^COMPOSE_PROJECT_NAME ./.env | cut -d '=' -f 2-)
DB_NAME=$(shell grep ^DB_NAME= ./.env | cut -d '=' -f 2-)
DB_USER=$(shell grep ^DB_USERNAME= ./.env | cut -d '=' -f 2-)
APP_ENV=$(shell grep ^APP_ENV= ./.env | cut -d '=' -f 2-)
WITH_RESET_DB=$(shell grep ^WITH_RESET_DB ./.env | cut -d '=' -f 2-)
YARN_CONTAINER_NAME= $(PROJECT_NAME)_yarn
ENCORE_COMMAND="./node_modules/.bin/encore dev"
DOCKER_EXEC_CMD=$(DOCKER_COMPOSE) exec
.DEFAULT_GOAL := help
ARGUMENT=$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)) #split argument from make
EVAL := $(eval $(ARGUMENT):;@:) #split argument from make
CURRENT_UID=$(shell id -u):$(shell id -g)
export HOST_UID=$(shell id -u)
export HOST_USER=$(shell whoami)
export HOST_GROUP=$(shell getent group docker | cut -d: -f3)
DOCKER_COMPOSE=@docker-compose $(COMPOSE_FILE_PATH)

## —— ComposedCommand 🚀 ———————————————————————————————————————————————————————————————
buildProject: install ## Alias for install

afterBuild: #vendorInstall resetDB reloadAssets ## Remove and reinstall the vendors, destroy and recreate database, rebuild assets

update: updateDB reloadAssets ## Update vendor, database, and rebuild assets


checkConfigFile: ## Check your config file
ifeq (,$(wildcard ./.env)) #if no .env
		@cp .env.dist .env
		@echo 'We have just generate a .env file for you'
		@echo 'Please configure this new .env'
		@exit 1;
endif

install: checkConfigFile destroy buildImage start afterBuild ## Check config files, destroy, rebuild, start containers, and do afterbuild

deploy: yarnDev updateDB  cacheClear restart ## update preproduction/production env

## —— Docker 🐳 ———————————————————————————————————————————————————————————————

start: ## Start the containers (only work when installed)
	   $(DOCKER_COMPOSE) up -d $(ARGUMENT)

restart: ## Restart the containers (only work when started)
		 $(DOCKER_COMPOSE) restart $(ARGUMENT)

stop: ## Stop the containers (only work when started)
		$(DOCKER_COMPOSE) stop $(ARGUMENT)

destroy: ## Destroy the containers
		$(DOCKER_COMPOSE) stop $(ARGUMENT)
		$(DOCKER_COMPOSE) rm -f $(ARGUMENT)

buildImage: ## Build the containers
		@echo $(DOCKER_COMPOSE)
		$(DOCKER_COMPOSE) build $(ARGUMENT)

## —— Vendors 🧙‍️ ———————————————————————————————————————————————————————————————

vendorInstall: ## Remove and reinstall the vendors
		$(DOCKER_EXEC_CMD) php ./bashrun.sh vendorinstall

vendorUpdate: ## Remove and update the vendors
		$(DOCKER_EXEC_CMD) php ./bashrun.sh vendorUpdate

cacheClear: ## Clear symfony cache
		$(DOCKER_EXEC_CMD) php ./bashrun.sh clearcache


## —— Front 🎨 ———————————————————————————————————————————————————————————————

routesJSGenerate: ## Regenerate routes file for ajax call
		$(DOCKER_EXEC_CMD) php ./bashrun.sh extractjs
		$(DOCKER_EXEC_CMD) php ./bashrun.sh uploadfolders

yarnInstall: ## Reinstall node_modules
		$(DOCKER_EXEC_CMD) php yarn install

yarnAdd: ## Add a package (node_modules) to assets
		$(DOCKER_EXEC_CMD) php yarn add --dev $(ARGUMENT)

yarnDev: routesJSGenerate ## build assets
		$(DOCKER_EXEC_CMD) php yarn dev

watchAssets: routesJSGenerate ## Watch assets
		$(DOCKER_EXEC_CMD) php yarn watch

reloadAssets:	YARN_CMD = yarn dev ## Rebuild assets

reloadAssets: yarnInstall yarnInstall yarnDev

## —— Database 🏢 ———————————————————————————————————————————————————————————————

updateDB:  ## Update the database
		$(DOCKER_EXEC_CMD) php ./bashrun.sh updatedb

migrateDB:  ## Execute a migration to a specified version or the latest available version.
		$(DOCKER_EXEC_CMD) php ./bashrun.sh migrateDB $(ARGUMENT)


executeDB:  ## Execute a single migration version up or down manually, Example make executeDB 20200406202523 down.
	$(DOCKER_EXEC_CMD) php ./bashrun.sh executeDB $(ARGUMENT)


dbReset:
	$(DOCKER_EXEC_CMD) -u postgres postgis psql -d $(DB_NAME) -c "CREATE EXTENSION postgis CASCADE;"
	$(DOCKER_EXEC_CMD) -u postgres postgis psql -d $(DB_NAME) -c "CREATE EXTENSION postgis_topology CASCADE;"
	$(DOCKER_EXEC_CMD) -u postgres postgis psql -d $(DB_NAME) -c "SET search_path = public, postgis;"



ifeq ($(WITH_RESET_DB), 1)
ifeq ($(WITH_DB), 1)
resetDB: destroyDB dbReset updateDB ## Reset everything in database
else
resetDB:
	@echo "This is not your DB can't reset"
endif
else
resetDB: updateDB
endif


ifeq ($(WITH_RESET_DB), 1)
destroyDB:
	$(DOCKER_EXEC_CMD) php ./bashrun.sh destroycreatedb
else
destroyDB:
	@echo "can't destroyDB"
endif

## —— Usefull 🧐 ———————————————————————————————————————————————————————————————

bash: ## Open a bash inside a container
ifneq ($(strip $(ARGUMENT)),)
		$(DOCKER_EXEC_CMD) $(ARGUMENT) /bin/bash
else
		@echo Usage: make bash {container}
		@exit 1
endif

help: ## Outputs this help screen
		@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
		@echo ""
		@echo "In case you want to build with db, just change \033[32mWITH_DB=1\033[0m in .env"
		@echo "Make sure you are in the docker groups, give the repo's right to this group (read and write)"
		@echo ""
