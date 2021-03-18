#
# "make pull" to bringing new changes from upstream
# "make list" to list one line summary of each new change
# "make diff" to show diff of all new changes
# "make updated-packages" to build only updated packages
# "make all-packages" to rebuild all packages
# "make kimr" to copy built packages to ../melpa-packages
# "make rebase" to rebase site branches
#
# To rebuild one pacakge:
# "make recipes/<pkg name>"

KIMR_PACKAGES = $(shell cat package-list)

# Git branch on which to add site local customizations.
# This is rebased requently!
SITE_BRANCH = site

# File containing main branch name if not "master".
MAIN_BRANCH_FILE = .branch-name

kimr : packages/archive-contents
	cp -a packages/* ../melpa-packages

# Create site local branch on all git repos
mk-site-branch :
	@for pkg in $(KIMR_PACKAGES); do \
	  if [ -d $(PWD)/working/$$pkg/.git ] ; then \
	    echo "Creating branched named '$(SITE_BRANCH)' for working/$$pkg ..."; \
	    cd $(PWD)/working/$$pkg; \
	    git branch $(SITE_BRANCH); \
	  elif [ -d $(PWD)/working/$$pkg ] ; then \
	    echo "Warning: $$pkg is not a git repo"; \
	  else \
	    echo "Error:: working/$$pkg does not exist"; \
	  fi \
	done

rebase :
	@echo "Rebasing $(SITE_BRANCH) branch in all repos ..."
	@for pkg in $(KIMR_PACKAGES); do \
	  if [ -d $(PWD)/working/$$pkg/.git ] ; then \
	    echo ""; \
	    echo "Rebasing '$(SITE_BRANCH)' for working/$$pkg ..."; \
	    cd $(PWD)/working/$$pkg; \
	    git checkout $(SITE_BRANCH); \
	    if [ -f $(MAIN_BRANCH_FILE) ]; then \
	      parent_branch=`cat $(MAIN_BRANCH_FILE)`; \
	    else \
	      parent_branch=master; \
	    fi; \
	    git rebase $$parent_branch; \
	    git checkout $$parent_branch; \
	  fi \
	done

list :
	@echo "List all changes made since $(SITE_BRANCH) ..."
	@for pkg in $(KIMR_PACKAGES); do \
	  if [ -f $(PWD)/working/$$pkg/$(MAIN_BRANCH_FILE) ]; then \
	    branch=`cat $(PWD)/working/$$pkg/$(MAIN_BRANCH_FILE)`; \
	  else \
	    branch=master; \
	  fi; \
	  if [ -d $(PWD)/working/$$pkg/.git ] ; then \
	    cd $(PWD)/working/$$pkg; \
	    if ! git diff --quiet $(SITE_BRANCH) $$branch; then \
	      echo ""; \
	      echo "$$pkg"; \
	      git log --oneline --graph --format='%ai %h %an %s' -9 $(SITE_BRANCH)..HEAD; \
	    fi; \
	  fi \
	done


list-site :
	@echo "List changes made in $(SITE_BRANCH)"
	@for pkg in $(KIMR_PACKAGES); do \
	  if [ -d $(PWD)/working/$$pkg/.git ] ; then \
	    cd $(PWD)/working/$$pkg; \
	    if [ $$pkg = google-c-style ]; then \
		PARENT=gh-pages; \
	    elif [ $$pkg = neotree ]; then \
		PARENT=dev; \
	    elif [ $$pkg = ox-jira ]; then \
		PARENT=trunk; \
	    elif [ $$pkg = rcirc-styles ]; then \
		PARENT=develop; \
	    else \
		PARENT=master; \
	    fi; \
	    git branch | grep -q -e \\b${SITE_BRANCH}\\b || git branch ${SITE_BRANCH}; \
	    if [ ! `git rev-list ${SITE_BRANCH} ^$${PARENT} | wc -l` = "0" ]; then \
	      echo "$$pkg has changes in ${SITE_BRANCH}:"; \
	      git log --oneline ${SITE_BRANCH} ^$${PARENT}; \
	    fi; \
	  fi; \
	done

pull :
	@echo "Update all packages by doing 'git pull' ..."
	@PKGS=`(cd working; ls)`; \
	for pkg in $$PKGS; do \
	  echo ""; \
	  if [ -d $(PWD)/working/$$pkg/.git ] ; then \
	    echo "Updating working/$$pkg ..."; \
	    cd $(PWD)/working/$$pkg; \
	    if [ -f $(MAIN_BRANCH_FILE) ]; then \
	      branch=`cat $(MAIN_BRANCH_FILE)`; \
	    else \
	      branch=master; \
	    fi; \
	    git checkout $$branch; \
	    git pull; \
	  elif [ -d $(PWD)/working/$$pkg ] ; then \
	    echo "Warning: $$pkg is not a git repo"; \
	  else \
	    $(MAKE) -C $(PWD) recipes/$$pkg; \
	  fi \
	done

DATE = '2020-01-24 06:00'

update-by-date : co-by-date all-packages rm-melpa-packages kimr

rm-melpa-packages :
	rm ~/Public/emacs18/melpa-packages/*

co-by-date :
	@echo "Checkout all packages at $(DATE) ..."
	@PKGS=`(cd working; ls)`; \
	for pkg in $$PKGS; do \
	  echo ""; \
	  if [ -d $(PWD)/working/$$pkg/.git ] ; then \
	    echo "Updating working/$$pkg ..."; \
	    cd $(PWD)/working/$$pkg; \
	    git checkout "master@{$(DATE)}"; \
	  elif [ -d $(PWD)/working/$$pkg ] ; then \
	    echo "Warning: $$pkg is not a git repo"; \
	  else \
	    $(MAKE) -C $(PWD) recipes/$$pkg; \
	  fi \
	done

diff-by-date :
	@echo "Checkout all packages by date ..."
	@PKGS=`(cd working; ls)`; \
	for pkg in $$PKGS; do \
	  echo ""; \
	  if [ -d $(PWD)/working/$$pkg/.git ] ; then \
	    echo "Diffing working/$$pkg ..."; \
	    cd $(PWD)/working/$$pkg; \
	    git log --oneline --graph --format='%ai %h %an %s' 'master@{2020-01-24 06:00:00}..master@{2020-01-25 06:00:00}'; \
	  fi \
	done

update-pkg-list :
	@grep -e "^ (" packages/archive-contents  | sed "s/^ (\(.*\) \./\1/" | sort > package-list
	@echo "Updated package-list file from packages/archive-contents"


diff :
	@echo "Show unified diff of all repos since $(SITE_BRANCH) ..."
	@for pkg in $(KIMR_PACKAGES); do \
	  if [ -d $(PWD)/working/$$pkg/.git ] ; then \
	    echo "Diff working/$$pkg ..."; \
	    cd $(PWD)/working/$$pkg; \
	    git checkout $(SITE_BRANCH); \
	    git diff -R master; \
	  elif [ -d $(PWD)/working/$$pkg ] ; then \
	    echo "Warning: $$pkg is not a git repo"; \
	  else \
	    echo "Error:: working/$$pkg does not exist"; \
	  fi \
	done

#  $(patsubst %,$(RCPDIR)/%,$(KIMR_PACKAGES))
# Rebuild a package only if master branch is not the same as site branch.
# FIXME: not yet done.  See also 'packages' target in Makefile.
my-packages:
	@for pkg in $(KIMR_PACKAGES); do \
	  cd $(PWD)/working/$$pkg; \
	  if [ ! diff -s --exit-code master $(SITE_BRANCH) ]; then \
	    echo "Rebuilding $$pkg ..."; \
	  fi; \
	done

updated-packages :
	@PKGS=`(cd working; ls)`; \
	for pkg in $$PKGS; do \
	  if [ ! -d $(PWD)/working/$$pkg/.git ] ; then \
	    echo "Warning: $$pkg is not a git repo"; \
	    continue; \
	  fi; \
	  cd $(PWD)/working/$$pkg; \
	  if ! git rev-parse --verify $(SITE_BRANCH) > /dev/null; then \
	    echo "Info: created $(SITE_BRANCH) branch for $$pkg"; \
	    git checkout -b $(SITE_BRANCH); \
	  fi; \
	  if [ -f $(MAIN_BRANCH_FILE) ]; then \
	    parent_branch=`cat $(MAIN_BRANCH_FILE)`; \
	  else \
	    parent_branch=master; \
	  fi; \
	  if git diff --quiet $(SITE_BRANCH) $${parent_branch}; then \
	    continue; \
	  fi; \
	  echo ""; \
	  echo "Building $$pkg ..."; \
	  cd $(PWD); \
	  $(MAKE) recipes/$$pkg; \
	  cp -a $(PWD)/packages/$$pkg-20* $(PWD)/packages/$$pkg-badge.svg \
	    $(PWD)/packages/$$pkg-readme.txt $(PWD)/../melpa-packages; \
	  if [ -f $(PWD)/packages/$$pkg-readme.txt ]; then \
	    cp -a $(PWD)/packages/$$pkg-readme.txt $(PWD)/../melpa-packages; \
	  fi; \
	done
	cp -a $(PWD)/packages/archive-contents $(PWD)/../melpa-packages


all-packages :
	@PKGS=`(cd working; ls)`; \
	for pkg in $$PKGS; do \
	  echo "Building $$pkg ..."; \
	  $(MAKE) recipes/$$pkg; \
	done

diff-list :
	cd working; ls > ../packages-in-working
	diff -u package-list packages-in-working

# Sandbox for doing random stuff.
site :
	@PKGS=`(cd working; ls)`; \
	for pkg in $$PKGS; do \
	  cd $(PWD)/working/$$pkg; \
	  git checkout master; \
	done
#	  git branch | grep -q -e '\bsite\b' || (echo "create 'site' branch in $$pkg"; git checkout -b site); \

list-packages :
	@cd ../melpa-packages; ls *.entry | sed 's/\(.*\)-20[0-9][0-9].*/\1/' | sort | uniq
