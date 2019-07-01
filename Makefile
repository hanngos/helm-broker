APP_NAME = helm-broker
TOOLS_NAME = helm-broker-tools
REPO = $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/
TAG = $(DOCKER_TAG)

.PHONY: build
build:
	./before-commit.sh ci

.PHONY: generates
# Generate CRD manifests, clients etc.
generates: crd-manifests client

.PHONY: crd-manifests
# Generate CRD manifests
crd-manifests:
	go run vendor/sigs.k8s.io/controller-tools/cmd/controller-gen/main.go crd --domain kyma-project.io

# Generate code
.PHONY: client
client:
	./contrib/hack/update-codegen.sh

.PHONY: build-image
build-image:
	cp broker deploy/broker/helm-broker
	cp targz deploy/tools/targz
	cp indexbuilder deploy/tools/indexbuilder
	cp preupgrade deploy/tools/preupgrade

	docker build -t $(APP_NAME) deploy/broker
	docker build -t $(TOOLS_NAME) deploy/tools

.PHONY: push-image
push-image:
	docker tag $(APP_NAME) $(REPO)$(APP_NAME):$(TAG)
	docker push $(REPO)$(APP_NAME):$(TAG)

	docker tag $(TOOLS_NAME) $(REPO)$(TOOLS_NAME):$(TAG)
	docker push $(REPO)$(TOOLS_NAME):$(TAG)

.PHONY: ci-pr
ci-pr: build build-image push-image

.PHONY: ci-master
ci-master: build build-image push-image

.PHONY: ci-release
ci-release: build build-image push-image

.PHONY: clean
clean:
	rm -f broker
	rm -f targz
	rm -f indexbuilder

.PHONY: path-to-referenced-charts
path-to-referenced-charts:
	@echo "resources/helm-broker"
