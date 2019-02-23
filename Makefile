
.PHONY: test

clean-derived:
	rm -rf ~/Library/Developer/Xcode/DerivedData/Entropy-*

clean:
	@echo "+ $@"
	@xcodebuild clean \
		-workspace Entropy.xcworkspace \
		-scheme Entropy

clean-containers:
	@echo "+ $@"
	@rm -rf ~/Library/Containers/com.kodeshack.Entropy*

test:
	@echo "+ $@"
	@xcodebuild test \
		-quiet \
		-workspace Entropy.xcworkspace \
		-scheme Entropy \
		-destination 'platform=OS X,arch=x86_64'

format:
	@echo "+ $@"
	@./Pods/SwiftFormat/CommandLineTool/swiftformat \
		--swiftversion '4.2' \
		Sources Tests

reset-dev-team:
	@echo "+ $@"
	@sed \
		-e 's/\(DEVELOPMENT_TEAM = \)[[:alnum:]]*/\1""/g' \
		-e '/DevelopmentTeam = [[:alnum:]]*;/d' \
		-i "" Entropy.xcodeproj/project.pbxproj
