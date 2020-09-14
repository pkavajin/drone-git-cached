TAG := v0.0.3
IMAGE := kavatech/drone-git-cached:$(TAG)

all: docker-build docker-push

docker-build:
	docker build -t $(IMAGE) .

docker-push: docker-build
	docker push $(IMAGE)
