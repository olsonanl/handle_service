# totrack variables added herein
VARS_OLD := $(.VARIABLES)

TOP_DIR = ../..
DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment
include $(TOP_DIR)/tools/Makefile.common

SERVICE_SPEC = handle_service.spec	
SERVICE_NAME = AbstractHandle
SERVICE_PORT = 7109 
SERVICE_DIR  = handle_service

ifeq ($(SELF_URL),)
	SELF_URL = http://localhost:$(SERVICE_PORT)
endif

SERVICE_PSGI = $(SERVICE_NAME).psgi
TPAGE_ARGS = --define kb_runas_user=$(SERVICE_USER) --define kb_top=$(TARGET) --define kb_runtime=$(DEPLOY_RUNTIME) --define kb_service_name=$(SERVICE_NAME) --define kb_service_dir=$(SERVICE_DIR) --define kb_service_port=$(SERVICE_PORT) --define kb_psgi=$(SERVICE_PSGI)

SRC_PERL = $(wildcard scripts/*.pl)

# You can change these if you are putting your tests somewhere
# else or if you are not using the standard .t suffix
CLIENT_TESTS = $(wildcard client-tests/*.t)
SCRIPTS_TESTS = $(wildcard script-tests/*.t)
SERVER_TESTS = $(wildcard server-tests/*.t)

# This is a very client-centric view of release engineering.
# We assume our primary product for the community is the client
# libraries, command line interfaces, and the related documentation
# from which specific science applications can be built.
#
# A service is composed of a client and a server, each of which
# should be independently deployable. Clients are composed of
# an application programming interface (API) and a command line
# interface (CLI). In our make targets, deploy-service deploys
# the server, deploy-client deploys the application
# programming interface libraries, and deploy-scripts deploys
# the command line interface (usually scripts written in a
# scripting language but java executables also qualify), and the
# deploy target would be equivelant to deploying a service (client
# libs, scripts, and server).
#
# Because the deployment of the server side code depends on the
# specific software module being deployed, the strategy needs
# to be one that leaves this decision to the module developer.
# This is done by having the deploy target depend on the
# deploy-service target. The module developer who chooses for
# good reason not to deploy the server with the client simply
# manages this dependancy accordingly. One option is to have
# a deploy-service target that does nothing, the other is to
# remove the dependancy from the deploy target.
#
# A smiliar naming convention is used for tests. 


default: build-libs

.SILENT:

vars:
	@echo "nothing to do for default"
	$(foreach v,                                      \
	$(filter-out $(VARS_OLD) VARS_OLD,$(.VARIABLES)), \
	$(info $(v) = $($(v))))


# Distribution Section
#
# This section deals with the packaging of source code into a 
# distributable form. This is different from a deployable form
# as our deployments tend to be kbase specific. To create a
# distribution, we have to consider the distribution mechanisms.
# For starters, we will consider cpan style packages for perl
# code, we will consider egg for python, npm for javascript,
# and it is not clear at this time what is right for java.
#
# In all cases, it is important not to implement into these
# targets the actual distribution. What these targets deal
# with is creating the distributable object (.tar.gz, .jar,
# etc) and placing it in the top level directory of the module
# distrubution directory.
#
# Use <module_name>/distribution as the top level distribution
# directory
dist: dist-cpan dist-egg dist-npm dist-java dist-r

dist-cpan: dist-cpan-client dist-cpan-service

dist-egg: dist-egg-client dist-egg-service

# In this case, it is not clear what npm service would mean,
# unless we are talking about a service backend implemented
# in javascript, which I can imagine happing. So the target
# is here, even though we don't have support for javascript
# on the back end of the compiler at this time.
dist-npm: dist-npm-client dist-npm-service

dist-java: dist-java-client dist-java-service

# in this case, I'm using the word client just for consistency
# sake. What we mean by client is an R library. At this time
# the meaning of a r-service is not understood. It can be
# added at a later time if there is a good reason.
dist-r: dist-r-client

dist-cpan-client:
	echo "cpan client distribution not supported"

dist-cpan-service:
	echo "cpan service distribution not supported"

dist-egg-client:
	echo "egg client distribution not supported"

dist-egg-service:
	echo "egg service distribution not supported"

dist-npm-client:
	echo "npm client distribution not supported"

dist-npm-service:
	echo "npm service distribution not supported"

dist-java-client:
	echo "java client distribution not supported"

dist-java-service:
	echo "java service distribuiton not supported"

dist-r-client:
	echo "r client lib distribution not supported"

# Test Section

test: test-client 
	@echo "done running client tests"

# test-all is deprecated. 
# test-all: test-client test-scripts test-service
#
# test-client: This is a test of a client library. If it is a
# client-server module, then it should be run against a running
# server. You can say that this also tests the server, and I
# agree. You can add a test-service dependancy to the test-client
# target if it makes sense to you. This test example assumes there is
# already a tested running server.
test-client:
	# run each test
	for t in $(CLIENT_TESTS) ; do \
		if [ -f $$t ] ; then \
			$(DEPLOY_RUNTIME)/bin/perl $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done

# test-scripts: A script test should test the command line scripts. If
# the script is a client in a client-server architecture, then there
# should be tests against a running server. You can add a test-service
# dependency to the test-client target. You could also add a
# deploy-service and start-server dependancy to the test-scripts
# target if it makes sense to you. Future versions of the makefiles
# for services will move in this direction.
test-scripts:
	# run each test
	for t in $(SCRIPT_TESTS) ; do \
		if [ -f $$t ] ; then \
			$(DEPLOY_RUNTIME)/bin/perl $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done

# test-service: A server test should not rely on the client libraries
# or scripts--you should not have a test-service target that depends
# on the test-client or test-scripts targets. Otherwise, a circular
# dependency graph could result.
test-service:
	# run each test
	for t in $(SERVER_TESTS) ; do \
		if [ -f $$t ] ; then \
			$(DEPLOY_RUNTIME)/bin/perl $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done

# Deployment:
# 
# We are assuming our primary products to the community are
# client side application programming interface libraries and a
# command line interface (scripts). The deployment of client
# artifacts should not be dependent on deployment of a server,
# although we recommend deploying the server code with the
# client code when the deploy target is executed. If you have
# good reason not to deploy the server at the same time as the
# client, just delete the dependancy on deploy-service. It is
# important to note that you must have a deploy-service target
# even if there is no server side code to deploy.

deploy: deploy-client deploy-service

# deploy-all deploys client *and* server. This target is deprecated
# and should be replaced by the deploy target.

deploy-all: deploy-client deploy-service

# deploy-client should deploy the client artifacts, mainly
# the application programming interface libraries, command
# line scripts, and associated reference documentation.

deploy-client: build-libs deploy-libs deploy-scripts deploy-docs vars

# The deploy-libs and deploy-scripts targets are used to recognize
# and delineate the client types, mainly a set of libraries that
# implement an application programming interface and a set of 
# command line scripts that provide command-based execution of
# individual API functions and aggregated sets of API functions.

deploy-libs: 
	rsync --exclude '*.bak*' -arv lib/. $(TARGET)/lib/.

# Deploying a service refers to to deploying the capability
# to run a service. Becuase service code is often deployed 
# as part of the libs, meaning service code gets deployed
# when deploy-libs is called, the deploy-service target is
# generally concerned with the service start and stop scripts.
# The deploy-cfg target is defined in the common rules file
# located at $TOP_DIR/tools/Makefile.common.rules and included
# at the end of this file.

deploy-service: deploy-cfg
	mkdir -p $(TARGET)/services/$(SERVICE_DIR)
	$(TPAGE) $(TPAGE_ARGS) service/start_service.tt > $(TARGET)/services/$(SERVICE_DIR)/start_service
	chmod +x $(TARGET)/services/$(SERVICE_DIR)/start_service
	$(TPAGE) $(TPAGE_ARGS) service/stop_service.tt > $(TARGET)/services/$(SERVICE_DIR)/stop_service
	chmod +x $(TARGET)/services/$(SERVICE_DIR)/stop_service
	$(TPAGE) $(TPAGE_ARGS) service/upstart.tt > service/$(SERVICE_NAME).conf
	chmod +x service/$(SERVICE_NAME).conf
	echo "done executing deploy-service target"

deploy-upstart: deploy-service
	-cp service/$(SERVICE_NAME).conf /etc/init/
	echo "done executing deploy-upstart target"

# Deploying docs here refers to the deployment of documentation
# of the API. We'll include a description of deploying documentation
# of command line interface scripts when we have a better understanding of
# how to standardize and automate CLI documentation.

deploy-docs: build-docs
	-mkdir -p $(TARGET)/services/$(SERVICE_DIR)/webroot/.
	cp docs/*.html $(TARGET)/services/$(SERVICE_DIR)/webroot/.

# The location of the Client.pm file depends on the --client param
# that is provided to the compile_typespec command. The
# compile_typespec command is called in the build-libs target.

build-docs: compile-docs
	-mkdir -p docs
	pod2html --infile=lib/Bio/KBase/$(SERVICE_NAME)/Client.pm --outfile=docs/$(SERVICE_NAME).html

# Use the compile-docs target if you want to unlink the generation of
# the docs from the generation of the libs. Not recommended, but there
# could be a reason for it that I'm not seeing.
# The compile-docs target should depend on build-libs so that we are
# assured of having a set of documentation that is based on the latest
# type spec.

compile-docs: build-libs

# build-libs should be dependent on the type specification and the
# type compiler. Building the libs in this way means that you don't
# need to put automatically generated code in a source code version
# control repository (e.g., cvs, git). It also ensures that you always
# have the most up-to-date libs and documentation if your compile-docs
# target depends on the compiled libs.

build-libs:
	compile_typespec \
		--patric \
		--psgi $(SERVICE_PSGI)  \
		--impl Bio::KBase::$(SERVICE_NAME)::$(SERVICE_NAME)Impl \
		--service Bio::KBase::$(SERVICE_NAME)::Service \
		--client Bio::KBase::$(SERVICE_NAME)::Client \
		--py biokbase/$(SERVICE_NAME)/Client \
		--js javascript/$(SERVICE_NAME)/Client \
		--url $(SELF_URL) \
		$(SERVICE_SPEC) lib

# the Makefile.common.rules contains a set of rules that can be used
# in this setup. Because it is included last, it has the effect of
# shadowing any targets defined above. So lease be aware of the
# set of targets in the common rules file.
include $(TOP_DIR)/tools/Makefile.common.rules
