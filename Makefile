REPO = dr.yt.com
REPO_HUB = looploy
NAME = nginx
VERSION = 1.17.1
TAGNAME = $(VERSION)
#include ENVAR


.PHONY: all build push test tag_latest release ssh

all: build docs

test:
	echo $(VERSION)

changeconfig:
		@CONTAINER_ID=$(shell docker run -d $(REPO_HUB)/$(NAME):$(TAGNAME)) ;\
		 echo "COPY TO [$$CONTAINER_ID]" ;\
		 docker cp "files/." "$$CONTAINER_ID":/ ;\
		 docker exec -it "$$CONTAINER_ID" sh -c "echo `date +%Y-%m-%d:%H:%M:%S` > /.made_day" ;\
		 echo "COMMIT [$$CONTAINER_ID]" ;\
		 docker commit -m "Change config `date`" "$$CONTAINER_ID" $(REPO_HUB)/$(NAME):$(TAGNAME) ;\
		 echo "STOP [$$CONTAINER_ID]" ;\
		 docker stop "$$CONTAINER_ID" ;\
		 echo "CLEAN UP [$$CONTAINER_ID]" ;\
		 docker rm "$$CONTAINER_ID"

build:
		sed -i '' "s/$(REPO_HUB)\/$(NAME).*/$(REPO_HUB)\/$(NAME):$(VERSION)/g" docker-compose_grpc.yml
		sed -i '' "s/$(REPO_HUB)\/$(NAME).*/$(REPO_HUB)\/$(NAME):$(VERSION)/g" docker-compose.yml
		docker build --no-cache --rm=true --build-arg NGINX_VERSION=$(NAME)-$(VERSION) -t $(REPO_HUB)/$(NAME):$(TAGNAME) .

push:
		# docker tag  $(NAME):$(VERSION) $(REPO)/$(NAME):$(TAGNAME)
		docker push $(REPO_HUB)/$(NAME):$(TAGNAME)

prod:
		docker tag $(REPO_HUB)/$(NAME):$(TAGNAME)  $(REPO_HUB)/$(NAME):$(VERSION)
		docker push $(REPO_HUB)/$(NAME):$(VERSION)

push_hub:
		#docker tag  $(NAME):$(VERSION) $(REPO_HUB)/$(NAME):$(VERSION)
		docker push $(REPO_HUB)/$(NAME):$(TAGNAME)

tag_latest:
		docker tag  $(REPO)/$(NAME):$(TAGNAME) $(REPO)/$(NAME):latest
		docker push $(REPO)/$(NAME):latest

build_hub:
		echo "TRIGGER_KEY" ${TRIGGERKEY}
		git add .
		git commit -m "$(NAME):$(VERSION) by Makefile"
		git tag -a "$(VERSION)" -m "$(VERSION) by Makefile"
		git push origin --tags
		curl -H "Content-Type: application/json" --data '{"build": true,"source_type": "Tag", "source_name": "$(VERSION)"}' -X POST https://registry.hub.docker.com/u/${REPO_HUB}/${NAME}/trigger/${TRIGGERKEY}/

init:
		git init
		git add .
		git commit -m "first commit"
		git remote add origin git@repo.theloop.co.kr:jinwoo/$(NAME).git
		git push -u origin master
bash:
	docker run -it --rm $(REPO_HUB)/$(NAME):$(TAGNAME) bash

docs:
	@$(shell ./makeMarkDown.sh)
